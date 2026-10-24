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
from .models import FrozenSnapshot, SourceSpec, ValidatedResponse
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


def _revision_head(document: dict[str, Any], spec: SourceSpec) -> tuple[int, str, int]:
    if not isinstance(document, dict) or document.get("error") is not None:
        raise ResponseValidationError(f"{spec.title}: module head query failed")
    query = document.get("query")
    pages = query.get("pages") if isinstance(query, dict) else None
    if not isinstance(pages, list) or len(pages) != 1:
        raise ResponseValidationError(f"{spec.title}: expected exactly one module head")
    page = pages[0]
    if not isinstance(page, dict) or "missing" in page or "invalid" in page:
        raise ResponseValidationError(f"{spec.title}: module head is missing or invalid")
    page_id = page.get("pageid")
    title = page.get("title")
    revisions = page.get("revisions")
    if (
        not isinstance(page_id, int) or isinstance(page_id, bool) or page_id <= 0
        or not isinstance(title, str)
        or title.split(":", 1)[-1] != spec.title.split(":", 1)[-1]
        or not isinstance(revisions, list) or len(revisions) != 1
        or not isinstance(revisions[0], dict)
    ):
        raise ResponseValidationError(f"{spec.title}: invalid module head identity")
    revision_id = revisions[0].get("revid")
    if not isinstance(revision_id, int) or isinstance(revision_id, bool) or revision_id <= 0:
        raise ResponseValidationError(f"{spec.title}: invalid module head revision")
    return page_id, title, revision_id


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
    imported_specs = [spec for spec in specs if spec.level in _IMPORT_LEVELS]
    if not imported_specs:
        raise InputError("Live source configuration has no importable modules")

    requested = False

    def request(form: dict[str, str]) -> dict[str, Any]:
        nonlocal requested
        if requested:
            sleep(float(interval))
        requested = True
        return client.post_json(endpoint, form)

    def heads() -> dict[str, tuple[int, str, int]]:
        return {
            spec.source_key: _revision_head(
                request({
                    "action": "query",
                    "format": "json",
                    "formatversion": "2",
                    "prop": "revisions",
                    "rvprop": "ids",
                    "titles": spec.title,
                }),
                spec,
            )
            for spec in imported_specs
        }

    responses: list[ValidatedResponse] = []
    temporary = Path(tempfile.mkdtemp(prefix="roco-live-snapshot."))
    try:
        frozen_heads = heads()
        for spec in imported_specs:
            document = request(
                {
                    "action": "query",
                    "format": "json",
                    "formatversion": "2",
                    "prop": "revisions",
                    "rvprop": "ids|timestamp|sha1|size|content",
                    "rvslots": "main",
                    "revids": str(frozen_heads[spec.source_key][2]),
                },
            )
            response_path = temporary / f"{spec.source_key}.json"
            response_path.write_text(
                json.dumps(document, ensure_ascii=False, separators=(",", ":")),
                encoding="utf-8",
            )
            response = validate_response(response_path, spec)
            body_revision = (response.page_id, response.canonical_title, response.revision_id)
            if body_revision != frozen_heads[spec.source_key]:
                raise ResponseValidationError(f"{spec.title}: body does not match frozen revision")
            if response.content_model != "Scribunto" or not response.content.strip():
                raise ResponseValidationError(f"{spec.title}: expected non-empty Scribunto content")
            responses.append(response)

        if heads() != frozen_heads:
            raise ResponseValidationError("Module heads changed during import; no snapshot was frozen")

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
            "revision_set_verified": True,
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
