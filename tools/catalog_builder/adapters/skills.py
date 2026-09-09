from __future__ import annotations

from dataclasses import dataclass
import re
from typing import Any

from catalog_builder.errors import AdapterError
from catalog_builder.lua_parser import LuaTable, LuaValue

from .common import record_profile, require_mapping, require_string, unknown_fields


_SKILL_ID = re.compile(r"^skill_\d{6}$")
_FIELDS = {
    "category",
    "damage_class",
    "desc",
    "desc_notes",
    "element",
    "energy",
    "flavor",
    "icon_id",
    "id",
    "name",
    "power",
    "target",
}


@dataclass(frozen=True)
class SkillInspection:
    report: dict[str, Any]
    records: dict[str, dict[str, LuaValue]]


def inspect_skills(root: LuaTable) -> SkillInspection:
    root_map = root.as_mapping("skill_catalog")
    records: dict[str, dict[str, LuaValue]] = {}
    for skill_id, value in root_map.items():
        if not _SKILL_ID.fullmatch(skill_id):
            raise AdapterError(f"skill_catalog: unexpected top-level key {skill_id!r}")
        record = require_mapping(value, f"skill_catalog.{skill_id}")
        require_string(record.get("name"), f"skill_catalog.{skill_id}.name")
        records[skill_id] = record

    categories: dict[str, int] = {}
    for record in records.values():
        value = record.get("category")
        key = value if isinstance(value, str) else "<missing>"
        categories[key] = categories.get(key, 0) + 1

    sample = records.get("skill_000003")
    sample_summary = None
    if sample is not None:
        sample_summary = {
            "skill_id": "skill_000003",
            "name": sample.get("name"),
            "category": sample.get("category"),
            "upstream_numeric_id": sample.get("id"),
            "energy": sample.get("energy"),
        }

    return SkillInspection(
        report={
            "record_count": len(records),
            "categories": dict(sorted(categories.items())),
            "field_profile": record_profile(records.values()),
            "unknown_fields": unknown_fields(records, top_level=_FIELDS),
            "sample_feature": sample_summary,
        },
        records=records,
    )
