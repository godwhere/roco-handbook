from __future__ import annotations

from dataclasses import dataclass

from .errors import AdapterError
from .lua_parser import LuaField, LuaTable, LuaValue


@dataclass(frozen=True)
class ExpansionResult:
    table: LuaTable
    mapping: dict[str, str]


def _metadata_mapping(root: LuaTable) -> dict[str, str]:
    root_map = root.as_mapping("root")
    metadata = root_map.get("_meta")
    if metadata is None:
        return {}
    if not isinstance(metadata, LuaTable):
        raise AdapterError("root._meta must be a table")
    key_table = metadata.as_mapping("root._meta").get("key")
    if key_table is None:
        return {}
    if not isinstance(key_table, LuaTable):
        raise AdapterError("root._meta.key must be a table")

    mapping: dict[str, str] = {}
    for short, full in key_table.as_mapping("root._meta.key").items():
        if not isinstance(full, str) or not full:
            raise AdapterError(f"Key expansion for {short!r} must be a non-empty string")
        if full in mapping.values() and mapping.get(short) != full:
            raise AdapterError(f"Multiple metadata keys expand to {full!r}")
        mapping[short] = full
    return mapping


def _expand_value(value: LuaValue, mapping: dict[str, str]) -> LuaValue:
    if not isinstance(value, LuaTable):
        return value

    expanded: list[LuaField] = []
    resolved_keys: set[tuple[type[object], object]] = set()
    implicit_index = 1
    for field in value.fields:
        if field.implicit:
            key: LuaValue | None = None
            identity: tuple[type[object], object] = (int, implicit_index)
            implicit_index += 1
        else:
            raw_key = field.key
            key = mapping.get(raw_key, raw_key) if isinstance(raw_key, str) else raw_key
            identity = (type(key), key)
        if identity in resolved_keys:
            raise AdapterError(
                f"{field.position.render()}: key expansion creates duplicate key {key!r}"
            )
        resolved_keys.add(identity)
        expanded.append(
            LuaField(
                key=key,
                value=_expand_value(field.value, mapping),
                position=field.position,
                implicit=field.implicit,
            )
        )
    return LuaTable(tuple(expanded), value.position)


def expand_metadata_keys(root: LuaTable) -> ExpansionResult:
    mapping = _metadata_mapping(root)
    root_fields: list[LuaField] = []
    for field in root.fields:
        if not field.implicit and field.key == "_meta":
            root_fields.append(field)
        else:
            root_fields.append(
                LuaField(
                    key=field.key,
                    value=_expand_value(field.value, mapping),
                    position=field.position,
                    implicit=field.implicit,
                )
            )
    return ExpansionResult(LuaTable(tuple(root_fields), root.position), mapping)
