from __future__ import annotations

import hashlib
import json
import os
from pathlib import Path
import tempfile
from typing import Any

from .errors import AdapterError


_ENTITY_SOURCES = {
    "pet": "core",
    "handbook": "handbook",
    "skill": "skill_catalog",
}


def _fingerprint(value: dict[str, Any]) -> str:
    encoded = json.dumps(
        value,
        ensure_ascii=False,
        sort_keys=True,
        separators=(",", ":"),
    ).encode("utf-8")
    return hashlib.sha256(encoded).hexdigest()


def _revision_by_source(normalized: dict[str, Any]) -> dict[str, int]:
    result: dict[str, int] = {}
    for source in normalized["source_revisions"]:
        key = source.get("source_key")
        revision = source.get("revision_id")
        if isinstance(key, str) and isinstance(revision, int):
            result[key] = revision
    return result


def identity_candidates(normalized: dict[str, Any]) -> list[dict[str, Any]]:
    revisions = _revision_by_source(normalized)
    candidates: list[dict[str, Any]] = []
    definitions = (
        (
            "pet",
            normalized["pets"],
            "pet_id",
            lambda row: {
                key: row.get(key)
                for key in ("name", "title", "handbook_id", "form", "stage")
            },
        ),
        (
            "handbook",
            normalized["handbook_entries"],
            "handbook_id",
            lambda row: {
                key: row.get(key) for key in ("dex_no", "display_name")
            },
        ),
        (
            "skill",
            normalized["skills"],
            "skill_id",
            lambda row: {
                key: row.get(key)
                for key in ("upstream_numeric_id", "name", "category")
            },
        ),
    )
    for entity_kind, rows, id_key, fingerprint_value in definitions:
        source_key = _ENTITY_SOURCES[entity_kind]
        revision_id = revisions.get(source_key)
        if revision_id is None:
            raise AdapterError(f"No source revision for identity kind {entity_kind}")
        for row in rows:
            local_id = row[id_key]
            candidates.append(
                {
                    "entity_kind": entity_kind,
                    "local_id": local_id,
                    "source_system": "bwiki.rocom",
                    "source_record_key": local_id,
                    "first_revision_id": revision_id,
                    "fingerprint_sha256": _fingerprint(fingerprint_value(row)),
                    "remapped_from": [],
                }
            )
    return sorted(
        candidates,
        key=lambda item: (item["entity_kind"], item["source_record_key"]),
    )


def _read_registry(path: Path) -> dict[str, Any]:
    try:
        document = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeDecodeError, json.JSONDecodeError) as error:
        raise AdapterError(f"Cannot read identity registry {path}: {error}") from error
    if document.get("dataset_id") != "roco-world-zh-cn":
        raise AdapterError("Identity registry dataset does not match")
    mappings = document.get("mappings")
    if not isinstance(mappings, list) or not all(isinstance(item, dict) for item in mappings):
        raise AdapterError("Identity registry mappings must be an array of objects")
    return document


def initialize_identity_registry(
    path: Path,
    normalized: dict[str, Any],
) -> int:
    current = _read_registry(path)
    if current["mappings"]:
        raise AdapterError("Identity registry is already initialized")
    mappings = identity_candidates(normalized)
    document = {
        "registry_version": 1,
        "dataset_id": normalized["dataset_id"],
        "mappings": mappings,
    }
    path.parent.mkdir(parents=True, exist_ok=True)
    file_descriptor, temporary_name = tempfile.mkstemp(
        prefix=f".{path.name}.",
        dir=path.parent,
        text=True,
    )
    try:
        with os.fdopen(file_descriptor, "w", encoding="utf-8") as handle:
            json.dump(document, handle, ensure_ascii=True, indent=2, sort_keys=True)
            handle.write("\n")
            handle.flush()
            os.fsync(handle.fileno())
        os.replace(temporary_name, path)
    except OSError as error:
        try:
            os.unlink(temporary_name)
        except OSError:
            pass
        raise AdapterError(f"Cannot initialize identity registry {path}: {error}") from error
    return len(mappings)


def audit_identity_registry(
    path: Path,
    normalized: dict[str, Any],
) -> dict[str, Any]:
    registry = _read_registry(path)
    expected = identity_candidates(normalized)
    actual = registry["mappings"]
    if not actual:
        return {
            "status": "initialization_required",
            "blocking_issues": [{"code": "identity_registry_empty"}],
            "mapping_count": 0,
            "candidate_count": len(expected),
        }

    def keyed(items: list[dict[str, Any]]) -> dict[tuple[str, str], dict[str, Any]]:
        result: dict[tuple[str, str], dict[str, Any]] = {}
        for item in items:
            kind = item.get("entity_kind")
            source_key = item.get("source_record_key")
            if not isinstance(kind, str) or not isinstance(source_key, str):
                raise AdapterError("Identity registry entry has an invalid key")
            key = (kind, source_key)
            if key in result:
                raise AdapterError(f"Identity registry repeats {kind}:{source_key}")
            result[key] = item
        return result

    expected_by_key = keyed(expected)
    actual_by_key = keyed(actual)
    additions = sorted(set(expected_by_key) - set(actual_by_key))
    removals = sorted(set(actual_by_key) - set(expected_by_key))
    local_id_conflicts = [
        {
            "entity_kind": key[0],
            "source_record_key": key[1],
            "registry_local_id": actual_by_key[key].get("local_id"),
            "current_local_id": expected_by_key[key].get("local_id"),
        }
        for key in sorted(set(expected_by_key) & set(actual_by_key))
        if actual_by_key[key].get("local_id") != expected_by_key[key].get("local_id")
    ]
    fingerprint_changes = [
        {"entity_kind": key[0], "source_record_key": key[1]}
        for key in sorted(set(expected_by_key) & set(actual_by_key))
        if actual_by_key[key].get("fingerprint_sha256")
        != expected_by_key[key].get("fingerprint_sha256")
    ]
    blocking: list[dict[str, Any]] = []
    if additions:
        blocking.append({"code": "unregistered_entities", "items": additions})
    if removals:
        blocking.append({"code": "identity_removal_candidates", "items": removals})
    if local_id_conflicts:
        blocking.append({"code": "identity_local_id_conflicts", "items": local_id_conflicts})
    if fingerprint_changes:
        blocking.append(
            {"code": "identity_fingerprint_changes", "items": fingerprint_changes}
        )
    return {
        "status": "blocked" if blocking else "passed",
        "blocking_issues": blocking,
        "mapping_count": len(actual),
        "candidate_count": len(expected),
        "fingerprint_changes": fingerprint_changes,
        "unreviewed_removal_count": len(removals),
    }
