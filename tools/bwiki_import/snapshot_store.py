from __future__ import annotations

from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path
import shutil
import tempfile
from typing import Any

from .errors import InputError, SnapshotWriteError
from .models import FrozenSnapshot, SourceSpec, ValidatedResponse
from .response_validator import validate_response


_IMPORT_LEVELS = {"required", "adapter_review"}


def _read_config(path: Path) -> tuple[str, list[SourceSpec]]:
    try:
        document = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeDecodeError, json.JSONDecodeError) as error:
        raise InputError(f"Cannot read source configuration {path}: {error}") from error

    dataset_id = document.get("dataset_id")
    if not isinstance(dataset_id, str) or not dataset_id:
        raise InputError("Source configuration requires a non-empty dataset_id")

    raw_sources = document.get("sources")
    if not isinstance(raw_sources, list):
        raise InputError("Source configuration requires a sources array")

    specs: list[SourceSpec] = []
    seen_keys: set[str] = set()
    for raw in raw_sources:
        if not isinstance(raw, dict):
            raise InputError("Every source entry must be an object")
        source_key = raw.get("source_key")
        title = raw.get("title")
        level = raw.get("level")
        filenames = raw.get("local_filenames", [])
        if (
            not isinstance(source_key, str)
            or not isinstance(title, str)
            or not isinstance(level, str)
            or not isinstance(filenames, list)
            or not all(isinstance(item, str) and item for item in filenames)
        ):
            raise InputError(f"Invalid source configuration entry: {raw!r}")
        if source_key in seen_keys:
            raise InputError(f"Duplicate source key: {source_key}")
        seen_keys.add(source_key)
        if not filenames:
            filenames = [title.replace(":", "_").replace("/", "_") + ".json"]
        specs.append(SourceSpec(source_key, title, level, tuple(filenames)))
    return dataset_id, specs


def _find_input(input_dir: Path, spec: SourceSpec) -> Path | None:
    matches = [input_dir / name for name in spec.local_filenames if (input_dir / name).is_file()]
    if len(matches) > 1:
        raise InputError(
            f"Multiple local files match {spec.source_key}: "
            + ", ".join(path.name for path in matches)
        )
    return matches[0] if matches else None


def _snapshot_id(responses: list[ValidatedResponse]) -> str:
    identity = [
        {
            "source_key": response.spec.source_key,
            "revision_id": response.revision_id,
            "content_sha256": response.content_sha256,
            "response_sha256": response.response_sha256,
        }
        for response in sorted(responses, key=lambda item: item.spec.source_key)
    ]
    digest = hashlib.sha256(
        json.dumps(identity, sort_keys=True, separators=(",", ":")).encode("utf-8")
    ).hexdigest()
    return f"snapshot-{digest[:16]}"


def _verify_existing(
    target: Path,
    snapshot_id: str,
    responses: list[ValidatedResponse],
) -> FrozenSnapshot:
    lock_path = target / "sources.lock.json"
    try:
        lock = json.loads(lock_path.read_text(encoding="utf-8"))
    except (OSError, UnicodeDecodeError, json.JSONDecodeError) as error:
        raise SnapshotWriteError(
            f"Existing snapshot {target} has no valid source lock: {error}"
        ) from error
    if lock.get("snapshot_id") != snapshot_id:
        raise SnapshotWriteError(f"Existing snapshot ID mismatch at {target}")

    locked_sources = {
        source.get("source_key"): source
        for source in lock.get("sources", [])
        if isinstance(source, dict)
    }
    for response in responses:
        locked = locked_sources.get(response.spec.source_key)
        if not locked or locked.get("response_sha256") != response.response_sha256:
            raise SnapshotWriteError(
                f"Existing snapshot differs for source {response.spec.source_key}"
            )
        response_path = target / str(locked["response_file"])
        content_path = target / str(locked["content_file"])
        if hashlib.sha256(response_path.read_bytes()).hexdigest() != response.response_sha256:
            raise SnapshotWriteError(f"Frozen response changed: {response_path}")
        if hashlib.sha256(content_path.read_bytes()).hexdigest() != response.content_sha256:
            raise SnapshotWriteError(f"Frozen content changed: {content_path}")

    return FrozenSnapshot(
        snapshot_id=snapshot_id,
        path=target,
        lock_path=lock_path,
        source_keys=tuple(sorted(locked_sources)),
        reused_existing=True,
    )


def import_local_snapshot(
    input_dir: Path,
    output_root: Path,
    config_path: Path,
) -> FrozenSnapshot:
    if not input_dir.is_dir():
        raise InputError(f"Input directory does not exist: {input_dir}")

    dataset_id, specs = _read_config(config_path)
    responses: list[ValidatedResponse] = []
    missing_required: list[str] = []
    missing_review: list[str] = []

    for spec in specs:
        if spec.level not in _IMPORT_LEVELS:
            continue
        path = _find_input(input_dir, spec)
        if path is None:
            if spec.level == "required":
                missing_required.append(spec.source_key)
            else:
                missing_review.append(spec.source_key)
            continue
        responses.append(validate_response(path, spec))

    if missing_required:
        raise InputError("Missing required local responses: " + ", ".join(missing_required))

    snapshot_id = _snapshot_id(responses)
    output_root.mkdir(parents=True, exist_ok=True)
    target = output_root / snapshot_id
    if target.exists():
        return _verify_existing(target, snapshot_id, responses)

    lock: dict[str, Any] = {
        "lock_version": 1,
        "dataset_id": dataset_id,
        "snapshot_id": snapshot_id,
        "imported_at_utc": datetime.now(timezone.utc).isoformat().replace("+00:00", "Z"),
        "import_mode": "local_responses",
        "transport_evidence": "not_available_for_local_files",
        "missing_adapter_review_sources": sorted(missing_review),
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
            (stage / "content" / f"{response.spec.source_key}.lua").write_bytes(
                response.content.encode("utf-8")
            )
        lock_path = stage / "sources.lock.json"
        lock_path.write_text(
            json.dumps(lock, ensure_ascii=False, indent=2, sort_keys=True) + "\n",
            encoding="utf-8",
        )
        os.rename(stage, target)
    except OSError as error:
        raise SnapshotWriteError(f"Cannot freeze snapshot {snapshot_id}: {error}") from error
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
