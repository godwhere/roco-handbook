from __future__ import annotations

from collections import Counter
from dataclasses import dataclass
import re
from typing import Any

from catalog_builder.errors import AdapterError
from catalog_builder.key_expander import expand_metadata_keys
from catalog_builder.lua_parser import LuaTable, LuaValue

from .common import (
    record_profile,
    require_mapping,
    require_sequence,
    require_string,
    unknown_fields,
)


_PET_ID = re.compile(r"^pet_\d{6}$")
_LEARNSET_ID = re.compile(r"^learnset_\d{6}$")
_FIELDS = {
    "blood_skills",
    "feature_skill",
    "legendary",
    "native_skills",
    "skill_stones",
}


@dataclass(frozen=True)
class LearnsetInspection:
    report: dict[str, Any]
    pet_to_learnset: dict[str, str]
    records: dict[str, dict[str, LuaValue]]
    skill_references: set[str]
    feature_references: set[str]


def inspect_learnsets(
    assignments_root: LuaTable,
    catalog_root: LuaTable,
) -> LearnsetInspection:
    assignments_map = assignments_root.as_mapping("learnsets")
    pet_to_learnset: dict[str, str] = {}
    for pet_id, value in assignments_map.items():
        if not _PET_ID.fullmatch(pet_id):
            raise AdapterError(f"learnsets: unexpected pet key {pet_id!r}")
        learnset_id = require_string(value, f"learnsets.{pet_id}")
        if not _LEARNSET_ID.fullmatch(learnset_id):
            raise AdapterError(f"learnsets.{pet_id}: invalid learnset ID {learnset_id!r}")
        pet_to_learnset[pet_id] = learnset_id

    expansion = expand_metadata_keys(catalog_root)
    catalog_map = expansion.table.as_mapping("learnset_catalog")
    records: dict[str, dict[str, LuaValue]] = {}
    for learnset_id, value in catalog_map.items():
        if learnset_id == "_meta":
            continue
        if not _LEARNSET_ID.fullmatch(learnset_id):
            raise AdapterError(f"learnset_catalog: unexpected key {learnset_id!r}")
        records[learnset_id] = require_mapping(
            value,
            f"learnset_catalog.{learnset_id}",
        )

    skill_references: set[str] = set()
    feature_references: set[str] = set()
    stage_counts: Counter[int] = Counter()
    source_counts: Counter[str] = Counter()
    for learnset_id, record in records.items():
        feature = record.get("feature_skill")
        if feature is not None:
            feature_references.add(
                require_string(feature, f"learnset_catalog.{learnset_id}.feature_skill")
            )
            source_counts["feature"] += 1

        native = record.get("native_skills")
        if native is not None:
            for index, item in enumerate(
                require_sequence(native, f"learnset_catalog.{learnset_id}.native_skills")
            ):
                mapping = require_mapping(
                    item,
                    f"learnset_catalog.{learnset_id}.native_skills[{index}]",
                )
                skill_references.add(
                    require_string(
                        mapping.get("skill"),
                        f"learnset_catalog.{learnset_id}.native_skills[{index}].skill",
                    )
                )
                stage = mapping.get("stage")
                if stage is not None:
                    if not isinstance(stage, int) or isinstance(stage, bool):
                        raise AdapterError(
                            f"learnset_catalog.{learnset_id}.native_skills[{index}].stage "
                            "must be an integer"
                        )
                    stage_counts[stage] += 1
                source_counts["native"] += 1

        blood = record.get("blood_skills")
        if blood is not None:
            for index, item in enumerate(
                require_sequence(blood, f"learnset_catalog.{learnset_id}.blood_skills")
            ):
                mapping = require_mapping(
                    item,
                    f"learnset_catalog.{learnset_id}.blood_skills[{index}]",
                )
                skill_references.add(
                    require_string(
                        mapping.get("skill"),
                        f"learnset_catalog.{learnset_id}.blood_skills[{index}].skill",
                    )
                )
                source_counts["blood"] += 1

        stones = record.get("skill_stones")
        if stones is not None:
            for index, skill_id in enumerate(
                require_sequence(stones, f"learnset_catalog.{learnset_id}.skill_stones")
            ):
                skill_references.add(
                    require_string(
                        skill_id,
                        f"learnset_catalog.{learnset_id}.skill_stones[{index}]",
                    )
                )
                source_counts["stone"] += 1

        legendary = record.get("legendary")
        if legendary is not None:
            mapping = require_mapping(legendary, f"learnset_catalog.{learnset_id}.legendary")
            skill = mapping.get("skill")
            if skill is not None:
                skill_references.add(
                    require_string(skill, f"learnset_catalog.{learnset_id}.legendary.skill")
                )
                source_counts["legendary"] += 1

    reuse_counts = Counter(pet_to_learnset.values())
    return LearnsetInspection(
        report={
            "assignment_count": len(pet_to_learnset),
            "record_count": len(records),
            "shared_learnset_count": sum(count > 1 for count in reuse_counts.values()),
            "maximum_pet_reuse": max(reuse_counts.values(), default=0),
            "source_counts": dict(sorted(source_counts.items())),
            "source_stage": {
                "observed_values": {
                    str(key): value for key, value in sorted(stage_counts.items())
                },
                "normalized_field": "source_stage",
                "filtering_rule": (
                    "Preserve the value and do not filter by the current creature stage."
                ),
                "evidence": (
                    "The reviewed Skills module aliases native_skills to level and "
                    "contains no stage filter."
                ),
            },
            "metadata_key_count": len(expansion.mapping),
            "metadata_keys": dict(sorted(expansion.mapping.items())),
            "field_profile": record_profile(records.values()),
            "unknown_fields": unknown_fields(
                records,
                top_level=_FIELDS,
                nested_maps={"legendary": {"requires", "skill"}},
                nested_arrays={
                    "native_skills": {"level", "skill", "stage"},
                    "blood_skills": {"blood", "level", "skill"},
                },
            ),
        },
        pet_to_learnset=pet_to_learnset,
        records=records,
        skill_references=skill_references,
        feature_references=feature_references,
    )
