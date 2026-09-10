from __future__ import annotations

from datetime import datetime, timedelta, timezone
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import re
import tempfile
from typing import Any
from urllib.parse import urlencode, urlparse

from catalog_builder.errors import LuaSyntaxError
from catalog_builder.lua_parser import LuaTable, LuaValue, parse_lua_table

from .errors import InputError, ResponseValidationError, SnapshotWriteError
from .image_assets import (
    AssetSpec,
    FrozenAssetSet,
    UrlTransport,
    _read_json,
    freeze_asset_specs,
)


_ACTIVITY_FIELDS = {
    "category",
    "description",
    "fashion_groups",
    "id",
    "kind",
    "kind_label",
    "masked",
    "name",
    "page_title",
    "prerequisite",
    "related",
    "relation_targets",
    "relations",
    "returning_player_only",
    "reward_overviews",
    "season_spanning_single",
    "series_id",
    "shop_ids",
    "source_id",
    "stages",
    "summary",
    "visual",
    "window",
    "window_note",
}
_ACTIVITY_VISUAL_FIELDS = {
    "icon",
    "icon_selected",
    "poster",
    "poster_evidence",
    "posters",
    "story_card",
    "title",
}
_FASHION_FIELDS = {
    "bond_id",
    "color_ids",
    "description",
    "genders",
    "grade",
    "grade_name",
    "id",
    "monthly",
    "name",
    "original_ids",
    "package_related_ids",
    "page_title",
    "quality",
    "series_id",
    "source_ids",
    "style_key",
    "variants",
}
_FASHION_VARIANT_FIELDS = {
    "acquire",
    "activity_available_at",
    "bond_id",
    "card_image",
    "description",
    "effects",
    "gender",
    "gender_label",
    "grade",
    "grade_name",
    "item_count",
    "main_image",
    "name",
    "original_id",
    "package",
    "piece_ids",
    "quality",
    "series_id",
    "shops",
    "source_id",
    "source_ids",
    "upgrades",
}
_SOURCE_FILENAME = re.compile(r"[A-Za-z0-9_. -]+\.png")
_UTC_PLUS_EIGHT = timezone(timedelta(hours=8))


def _catalog_configuration(path: Path, kind: str) -> dict[str, Any]:
    config = _read_json(path, f"{kind} configuration")
    endpoint = config.get("api_endpoint")
    policy = config.get("request_policy")
    if (
        config.get("config_version") != 1
        or config.get("dataset_id") != "roco-world-zh-cn"
        or config.get("catalog_kind") != kind
        or not isinstance(endpoint, str)
        or urlparse(endpoint).scheme != "https"
        or not isinstance(config.get("source_title"), str)
        or not isinstance(config.get("source_page_id"), int)
        or not isinstance(config.get("source_url_prefix"), str)
        or not isinstance(config.get("expected_count"), int)
        or config["expected_count"] <= 0
        or not isinstance(policy, dict)
        or not isinstance(policy.get("timeout_seconds"), int)
        or policy["timeout_seconds"] <= 0
        or not isinstance(policy.get("max_retries"), int)
        or policy["max_retries"] <= 0
    ):
        raise InputError(f"{kind.capitalize()} configuration is invalid")
    return config


def _source_response(
    document: dict[str, Any], config: dict[str, Any], label: str
) -> tuple[dict[str, Any], str]:
    if document.get("batchcomplete") is not True:
        raise ResponseValidationError(f"{label} response is incomplete")
    query = document.get("query")
    pages = query.get("pages") if isinstance(query, dict) else None
    if not isinstance(pages, list) or len(pages) != 1:
        raise ResponseValidationError(f"{label} response requires one page")
    page = pages[0]
    if not isinstance(page, dict) or page.get("pageid") != config["source_page_id"]:
        raise ResponseValidationError(f"{label} source identity changed")
    actual_title = page.get("title")
    expected_title = config["source_title"]
    if not isinstance(actual_title, str) or actual_title.split(":", 1)[-1] != expected_title.split(":", 1)[-1]:
        raise ResponseValidationError(f"{label} source title changed")
    revisions = page.get("revisions")
    if not isinstance(revisions, list) or len(revisions) != 1:
        raise ResponseValidationError(f"{label} source requires one revision")
    revision = revisions[0]
    slot = revision.get("slots", {}).get("main") if isinstance(revision, dict) else None
    content = slot.get("content") if isinstance(slot, dict) else None
    if (
        not isinstance(revision, dict)
        or not isinstance(revision.get("revid"), int)
        or not isinstance(revision.get("timestamp"), str)
        or not isinstance(revision.get("sha1"), str)
        or not isinstance(content, str)
        or slot.get("contentmodel") != "Scribunto"
    ):
        raise ResponseValidationError(f"{label} revision metadata is invalid")
    if hashlib.sha1(content.encode("utf-8")).hexdigest() != revision["sha1"]:
        raise ResponseValidationError(f"{label} source SHA-1 mismatch")
    return revision, content


def _fetch_source(
    config: dict[str, Any], transport: UrlTransport | None
) -> tuple[dict[str, Any], str]:
    policy = config["request_policy"]
    client = transport or UrlTransport(
        timeout_seconds=policy["timeout_seconds"],
        max_retries=policy["max_retries"],
    )
    url = config["api_endpoint"] + "?" + urlencode(
        {
            "action": "query",
            "format": "json",
            "formatversion": "2",
            "prop": "revisions",
            "titles": config["source_title"],
            "rvprop": "ids|timestamp|sha1|size|content",
            "rvslots": "main",
        }
    )
    return _source_response(client.get_json(url), config, config["catalog_kind"])


def _lua_json(value: LuaValue) -> Any:
    if not isinstance(value, LuaTable):
        return value
    items = value.resolved_items()
    if value.kind in {"array", "empty"}:
        return [_lua_json(item) for _, item in items]
    if value.kind == "map" and all(isinstance(key, str) for key, _ in items):
        return {str(key): _lua_json(item) for key, item in items}
    return {
        "lua_entries": [
            {"key": _lua_json(key), "value": _lua_json(item)}
            for key, item in items
        ]
    }


def _mapping(value: LuaValue, context: str) -> dict[str, LuaValue]:
    if not isinstance(value, LuaTable):
        raise ResponseValidationError(f"{context}: expected a table")
    try:
        return value.as_mapping(context)
    except LuaSyntaxError as error:
        raise ResponseValidationError(str(error)) from error


def _sequence(value: LuaValue, context: str) -> tuple[LuaValue, ...]:
    if not isinstance(value, LuaTable):
        raise ResponseValidationError(f"{context}: expected an array")
    try:
        return value.as_sequence(context)
    except LuaSyntaxError as error:
        raise ResponseValidationError(str(error)) from error


def _required_text(record: dict[str, LuaValue], key: str, context: str) -> str:
    value = record.get(key)
    if not isinstance(value, str) or not value:
        raise ResponseValidationError(f"{context}: invalid {key}")
    return value


def _optional_text(record: dict[str, LuaValue], key: str, context: str) -> str | None:
    value = record.get(key)
    if value is not None and not isinstance(value, str):
        raise ResponseValidationError(f"{context}: invalid {key}")
    return value


def _source_filename(value: str, context: str) -> str:
    if _SOURCE_FILENAME.fullmatch(value) is None or PurePosixPath(value).name != value:
        raise ResponseValidationError(f"{context}: unsafe source image filename")
    return value


def _local_time(value: str | None, context: str) -> str | None:
    if value is None:
        return None
    try:
        parsed = datetime.strptime(value, "%Y-%m-%d %H:%M:%S").replace(
            tzinfo=_UTC_PLUS_EIGHT
        )
    except ValueError as error:
        raise ResponseValidationError(f"{context}: invalid local timestamp") from error
    return parsed.isoformat()


def parse_activity_catalog(
    content: str, *, source: str, categories: list[str], expected_count: int
) -> list[dict[str, Any]]:
    try:
        root = parse_lua_table(content, source=source).value
        rows = root.resolved_items()
    except LuaSyntaxError as error:
        raise ResponseValidationError(str(error)) from error
    entries: list[dict[str, Any]] = []
    seen: set[str] = set()
    for raw_key, raw_value in rows:
        context = f"{source}[{raw_key!r}]"
        record = _mapping(raw_value, context)
        unexpected = set(record) - _ACTIVITY_FIELDS
        if unexpected:
            raise ResponseValidationError(
                f"{context}: unexpected fields {', '.join(sorted(unexpected))}"
            )
        activity_id = _required_text(record, "id", context)
        if raw_key != activity_id or activity_id in seen:
            raise ResponseValidationError(f"{context}: invalid activity identity")
        seen.add(activity_id)
        category = _required_text(record, "category", context)
        if category not in categories:
            raise ResponseValidationError(f"{context}: unknown activity category")
        masked = record.get("masked", False)
        if not isinstance(masked, bool):
            raise ResponseValidationError(f"{context}: invalid masked flag")
        window = _mapping(record.get("window"), f"{context}.window")
        if set(window) != {"start", "end", "timezone"} or window["timezone"] != "UTC+8":
            raise ResponseValidationError(f"{context}: invalid activity window")
        start_at = _local_time(window["start"], f"{context}.window.start")
        end_at = _local_time(window["end"], f"{context}.window.end")
        if start_at is not None and end_at is not None and start_at > end_at:
            raise ResponseValidationError(f"{context}: reversed activity window")
        visual = _mapping(record.get("visual"), f"{context}.visual")
        unexpected_visual = set(visual) - _ACTIVITY_VISUAL_FIELDS
        if unexpected_visual:
            raise ResponseValidationError(f"{context}: unexpected visual fields")
        icon = visual.get("icon")
        if icon is not None and not isinstance(icon, str):
            raise ResponseValidationError(f"{context}: invalid activity icon")
        source_icon = _source_filename(icon, context) if icon else None
        entries.append(
            {
                "activity_id": activity_id,
                "series_id": _required_text(record, "series_id", context),
                "name": _required_text(record, "name", context),
                "summary": _optional_text(record, "summary", context),
                "description": _optional_text(record, "description", context),
                "category": category,
                "kind_label": _required_text(record, "kind_label", context)
                if not masked
                else _optional_text(record, "kind_label", context) or "",
                "page_title": _optional_text(record, "page_title", context),
                "masked": masked,
                "start_at": start_at,
                "end_at": end_at,
                "source_icon": source_icon,
                "icon_path": f"activities/icons/{source_icon}" if source_icon else None,
                "source_record": _lua_json(raw_value),
            }
        )
    if len(entries) != expected_count:
        raise ResponseValidationError(
            f"Activity count changed: expected {expected_count}, found {len(entries)}"
        )
    entries.sort(
        key=lambda entry: (
            entry["start_at"] is None,
            entry["start_at"] or "",
            entry["end_at"] or "",
            entry["activity_id"],
        )
    )
    return entries


def parse_fashion_catalog(
    content: str,
    *,
    source: str,
    expected_count: int,
    gender_order: list[str],
    image_overrides: dict[str, str],
) -> list[dict[str, Any]]:
    try:
        root = parse_lua_table(content, source=source).value
        rows = root.resolved_items()
    except LuaSyntaxError as error:
        raise ResponseValidationError(str(error)) from error
    entries: list[dict[str, Any]] = []
    seen: set[str] = set()
    used_overrides: set[str] = set()
    for raw_key, raw_value in rows:
        context = f"{source}[{raw_key!r}]"
        record = _mapping(raw_value, context)
        unexpected = set(record) - _FASHION_FIELDS
        if unexpected:
            raise ResponseValidationError(
                f"{context}: unexpected fields {', '.join(sorted(unexpected))}"
            )
        outfit_id = _required_text(record, "id", context)
        if raw_key != outfit_id or outfit_id in seen:
            raise ResponseValidationError(f"{context}: invalid outfit identity")
        seen.add(outfit_id)
        variants = _mapping(record.get("variants"), f"{context}.variants")
        if set(variants) != set(gender_order):
            raise ResponseValidationError(f"{context}: unexpected outfit variants")
        normalized_variants: list[dict[str, Any]] = []
        for gender in gender_order:
            variant_context = f"{context}.variants.{gender}"
            variant = _mapping(variants[gender], variant_context)
            unexpected_variant = set(variant) - _FASHION_VARIANT_FIELDS
            if unexpected_variant:
                raise ResponseValidationError(
                    f"{variant_context}: unexpected fields "
                    + ", ".join(sorted(unexpected_variant))
                )
            if variant.get("gender") != gender:
                raise ResponseValidationError(f"{variant_context}: gender mismatch")
            acquisition = _sequence(variant.get("acquire"), f"{variant_context}.acquire")
            if not all(isinstance(item, str) and item for item in acquisition):
                raise ResponseValidationError(f"{variant_context}: invalid acquisition")
            override_key = f"{outfit_id}:{gender}"
            source_image_value = image_overrides.get(
                override_key, _required_text(variant, "card_image", variant_context)
            )
            if override_key in image_overrides:
                used_overrides.add(override_key)
            source_image = _source_filename(source_image_value, variant_context)
            item_count = variant.get("item_count")
            if not isinstance(item_count, int) or isinstance(item_count, bool) or item_count <= 0:
                raise ResponseValidationError(f"{variant_context}: invalid item count")
            normalized_variants.append(
                {
                    "gender": gender,
                    "gender_label": _required_text(
                        variant, "gender_label", variant_context
                    ),
                    "name": _required_text(variant, "name", variant_context),
                    "description": _optional_text(
                        variant, "description", variant_context
                    ),
                    "acquisition": list(acquisition),
                    "item_count": item_count,
                    "source_image": source_image,
                    "image_path": f"fashions/cards/{outfit_id}-{gender}.png",
                }
            )
        quality = record.get("quality")
        series_id = record.get("series_id")
        if (
            not isinstance(quality, int)
            or isinstance(quality, bool)
            or quality <= 0
            or not isinstance(series_id, int)
            or isinstance(series_id, bool)
            or series_id <= 0
        ):
            raise ResponseValidationError(f"{context}: invalid outfit classification")
        entries.append(
            {
                "outfit_id": outfit_id,
                "name": _required_text(record, "name", context),
                "page_title": _required_text(record, "page_title", context),
                "description": _optional_text(record, "description", context),
                "grade_name": _required_text(record, "grade_name", context),
                "quality": quality,
                "series_id": series_id,
                "variants": normalized_variants,
                "source_record": _lua_json(raw_value),
            }
        )
    if len(entries) != expected_count:
        raise ResponseValidationError(
            f"Outfit count changed: expected {expected_count}, found {len(entries)}"
        )
    if used_overrides != set(image_overrides):
        raise ResponseValidationError("Outfit image override identities changed")
    entries.sort(key=lambda entry: entry["outfit_id"])
    return entries


def _write_contract(output_path: Path, document: dict[str, Any], label: str) -> Path:
    if output_path.exists():
        try:
            existing = json.loads(output_path.read_text(encoding="utf-8"))
        except (OSError, UnicodeDecodeError, json.JSONDecodeError) as error:
            raise SnapshotWriteError(f"Existing {label} asset is invalid: {error}") from error
        comparable = dict(document)
        comparable.pop("imported_at_utc")
        existing_comparable = dict(existing)
        existing_comparable.pop("imported_at_utc", None)
        if existing_comparable != comparable:
            raise SnapshotWriteError(f"Existing {label} asset differs")
        return output_path
    serialized = json.dumps(document, ensure_ascii=False, indent=2, sort_keys=True) + "\n"
    output_path.parent.mkdir(parents=True, exist_ok=True)
    descriptor, temporary_name = tempfile.mkstemp(
        prefix=f".{output_path.name}.", dir=output_path.parent
    )
    try:
        with os.fdopen(descriptor, "w", encoding="utf-8") as file:
            file.write(serialized)
        os.rename(temporary_name, output_path)
    except OSError as error:
        raise SnapshotWriteError(f"Cannot freeze {label}: {error}") from error
    finally:
        temporary = Path(temporary_name)
        if temporary.exists():
            temporary.unlink()
    return output_path


def _source_document(
    config: dict[str, Any], revision: dict[str, Any]
) -> dict[str, Any]:
    return {
        "page_id": config["source_page_id"],
        "title": config["source_title"],
        "revision_id": revision["revid"],
        "revised_at_utc": revision["timestamp"],
        "source_sha1": revision["sha1"],
        "source_url": config["source_url_prefix"] + str(revision["revid"]),
    }


def import_activity_catalog(
    config_path: Path,
    output_path: Path,
    *,
    transport: UrlTransport | None = None,
) -> Path:
    config = _catalog_configuration(config_path, "activity")
    categories = config.get("category_order")
    labels = config.get("category_labels")
    if (
        not isinstance(categories, list)
        or not categories
        or not all(isinstance(item, str) and item for item in categories)
        or not isinstance(labels, dict)
        or set(labels) != set(categories)
    ):
        raise InputError("Activity categories are invalid")
    revision, content = _fetch_source(config, transport)
    entries = parse_activity_catalog(
        content,
        source=config["source_title"],
        categories=categories,
        expected_count=config["expected_count"],
    )
    return _write_contract(
        output_path,
        {
            "contract_version": 1,
            "dataset_id": config["dataset_id"],
            "imported_at_utc": datetime.now(timezone.utc)
            .isoformat()
            .replace("+00:00", "Z"),
            "source": _source_document(config, revision),
            "category_order": categories,
            "category_labels": labels,
            "entries": entries,
        },
        "activity timeline",
    )


def import_fashion_catalog(
    config_path: Path,
    output_path: Path,
    *,
    transport: UrlTransport | None = None,
) -> Path:
    config = _catalog_configuration(config_path, "fashion")
    gender_order = config.get("gender_order")
    image_overrides = config.get("image_overrides", {})
    if (
        gender_order != ["female", "male"]
        or not isinstance(image_overrides, dict)
        or not all(
            isinstance(key, str) and isinstance(value, str)
            for key, value in image_overrides.items()
        )
    ):
        raise InputError("Fashion variant configuration is invalid")
    revision, content = _fetch_source(config, transport)
    entries = parse_fashion_catalog(
        content,
        source=config["source_title"],
        expected_count=config["expected_count"],
        gender_order=gender_order,
        image_overrides=image_overrides,
    )
    return _write_contract(
        output_path,
        {
            "contract_version": 1,
            "dataset_id": config["dataset_id"],
            "imported_at_utc": datetime.now(timezone.utc)
            .isoformat()
            .replace("+00:00", "Z"),
            "source": _source_document(config, revision),
            "gender_order": gender_order,
            "entries": entries,
        },
        "fashion catalog",
    )


def derive_tool_asset_specs(
    activity_catalog_path: Path,
    fashion_catalog_path: Path,
    asset_config_path: Path,
) -> list[AssetSpec]:
    activity = _read_json(activity_catalog_path, "activity timeline contract")
    fashion = _read_json(fashion_catalog_path, "fashion catalog contract")
    config = _read_json(asset_config_path, "tool asset configuration")
    if any(
        document.get("contract_version") != 1
        or document.get("dataset_id") != "roco-world-zh-cn"
        for document in (activity, fashion)
    ):
        raise InputError("Tool Catalog contract identity is invalid")
    widths = config.get("thumbnail_widths")
    if not isinstance(widths, dict):
        raise InputError("Tool asset thumbnail widths are missing")
    activity_width = widths.get("activity_icon")
    fashion_width = widths.get("fashion_card")
    if (
        not isinstance(activity_width, int)
        or activity_width <= 0
        or not isinstance(fashion_width, int)
        or fashion_width <= 0
    ):
        raise InputError("Tool asset thumbnail widths are invalid")
    grouped_icons: dict[tuple[str, str], list[str]] = {}
    entries = activity.get("entries")
    if not isinstance(entries, list):
        raise InputError("Activity timeline contract has no entries")
    for entry in entries:
        if not isinstance(entry, dict):
            raise InputError("Activity timeline entry is invalid")
        source = entry.get("source_icon")
        local_path = entry.get("icon_path")
        activity_id = entry.get("activity_id")
        if source is None and local_path is None:
            continue
        if not all(isinstance(value, str) and value for value in (source, local_path, activity_id)):
            raise InputError("Activity icon reference is invalid")
        grouped_icons.setdefault((source, local_path), []).append(activity_id)
    specs = [
        AssetSpec(
            asset_id=f"activity_icon:{source}",
            kind="activity_icon",
            source_title=f"File:{source}",
            local_path=local_path,
            width=activity_width,
            catalog_ids=tuple(sorted(ids)),
        )
        for (source, local_path), ids in grouped_icons.items()
    ]
    outfits = fashion.get("entries")
    if not isinstance(outfits, list):
        raise InputError("Fashion catalog contract has no entries")
    for outfit in outfits:
        if not isinstance(outfit, dict) or not isinstance(outfit.get("variants"), list):
            raise InputError("Fashion catalog entry is invalid")
        outfit_id = outfit.get("outfit_id")
        for variant in outfit["variants"]:
            if not isinstance(variant, dict):
                raise InputError("Fashion variant is invalid")
            gender = variant.get("gender")
            source = variant.get("source_image")
            local_path = variant.get("image_path")
            if not all(
                isinstance(value, str) and value
                for value in (outfit_id, gender, source, local_path)
            ):
                raise InputError("Fashion image reference is invalid")
            specs.append(
                AssetSpec(
                    asset_id=f"fashion_card:{outfit_id}:{gender}",
                    kind="fashion_card",
                    source_title=f"File:{source}",
                    local_path=local_path,
                    width=fashion_width,
                    catalog_ids=(f"{outfit_id}:{gender}",),
                )
            )
    return sorted(specs, key=lambda item: item.asset_id)


def import_tool_assets(
    activity_catalog_path: Path,
    fashion_catalog_path: Path,
    config_path: Path,
    output_root: Path,
    *,
    cache_root: Path | None = None,
    transport: UrlTransport | None = None,
) -> FrozenAssetSet:
    specs = derive_tool_asset_specs(
        activity_catalog_path, fashion_catalog_path, config_path
    )
    return freeze_asset_specs(
        specs,
        config_path,
        output_root,
        cache_root=cache_root,
        transport=transport,
    )
