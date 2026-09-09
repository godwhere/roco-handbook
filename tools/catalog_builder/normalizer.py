from __future__ import annotations

import hashlib
import json
from pathlib import Path
from typing import Any
from urllib.parse import quote

from .adapters.common import (
    require_integer,
    require_mapping,
    require_sequence,
    require_string,
    to_plain,
)
from .adapters.core import inspect_core
from .adapters.evolution import inspect_evolution
from .adapters.handbook import inspect_handbook
from .adapters.index import inspect_index
from .adapters.learnsets import inspect_learnsets
from .adapters.skills import inspect_skills
from .errors import AdapterError
from .inspection import (
    _load_lock,
    _parse_sources,
    _source_by_key,
    build_inspection_report,
)
from .lua_parser import LuaValue


def _optional_string(value: LuaValue, context: str) -> str | None:
    if value is None:
        return None
    return require_string(value, context)


def _optional_integer(value: LuaValue, context: str) -> int | None:
    if value is None:
        return None
    return require_integer(value, context)


def _optional_boolean(value: LuaValue, context: str) -> int | None:
    if value is None:
        return None
    if not isinstance(value, bool):
        raise AdapterError(f"{context}: expected a boolean")
    return int(value)


def _sequence(value: LuaValue, context: str) -> tuple[LuaValue, ...]:
    if value is None:
        return ()
    return require_sequence(value, context)


def _plain_mapping(record: dict[str, LuaValue]) -> dict[str, Any]:
    return {key: to_plain(value) for key, value in sorted(record.items())}


def _numeric_and_text(
    value: LuaValue,
    context: str,
) -> tuple[int | float | None, str | None]:
    if value is None:
        return None, None
    if isinstance(value, (int, float)) and not isinstance(value, bool):
        return value, None
    if isinstance(value, str):
        return None, value
    raise AdapterError(f"{context}: expected a number, string, or null")


def _load_type_aliases(path: Path) -> dict[str, str | None]:
    try:
        document = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeDecodeError, json.JSONDecodeError) as error:
        raise AdapterError(f"Cannot read type aliases {path}: {error}") from error
    aliases = document.get("aliases")
    if not isinstance(aliases, dict):
        raise AdapterError("Type aliases must be an object")
    result: dict[str, str | None] = {}
    for source, target in aliases.items():
        if not isinstance(source, str) or not source:
            raise AdapterError("Every type alias key must be a non-empty string")
        if target is not None and (not isinstance(target, str) or not target):
            raise AdapterError(f"Type alias {source!r} has an invalid target")
        result[source] = target
    return result


def _type_id(name: str) -> str:
    digest = hashlib.sha256(name.encode("utf-8")).hexdigest()
    return f"type_{digest[:12]}"


def _source_revisions(
    lock: dict[str, Any],
    source_records: dict[str, dict[str, Any]],
) -> tuple[list[dict[str, Any]], dict[str, str]]:
    rows: list[dict[str, Any]] = []
    refs: dict[str, str] = {}
    endpoint = "https://wiki.biligame.com/rocom/index.php"
    for source_key, source in sorted(source_records.items()):
        page_id = source.get("page_id")
        revision_id = source.get("revision_id")
        if not isinstance(page_id, int) or not isinstance(revision_id, int):
            raise AdapterError(f"Source {source_key} has invalid page or revision metadata")
        source_ref = f"bwiki.rocom:{page_id}:{revision_id}"
        refs[source_key] = source_ref
        canonical_title = source.get("canonical_title")
        if not isinstance(canonical_title, str):
            raise AdapterError(f"Source {source_key} has no canonical title")
        rows.append(
            {
                "source_ref": source_ref,
                "source_key": source_key,
                "source_name": "Roco World BWIKI",
                "requested_title": source.get("requested_title"),
                "canonical_title": canonical_title,
                "page_id": page_id,
                "revision_id": revision_id,
                "revised_at_utc": source.get("revised_at_utc"),
                "fetched_at_utc": lock.get("imported_at_utc"),
                "content_bytes": source.get("content_bytes"),
                "api_sha1": source.get("api_sha1"),
                "content_sha256": source.get("content_sha256"),
                "source_url": (
                    f"{endpoint}?title={quote(canonical_title)}&oldid={revision_id}"
                ),
                "attribution_text": (
                    "Roco World BWIKI contributors; transformed for offline use."
                ),
                "license_id": "CC-BY-NC-SA-4.0",
            }
        )
    return rows, refs


def normalize_snapshot(
    snapshot: Path,
    *,
    rendered_index_response_path: Path,
    display_overrides_path: Path,
    type_aliases_path: Path,
    data_version: int,
    built_at_utc: str,
) -> dict[str, Any]:
    if data_version <= 0:
        raise AdapterError("Data version must be positive")
    inspection, samples = build_inspection_report(
        snapshot,
        display_overrides_path=display_overrides_path,
        rendered_index_response_path=rendered_index_response_path,
    )
    if inspection["blocking_issues"]:
        raise AdapterError("Snapshot inspection contains blocking issues")

    lock = _load_lock(snapshot)
    source_records = _source_by_key(lock)
    parsed, _ = _parse_sources(snapshot, source_records)
    core = inspect_core(parsed["core"].value)
    index = inspect_index(parsed["index"].value)
    handbook = inspect_handbook(parsed["handbook"].value)
    evolution = inspect_evolution(parsed["evolution"].value)
    skills = inspect_skills(parsed["skill_catalog"].value)
    learnsets = inspect_learnsets(
        parsed["learnsets"].value,
        parsed["learnset_catalog"].value,
    )

    aliases = _load_type_aliases(type_aliases_path)
    canonical_type_names = {
        require_string(type_name, f"core.{pet_id}.types")
        for pet_id, record in core.records.items()
        for type_name in _sequence(record.get("types"), f"core.{pet_id}.types")
    }
    type_ids = {name: _type_id(name) for name in canonical_type_names}
    if len(set(type_ids.values())) != len(type_ids):
        raise AdapterError("Type ID hash collision")

    def resolve_type(raw: LuaValue, context: str) -> str | None:
        name = require_string(raw, context)
        canonical = name if name in canonical_type_names else aliases.get(name)
        if canonical is None:
            if name not in aliases:
                raise AdapterError(f"{context}: unmapped type {name!r}")
            return None
        if canonical not in type_ids:
            raise AdapterError(f"{context}: alias target {canonical!r} is not a pet type")
        return type_ids[canonical]

    source_revisions, source_refs = _source_revisions(lock, source_records)
    display_numbers = inspection["rendered_index_evidence"]["display_numbers"]
    default_display = inspection["handbook_default_display"]["resolved"]

    handbook_rows: list[dict[str, Any]] = []
    handbook_display_rows: list[dict[str, Any]] = []
    for handbook_id, record in sorted(handbook.records.items()):
        dex_no = display_numbers.get(handbook_id)
        if not isinstance(dex_no, str) or not dex_no:
            raise AdapterError(f"Missing verified display number for {handbook_id}")
        resolved = default_display.get(handbook_id)
        if not isinstance(resolved, dict):
            raise AdapterError(f"Missing default display for {handbook_id}")
        handbook_rows.append(
            {
                "handbook_id": handbook_id,
                "dex_no": dex_no,
                "display_name": require_string(
                    record.get("entry_name"),
                    f"handbook.{handbook_id}.entry_name",
                ),
                "sort_order": int(dex_no) if dex_no.isascii() and dex_no.isdecimal() else None,
                "status": "active",
                "source_extra": _plain_mapping(record),
            }
        )
        handbook_display_rows.append(
            {
                "handbook_id": handbook_id,
                "default_pet_id": resolved["default_pet_id"],
                "selection_reason": resolved["selection_reason"],
            }
        )

    skill_rows: list[dict[str, Any]] = []
    skill_note_rows: list[dict[str, Any]] = []
    for skill_id, record in sorted(skills.records.items()):
        energy_value, energy_text = _numeric_and_text(
            record.get("energy"),
            f"skill_catalog.{skill_id}.energy",
        )
        power_value, power_text = _numeric_and_text(
            record.get("power"),
            f"skill_catalog.{skill_id}.power",
        )
        skill_rows.append(
            {
                "skill_id": skill_id,
                "upstream_numeric_id": _optional_integer(
                    record.get("id"),
                    f"skill_catalog.{skill_id}.id",
                ),
                "name": require_string(record.get("name"), f"skill_catalog.{skill_id}.name"),
                "category": _optional_string(
                    record.get("category"),
                    f"skill_catalog.{skill_id}.category",
                ),
                "element_raw": _optional_string(
                    record.get("element"),
                    f"skill_catalog.{skill_id}.element",
                ),
                "type_id": None
                if record.get("element") is None
                else resolve_type(record["element"], f"skill_catalog.{skill_id}.element"),
                "description": _optional_string(
                    record.get("desc"),
                    f"skill_catalog.{skill_id}.desc",
                ),
                "energy_value": energy_value,
                "energy_text": energy_text,
                "power_value": power_value,
                "power_text": power_text,
                "target_text": _optional_string(
                    record.get("target"),
                    f"skill_catalog.{skill_id}.target",
                ),
                "icon_key": _optional_string(
                    record.get("icon_id"),
                    f"skill_catalog.{skill_id}.icon_id",
                ),
                "extra_json": {
                    key: to_plain(record[key])
                    for key in ("damage_class", "flavor")
                    if record.get(key) is not None
                },
                "status": "active",
            }
        )
        for ordinal, note_id in enumerate(
            _sequence(record.get("desc_notes"), f"skill_catalog.{skill_id}.desc_notes")
        ):
            if not isinstance(note_id, (int, str)) or isinstance(note_id, bool):
                raise AdapterError(
                    f"skill_catalog.{skill_id}.desc_notes[{ordinal}]: invalid note ID"
                )
            skill_note_rows.append(
                {"skill_id": skill_id, "ordinal": ordinal, "note_id": str(note_id)}
            )

    pet_rows: list[dict[str, Any]] = []
    pet_alias_rows: list[dict[str, Any]] = []
    pet_type_rows: list[dict[str, Any]] = []
    for pet_id, record in sorted(core.records.items()):
        handbook_value = require_mapping(record.get("handbook"), f"core.{pet_id}.handbook")
        image = require_mapping(record.get("image"), f"core.{pet_id}.image")
        stats_value = record.get("stats")
        stats = {} if stats_value is None else require_mapping(stats_value, f"core.{pet_id}.stats")
        pet_rows.append(
            {
                "pet_id": pet_id,
                "handbook_id": require_string(
                    handbook_value.get("id"),
                    f"core.{pet_id}.handbook.id",
                ),
                "name": require_string(record.get("name"), f"core.{pet_id}.name"),
                "title": require_string(record.get("title"), f"core.{pet_id}.title"),
                "form": _optional_string(record.get("form"), f"core.{pet_id}.form"),
                "class_name": _optional_string(record.get("class"), f"core.{pet_id}.class"),
                "description": _optional_string(
                    record.get("description"),
                    f"core.{pet_id}.description",
                ),
                "stage": _optional_integer(record.get("stage"), f"core.{pet_id}.stage"),
                "belong_season_raw": None
                if record.get("belong_season") is None
                else str(to_plain(record["belong_season"])),
                "starlight": _optional_integer(
                    record.get("starlight"),
                    f"core.{pet_id}.starlight",
                ),
                "review_gold": _optional_integer(
                    record.get("review_gold"),
                    f"core.{pet_id}.review_gold",
                ),
                "height_text": _optional_string(
                    record.get("height"),
                    f"core.{pet_id}.height",
                ),
                "weight_text": _optional_string(
                    record.get("weight"),
                    f"core.{pet_id}.weight",
                ),
                "can_double_ride": _optional_boolean(
                    record.get("can_double_ride"),
                    f"core.{pet_id}.can_double_ride",
                ),
                "has_shiny": _optional_boolean(
                    record.get("has_shiny"),
                    f"core.{pet_id}.has_shiny",
                ),
                "is_lord_evolution": _optional_boolean(
                    record.get("is_lord_evolution"),
                    f"core.{pet_id}.is_lord_evolution",
                ),
                "hide_entry_name": _optional_boolean(
                    handbook_value.get("hide_entry_name"),
                    f"core.{pet_id}.handbook.hide_entry_name",
                ),
                "show_topics": _optional_boolean(
                    handbook_value.get("show_topics"),
                    f"core.{pet_id}.handbook.show_topics",
                ),
                "feature_skill_id": _optional_string(
                    record.get("feature_skill"),
                    f"core.{pet_id}.feature_skill",
                ),
                **{
                    key: _optional_integer(stats.get(key), f"core.{pet_id}.stats.{key}")
                    for key in ("hp", "atk", "def", "spa", "spd", "spe")
                },
                "illustration_key": _optional_string(
                    image.get("illustration"),
                    f"core.{pet_id}.image.illustration",
                ),
                "head_key": _optional_string(
                    image.get("head"),
                    f"core.{pet_id}.image.head",
                ),
                "extra_json": {
                    **{
                        key: to_plain(record[key])
                        for key in ("egg_group", "gender_ratio")
                        if record.get(key) is not None
                    },
                    "image": {
                        key: to_plain(image[key])
                        for key in ("egg", "fruit", "fruits", "has_egg", "has_fruit")
                        if image.get(key) is not None
                    },
                },
                "source_evolution_group_ids": [
                    require_string(value, f"core.{pet_id}.evolution_groups")
                    for value in _sequence(
                        record.get("evolution_groups"),
                        f"core.{pet_id}.evolution_groups",
                    )
                ],
                "status": "active",
            }
        )
        if record.get("title") != record.get("name"):
            pet_alias_rows.append(
                {
                    "pet_id": pet_id,
                    "alias": require_string(record.get("title"), f"core.{pet_id}.title"),
                    "alias_kind": "source_title",
                }
            )
        for slot, type_name in enumerate(
            _sequence(record.get("types"), f"core.{pet_id}.types"),
            start=1,
        ):
            type_id = resolve_type(type_name, f"core.{pet_id}.types[{slot - 1}]")
            if type_id is None:
                raise AdapterError(f"core.{pet_id}.types[{slot - 1}]: pet type cannot be null")
            pet_type_rows.append({"pet_id": pet_id, "slot": slot, "type_id": type_id})

    learnset_rows: list[dict[str, Any]] = []
    native_rows: list[dict[str, Any]] = []
    blood_rows: list[dict[str, Any]] = []
    stone_rows: list[dict[str, Any]] = []
    legendary_rows: list[dict[str, Any]] = []
    for learnset_id, record in sorted(learnsets.records.items()):
        learnset_rows.append(
            {
                "learnset_id": learnset_id,
                "feature_skill_id": _optional_string(
                    record.get("feature_skill"),
                    f"learnset_catalog.{learnset_id}.feature_skill",
                ),
                "extra_json": {},
            }
        )
        for ordinal, item in enumerate(
            _sequence(record.get("native_skills"), f"learnset_catalog.{learnset_id}.native_skills")
        ):
            mapping = require_mapping(item, f"learnset_catalog.{learnset_id}.native_skills")
            native_rows.append(
                {
                    "learnset_id": learnset_id,
                    "ordinal": ordinal,
                    "skill_id": require_string(mapping.get("skill"), "native skill"),
                    "learn_level": _optional_integer(mapping.get("level"), "native level"),
                    "source_stage": _optional_integer(mapping.get("stage"), "native stage"),
                }
            )
        for ordinal, item in enumerate(
            _sequence(record.get("blood_skills"), f"learnset_catalog.{learnset_id}.blood_skills")
        ):
            mapping = require_mapping(item, f"learnset_catalog.{learnset_id}.blood_skills")
            blood_raw = require_string(mapping.get("blood"), "blood condition")
            blood_rows.append(
                {
                    "learnset_id": learnset_id,
                    "ordinal": ordinal,
                    "skill_id": require_string(mapping.get("skill"), "blood skill"),
                    "blood_raw": blood_raw,
                    "blood_type_id": resolve_type(blood_raw, "blood condition"),
                    "learn_level": _optional_integer(mapping.get("level"), "blood level"),
                }
            )
        for ordinal, skill_id in enumerate(
            _sequence(record.get("skill_stones"), f"learnset_catalog.{learnset_id}.skill_stones")
        ):
            stone_rows.append(
                {
                    "learnset_id": learnset_id,
                    "ordinal": ordinal,
                    "skill_id": require_string(skill_id, "skill stone"),
                }
            )
        legendary = record.get("legendary")
        if legendary is not None:
            mapping = require_mapping(legendary, f"learnset_catalog.{learnset_id}.legendary")
            legendary_rows.append(
                {
                    "learnset_id": learnset_id,
                    "ordinal": 0,
                    "skill_id": require_string(mapping.get("skill"), "legendary skill"),
                    "requirement_text": _optional_string(
                        mapping.get("requires"),
                        "legendary requirement",
                    ),
                }
            )

    evolution_group_rows: list[dict[str, Any]] = []
    evolution_member_rows: list[dict[str, Any]] = []
    evolution_type_mismatches: list[dict[str, str]] = []
    for group_id, record in sorted(evolution.records.items()):
        evolution_group_rows.append(
            {
                "evolution_group_id": group_id,
                "label": _optional_string(record.get("name"), f"evolution.{group_id}.name"),
                "status": "active",
            }
        )
        source_order = 0
        for field in ("chain", "lord_branches"):
            for item in _sequence(record.get(field), f"evolution.{group_id}.{field}"):
                mapping = require_mapping(item, f"evolution.{group_id}.{field}")
                pet_id = require_string(mapping.get("id"), f"evolution.{group_id}.{field}.id")
                evolution_member_rows.append(
                    {
                        "evolution_group_id": group_id,
                        "pet_id": pet_id,
                        "source_order": source_order,
                    }
                )
                source_order += 1
                source_types = [
                    require_string(value, "evolution member type")
                    for value in _sequence(mapping.get("types"), "evolution member types")
                ]
                core_types = [
                    require_string(value, "core pet type")
                    for value in _sequence(core.records[pet_id].get("types"), "core pet types")
                ]
                if source_types != core_types:
                    evolution_type_mismatches.append(
                        {"evolution_group_id": group_id, "pet_id": pet_id}
                    )

    entity_sources: list[dict[str, str]] = []
    for entity_kind, records, source_key in (
        ("pet", core.records, "core"),
        ("handbook", handbook.records, "handbook"),
        ("skill", skills.records, "skill_catalog"),
        ("learnset", learnsets.records, "learnset_catalog"),
        ("evolution_group", evolution.records, "evolution"),
    ):
        for entity_id in sorted(records):
            entity_sources.append(
                {
                    "entity_kind": entity_kind,
                    "entity_id": entity_id,
                    "source_ref": source_refs[source_key],
                    "source_record_key": entity_id,
                }
            )

    return {
        "normalized_version": 1,
        "dataset_id": lock["dataset_id"],
        "schema_version": 1,
        "data_version": data_version,
        "snapshot_id": lock["snapshot_id"],
        "adapter_version": inspection["adapter_version"],
        "builder_version": "phase2-v1",
        "built_at_utc": built_at_utc,
        "coverage": {
            "pets": True,
            "skills": True,
            "evolutions": True,
            "topic_rewards": False,
            "skill_stone_topics": False,
            "description_note_definitions": False,
        },
        "inspection_summary": {
            "status": inspection["status"],
            "warnings": inspection["warnings"],
            "sample_mappings": samples,
            "rendered_index_evidence": {
                key: inspection["rendered_index_evidence"][key]
                for key in (
                    "page_id",
                    "page_revision_id",
                    "response_bytes",
                    "response_sha256",
                    "card_count",
                    "main_form_count",
                    "display_number_count",
                )
            },
            "evolution_type_mismatches": evolution_type_mismatches,
            "handbook_fields_not_in_v1_database": [
                "areas",
                "habitat",
                "title",
                "topics",
            ],
        },
        "source_revisions": source_revisions,
        "types": [
            {"type_id": type_ids[name], "name": name}
            for name in sorted(type_ids)
        ],
        "handbook_entries": handbook_rows,
        "handbook_display": handbook_display_rows,
        "skills": skill_rows,
        "skill_description_notes": skill_note_rows,
        "pets": pet_rows,
        "pet_aliases": pet_alias_rows,
        "pet_types": pet_type_rows,
        "learnsets": learnset_rows,
        "pet_learnsets": [
            {"pet_id": pet_id, "learnset_id": learnset_id}
            for pet_id, learnset_id in sorted(learnsets.pet_to_learnset.items())
        ],
        "learnset_native_skills": native_rows,
        "learnset_blood_skills": blood_rows,
        "learnset_skill_stones": stone_rows,
        "learnset_legendary_skills": legendary_rows,
        "evolution_groups": evolution_group_rows,
        "pet_evolution_groups": evolution_member_rows,
        "evolution_edges": evolution.edges,
        "entity_sources": entity_sources,
        "index_summary": index.report,
    }
