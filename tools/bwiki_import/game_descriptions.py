from __future__ import annotations

from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path
import tempfile
from typing import Any
from urllib.parse import urlencode, urlparse

from catalog_builder.errors import LuaSyntaxError
from catalog_builder.lua_parser import LuaTable, parse_lua_table

from .errors import InputError, ResponseValidationError, SnapshotWriteError
from .image_assets import UrlTransport, _read_json


def _configuration(path: Path) -> dict[str, Any]:
    config = _read_json(path, "game description configuration")
    endpoint = config.get("api_endpoint")
    policy = config.get("request_policy")
    order = config.get("category_order")
    labels = config.get("category_labels")
    terms = config.get("category_terms")
    if (
        config.get("config_version") != 1
        or config.get("dataset_id") != "roco-world-zh-cn"
        or not isinstance(endpoint, str)
        or urlparse(endpoint).scheme != "https"
        or not isinstance(config.get("source_title"), str)
        or not isinstance(config.get("source_page_id"), int)
        or not isinstance(config.get("source_url_prefix"), str)
        or not isinstance(policy, dict)
        or not isinstance(policy.get("timeout_seconds"), int)
        or not isinstance(policy.get("max_retries"), int)
        or not isinstance(order, list)
        or not order
        or not all(isinstance(item, str) and item for item in order)
        or len(order) != len(set(order))
        or not isinstance(labels, dict)
        or set(labels) != set(order)
        or not all(isinstance(value, str) and value for value in labels.values())
        or not isinstance(terms, dict)
        or set(terms) != set(order)
    ):
        raise InputError("Game description configuration is invalid")
    configured_names: list[str] = []
    for category in order:
        values = terms[category]
        if not isinstance(values, list) or not all(
            isinstance(value, str) and value for value in values
        ):
            raise InputError("Game description category terms are invalid")
        configured_names.extend(values)
    if len(configured_names) != len(set(configured_names)):
        raise InputError("Game description category terms contain duplicates")
    return config


def _validate_response(
    document: dict[str, Any], config: dict[str, Any]
) -> tuple[dict[str, Any], str]:
    if document.get("batchcomplete") is not True:
        raise ResponseValidationError("Game description response is incomplete")
    query = document.get("query")
    pages = query.get("pages") if isinstance(query, dict) else None
    if not isinstance(pages, list) or len(pages) != 1:
        raise ResponseValidationError("Game description response requires one page")
    page = pages[0]
    if (
        not isinstance(page, dict)
        or page.get("pageid") != config["source_page_id"]
        or page.get("title")
        not in {config["source_title"], "\u6a21\u5757:Pets/data/Terms"}
    ):
        raise ResponseValidationError("Game description source identity changed")
    revisions = page.get("revisions")
    if not isinstance(revisions, list) or len(revisions) != 1:
        raise ResponseValidationError("Game description source requires one revision")
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
        raise ResponseValidationError("Game description revision metadata is invalid")
    if hashlib.sha1(content.encode("utf-8")).hexdigest() != revision["sha1"]:
        raise ResponseValidationError("Game description source SHA-1 mismatch")
    return revision, content


def parse_game_descriptions(
    content: str,
    *,
    source: str,
    category_order: list[str],
    category_terms: dict[str, list[str]],
) -> list[dict[str, str]]:
    try:
        root = parse_lua_table(content, source=source).value
        resolved = root.resolved_items()
    except LuaSyntaxError as error:
        raise ResponseValidationError(str(error)) from error
    category_by_name = {
        name: category
        for category in category_order
        for name in category_terms[category]
    }
    entries: list[dict[str, str]] = []
    seen_ids: set[int] = set()
    seen_names: set[str] = set()
    for raw_id, raw_entry in resolved:
        if (
            not isinstance(raw_id, int)
            or isinstance(raw_id, bool)
            or raw_id <= 0
            or raw_id in seen_ids
            or not isinstance(raw_entry, LuaTable)
        ):
            raise ResponseValidationError(
                f"{source}: invalid game description identity {raw_id!r}"
            )
        try:
            record = raw_entry.as_mapping(f"{source}[{raw_id}]")
        except LuaSyntaxError as error:
            raise ResponseValidationError(str(error)) from error
        if set(record) != {"note", "desc"}:
            raise ResponseValidationError(
                f"{source}[{raw_id}]: expected note and desc fields"
            )
        name = record["note"]
        description = record["desc"]
        if (
            not isinstance(name, str)
            or not name
            or name in seen_names
            or not isinstance(description, str)
            or not description
            or name not in category_by_name
        ):
            raise ResponseValidationError(
                f"{source}[{raw_id}]: invalid or unclassified description"
            )
        seen_ids.add(raw_id)
        seen_names.add(name)
        entries.append(
            {
                "note_id": str(raw_id),
                "name": name,
                "description": description,
                "category": category_by_name[name],
            }
        )
    configured_names = set(category_by_name)
    if seen_names != configured_names:
        missing = sorted(configured_names - seen_names)
        unexpected = sorted(seen_names - configured_names)
        details: list[str] = []
        if missing:
            details.append("missing " + ", ".join(missing))
        if unexpected:
            details.append("unexpected " + ", ".join(unexpected))
        raise ResponseValidationError(
            "Game description category review changed: " + "; ".join(details)
        )
    entries.sort(key=lambda entry: int(entry["note_id"]))
    return entries


def import_game_descriptions(
    config_path: Path,
    output_path: Path,
    *,
    transport: UrlTransport | None = None,
) -> Path:
    config = _configuration(config_path)
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
    revision, content = _validate_response(client.get_json(url), config)
    entries = parse_game_descriptions(
        content,
        source=config["source_title"],
        category_order=config["category_order"],
        category_terms=config["category_terms"],
    )
    document = {
        "contract_version": 1,
        "dataset_id": config["dataset_id"],
        "imported_at_utc": datetime.now(timezone.utc).isoformat().replace(
            "+00:00", "Z"
        ),
        "source": {
            "page_id": config["source_page_id"],
            "title": config["source_title"],
            "revision_id": revision["revid"],
            "revised_at_utc": revision["timestamp"],
            "source_sha1": revision["sha1"],
            "source_url": config["source_url_prefix"] + str(revision["revid"]),
        },
        "category_order": config["category_order"],
        "category_labels": config["category_labels"],
        "entries": entries,
    }
    serialized = json.dumps(
        document, ensure_ascii=False, indent=2, sort_keys=True
    ) + "\n"
    if output_path.exists():
        try:
            existing = json.loads(output_path.read_text(encoding="utf-8"))
        except (OSError, UnicodeDecodeError, json.JSONDecodeError) as error:
            raise SnapshotWriteError(
                f"Existing game description asset is invalid: {error}"
            ) from error
        comparable = dict(document)
        comparable.pop("imported_at_utc")
        existing_comparable = dict(existing)
        existing_comparable.pop("imported_at_utc", None)
        if existing_comparable != comparable:
            raise SnapshotWriteError("Existing game description asset differs")
        return output_path
    output_path.parent.mkdir(parents=True, exist_ok=True)
    descriptor, temporary_name = tempfile.mkstemp(
        prefix=f".{output_path.name}.", dir=output_path.parent
    )
    try:
        with os.fdopen(descriptor, "w", encoding="utf-8") as file:
            file.write(serialized)
        os.rename(temporary_name, output_path)
    except OSError as error:
        raise SnapshotWriteError(
            f"Cannot freeze game descriptions: {error}"
        ) from error
    finally:
        temporary = Path(temporary_name)
        if temporary.exists():
            temporary.unlink()
    return output_path
