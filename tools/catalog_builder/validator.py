from __future__ import annotations

import hashlib
import json
from pathlib import Path
from typing import Any

from .errors import AdapterError


def _load_exceptions(path: Path) -> list[dict[str, Any]]:
    try:
        document = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeDecodeError, json.JSONDecodeError) as error:
        raise AdapterError(f"Cannot read reviewed exceptions {path}: {error}") from error
    exceptions = document.get("exceptions")
    if not isinstance(exceptions, list) or not all(
        isinstance(item, dict) for item in exceptions
    ):
        raise AdapterError("Reviewed exceptions must be an array of objects")
    return exceptions


def _unique_ids(rows: list[dict[str, Any]], key: str, errors: list[dict[str, Any]]) -> set[str]:
    values = [row.get(key) for row in rows]
    invalid = [value for value in values if not isinstance(value, str) or not value]
    if invalid:
        errors.append({"code": "invalid_identifier", "field": key, "count": len(invalid)})
    valid = [value for value in values if isinstance(value, str) and value]
    if len(valid) != len(set(valid)):
        errors.append({"code": "duplicate_identifier", "field": key})
    return set(valid)


def _revision_id(normalized: dict[str, Any], source_key: str) -> int | None:
    for source in normalized["source_revisions"]:
        if source.get("source_key") == source_key:
            value = source.get("revision_id")
            return value if isinstance(value, int) else None
    return None


def validate_normalized_catalog(
    normalized: dict[str, Any],
    *,
    reviewed_exceptions_path: Path,
) -> dict[str, Any]:
    blocking: list[dict[str, Any]] = []
    warnings: list[dict[str, Any]] = []

    pet_ids = _unique_ids(normalized["pets"], "pet_id", blocking)
    handbook_ids = _unique_ids(normalized["handbook_entries"], "handbook_id", blocking)
    skill_ids = _unique_ids(normalized["skills"], "skill_id", blocking)
    learnset_ids = _unique_ids(normalized["learnsets"], "learnset_id", blocking)
    evolution_ids = _unique_ids(
        normalized["evolution_groups"],
        "evolution_group_id",
        blocking,
    )
    type_ids = _unique_ids(normalized["types"], "type_id", blocking)
    source_refs = _unique_ids(normalized["source_revisions"], "source_ref", blocking)

    checks = (
        ("pet_handbook", {row["handbook_id"] for row in normalized["pets"]}, handbook_ids),
        (
            "pet_feature_skill",
            {row["feature_skill_id"] for row in normalized["pets"] if row["feature_skill_id"]},
            skill_ids,
        ),
        (
            "learnset_feature_skill",
            {
                row["feature_skill_id"]
                for row in normalized["learnsets"]
                if row["feature_skill_id"]
            },
            skill_ids,
        ),
        ("pet_type", {row["type_id"] for row in normalized["pet_types"]}, type_ids),
        (
            "pet_learnset_pet",
            {row["pet_id"] for row in normalized["pet_learnsets"]},
            pet_ids,
        ),
        (
            "pet_learnset",
            {row["learnset_id"] for row in normalized["pet_learnsets"]},
            learnset_ids,
        ),
        (
            "evolution_member_group",
            {row["evolution_group_id"] for row in normalized["pet_evolution_groups"]},
            evolution_ids,
        ),
        (
            "evolution_member_pet",
            {row["pet_id"] for row in normalized["pet_evolution_groups"]},
            pet_ids,
        ),
        (
            "entity_source",
            {row["source_ref"] for row in normalized["entity_sources"]},
            source_refs,
        ),
    )
    for context, references, targets in checks:
        missing = sorted(references - targets)
        if missing:
            blocking.append(
                {"code": "missing_reference", "context": context, "values": missing}
            )

    for table in (
        "learnset_native_skills",
        "learnset_blood_skills",
        "learnset_skill_stones",
        "learnset_legendary_skills",
    ):
        rows = normalized[table]
        missing_learnsets = sorted({row["learnset_id"] for row in rows} - learnset_ids)
        missing_skills = sorted({row["skill_id"] for row in rows} - skill_ids)
        if missing_learnsets or missing_skills:
            blocking.append(
                {
                    "code": "missing_skill_source_reference",
                    "context": table,
                    "missing_learnsets": missing_learnsets,
                    "missing_skills": missing_skills,
                }
            )

    pet_handbooks = {row["pet_id"]: row["handbook_id"] for row in normalized["pets"]}
    display_mismatches = [
        row["handbook_id"]
        for row in normalized["handbook_display"]
        if row["default_pet_id"] not in pet_ids
        or pet_handbooks.get(row["default_pet_id"]) != row["handbook_id"]
    ]
    if display_mismatches or len(normalized["handbook_display"]) != len(handbook_ids):
        blocking.append(
            {
                "code": "invalid_handbook_display",
                "count": len(display_mismatches),
                "coverage": len(normalized["handbook_display"]),
            }
        )

    member_pairs = {
        (row["evolution_group_id"], row["pet_id"])
        for row in normalized["pet_evolution_groups"]
    }
    if len(member_pairs) != len(normalized["pet_evolution_groups"]):
        blocking.append({"code": "duplicate_evolution_member"})
    edge_membership_failures = [
        {
            "evolution_group_id": row["evolution_group_id"],
            "from_pet_id": row["from_pet_id"],
            "to_pet_id": row["to_pet_id"],
        }
        for row in normalized["evolution_edges"]
        if (row["evolution_group_id"], row["from_pet_id"]) not in member_pairs
        or (row["evolution_group_id"], row["to_pet_id"]) not in member_pairs
    ]
    if edge_membership_failures:
        blocking.append(
            {
                "code": "evolution_edge_endpoint_not_member",
                "items": edge_membership_failures,
            }
        )

    core_pairs = {
        (group_id, row["pet_id"])
        for row in normalized["pets"]
        for group_id in row["source_evolution_group_ids"]
    }
    if core_pairs != member_pairs:
        blocking.append(
            {
                "code": "evolution_membership_source_mismatch",
                "core_only": sorted(core_pairs - member_pairs),
                "evolution_only": sorted(member_pairs - core_pairs),
            }
        )

    entity_targets = {
        "pet": pet_ids,
        "handbook": handbook_ids,
        "skill": skill_ids,
        "learnset": learnset_ids,
        "evolution_group": evolution_ids,
    }
    invalid_entity_sources = [
        {"entity_kind": row["entity_kind"], "entity_id": row["entity_id"]}
        for row in normalized["entity_sources"]
        if row["entity_kind"] not in entity_targets
        or row["entity_id"] not in entity_targets.get(row["entity_kind"], set())
    ]
    if invalid_entity_sources:
        blocking.append(
            {"code": "invalid_entity_source_target", "items": invalid_entity_sources}
        )

    mismatches = normalized["inspection_summary"]["evolution_type_mismatches"]
    mismatch_hash = hashlib.sha256(
        json.dumps(mismatches, sort_keys=True, separators=(",", ":")).encode("utf-8")
    ).hexdigest()
    exceptions = _load_exceptions(reviewed_exceptions_path)
    matching_exception = next(
        (
            item
            for item in exceptions
            if item.get("exception_type") == "evolution_member_type_snapshot_mismatch"
            and item.get("core_revision_id") == _revision_id(normalized, "core")
            and item.get("evolution_revision_id") == _revision_id(normalized, "evolution")
            and item.get("pair_count") == len(mismatches)
            and item.get("pair_set_sha256") == mismatch_hash
            and item.get("resolution") == "use_core_pet_types"
        ),
        None,
    )
    if mismatches and matching_exception is None:
        blocking.append(
            {
                "code": "unreviewed_evolution_type_mismatches",
                "count": len(mismatches),
                "pair_set_sha256": mismatch_hash,
            }
        )

    fields_not_stored = normalized["inspection_summary"][
        "handbook_fields_not_in_v1_database"
    ]
    if fields_not_stored:
        warnings.append(
            {
                "code": "handbook_fields_outside_v1_database",
                "fields": fields_not_stored,
                "preserved_in_normalized_source_extra": True,
            }
        )
    false_coverage = sorted(
        key for key, covered in normalized["coverage"].items() if not covered
    )
    if false_coverage:
        warnings.append({"code": "disabled_coverage", "features": false_coverage})

    return {
        "status": "blocked" if blocking else "passed_with_warnings" if warnings else "passed",
        "blocking_issues": blocking,
        "warnings": warnings,
        "reviewed_evolution_type_exception_id": None
        if matching_exception is None
        else matching_exception.get("exception_id"),
        "counts": {
            "pets": len(pet_ids),
            "handbooks": len(handbook_ids),
            "skills": len(skill_ids),
            "learnsets": len(learnset_ids),
            "evolution_groups": len(evolution_ids),
            "types": len(type_ids),
            "evolution_edges": len(normalized["evolution_edges"]),
            "legendary_skill_sources": len(normalized["learnset_legendary_skills"]),
        },
    }
