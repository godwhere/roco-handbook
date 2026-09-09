from __future__ import annotations

from dataclasses import dataclass
from typing import Any

from catalog_builder.errors import AdapterError
from catalog_builder.lua_parser import LuaTable

from .common import require_mapping, require_sequence, require_string


@dataclass(frozen=True)
class IndexInspection:
    report: dict[str, Any]
    by_id: set[str]
    referenced_pet_ids: set[str]


def inspect_index(root: LuaTable) -> IndexInspection:
    root_map = root.as_mapping("index")
    expected = {"by_id", "by_name", "by_title", "titles"}
    unknown = sorted(set(root_map) - expected)
    missing = sorted(expected - set(root_map))
    if missing:
        raise AdapterError("index: missing fields " + ", ".join(missing))

    by_id_map = require_mapping(root_map["by_id"], "index.by_id")
    by_id = set(by_id_map)
    for pet_id, marker in by_id_map.items():
        if marker is not True:
            raise AdapterError(f"index.by_id.{pet_id}: expected true marker")

    by_title = require_mapping(root_map["by_title"], "index.by_title")
    referenced: set[str] = set()
    for title, pet_id in by_title.items():
        referenced.add(require_string(pet_id, f"index.by_title.{title}"))

    by_name = require_mapping(root_map["by_name"], "index.by_name")
    duplicate_name_count = 0
    for name, value in by_name.items():
        matches = require_sequence(value, f"index.by_name.{name}")
        if len(matches) > 1:
            duplicate_name_count += 1
        for index, pet_id in enumerate(matches):
            referenced.add(require_string(pet_id, f"index.by_name.{name}[{index}]"))

    titles = require_mapping(root_map["titles"], "index.titles")
    for pet_id, title in titles.items():
        referenced.add(pet_id)
        require_string(title, f"index.titles.{pet_id}")

    return IndexInspection(
        report={
            "by_id_count": len(by_id),
            "by_name_count": len(by_name),
            "by_title_count": len(by_title),
            "titles_count": len(titles),
            "duplicate_name_count": duplicate_name_count,
            "top_level_unknown_fields": unknown,
        },
        by_id=by_id,
        referenced_pet_ids=referenced,
    )
