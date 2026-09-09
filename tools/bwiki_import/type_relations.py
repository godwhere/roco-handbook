from __future__ import annotations

from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path
import tempfile
from typing import Any
from urllib.parse import urlencode

from catalog_builder.errors import LuaSyntaxError
from catalog_builder.lua_parser import LuaTable, parse_lua_table

from .errors import InputError, ResponseValidationError, SnapshotWriteError
from .image_assets import UrlTransport, _read_json


def _source_table(content: str, source: str) -> LuaTable:
    marker = "local type_relations ="
    offsets: list[tuple[int, int]] = []
    offset = 0
    for line_number, line in enumerate(content.splitlines(keepends=True), start=1):
        stripped = line.lstrip()
        if not stripped.startswith("--") and marker in line:
            offsets.append((offset + line.index(marker), line_number))
        offset += len(line)
    if len(offsets) != 1:
        raise ResponseValidationError(
            f"{source}: expected one data-only type_relations declaration"
        )
    declaration, line_number = offsets[0]
    opener = content.find("{", declaration + len(marker))
    if opener < 0:
        raise ResponseValidationError(f"{source}:{line_number}: missing table opener")
    depth = 0
    quote: str | None = None
    escaped = False
    line_comment = False
    long_comment = False
    closer = -1
    index = opener
    while index < len(content):
        character = content[index]
        pair = content[index : index + 2]
        if line_comment:
            if character == "\n":
                line_comment = False
            index += 1
            continue
        if long_comment:
            if pair == "]]":
                long_comment = False
                index += 2
            else:
                index += 1
            continue
        if quote is not None:
            if escaped:
                escaped = False
            elif character == "\\":
                escaped = True
            elif character == quote:
                quote = None
            index += 1
            continue
        if content[index : index + 4] == "--[[":
            long_comment = True
            index += 4
            continue
        if pair == "--":
            line_comment = True
            index += 2
            continue
        if character in {"'", '"'}:
            quote = character
        elif character == "{":
            depth += 1
        elif character == "}":
            depth -= 1
            if depth == 0:
                closer = index + 1
                break
            if depth < 0:
                break
        index += 1
    if closer < 0 or quote is not None or long_comment:
        raise ResponseValidationError(
            f"{source}:{line_number}: unterminated type_relations table"
        )
    extracted = "return " + ("\n" * (line_number - 1)) + content[opener:closer]
    try:
        return parse_lua_table(extracted, source=source).value
    except LuaSyntaxError as error:
        raise ResponseValidationError(str(error)) from error


def _strings(value: Any, context: str, allowed: set[str]) -> list[str]:
    if not isinstance(value, LuaTable):
        raise ResponseValidationError(f"{context}: expected an array")
    try:
        entries = value.as_sequence(context)
    except LuaSyntaxError as error:
        raise ResponseValidationError(str(error)) from error
    result: list[str] = []
    for entry in entries:
        if not isinstance(entry, str) or entry not in allowed:
            raise ResponseValidationError(f"{context}: invalid related type {entry!r}")
        if entry in result:
            raise ResponseValidationError(f"{context}: duplicate related type {entry!r}")
        result.append(entry)
    return result


def parse_type_relations(
    content: str,
    *,
    source: str,
    type_order: list[str],
    relation_names: dict[str, str],
    reviewed_conflicts: set[str] | None = None,
) -> dict[str, dict[str, list[str]]]:
    table = _source_table(content, source)
    try:
        raw_types = table.as_mapping(source)
    except LuaSyntaxError as error:
        raise ResponseValidationError(str(error)) from error
    if set(raw_types) != set(type_order):
        raise ResponseValidationError("Type relation keys differ from configured types")
    if set(relation_names) != {
        "strong_against",
        "resisted_by",
        "weak_to",
        "resists",
    }:
        raise InputError("Type relation semantic keys are incomplete")
    allowed = set(type_order)
    result: dict[str, dict[str, list[str]]] = {}
    for type_name in type_order:
        value = raw_types[type_name]
        if not isinstance(value, LuaTable):
            raise ResponseValidationError(f"{source}.{type_name}: expected a table")
        try:
            raw_relations = value.as_mapping(f"{source}.{type_name}")
        except LuaSyntaxError as error:
            raise ResponseValidationError(str(error)) from error
        if set(raw_relations) != set(relation_names.values()):
            raise ResponseValidationError(
                f"{source}.{type_name}: relation keys are incomplete"
            )
        result[type_name] = {
            semantic: _strings(
                raw_relations[source_name],
                f"{source}.{type_name}.{source_name}",
                allowed,
            )
            for semantic, source_name in relation_names.items()
        }
    conflicts: set[str] = set()
    for attacker, relations in result.items():
        for defender in relations["strong_against"]:
            if attacker not in result[defender]["weak_to"]:
                conflicts.add(f"strong_against:{attacker}:{defender}")
        for defender in relations["resisted_by"]:
            if attacker not in result[defender]["resists"]:
                conflicts.add(f"resisted_by:{attacker}:{defender}")
        for defender in relations["weak_to"]:
            if attacker not in result[defender]["strong_against"]:
                conflicts.add(f"weak_to:{attacker}:{defender}")
        for defender in relations["resists"]:
            if attacker not in result[defender]["resisted_by"]:
                conflicts.add(f"resists:{attacker}:{defender}")
    reviewed = reviewed_conflicts or set()
    if conflicts != reviewed:
        unexpected = sorted(conflicts - reviewed)
        stale = sorted(reviewed - conflicts)
        details = []
        if unexpected:
            details.append("unreviewed " + ", ".join(unexpected))
        if stale:
            details.append("stale review " + ", ".join(stale))
        raise ResponseValidationError(
            "Type relation reciprocity conflicts changed: " + "; ".join(details)
        )
    return result


def _validate_response(
    document: dict[str, Any], config: dict[str, Any]
) -> tuple[dict[str, Any], str]:
    if document.get("batchcomplete") is not True:
        raise ResponseValidationError("Type relation response is incomplete")
    query = document.get("query")
    pages = query.get("pages") if isinstance(query, dict) else None
    if not isinstance(pages, list) or len(pages) != 1:
        raise ResponseValidationError("Type relation response requires one page")
    page = pages[0]
    if (
        not isinstance(page, dict)
        or page.get("pageid") != config["source_page_id"]
        or page.get("title") not in {config["source_title"], "\u6a21\u5757:TypeRelation"}
    ):
        raise ResponseValidationError("Type relation source identity changed")
    revisions = page.get("revisions")
    if not isinstance(revisions, list) or len(revisions) != 1:
        raise ResponseValidationError("Type relation source requires one revision")
    revision = revisions[0]
    slot = revision.get("slots", {}).get("main") if isinstance(revision, dict) else None
    content = slot.get("content") if isinstance(slot, dict) else None
    if (
        not isinstance(revision.get("revid"), int)
        or not isinstance(revision.get("timestamp"), str)
        or not isinstance(revision.get("sha1"), str)
        or not isinstance(content, str)
        or slot.get("contentmodel") != "Scribunto"
    ):
        raise ResponseValidationError("Type relation revision metadata is invalid")
    if hashlib.sha1(content.encode("utf-8")).hexdigest() != revision["sha1"]:
        raise ResponseValidationError("Type relation source SHA-1 mismatch")
    return revision, content


def import_type_relations(
    config_path: Path,
    output_path: Path,
    *,
    transport: UrlTransport | None = None,
) -> Path:
    config = _read_json(config_path, "type relation configuration")
    if config.get("config_version") != 1:
        raise InputError("Type relation configuration version must be 1")
    policy = config.get("request_policy")
    type_order = config.get("type_order")
    relation_names = config.get("source_relation_names")
    reviewed_conflicts = config.get("reviewed_reciprocity_exceptions")
    if (
        not isinstance(policy, dict)
        or not isinstance(type_order, list)
        or not all(isinstance(item, str) and item for item in type_order)
        or len(type_order) != len(set(type_order))
        or not isinstance(relation_names, dict)
        or not all(
            isinstance(key, str) and isinstance(value, str)
            for key, value in relation_names.items()
        )
        or not isinstance(reviewed_conflicts, list)
        or not all(isinstance(item, str) for item in reviewed_conflicts)
        or len(reviewed_conflicts) != len(set(reviewed_conflicts))
    ):
        raise InputError("Type relation configuration is invalid")
    client = transport or UrlTransport(
        timeout_seconds=int(policy["timeout_seconds"]),
        max_retries=int(policy["max_retries"]),
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
    relations = parse_type_relations(
        content,
        source=config["source_title"],
        type_order=type_order,
        relation_names=relation_names,
        reviewed_conflicts=set(reviewed_conflicts),
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
            "source_url": (
                "https://wiki.biligame.com/rocom/index.php?title="
                f"Module%3ATypeRelation&oldid={revision['revid']}"
            ),
        },
        "type_order": type_order,
        "reviewed_reciprocity_exceptions": reviewed_conflicts,
        "relations": relations,
    }
    serialized = json.dumps(
        document, ensure_ascii=False, indent=2, sort_keys=True
    ) + "\n"
    if output_path.exists():
        try:
            existing = json.loads(output_path.read_text(encoding="utf-8"))
        except (OSError, UnicodeDecodeError, json.JSONDecodeError) as error:
            raise SnapshotWriteError(
                f"Existing type relation asset is invalid: {error}"
            ) from error
        comparable = dict(document)
        comparable.pop("imported_at_utc")
        existing_comparable = dict(existing)
        existing_comparable.pop("imported_at_utc", None)
        if existing_comparable != comparable:
            raise SnapshotWriteError("Existing type relation asset differs")
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
        raise SnapshotWriteError(f"Cannot freeze type relations: {error}") from error
    finally:
        temporary = Path(temporary_name)
        if temporary.exists():
            temporary.unlink()
    return output_path
