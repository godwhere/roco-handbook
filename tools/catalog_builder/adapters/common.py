from __future__ import annotations

from collections import Counter, defaultdict
from typing import Any, Iterable

from catalog_builder.errors import AdapterError
from catalog_builder.lua_parser import LuaTable, LuaValue


def require_table(value: LuaValue, context: str) -> LuaTable:
    if not isinstance(value, LuaTable):
        raise AdapterError(f"{context}: expected a table")
    return value


def require_mapping(value: LuaValue, context: str) -> dict[str, LuaValue]:
    return require_table(value, context).as_mapping(context)


def require_sequence(value: LuaValue, context: str) -> tuple[LuaValue, ...]:
    return require_table(value, context).as_sequence(context)


def require_string(value: LuaValue, context: str) -> str:
    if not isinstance(value, str):
        raise AdapterError(f"{context}: expected a string")
    return value


def optional_string(value: LuaValue, context: str) -> str | None:
    if value is None:
        return None
    return require_string(value, context)


def require_integer(value: LuaValue, context: str) -> int:
    if not isinstance(value, int) or isinstance(value, bool):
        raise AdapterError(f"{context}: expected an integer")
    return value


def value_type(value: LuaValue) -> str:
    if isinstance(value, LuaTable):
        return "table"
    if value is None:
        return "null"
    if isinstance(value, bool):
        return "boolean"
    if isinstance(value, int):
        return "integer"
    if isinstance(value, float):
        return "number"
    return "string"


def to_plain(value: LuaValue) -> Any:
    if not isinstance(value, LuaTable):
        return value
    if value.kind == "empty":
        return {"$lua_table": "empty"}
    if value.kind == "array":
        return [to_plain(item) for item in value.as_sequence("array")]
    if value.kind == "map":
        return {
            key: to_plain(item)
            for key, item in value.as_mapping("map").items()
        }
    entries = []
    for key, item in value.resolved_items():
        entries.append({"key": key, "value": to_plain(item)})
    return {"$lua_table": "mixed", "entries": entries}


def record_profile(records: Iterable[dict[str, LuaValue]]) -> list[dict[str, Any]]:
    counts: Counter[str] = Counter()
    types: dict[str, Counter[str]] = defaultdict(Counter)
    table_kinds: dict[str, Counter[str]] = defaultdict(Counter)

    def visit(value: LuaValue, path: str) -> None:
        counts[path] += 1
        types[path][value_type(value)] += 1
        if not isinstance(value, LuaTable):
            return
        table_kinds[path][value.kind] += 1
        if value.kind in {"map", "empty"}:
            for key, item in value.as_mapping(path).items():
                visit(item, f"{path}.{key}")
        elif value.kind == "array":
            for item in value.as_sequence(path):
                visit(item, f"{path}[]")
        else:
            for key, item in value.resolved_items():
                segment = "[]" if isinstance(key, int) else f".{key}"
                visit(item, f"{path}{segment}")

    record_count = 0
    for record in records:
        record_count += 1
        for key, value in record.items():
            visit(value, f"record.{key}")

    result: list[dict[str, Any]] = []
    for path in sorted(counts):
        item: dict[str, Any] = {
            "path": path,
            "occurrences": counts[path],
            "record_coverage": counts[path] / record_count if record_count else 0,
            "types": dict(sorted(types[path].items())),
        }
        if table_kinds[path]:
            item["table_kinds"] = dict(sorted(table_kinds[path].items()))
        result.append(item)
    return result


def unknown_fields(
    records: dict[str, dict[str, LuaValue]],
    *,
    top_level: set[str],
    nested_maps: dict[str, set[str]] | None = None,
    nested_arrays: dict[str, set[str]] | None = None,
) -> list[str]:
    nested_maps = nested_maps or {}
    nested_arrays = nested_arrays or {}
    unknown: set[str] = set()
    for record_id, record in records.items():
        for key in set(record) - top_level:
            unknown.add(f"{record_id}.{key}")
        for key, allowed in nested_maps.items():
            value = record.get(key)
            if value is None:
                continue
            mapping = require_mapping(value, f"{record_id}.{key}")
            for child in set(mapping) - allowed:
                unknown.add(f"{record_id}.{key}.{child}")
        for key, allowed in nested_arrays.items():
            value = record.get(key)
            if value is None:
                continue
            for index, item in enumerate(require_sequence(value, f"{record_id}.{key}")):
                mapping = require_mapping(item, f"{record_id}.{key}[{index}]")
                for child in set(mapping) - allowed:
                    unknown.add(f"{record_id}.{key}[].{child}")
    return sorted(unknown)
