from __future__ import annotations

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
    to_plain,
    unknown_fields,
)


_PET_ID = re.compile(r"^pet_\d{6}$")
_TOP_LEVEL_FIELDS = {
    "belong_season",
    "can_double_ride",
    "class",
    "description",
    "egg_group",
    "evolution_groups",
    "feature_skill",
    "form",
    "gender_ratio",
    "handbook",
    "has_shiny",
    "height",
    "id",
    "image",
    "is_lord_evolution",
    "name",
    "review_gold",
    "stage",
    "starlight",
    "stats",
    "title",
    "types",
    "weight",
}
_NESTED_MAPS = {
    "gender_ratio": {"female", "male"},
    "handbook": {"hide_entry_name", "id", "show_topics"},
    "image": {
        "egg",
        "fruit",
        "fruits",
        "has_egg",
        "has_fruit",
        "head",
        "illustration",
    },
    "stats": {"atk", "def", "hp", "spa", "spd", "spe"},
}


@dataclass(frozen=True)
class CoreInspection:
    report: dict[str, Any]
    records: dict[str, dict[str, LuaValue]]
    handbook_references: set[str]
    evolution_references: set[str]
    feature_references: set[str]


def inspect_core(root: LuaTable) -> CoreInspection:
    expansion = expand_metadata_keys(root)
    root_map = expansion.table.as_mapping("core")
    records: dict[str, dict[str, LuaValue]] = {}
    for record_id, value in root_map.items():
        if record_id == "_meta":
            continue
        if not _PET_ID.fullmatch(record_id):
            raise AdapterError(f"core: unexpected top-level key {record_id!r}")
        record = require_mapping(value, f"core.{record_id}")
        if require_string(record.get("id"), f"core.{record_id}.id") != record_id:
            raise AdapterError(f"core.{record_id}: embedded ID does not match its key")
        require_string(record.get("name"), f"core.{record_id}.name")
        require_string(record.get("title"), f"core.{record_id}.title")
        records[record_id] = record

    handbook_references: set[str] = set()
    evolution_references: set[str] = set()
    feature_references: set[str] = set()
    for record_id, record in records.items():
        handbook = record.get("handbook")
        if handbook is not None:
            reference = require_mapping(handbook, f"core.{record_id}.handbook").get("id")
            handbook_references.add(
                require_string(reference, f"core.{record_id}.handbook.id")
            )
        groups = record.get("evolution_groups")
        if groups is not None:
            for index, value in enumerate(
                require_sequence(groups, f"core.{record_id}.evolution_groups")
            ):
                evolution_references.add(
                    require_string(value, f"core.{record_id}.evolution_groups[{index}]")
                )
        feature = record.get("feature_skill")
        if feature is not None:
            feature_references.add(
                require_string(feature, f"core.{record_id}.feature_skill")
            )

    samples = {
        record_id: {
            key: to_plain(records[record_id].get(key))
            for key in ("id", "name", "title", "form", "handbook", "feature_skill", "stats")
        }
        for record_id in ("pet_000007", "pet_000538", "pet_000595")
        if record_id in records
    }
    unknown = unknown_fields(
        records,
        top_level=_TOP_LEVEL_FIELDS,
        nested_maps=_NESTED_MAPS,
    )
    return CoreInspection(
        report={
            "record_count": len(records),
            "metadata_key_count": len(expansion.mapping),
            "metadata_keys": dict(sorted(expansion.mapping.items())),
            "field_profile": record_profile(records.values()),
            "unknown_fields": unknown,
            "sample_records": samples,
        },
        records=records,
        handbook_references=handbook_references,
        evolution_references=evolution_references,
        feature_references=feature_references,
    )
