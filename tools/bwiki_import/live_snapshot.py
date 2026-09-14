from __future__ import annotations

from datetime import datetime, timezone
import json
import os
from pathlib import Path
import shutil
import tempfile
import time
from typing import Any, Callable
from urllib.parse import urlparse

from .errors import InputError, ResponseValidationError, SnapshotWriteError
from .image_assets import UrlTransport
from .models import FrozenSnapshot, ValidatedResponse
from .response_validator import validate_response
from .snapshot_store import (
    _IMPORT_LEVELS,
    _read_config,
    _snapshot_id,
    _verify_existing,
)


def _positive_integer(value: Any, label: str) -> int:
    if not isinstance(value, int) or isinstance(value, bool) or value <= 0:
        raise InputError(f"{label} must be a positive integer")
    return value


def import_live_snapshot(
    output_root: Path,
    config_path: Path,
    *,
    transport: UrlTransport | None = None,
    sleep: Callable[[float], None] = time.sleep,
) -> FrozenSnapshot:
    config, specs = _read_config(config_path)
    endpoint = config.get("endpoint")
    source_system = config.get("source_system")
    policy = config.get("request_policy")
    if (
        not isinstance(endpoint, str)
        or urlparse(endpoint).scheme != "https"
        or not isinstance(source_system, str)
        or not source_system
        or not isinstance(policy, dict)
    ):
        raise InputError("Live source configuration is incomplete")
    timeout = max(
        _positive_integer(policy.get("connect_timeout_seconds"), "connect timeout"),
        _positive_integer(policy.get("read_timeout_seconds"), "read timeout"),
    )
    max_retries = _positive_integer(policy.get("max_retries"), "max retries")
    interval = policy.get("minimum_interval_seconds")
    if not isinstance(interval, (int, float)) or isinstance(interval, bool) or interval < 0:
        raise InputError("minimum_interval_seconds must be non-negative")
    client = transport or UrlTransport(
        timeout_seconds=timeout,
        max_retries=max_retries,
    )

    responses: list[ValidatedResponse] = []
    temporary = Path(tempfile.mkdtemp(prefix="roco-live-snapshot."))
    try:
        imported_specs = [spec for spec in specs if spec.level in _IMPORT_LEVELS]
        for index, spec in enumerate(imported_specs):
            if index:
                sleep(float(interval))
            document = client.post_json(
                endpoint,
                {
                    "action": "query",
                    "format": "json",
                    "formatversion": "2",
                    "prop": "revisions",
                    "rvprop": "ids|timestamp|sha1|size|content",
                    "rvslots": "main",
                    "titles": spec.title,
                },
            )
            response_path = temporary / f"{spec.source_key}.json"
            response_path.write_text(
                json.dumps(document, ensure_ascii=False, separators=(",", ":")),
                encoding="utf-8",
            )
            responses.append(validate_response(response_path, spec))

        snapshot_id = _snapshot_id(responses)
        output_root.mkdir(parents=True, exist_ok=True)
        target = output_root / snapshot_id
        if target.exists():
            return _verify_existing(target, snapshot_id, responses)

        lock = {
            "lock_version": 1,
            "dataset_id": config["dataset_id"],
            "snapshot_id": snapshot_id,
            "imported_at_utc": datetime.now(timezone.utc)
            .isoformat()
            .replace("+00:00", "Z"),
            "import_mode": "mediawiki_api",
            "transport_evidence": "validated_https_mediawiki_api_response",
            "source_system": source_system,
            "api_endpoint": endpoint,
            "missing_adapter_review_sources": [],
            "sources": [
                response.lock_record()
                for response in sorted(responses, key=lambda item: item.spec.source_key)
            ],
        }
        stage = Path(tempfile.mkdtemp(prefix=f".{snapshot_id}.", dir=output_root))
        try:
            (stage / "responses").mkdir()
            (stage / "content").mkdir()
            for response in responses:
                (stage / "responses" / f"{response.spec.source_key}.json").write_bytes(
                    response.raw_bytes
                )
                (stage / "content" / f"{response.spec.source_key}.lua").write_text(
                    response.content,
                    encoding="utf-8",
                )
            (stage / "sources.lock.json").write_text(
                json.dumps(lock, ensure_ascii=False, indent=2, sort_keys=True) + "\n",
                encoding="utf-8",
            )
            os.rename(stage, target)
        except OSError as error:
            raise SnapshotWriteError(f"Cannot freeze live snapshot {snapshot_id}: {error}") from error
        finally:
            if stage.exists():
                shutil.rmtree(stage)
        return FrozenSnapshot(
            snapshot_id=snapshot_id,
            path=target,
            lock_path=target / "sources.lock.json",
            source_keys=tuple(sorted(response.spec.source_key for response in responses)),
            reused_existing=False,
        )
    except ResponseValidationError:
        raise
    finally:
        shutil.rmtree(temporary, ignore_errors=True)
