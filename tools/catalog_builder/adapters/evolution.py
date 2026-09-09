from __future__ import annotations

from dataclasses import dataclass
import re
from typing import Any

from catalog_builder.errors import AdapterError
from catalog_builder.lua_parser import LuaTable, LuaValue

from .common import (
    record_profile,
    require_mapping,
    require_sequence,
    require_string,
    unknown_fields,
)


_EVOLUTION_ID = re.compile(r"^evo_\d{6}$")
_FIELDS = {"chain", "lord_branches", "name"}
_MEMBER_FIELDS = {
    "cond",
    "form",
    "head",
    "id",
    "illustration",
    "level",
    "name",
    "stage",
    "title",
    "types",
}


@dataclass(frozen=True)
class EvolutionInspection:
    report: dict[str, Any]
    records: dict[str, dict[str, LuaValue]]
    member_pet_ids: set[str]
    edges: list[dict[str, Any]]


def _members(
    record: dict[str, LuaValue],
    field: str,
    group_id: str,
) -> list[dict[str, LuaValue]]:
    value = record.get(field)
    if value is None:
        return []
    return [
        require_mapping(item, f"evolution.{group_id}.{field}[{index}]")
        for index, item in enumerate(
            require_sequence(value, f"evolution.{group_id}.{field}")
        )
    ]


def inspect_evolution(root: LuaTable) -> EvolutionInspection:
    root_map = root.as_mapping("evolution")
    records: dict[str, dict[str, LuaValue]] = {}
    member_pet_ids: set[str] = set()
    edges: list[dict[str, Any]] = []
    for group_id, value in root_map.items():
        if not _EVOLUTION_ID.fullmatch(group_id):
            raise AdapterError(f"evolution: unexpected key {group_id!r}")
        record = require_mapping(value, f"evolution.{group_id}")
        records[group_id] = record

        chain = _members(record, "chain", group_id)
        branches = _members(record, "lord_branches", group_id)
        chain_ids = [
            require_string(member.get("id"), f"evolution.{group_id}.chain.id")
            for member in chain
        ]
        branch_ids = [
            require_string(member.get("id"), f"evolution.{group_id}.lord_branches.id")
            for member in branches
        ]
        member_pet_ids.update(chain_ids)
        member_pet_ids.update(branch_ids)

        for ordinal, (source_id, target_id, target) in enumerate(
            zip(chain_ids, chain_ids[1:], chain[1:])
        ):
            edges.append(
                {
                    "evolution_group_id": group_id,
                    "edge_kind": "chain",
                    "ordinal": ordinal,
                    "from_pet_id": source_id,
                    "to_pet_id": target_id,
                    "condition_text": target.get("cond"),
                    "level_requirement": target.get("level"),
                }
            )
        if chain_ids:
            source_id = chain_ids[-1]
            for branch_index, (target_id, target) in enumerate(zip(branch_ids, branches)):
                edges.append(
                    {
                        "evolution_group_id": group_id,
                        "edge_kind": "lord_branch",
                        "ordinal": len(chain_ids) - 1 + branch_index,
                        "from_pet_id": source_id,
                        "to_pet_id": target_id,
                        "condition_text": target.get("cond"),
                        "level_requirement": target.get("level"),
                    }
                )

    return EvolutionInspection(
        report={
            "record_count": len(records),
            "member_count": len(member_pet_ids),
            "derived_edge_count": len(edges),
            "direction_contract": {
                "chain": "Earlier chain member to the next member.",
                "lord_branch": "Terminal chain member to each ordered lord branch.",
                "condition_source": "The target member's level and cond fields.",
                "basis": (
                    "The source separates ordered chain and lord_branches tables; "
                    "the adapter preserves their order and explicit target conditions."
                ),
            },
            "field_profile": record_profile(records.values()),
            "unknown_fields": unknown_fields(
                records,
                top_level=_FIELDS,
                nested_arrays={
                    "chain": _MEMBER_FIELDS,
                    "lord_branches": _MEMBER_FIELDS,
                },
            ),
        },
        records=records,
        member_pet_ids=member_pet_ids,
        edges=edges,
    )
