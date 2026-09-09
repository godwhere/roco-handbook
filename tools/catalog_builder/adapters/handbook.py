from __future__ import annotations

from dataclasses import dataclass
import re
from typing import Any

from catalog_builder.errors import AdapterError
from catalog_builder.lua_parser import LuaTable, LuaValue

from .common import record_profile, require_mapping, require_sequence, unknown_fields


_HANDBOOK_ID = re.compile(r"^handbook_\d{6}$")
_TOP_LEVEL_FIELDS = {"areas", "entry_name", "habitat", "title", "topics"}
_TOPIC_FIELDS = {"id", "target", "text"}


@dataclass(frozen=True)
class HandbookInspection:
    report: dict[str, Any]
    records: dict[str, dict[str, LuaValue]]


def inspect_handbook(root: LuaTable) -> HandbookInspection:
    root_map = root.as_mapping("handbook")
    records: dict[str, dict[str, LuaValue]] = {}
    topic_count = 0
    for record_id, value in root_map.items():
        if not _HANDBOOK_ID.fullmatch(record_id):
            raise AdapterError(f"handbook: unexpected top-level key {record_id!r}")
        record = require_mapping(value, f"handbook.{record_id}")
        if "topics" in record:
            topic_count += len(require_sequence(record["topics"], f"handbook.{record_id}.topics"))
        records[record_id] = record

    unknown = unknown_fields(
        records,
        top_level=_TOP_LEVEL_FIELDS,
        nested_arrays={"topics": _TOPIC_FIELDS},
    )
    return HandbookInspection(
        report={
            "record_count": len(records),
            "topic_count": topic_count,
            "field_profile": record_profile(records.values()),
            "unknown_fields": unknown,
            "display_number": {
                "source_field": None,
                "verified_count": 0,
                "status": "not_present_in_snapshot",
                "rule": "Do not derive a display number from handbook ID suffixes.",
            },
        },
        records=records,
    )
