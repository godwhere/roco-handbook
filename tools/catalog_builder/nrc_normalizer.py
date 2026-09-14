from __future__ import annotations

import json
from pathlib import Path, PurePosixPath
import re
import sqlite3
from typing import Any
from urllib.parse import quote

from .adapters.common import (
    require_integer,
    require_mapping,
    require_sequence,
    require_string,
    to_plain,
)
from .errors import AdapterError
from .inspection import _load_lock, _source_by_key
from .lua_parser import LuaTable, LuaValue, parse_lua_table
from .normalizer import (
    _load_type_aliases,
    _numeric_and_text,
    _optional_boolean,
    _optional_integer,
    _optional_string,
    _plain_mapping,
    _sequence,
    _type_id,
)


_REQUIRED_MODULES = (
    "core",
    "handbook",
    "evolution",
    "learnset_catalog",
    "skill_catalog",
    "index",
    "overview",
    "history",
)
_PET_ID = re.compile(r"^pet_\d{6}$")
_HANDBOOK_ID = re.compile(r"^handbook_\d{6}$")
_SKILL_ID = re.compile(r"^skill_\d{6}$")
_LEARNSET_ID = re.compile(r"^learnset_[0-9a-f]{12}$")
_EVOLUTION_ID = re.compile(r"^evolution_[0-9a-f]{12}$")
_IMAGE_FILE = re.compile(r"^[^/\\]+\.png$")
_SKILL_ICON = re.compile(r"^(Feature|Skill)_(.+)\.png$")
_LEGACY_HEAD = re.compile(r"^Head_(\d+)(?:_|$)")


def _module_mapping(
    snapshot: Path,
    source_records: dict[str, dict[str, Any]],
    source_key: str,
) -> dict[str, LuaValue]:
    source = source_records.get(source_key)
    if source is None:
        raise AdapterError(f"NRC snapshot is missing required module {source_key}")
    path = snapshot / str(source.get("content_file", ""))
    try:
        content = path.read_text(encoding="utf-8")
    except (OSError, UnicodeDecodeError) as error:
        raise AdapterError(f"Cannot read NRC module {source_key}: {error}") from error
    return parse_lua_table(content, source=path.name).value.as_mapping(source_key)


def _records(
    root: dict[str, LuaValue],
    *,
    context: str,
    identifier: re.Pattern[str],
) -> dict[str, dict[str, LuaValue]]:
    result: dict[str, dict[str, LuaValue]] = {}
    for record_id, value in root.items():
        if record_id == "_meta":
            continue
        if identifier.fullmatch(record_id) is None:
            raise AdapterError(f"{context}: invalid record ID {record_id!r}")
        result[record_id] = require_mapping(value, f"{context}.{record_id}")
    return result


def _source_revisions(
    lock: dict[str, Any],
    source_records: dict[str, dict[str, Any]],
) -> tuple[list[dict[str, Any]], dict[str, str]]:
    source_system = lock.get("source_system")
    api_endpoint = lock.get("api_endpoint")
    if source_system != "bwiki.nrc" or not isinstance(api_endpoint, str):
        raise AdapterError("NRC snapshot source identity is missing")
    page_endpoint = api_endpoint.removesuffix("api.php") + "index.php"
    rows: list[dict[str, Any]] = []
    refs: dict[str, str] = {}
    for source_key, source in sorted(source_records.items()):
        page_id = source.get("page_id")
        revision_id = source.get("revision_id")
        canonical_title = source.get("canonical_title")
        if (
            not isinstance(page_id, int)
            or not isinstance(revision_id, int)
            or not isinstance(canonical_title, str)
        ):
            raise AdapterError(f"Source {source_key} has invalid revision metadata")
        source_ref = f"{source_system}:{page_id}:{revision_id}"
        refs[source_key] = source_ref
        rows.append(
            {
                "source_ref": source_ref,
                "source_key": source_key,
                "source_name": "Roco Kingdom World BWIKI",
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
                    f"{page_endpoint}?title={quote(canonical_title)}&oldid={revision_id}"
                ),
                "attribution_text": (
                    "Roco Kingdom World BWIKI contributors; transformed for offline use."
                ),
                "license_id": "CC-BY-NC-SA-4.0",
            }
        )
    return rows, refs


def _png_stem(value: LuaValue, context: str) -> str:
    filename = require_string(value, context)
    if _IMAGE_FILE.fullmatch(filename) is None or PurePosixPath(filename).name != filename:
        raise AdapterError(f"{context}: invalid PNG filename {filename!r}")
    return filename[:-4]


def _legacy_illustrations(previous_catalog: Path | None) -> dict[int, str]:
    if previous_catalog is None:
        return {}
    if not previous_catalog.is_file():
        raise AdapterError(f"Previous Catalog does not exist: {previous_catalog}")
    try:
        connection = sqlite3.connect(
            f"file:{previous_catalog.resolve()}?mode=ro",
            uri=True,
        )
        rows = connection.execute(
            "SELECT head_key, illustration_key FROM pets WHERE status = 'active'"
        ).fetchall()
        connection.close()
    except sqlite3.Error as error:
        raise AdapterError(f"Cannot read previous Catalog image aliases: {error}") from error
    aliases: dict[int, str] = {}
    for head_key, illustration_key in rows:
        match = _LEGACY_HEAD.match(head_key or "")
        if match is None or not isinstance(illustration_key, str) or not illustration_key:
            raise AdapterError("Previous Catalog has an invalid image alias record")
        game_id = int(match.group(1))
        if game_id in aliases and aliases[game_id] != illustration_key:
            raise AdapterError(f"Previous Catalog repeats game ID {game_id}")
        aliases[game_id] = illustration_key
    return aliases


def _normalized_skill_category(record: dict[str, LuaValue], skill_id: str) -> str:
    category = require_string(record.get("category"), f"skills.{skill_id}.category")
    if category != "\u653b\u51fb":
        return category
    damage_class = require_string(
        record.get("damage_class"),
        f"skills.{skill_id}.damage_class",
    )
    if damage_class not in {"\u7269\u653b", "\u9b54\u653b"}:
        raise AdapterError(f"skills.{skill_id}: unsupported damage class {damage_class!r}")
    return damage_class


def normalize_nrc_snapshot(
    snapshot: Path,
    *,
    type_aliases_path: Path,
    previous_catalog_path: Path | None,
    data_version: int,
    built_at_utc: str,
) -> dict[str, Any]:
    if data_version <= 0:
        raise AdapterError("Data version must be positive")
    lock = _load_lock(snapshot)
    source_records = _source_by_key(lock)
    missing_modules = sorted(set(_REQUIRED_MODULES) - set(source_records))
    if missing_modules:
        raise AdapterError("NRC snapshot is incomplete: " + ", ".join(missing_modules))

    parsed = {
        key: _module_mapping(snapshot, source_records, key)
        for key in _REQUIRED_MODULES
    }
    pets = _records(parsed["core"], context="core", identifier=_PET_ID)
    handbooks = _records(
        parsed["handbook"],
        context="handbook",
        identifier=_HANDBOOK_ID,
    )
    skills = _records(
        parsed["skill_catalog"],
        context="skill_catalog",
        identifier=_SKILL_ID,
    )
    learnsets = _records(
        parsed["learnset_catalog"],
        context="learnset_catalog",
        identifier=_LEARNSET_ID,
    )
    overview = _records(
        parsed["overview"],
        context="overview",
        identifier=_PET_ID,
    )
    if set(overview) != set(pets):
        raise AdapterError("NRC Overview pet coverage differs from Catalog")

    evolution_values = {
        group_id: value
        for group_id, value in parsed["evolution"].items()
        if group_id != "_meta"
    }
    if any(_EVOLUTION_ID.fullmatch(group_id) is None for group_id in evolution_values):
        raise AdapterError("NRC Evolutions contains an invalid group ID")

    aliases = _load_type_aliases(type_aliases_path)
    canonical_type_names = {
        require_string(type_name, f"core.{pet_id}.types")
        for pet_id, record in pets.items()
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
    legacy_illustrations = _legacy_illustrations(previous_catalog_path)

    index = parsed["index"]
    handbook_order = [
        require_string(value, "index.handbook_order")
        for value in require_sequence(index.get("handbook_order"), "index.handbook_order")
    ]
    if len(handbook_order) != len(set(handbook_order)):
        raise AdapterError("NRC handbook order repeats a pet")
    default_by_handbook: dict[str, str] = {}
    for pet_id in handbook_order:
        record = pets.get(pet_id)
        if record is None:
            raise AdapterError(f"NRC handbook order references missing pet {pet_id}")
        handbook_id = require_string(
            record.get("handbook_id"),
            f"core.{pet_id}.handbook_id",
        )
        if handbook_id in default_by_handbook:
            raise AdapterError(f"NRC handbook order repeats handbook {handbook_id}")
        default_by_handbook[handbook_id] = pet_id
    if set(default_by_handbook) != set(handbooks):
        raise AdapterError("NRC handbook order does not cover every handbook")

    handbook_rows: list[dict[str, Any]] = []
    handbook_display_rows: list[dict[str, Any]] = []
    for handbook_id, record in sorted(handbooks.items()):
        members = [
            (pet_id, pet)
            for pet_id, pet in pets.items()
            if pet.get("handbook_id") == handbook_id
        ]
        numbers = {
            require_string(pet.get("number"), f"core.{pet_id}.number")
            for pet_id, pet in members
        }
        if len(numbers) != 1:
            raise AdapterError(f"Handbook {handbook_id} has inconsistent display numbers")
        dex_no = next(iter(numbers))
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
                "default_pet_id": default_by_handbook[handbook_id],
                "selection_reason": "nrc_handbook_order",
            }
        )

    skill_rows: list[dict[str, Any]] = []
    skill_note_rows: list[dict[str, Any]] = []
    for skill_id, record in sorted(skills.items()):
        energy_value, energy_text = _numeric_and_text(
            record.get("energy"),
            f"skill_catalog.{skill_id}.energy",
        )
        power_value, power_text = _numeric_and_text(
            record.get("power"),
            f"skill_catalog.{skill_id}.power",
        )
        icon_filename = require_string(
            record.get("icon"),
            f"skill_catalog.{skill_id}.icon",
        )
        icon_match = _SKILL_ICON.fullmatch(icon_filename)
        if icon_match is None:
            raise AdapterError(f"skill_catalog.{skill_id}: invalid icon filename")
        normalized_category = _normalized_skill_category(record, skill_id)
        expected_prefix = (
            "Feature" if normalized_category == "\u7279\u6027" else "Skill"
        )
        if icon_match.group(1) != expected_prefix:
            raise AdapterError(f"skill_catalog.{skill_id}: icon category mismatch")
        skill_rows.append(
            {
                "skill_id": skill_id,
                "upstream_numeric_id": require_integer(
                    record.get("game_id"),
                    f"skill_catalog.{skill_id}.game_id",
                ),
                "name": require_string(record.get("name"), f"skill_catalog.{skill_id}.name"),
                "category": normalized_category,
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
                "target_text": None,
                "icon_key": icon_match.group(2),
                "extra_json": {
                    key: to_plain(record[key])
                    for key in ("category", "damage_class", "flavor", "icon")
                    if record.get(key) is not None
                },
                "status": "active",
            }
        )
        for ordinal, note_id in enumerate(
            _sequence(record.get("desc_notes"), f"skill_catalog.{skill_id}.desc_notes")
        ):
            if not isinstance(note_id, (int, str)) or isinstance(note_id, bool):
                raise AdapterError(f"skill_catalog.{skill_id}: invalid description note")
            skill_note_rows.append(
                {"skill_id": skill_id, "ordinal": ordinal, "note_id": str(note_id)}
            )

    pet_rows: list[dict[str, Any]] = []
    pet_alias_rows: list[dict[str, Any]] = []
    pet_type_rows: list[dict[str, Any]] = []
    pet_learnset_rows: list[dict[str, str]] = []
    for pet_id, record in sorted(pets.items()):
        if require_string(record.get("id"), f"core.{pet_id}.id") != pet_id:
            raise AdapterError(f"core.{pet_id}: embedded ID does not match its key")
        image = require_mapping(record.get("image"), f"core.{pet_id}.image")
        stats = require_mapping(record.get("stats"), f"core.{pet_id}.stats")
        game_id = require_integer(record.get("game_id"), f"core.{pet_id}.game_id")
        source_illustration = _png_stem(
            image.get("illustration"),
            f"core.{pet_id}.image.illustration",
        )
        illustration = legacy_illustrations.get(game_id, source_illustration)
        source_shiny = (
            None
            if image.get("shiny") is None
            else _png_stem(image["shiny"], f"core.{pet_id}.image.shiny")
        )
        season = require_string(
            overview[pet_id].get("season"),
            f"overview.{pet_id}.season",
        )
        if season == "none":
            normalized_season = None
        elif re.fullmatch(r"S[1-9]\d*", season):
            normalized_season = season[1:]
        else:
            raise AdapterError(f"overview.{pet_id}: invalid season {season!r}")
        learnset_id = require_string(
            record.get("learnset_id"),
            f"core.{pet_id}.learnset_id",
        )
        evolution_id = require_string(
            record.get("evolution_id"),
            f"core.{pet_id}.evolution_id",
        )
        pet_rows.append(
            {
                "pet_id": pet_id,
                "handbook_id": require_string(
                    record.get("handbook_id"),
                    f"core.{pet_id}.handbook_id",
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
                "belong_season_raw": normalized_season,
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
                "is_lord_evolution": int(record.get("is_lord_evolution") is True),
                "hide_entry_name": 0,
                "show_topics": _optional_boolean(
                    record.get("handbook_show_topics"),
                    f"core.{pet_id}.handbook_show_topics",
                ),
                "feature_skill_id": _optional_string(
                    record.get("feature_skill_id"),
                    f"core.{pet_id}.feature_skill_id",
                ),
                **{
                    key: _optional_integer(stats.get(key), f"core.{pet_id}.stats.{key}")
                    for key in ("hp", "atk", "def", "spa", "spd", "spe")
                },
                "illustration_key": illustration,
                "head_key": _png_stem(image.get("head"), f"core.{pet_id}.image.head"),
                "extra_json": {
                    "game_id": game_id,
                    "egg_group": to_plain(record.get("egg_group")),
                    "gender_ratio": to_plain(record.get("gender_ratio")),
                    "release": to_plain(record.get("release")),
                    "source_image": _plain_mapping(image),
                    "source_illustration_key": source_illustration,
                    "source_shiny_illustration_key": source_shiny,
                    **{
                        key: to_plain(record[key])
                        for key in (
                            "affinity",
                            "can_ride",
                            "catch_threshold",
                            "ecology",
                            "egg_size",
                            "move_type",
                            "perception_range",
                            "relation_key",
                            "siblings",
                            "submit_reward",
                            "talent_pool_id",
                        )
                        if record.get(key) is not None
                    },
                },
                "source_evolution_group_ids": [evolution_id],
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
                raise AdapterError(f"core.{pet_id}: creature type cannot be null")
            pet_type_rows.append({"pet_id": pet_id, "slot": slot, "type_id": type_id})
        pet_learnset_rows.append({"pet_id": pet_id, "learnset_id": learnset_id})

    learnset_rows: list[dict[str, Any]] = []
    native_rows: list[dict[str, Any]] = []
    blood_rows: list[dict[str, Any]] = []
    stone_rows: list[dict[str, Any]] = []
    legendary_rows: list[dict[str, Any]] = []
    for learnset_id, record in sorted(learnsets.items()):
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
    evolution_edges: list[dict[str, Any]] = []
    mismatch_pairs: set[tuple[str, str]] = set()
    for group_id, value in sorted(evolution_values.items()):
        variants = require_sequence(value, f"evolution.{group_id}")
        names: list[str] = []
        member_order: dict[str, int] = {}
        raw_edges: list[tuple[str, str, str, str | None, int | None]] = []
        for variant_index, variant_value in enumerate(variants):
            variant = require_mapping(
                variant_value,
                f"evolution.{group_id}[{variant_index}]",
            )
            name = _optional_string(variant.get("name"), f"evolution.{group_id}.name")
            if name and name not in names:
                names.append(name)
            fields: dict[str, list[dict[str, LuaValue]]] = {}
            for field in ("chain", "lord_branches"):
                fields[field] = [
                    require_mapping(item, f"evolution.{group_id}.{field}")
                    for item in _sequence(variant.get(field), f"evolution.{group_id}.{field}")
                ]
                for member in fields[field]:
                    pet_id = require_string(member.get("id"), f"evolution.{group_id}.{field}.id")
                    if pet_id not in pets:
                        raise AdapterError(f"Evolution {group_id} references missing pet {pet_id}")
                    member_order.setdefault(pet_id, len(member_order))
                    source_types = [
                        require_string(item, "evolution member type")
                        for item in _sequence(member.get("types"), "evolution member types")
                    ]
                    core_types = [
                        require_string(item, "core pet type")
                        for item in _sequence(pets[pet_id].get("types"), "core pet types")
                    ]
                    if source_types != core_types:
                        mismatch_pairs.add((group_id, pet_id))
            chain = fields["chain"]
            for source, target in zip(chain, chain[1:]):
                raw_edges.append(
                    (
                        "chain",
                        require_string(source.get("id"), "evolution source"),
                        require_string(target.get("id"), "evolution target"),
                        _optional_string(target.get("cond"), "evolution condition"),
                        _optional_integer(target.get("level"), "evolution level"),
                    )
                )
            if chain:
                source_id = require_string(chain[-1].get("id"), "evolution source")
                for target in fields["lord_branches"]:
                    condition = _optional_string(target.get("cond"), "evolution condition")
                    item = _optional_string(target.get("item"), "evolution item")
                    if item:
                        condition = f"{condition}; {item}" if condition else item
                    raw_edges.append(
                        (
                            "lord_branch",
                            source_id,
                            require_string(target.get("id"), "evolution target"),
                            condition,
                            _optional_integer(target.get("level"), "evolution level"),
                        )
                    )
        evolution_group_rows.append(
            {
                "evolution_group_id": group_id,
                "label": " / ".join(names) if names else None,
                "status": "active",
            }
        )
        evolution_member_rows.extend(
            {
                "evolution_group_id": group_id,
                "pet_id": pet_id,
                "source_order": source_order,
            }
            for pet_id, source_order in member_order.items()
        )
        seen_edges: set[tuple[str, str, str, str | None, int | None]] = set()
        for edge in raw_edges:
            if edge in seen_edges:
                continue
            seen_edges.add(edge)
            evolution_edges.append(
                {
                    "evolution_group_id": group_id,
                    "edge_kind": edge[0],
                    "ordinal": len(seen_edges) - 1,
                    "from_pet_id": edge[1],
                    "to_pet_id": edge[2],
                    "condition_text": edge[3],
                    "level_requirement": edge[4],
                }
            )

    pet_ids = set(pets)
    handbook_ids = set(handbooks)
    skill_ids = set(skills)
    learnset_ids = set(learnsets)
    evolution_ids = set(evolution_values)
    missing_references = {
        "pet_handbooks": {
            require_string(row.get("handbook_id"), "pet handbook")
            for row in pets.values()
        }
        - handbook_ids,
        "pet_learnsets": {
            require_string(row.get("learnset_id"), "pet learnset") for row in pets.values()
        }
        - learnset_ids,
        "pet_evolutions": {
            require_string(row.get("evolution_id"), "pet evolution") for row in pets.values()
        }
        - evolution_ids,
        "pet_features": {
            require_string(row.get("feature_skill_id"), "pet feature")
            for row in pets.values()
            if row.get("feature_skill_id") is not None
        }
        - skill_ids,
        "learnset_skills": {
            row["skill_id"]
            for rows in (native_rows, blood_rows, stone_rows, legendary_rows)
            for row in rows
        }
        - skill_ids,
    }
    missing_references["learnset_features"] = {
        row["feature_skill_id"] for row in learnset_rows if row["feature_skill_id"]
    } - skill_ids
    if any(missing_references.values()):
        raise AdapterError(
            "NRC reference closure failed: "
            + json.dumps(
                {key: sorted(values) for key, values in missing_references.items() if values},
                ensure_ascii=False,
                sort_keys=True,
            )
        )

    evolution_membership = {
        (row["evolution_group_id"], row["pet_id"]) for row in evolution_member_rows
    }
    memberships_by_pet: dict[str, list[str]] = {pet_id: [] for pet_id in pets}
    for group_id, pet_id in sorted(evolution_membership):
        memberships_by_pet[pet_id].append(group_id)
    for row in pet_rows:
        direct_group = row["source_evolution_group_ids"][0]
        memberships = memberships_by_pet[row["pet_id"]]
        if direct_group not in memberships:
            raise AdapterError(
                f"NRC Catalog evolution {direct_group} does not include {row['pet_id']}"
            )
        row["source_evolution_group_ids"] = memberships
    catalog_membership = {
        (group_id, row["pet_id"])
        for row in pet_rows
        for group_id in row["source_evolution_group_ids"]
    }
    if catalog_membership != evolution_membership:
        raise AdapterError("NRC Catalog and Evolutions membership differ")

    entity_sources: list[dict[str, str]] = []
    for entity_kind, record_ids, source_key in (
        ("pet", pet_ids, "core"),
        ("handbook", handbook_ids, "handbook"),
        ("skill", skill_ids, "skill_catalog"),
        ("learnset", learnset_ids, "learnset_catalog"),
        ("evolution_group", evolution_ids, "evolution"),
    ):
        entity_sources.extend(
            {
                "entity_kind": entity_kind,
                "entity_id": entity_id,
                "source_ref": source_refs[source_key],
                "source_record_key": entity_id,
            }
            for entity_id in sorted(record_ids)
        )

    unfinished = next(
        (
            {"pet_id": pet_id, "number": record.get("number")}
            for pet_id, record in pets.items()
            if record.get("name") == "\u672a\u5b8c\u866b"
        ),
        None,
    )
    if unfinished is None:
        raise AdapterError("Required S4 source sample is missing")

    return {
        "normalized_version": 1,
        "dataset_id": lock["dataset_id"],
        "schema_version": 1,
        "data_version": data_version,
        "snapshot_id": lock["snapshot_id"],
        "adapter_version": "nrc-v1",
        "builder_version": "phase8-nrc-v1",
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
            "status": "passed",
            "warnings": [
                {
                    "code": "pre_release_identity_baseline_replaced",
                    "reason": "The application has not been released and has no user identity compatibility requirement.",
                }
            ],
            "sample_mappings": {"s4_creature": unfinished},
            "rendered_index_evidence": None,
            "evolution_type_mismatches": [
                {"evolution_group_id": group_id, "pet_id": pet_id}
                for group_id, pet_id in sorted(mismatch_pairs)
            ],
            "handbook_fields_not_in_v1_database": [
                "areas",
                "habitat",
                "title",
                "topics",
            ],
            "source_profile": "bwiki.nrc",
            "source_counts": {
                "pets": len(pets),
                "handbooks": len(handbooks),
                "skills": len(skills),
                "learnsets": len(learnsets),
                "evolution_groups": len(evolution_values),
            },
        },
        "source_revisions": source_revisions,
        "types": [
            {"type_id": type_ids[name], "name": name} for name in sorted(type_ids)
        ],
        "handbook_entries": handbook_rows,
        "handbook_display": handbook_display_rows,
        "skills": skill_rows,
        "skill_description_notes": skill_note_rows,
        "pets": pet_rows,
        "pet_aliases": pet_alias_rows,
        "pet_types": pet_type_rows,
        "learnsets": learnset_rows,
        "pet_learnsets": pet_learnset_rows,
        "learnset_native_skills": native_rows,
        "learnset_blood_skills": blood_rows,
        "learnset_skill_stones": stone_rows,
        "learnset_legendary_skills": legendary_rows,
        "evolution_groups": evolution_group_rows,
        "pet_evolution_groups": evolution_member_rows,
        "evolution_edges": evolution_edges,
        "entity_sources": entity_sources,
        "index_summary": {
            "pet_count": len(pets),
            "handbook_default_count": len(handbook_order),
            "history_revision_id": source_records["history"]["revision_id"],
        },
    }
