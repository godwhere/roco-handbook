from __future__ import annotations

import hashlib
import json
from pathlib import Path
import re
from typing import Any

from .errors import AdapterError


_KINDS = {
    "skill": ("skills", "skill_id", r"skill_\d{6}"),
    "learnset": ("learnsets", "learnset_id", r"learnset_[0-9a-f]{12}"),
    "evolution_group": ("evolution_groups", "evolution_group_id", r"evolution_[0-9a-f]{12}"),
}


def apply_reviewed_nrc_identities(
    normalized: dict[str, Any], review_path: Path, previous_catalog: Path | None,
) -> None:
    try:
        raw = review_path.read_bytes()
        review = json.loads(raw)
        previous_hash = hashlib.sha256(previous_catalog.read_bytes()).hexdigest() if previous_catalog else None
    except (OSError, json.JSONDecodeError) as error:
        raise AdapterError(f"Cannot read NRC identity review: {error}") from error
    if (
        not isinstance(review, dict) or review.get("config_version") != 1
        or review.get("dataset_id") != normalized["dataset_id"]
        or review.get("snapshot_id") != normalized["snapshot_id"]
        or previous_hash is None or review.get("previous_catalog_sha256") != previous_hash
    ):
        raise AdapterError("NRC identity review does not match the snapshot and previous Catalog")
    mappings = review.get("mappings")
    if not isinstance(mappings, dict) or set(mappings) != set(_KINDS):
        raise AdapterError("NRC identity review requires skill, learnset, and evolution mappings")
    for kind, (table, column, pattern) in _KINDS.items():
        mapping = mappings[kind]
        sources = {row[column] for row in normalized[table]}
        if (
            not isinstance(mapping, dict) or set(mapping) - sources
            or any(not isinstance(target, str) or re.fullmatch(pattern, target) is None for target in mapping.values())
        ):
            raise AdapterError(f"NRC identity review has invalid {kind} mappings")
        targets = [mapping.get(source, source) for source in sources]
        if len(targets) != len(set(targets)):
            raise AdapterError(f"NRC identity review merges distinct {kind} records")

    def remap(table: str, column: str, kind: str) -> None:
        for row in normalized[table]:
            value = row.get(column)
            if value is not None:
                row[column] = mappings[kind].get(value, value)

    for table in (
        "skills", "skill_description_notes", "learnset_native_skills", "learnset_blood_skills",
        "learnset_skill_stones", "learnset_legendary_skills",
    ):
        remap(table, "skill_id", "skill")
    for table in ("pets", "learnsets"):
        remap(table, "feature_skill_id", "skill")
    for table in (
        "learnsets", "pet_learnsets", "learnset_native_skills", "learnset_blood_skills",
        "learnset_skill_stones", "learnset_legendary_skills",
    ):
        remap(table, "learnset_id", "learnset")
    for table in ("evolution_groups", "pet_evolution_groups", "evolution_edges"):
        remap(table, "evolution_group_id", "evolution_group")
    for row in normalized["pets"]:
        row["source_evolution_group_ids"] = sorted(
            mappings["evolution_group"].get(value, value)
            for value in row["source_evolution_group_ids"]
        )
    for row in normalized["inspection_summary"]["evolution_type_mismatches"]:
        value = row["evolution_group_id"]
        row["evolution_group_id"] = mappings["evolution_group"].get(value, value)
    for row in normalized["entity_sources"]:
        mapping = mappings.get(row["entity_kind"], {})
        row["entity_id"] = mapping.get(row["entity_id"], row["entity_id"])
    normalized["inspection_summary"]["identity_review"] = {
        "review_sha256": hashlib.sha256(raw).hexdigest(),
        "previous_catalog_sha256": previous_hash,
        "mapping_counts": {kind: len(mapping) for kind, mapping in mappings.items()},
    }
    for table, column, _ in _KINDS.values():
        normalized[table].sort(key=lambda row: row[column])
    normalized["inspection_summary"]["evolution_type_mismatches"].sort(
        key=lambda row: (row["evolution_group_id"], row["pet_id"])
    )
