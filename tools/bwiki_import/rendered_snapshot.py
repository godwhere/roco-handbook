from __future__ import annotations

from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path
import shutil
import tempfile
from typing import Any

from .errors import InputError, ResponseValidationError, SnapshotWriteError
from .models import FrozenSnapshot


def _validated_metadata(path: Path) -> tuple[bytes, dict[str, Any]]:
    try:
        raw_bytes = path.read_bytes()
        document = json.loads(raw_bytes)
    except OSError as error:
        raise InputError(f"Cannot read {path}: {error}") from error
    except (UnicodeDecodeError, json.JSONDecodeError) as error:
        raise ResponseValidationError(
            f"{path.name}: response is not valid UTF-8 JSON: {error}"
        ) from error

    if not isinstance(document, dict) or document.get("error") is not None:
        raise ResponseValidationError(
            f"{path.name}: rendered page response contains an API error"
        )
    parsed = document.get("parse")
    if not isinstance(parsed, dict):
        raise ResponseValidationError(f"{path.name}: parse must be an object")
    page_id = parsed.get("pageid")
    revision_id = parsed.get("revid")
    title = parsed.get("title")
    html = parsed.get("text")
    if (
        not isinstance(page_id, int)
        or isinstance(page_id, bool)
        or page_id <= 0
        or not isinstance(revision_id, int)
        or isinstance(revision_id, bool)
        or revision_id <= 0
        or not isinstance(title, str)
        or not title
        or not isinstance(html, str)
        or not html
    ):
        raise ResponseValidationError(
            f"{path.name}: rendered page metadata or HTML is invalid"
        )
    return raw_bytes, {
        "page_id": page_id,
        "page_revision_id": revision_id,
        "page_title": title,
    }


def import_rendered_index_response(
    input_path: Path,
    output_root: Path,
) -> FrozenSnapshot:
    raw_bytes, metadata = _validated_metadata(input_path)
    response_sha256 = hashlib.sha256(raw_bytes).hexdigest()
    snapshot_id = f"rendered-index-{response_sha256[:16]}"
    target = output_root / snapshot_id
    lock_path = target / "sources.lock.json"
    response_file = "responses/pet_index.json"

    if target.exists():
        try:
            lock = json.loads(lock_path.read_text(encoding="utf-8"))
            frozen = target / response_file
            frozen_sha256 = hashlib.sha256(frozen.read_bytes()).hexdigest()
        except (OSError, UnicodeDecodeError, json.JSONDecodeError) as error:
            raise SnapshotWriteError(
                f"Existing rendered-index snapshot is invalid: {error}"
            ) from error
        if (
            lock.get("snapshot_id") != snapshot_id
            or lock.get("response_sha256") != response_sha256
            or frozen_sha256 != response_sha256
        ):
            raise SnapshotWriteError(
                f"Existing rendered-index snapshot differs at {target}"
            )
        return FrozenSnapshot(
            snapshot_id=snapshot_id,
            path=target,
            lock_path=lock_path,
            source_keys=("pet_index_render",),
            reused_existing=True,
        )

    output_root.mkdir(parents=True, exist_ok=True)
    stage = Path(tempfile.mkdtemp(prefix=f".{snapshot_id}.", dir=output_root))
    try:
        (stage / "responses").mkdir()
        (stage / response_file).write_bytes(raw_bytes)
        lock = {
            "lock_version": 1,
            "dataset_id": "roco-world-zh-cn",
            "snapshot_id": snapshot_id,
            "source_key": "pet_index_render",
            "imported_at_utc": datetime.now(timezone.utc)
            .isoformat()
            .replace("+00:00", "Z"),
            "import_mode": "local_rendered_page_response",
            "response_file": response_file,
            "response_bytes": len(raw_bytes),
            "response_sha256": response_sha256,
            **metadata,
        }
        (stage / "sources.lock.json").write_text(
            json.dumps(lock, ensure_ascii=False, indent=2, sort_keys=True) + "\n",
            encoding="utf-8",
        )
        os.rename(stage, target)
    except OSError as error:
        raise SnapshotWriteError(
            f"Cannot freeze rendered-index snapshot {snapshot_id}: {error}"
        ) from error
    finally:
        if stage.exists():
            shutil.rmtree(stage)

    return FrozenSnapshot(
        snapshot_id=snapshot_id,
        path=target,
        lock_path=target / "sources.lock.json",
        source_keys=("pet_index_render",),
        reused_existing=False,
    )
