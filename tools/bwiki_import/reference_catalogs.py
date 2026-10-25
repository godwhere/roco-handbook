"""Frozen, data-only reference supplements; no runtime or upstream code execution."""

from __future__ import annotations

import base64
from collections import Counter, defaultdict
from datetime import datetime, timezone
import hashlib
from html.parser import HTMLParser
import json
import os
from pathlib import Path
import re
import shutil
import tempfile
import time
from typing import Any, Callable
from urllib.parse import urlencode
import zlib

from catalog_builder.lua_parser import LuaSyntaxError, parse_lua_table
from .errors import InputError, ResponseValidationError, SnapshotWriteError
from .image_assets import UrlTransport
from .models import FrozenSnapshot, SourceSpec
from .response_validator import validate_response
from .tool_catalogs import _lua_json

KINDS = ("items", "research", "medals", "trials", "habitats")
ENDPOINT = "https://wiki.biligame.com/nrc/api.php"
_ITEM = re.compile(r"item_[0-9a-f]{12}\Z")
_PET = re.compile(r"pet_[0-9]{6}\Z")
_PROGRESS = re.compile(r"pt_[0-9]{6}_[0-9]{6}\Z")
_TRIAL = re.compile(r"gt_[0-9a-f]{16}\Z")
_POINT = re.compile(r"p-[0-9a-f]{16}\Z")
_FILE = re.compile(r"[A-Za-z0-9_. -]+\.png\Z")


def _json(path: Path) -> dict[str, Any]:
    try:
        value = json.loads(path.read_bytes())
    except (OSError, ValueError, UnicodeError) as error:
        raise InputError(f"Cannot read reference JSON {path}: {error}") from error
    if not isinstance(value, dict):
        raise InputError(f"Reference JSON must be an object: {path}")
    return value


def _bytes(value: Any) -> bytes:
    return (json.dumps(value, ensure_ascii=False, sort_keys=True, indent=2) + "\n").encode()


def _strict_pairs(pairs: list[tuple[str, Any]]) -> dict[str, Any]:
    result = {}
    for key, value in pairs:
        if key in result:
            raise ValueError("Duplicate JSON object key")
        result[key] = value
    return result


def _write_new(path: Path, value: Any) -> None:
    payload = _bytes(value)
    if path.exists():
        if path.read_bytes() != payload:
            raise SnapshotWriteError(f"Immutable reference output differs: {path}")
        return
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("xb") as stream:
        stream.write(payload)


def reference_configuration(path: Path) -> dict[str, Any]:
    config = _json(path)
    sources = config.get("sources")
    if (config.get("config_version") != 1 or config.get("dataset_id") != "roco-world-zh-cn"
            or config.get("api_endpoint") != ENDPOINT or not isinstance(sources, list) or not sources):
        raise InputError("Invalid reference source configuration")
    keys, titles, pages = set(), set(), set()
    for source in sources:
        key, title, page = source.get("key"), source.get("title"), source.get("page_id")
        if (not isinstance(key, str) or not re.fullmatch(r"[a-z0-9_]+", key)
                or not isinstance(title, str) or not title.startswith(("Module:", "MediaWiki:"))
                or not isinstance(page, int) or isinstance(page, bool) or page <= 0
                or source.get("content_model") not in {"Scribunto", "javascript"}
                or key in keys or title in titles or page in pages):
            raise InputError("Invalid or duplicate reference source identity")
        keys.add(key); titles.add(title); pages.add(page)
    return config


def _source_spec(source: dict[str, Any]) -> SourceSpec:
    return SourceSpec(source["key"], source["title"], "required", (source["key"] + ".json",))


def _head_rows(document: dict[str, Any], expected: list[dict[str, Any]]) -> dict[str, int]:
    if document.get("batchcomplete") is not True or document.get("error") or "continue" in document:
        raise ResponseValidationError("Reference head response is incomplete")
    pages = document.get("query", {}).get("pages")
    if not isinstance(pages, list) or len(pages) != len(expected):
        raise ResponseValidationError("Reference head response has an unexpected page count")
    by_page = {source["page_id"]: source for source in expected}
    result = {}
    for page in pages:
        source = by_page.get(page.get("pageid"))
        revisions = page.get("revisions")
        if (source is None or "missing" in page or "invalid" in page
                or page.get("title", "").split(":", 1)[-1] != source["title"].split(":", 1)[-1]
                or not isinstance(revisions, list) or len(revisions) != 1):
            raise ResponseValidationError("Reference source head identity changed")
        revision = revisions[0].get("revid")
        if not isinstance(revision, int) or isinstance(revision, bool) or revision <= 0 or source["key"] in result:
            raise ResponseValidationError("Invalid or duplicate reference revision")
        result[source["key"]] = revision
    return result


def load_reference_snapshot(path: Path, config: dict[str, Any]) -> tuple[dict[str, Any], dict[str, str]]:
    lock = _json(path / "sources.lock.json")
    expected = {source["key"]: source for source in config["sources"] + config["frozen_inputs"]}
    records = lock.get("sources", [])
    if (lock.get("dataset_id") != config["dataset_id"] or not lock.get("revision_set_verified")
            or len(records) != len(expected) or {row.get("source_key") for row in records} != set(expected)):
        raise ResponseValidationError("Reference snapshot source set is incomplete")
    content = {}
    for record in records:
        source = expected[record["source_key"]]
        extension = ".lua" if source["content_model"] == "Scribunto" else ".js"
        if (record.get("response_file") != "responses/" + source["key"] + ".json"
                or record.get("content_file") != "content/" + source["key"] + extension):
            raise ResponseValidationError("Frozen reference member path is unsafe")
        response_path = path / record["response_file"]
        response = validate_response(response_path, _source_spec(source))
        if (response.page_id != source["page_id"] or response.content_model != source["content_model"]
                or not response.content.strip() or response.revision_id != record["revision_id"]
                or response.response_sha256 != record["response_sha256"]
                or response.content_sha256 != record["content_sha256"]
                or (source.get("revision_id") and response.revision_id != source["revision_id"])
                or (source.get("content_sha256") and response.content_sha256 != source["content_sha256"])
                or (path / record["content_file"]).read_text() != response.content):
            raise ResponseValidationError("Frozen reference source content or identity changed")
        content[source["title"]] = response.content
    return lock, content


def freeze_reference_sources(config_path: Path, output_root: Path, *,
        transport: UrlTransport | None = None, sleep: Callable[[float], None] = time.sleep,
        repository_root: Path = Path(".")) -> FrozenSnapshot:
    config = reference_configuration(config_path)
    policy = config["request_policy"]
    client = transport or UrlTransport(timeout_seconds=policy["timeout_seconds"], max_retries=policy["max_retries"])
    temporary = Path(tempfile.mkdtemp(prefix="roco-reference-import."))
    requests = 0

    def request(form: dict[str, str]) -> dict[str, Any]:
        nonlocal requests
        if requests:
            sleep(policy["minimum_interval_seconds"])
        requests += 1
        document = client.post_json(ENDPOINT, {"format": "json", "formatversion": "2", **form})
        if document.get("batchcomplete") is not True or document.get("error") or "continue" in document:
            raise ResponseValidationError("Reference API response is incomplete")
        return document

    def heads() -> dict[str, int]:
        result = {}
        size = policy["head_batch_size"]
        for offset in range(0, len(config["sources"]), size):
            batch = config["sources"][offset:offset + size]
            document = request({"action": "query", "prop": "revisions", "rvprop": "ids",
                                "titles": "|".join(source["title"] for source in batch)})
            result.update(_head_rows(document, batch))
        return result

    try:
        frozen_heads = heads()
        records = []
        (temporary / "responses").mkdir()
        (temporary / "content").mkdir()
        for source in config["sources"] + config["frozen_inputs"]:
            response_path = temporary / "responses" / (source["key"] + ".json")
            if source in config["sources"]:
                document = request({"action": "query", "prop": "revisions",
                    "rvprop": "ids|timestamp|sha1|size|content", "rvslots": "main",
                    "revids": str(frozen_heads[source["key"]])})
                response_path.write_bytes(_bytes(document))
            else:
                original = repository_root / source["snapshot"] / source["response_file"]
                response_path.write_bytes(original.read_bytes())
            response = validate_response(response_path, _source_spec(source))
            revision = frozen_heads.get(source["key"], source.get("revision_id"))
            if (response.page_id != source["page_id"] or response.revision_id != revision
                    or response.content_model != source["content_model"] or not response.content.strip()
                    or response.content_bytes > policy["max_source_bytes"]
                    or (source.get("content_sha256") and response.content_sha256 != source["content_sha256"])):
                raise ResponseValidationError(f"Reference body identity/hash/size mismatch: {source['title']}")
            extension = ".lua" if source["content_model"] == "Scribunto" else ".js"
            content_file = "content/" + source["key"] + extension
            (temporary / content_file).write_text(response.content)
            records.append({**response.lock_record(), "content_file": content_file})
        if heads() != frozen_heads:
            raise ResponseValidationError("Reference heads changed during import; no snapshot frozen")
        fingerprint = hashlib.sha256(_bytes([{key: row[key] for key in
            ("requested_title", "page_id", "revision_id", "content_sha256")} for row in records])).hexdigest()[:16]
        snapshot_id = "references-" + fingerprint
        lock = {"lock_version": 1, "dataset_id": config["dataset_id"], "snapshot_id": snapshot_id,
                "api_endpoint": ENDPOINT, "revision_set_verified": True,
                "imported_at_utc": datetime.now(timezone.utc).isoformat().replace("+00:00", "Z"),
                "sources": records}
        (temporary / "sources.lock.json").write_bytes(_bytes(lock))
        output_root.mkdir(parents=True, exist_ok=True)
        target = output_root / snapshot_id
        reused = target.exists()
        if reused:
            existing, _ = load_reference_snapshot(target, config)
            if [{k: row[k] for k in ("requested_title", "page_id", "revision_id", "content_sha256")}
                    for row in existing["sources"]] != [{k: row[k] for k in
                    ("requested_title", "page_id", "revision_id", "content_sha256")} for row in records]:
                raise SnapshotWriteError("Existing reference snapshot differs")
        else:
            shutil.move(str(temporary), str(target))
        return FrozenSnapshot(snapshot_id, target, target / "sources.lock.json",
                              tuple(row["source_key"] for row in records), reused)
    finally:
        if temporary.exists():
            shutil.rmtree(temporary)


def parse_data_table(content: str, source: str) -> dict[str, Any]:
    try:
        value = _lua_json(parse_lua_table(content, source=source).value)
    except LuaSyntaxError as error:
        raise ResponseValidationError(str(error)) from error
    if not isinstance(value, dict) or not value:
        raise ResponseValidationError(f"Expected a nonempty data table: {source}")
    return value


def decode_map_part(content: str, title: str, *, max_bytes: int) -> Any:
    prefix = "window.NrcWorldMap.receive("
    text = content.strip()
    if not text.startswith(prefix):
        raise ResponseValidationError("Unsupported map wrapper prefix")
    decoder = json.JSONDecoder(object_pairs_hook=_strict_pairs)
    try:
        position = len(prefix)
        actual_title, length = decoder.raw_decode(text[position:]); position += length
        if text[position:position + 1] != ",":
            raise ValueError("Expected exactly two JSON arguments")
        position += 1
        payload, length = decoder.raw_decode(text[position:]); position += length
        if actual_title != title or text[position:] != ");" or not isinstance(payload, str) or not payload.startswith("gz1:"):
            raise ValueError("Map wrapper title, suffix or encoding differs")
        compressed = base64.b64decode(payload[4:], validate=True)
        inflater = zlib.decompressobj(wbits=31)
        raw = inflater.decompress(compressed, max_bytes + 1)
        if len(raw) > max_bytes or not inflater.eof or inflater.unused_data or inflater.unconsumed_tail:
            raise ValueError("Map gzip payload exceeds limit or has trailing/incomplete data")
        return json.loads(raw.decode("utf-8"), object_pairs_hook=_strict_pairs,
                          parse_constant=lambda value: (_ for _ in ()).throw(ValueError("Nonfinite JSON value")))
    except (ValueError, UnicodeError, zlib.error, IndexError) as error:
        raise ResponseValidationError(f"Unsupported map data wrapper: {title}: {error}") from error


def map_configuration(content: str) -> dict[str, Any]:
    marker = "  const config = "
    position = content.find(marker, 0, 512)
    if position < 0:
        raise ResponseValidationError("Map loader must start with its literal configuration")
    start = position + len(marker)
    try:
        value, length = json.JSONDecoder(object_pairs_hook=_strict_pairs).raw_decode(content[start:])
    except ValueError as error:
        raise ResponseValidationError("Map loader configuration is not literal JSON") from error
    if not isinstance(value, dict) or content[start + length:start + length + 1] != ";":
        raise ResponseValidationError("Map loader configuration suffix changed")
    return value


class TrialMarkupParser(HTMLParser):
    """Read explicit card/section attributes and text from generated source markup."""

    def __init__(self) -> None:
        super().__init__(convert_charrefs=True)
        self.stack: list[dict[str, Any]] = []
        self.cards: list[dict[str, Any]] = []
        self.groups: dict[str, dict[str, Any]] = {}
        self.declared_total: int | None = None

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        attributes = dict(attrs)
        frame = {"tag": tag, "attrs": attributes, "text": []}
        if "data-encounter-total" in attributes:
            self.declared_total = int(attributes["data-encounter-total"] or "-1")
        classes = (attributes.get("class") or "").split()
        if "grass-trial-pool" in classes:
            key = attributes.get("id")
            if not key or key in self.groups:
                raise ResponseValidationError("Trial section identity is missing or duplicated")
            self.groups[key] = {"id": key, "title": "", "attributes": attributes}
            frame["group"] = key
        if "data-encounter-id" in attributes:
            group = next((parent["group"] for parent in reversed(self.stack) if "group" in parent), None)
            if not group or not _TRIAL.fullmatch(attributes["data-encounter-id"] or ""):
                raise ResponseValidationError("Trial card has no valid section or encounter ID")
            frame["card"] = {"attributes": attributes, "group_id": group}
        self.stack.append(frame)

    def handle_data(self, data: str) -> None:
        for frame in self.stack:
            frame["text"].append(data)

    def handle_endtag(self, tag: str) -> None:
        if not self.stack or self.stack[-1]["tag"] != tag:
            raise ResponseValidationError("Trial source markup is unbalanced")
        frame = self.stack.pop()
        text = "".join(frame["text"])
        if "grass-trial-section-title" in (frame["attrs"].get("class") or "").split():
            group = next((parent["group"] for parent in reversed(self.stack) if "group" in parent), None)
            if group:
                self.groups[group]["title"] = text.strip()
        if "grass-trial-eyebrow" in (frame["attrs"].get("class") or "").split():
            group = next((parent["group"] for parent in reversed(self.stack) if "group" in parent), None)
            if group:
                self.groups[group]["floor_context"] = text.strip()
        if "card" in frame:
            self.cards.append({**frame["card"], "text": text})


def parse_trial_markup(content: str, *, expected_count: int) -> tuple[list[dict[str, Any]], list[dict[str, Any]]]:
    raw = parse_data_table(content, "Module:GrassTracker/Markup")
    if not isinstance(raw.get("body"), str):
        raise ResponseValidationError("Trial markup requires a literal body string")
    parser = TrialMarkupParser()
    parser.feed(raw["body"]); parser.close()
    ids = [card["attributes"]["data-encounter-id"] for card in parser.cards]
    if parser.stack or len(ids) != expected_count or len(set(ids)) != len(ids) or parser.declared_total != expected_count:
        raise ResponseValidationError("Trial source count, unique IDs or markup closure differs")
    groups = [group for group in parser.groups.values() if any(card["group_id"] == group["id"] for card in parser.cards)]
    if any(not group["title"] for group in groups):
        raise ResponseValidationError("Trial section title is missing")
    return groups, parser.cards


def _text(value: Any, label: str) -> str:
    if not isinstance(value, str) or not value.strip() or "\x00" in value:
        raise ResponseValidationError(f"Missing or invalid reference text: {label}")
    return value


def _lines(*values: Any) -> list[str]:
    result = []
    for value in values:
        if value is None or value == "":
            continue
        if isinstance(value, list):
            result.extend(_lines(*value))
        elif isinstance(value, str):
            result.extend(line.strip() for line in value.splitlines() if line.strip())
        elif isinstance(value, (int, float)):
            result.append(str(value))
    return result


def _section(title: str, *values: Any) -> dict[str, Any] | None:
    lines = _lines(*values)
    return {"title": title, "lines": lines} if lines else None


def _unique_links(links: list[dict[str, str] | None]) -> list[dict[str, str]]:
    seen = set()
    result = []
    for link in links:
        if link is not None and (link["kind"], link["id"]) not in seen:
            seen.add((link["kind"], link["id"])); result.append(link)
    return result


def _card(identifier: str, name: str, group: str, *, raw: Any,
          sections: list[dict[str, Any] | None] | None = None,
          links: list[dict[str, str] | None] | None = None, **optional: Any) -> dict[str, Any]:
    result = {"id": identifier, "name": _text(name, identifier), "group_id": group,
              "visible": True, "sections": [section for section in sections or [] if section],
              "links": _unique_links(links or []), "raw": raw}
    result.update({key: value for key, value in optional.items() if value is not None})
    return result


class ReferenceIdentityReview:
    def __init__(self, normalized: dict[str, Any], index: dict[str, Any],
                 asset_root: Path, review: dict[str, Any]) -> None:
        self.pets = {pet["pet_id"]: pet for pet in normalized["pets"]}
        self.by_title: dict[str, set[str]] = defaultdict(set)
        self.by_avatar: dict[str, set[str]] = defaultdict(set)
        self.images = {}
        self.type_images = {}
        self.results: list[dict[str, Any]] = []
        self.review = review
        for pet_id, title in index["titles"].items():
            if pet_id not in self.pets or self.pets[pet_id]["title"] != title:
                raise ResponseValidationError("Frozen Pets Index differs from accepted normalized identity")
            self.by_title[title].add(pet_id)
        for pet_id, avatar in index.get("avatars", {}).items():
            if pet_id not in self.pets or not isinstance(avatar, str):
                raise ResponseValidationError("Invalid explicit frozen avatar reference")
            self.by_avatar[avatar].add(pet_id)
        manifest = _json(asset_root / "v4/asset-manifest.json")
        for row in manifest["assets"]:
            for name, decoration in review.get("type_icons", {}).items():
                if row["asset_id"] == decoration["asset_id"]:
                    path = asset_root / "v4" / row["local_path"]
                    if (decoration["image_path"] != "wiki/v4/" + row["local_path"]
                            or decoration["source_title"] != row["source_title"]
                            or hashlib.sha256(path.read_bytes()).hexdigest() != row["local_sha256"]):
                        raise ResponseValidationError("Reviewed type decoration changed")
                    self.type_images[name] = decoration["image_path"]
            if row["kind"] != "pet_illustration":
                continue
            path = asset_root / "v4" / row["local_path"]
            if hashlib.sha256(path.read_bytes()).hexdigest() != row["local_sha256"]:
                raise ResponseValidationError("Previously approved creature asset changed")
            for pet_id in row["catalog_ids"]:
                if pet_id in self.images:
                    raise ResponseValidationError("Creature has multiple primary staged illustration mappings")
                self.images[pet_id] = "wiki/v4/" + row["local_path"]

    def _result(self, owner: str, reference: Any, candidates: set[str], method: str) -> dict[str, str] | None:
        if len(candidates) == 1:
            pet_id = next(iter(candidates)); pet = self.pets[pet_id]
            self.results.append({"owner": owner, "reference": reference, "status": "mapped",
                                 "method": method, "pet_id": pet_id, "title": pet["title"]})
            return {"kind": "pet", "id": pet_id, "name": pet["title"]}
        self.results.append({"owner": owner, "reference": reference,
                             "status": "ambiguous" if candidates else "unmapped",
                             "method": method, "candidates": sorted(candidates)})
        return None

    def title(self, owner: str, title: str) -> dict[str, str] | None:
        return self._result(owner, {"title": title}, self.by_title.get(title, set()), "exact_frozen_index_title")

    def explicit_pet(self, owner: str, pet: dict[str, Any]) -> dict[str, str] | None:
        pet_id = pet.get("id"); candidate = self.pets.get(pet_id, {})
        matches = (candidate.get("name") == pet.get("name")
                   and candidate.get("extra_json", {}).get("game_id") == pet.get("source_id"))
        return self._result(owner, pet, {pet_id} if matches else set(), "explicit_pet_id_name_and_game_id")

    def habitat(self, owner: str, pet: dict[str, Any], assets: dict[str, str]) -> dict[str, str] | None:
        filename = assets.get(pet.get("icon"))
        candidates = set(self.by_avatar.get(filename, set()))
        valid = set()
        for pet_id in candidates:
            accepted = self.pets[pet_id]
            source_form = pet.get("form")
            reviewed_form = self.review.get("source_form_display_labels", {}).get(source_form, source_form)
            if (accepted["name"] == pet.get("name") and accepted.get("form") == reviewed_form
                    and accepted.get("description") == pet.get("description")):
                valid.add(pet_id)
        reference = {**pet, "source_avatar_filename": filename, "avatar_candidates": sorted(candidates)}
        # A shared avatar never selects a preferred or default form.
        if len(candidates) != 1:
            return self._result(owner, reference, candidates, "exact_avatar_is_ambiguous_or_absent")
        return self._result(owner, reference, valid, "exact_avatar_title_name_form_description")


def _icon_path(record: dict[str, Any], unavailable: set[str]) -> str | None:
    icon = record.get("icon")
    if icon is None or record.get("icon_available", True) is False or icon in unavailable:
        return None
    if not isinstance(icon, str) or not _FILE.fullmatch(icon) or ".." in icon:
        raise ResponseValidationError("Reference icon filename is unsafe")
    return "wiki/references/v1/icons/" + icon


def _source_rows(lock: dict[str, Any], titles: set[str]) -> list[dict[str, Any]]:
    rows = []
    for row in lock["sources"]:
        title = row["requested_title"]
        if title in titles:
            rows.append({"title": title, "page_id": row["page_id"], "revision_id": row["revision_id"],
                "revised_at_utc": row["revised_at_utc"], "sha1": row["content_sha1"],
                "sha256": row["content_sha256"],
                "url": "https://wiki.biligame.com/nrc/index.php?" + urlencode({"title": title, "oldid": row["revision_id"]})})
    if len(rows) != len(titles):
        raise ResponseValidationError("Presentation source set does not close")
    return rows


def _numeric_mapping(value: Any) -> dict[int, Any]:
    if not isinstance(value, dict) or set(value) != {"lua_entries"}:
        raise ResponseValidationError("Expected a preserved numeric-key source table")
    result = {}
    for row in value["lua_entries"]:
        key = row.get("key")
        if not isinstance(key, int) or isinstance(key, bool) or key in result:
            raise ResponseValidationError("Invalid duplicate numeric source table key")
        result[key] = row["value"]
    return result


def medal_progress_targets(record: dict[str, Any]) -> list[str]:
    targets = [str(task.get("condition_label") or record["name"]) + " · " + str(task["count"])
               for task in record.get("tasks", [])
               if not task.get("deprecated") and task.get("count") is not None]
    targets.extend(str(tier.get("label") or tier.get("rank")) + " · " + str(tier["progress_target"])
                   for tier in record.get("upgrade_tiers", []) if tier.get("progress_target") is not None)
    return targets


def _build_habitats(content: dict[str, str], lock: dict[str, Any], config: dict[str, Any],
                    identities: ReferenceIdentityReview) -> tuple[dict[str, Any], dict[str, Any], dict[str, Any]]:
    loader = content["MediaWiki:WorldMap.js"]
    data = map_configuration(loader)
    titles = [title for group in data.get("data", {}).values() for title in group]
    allowed = {title for title in content if title.startswith("MediaWiki:WorldMap/data/")}
    if (len(titles) != config["expected_counts"]["map_parts"] or len(set(titles)) != len(titles)
            or set(titles) != allowed or set(data.get("dataVersions", {})) != allowed):
        raise ResponseValidationError("Map source-page allowlist/version closure failed")
    maximum = config["request_policy"]["max_decoded_part_bytes"]
    parts = {title: decode_map_part(content[title], title, max_bytes=maximum) for title in titles}
    if sum(len(_bytes(value)) for value in parts.values()) > config["request_policy"]["max_decoded_total_bytes"]:
        raise ResponseValidationError("Decoded map source exceeds total size limit")
    notes = identities.review["location_notes"]
    if any(note not in loader for note in notes.values()):
        raise ResponseValidationError("Reviewed source map location note changed")
    scenes = {}; groups = {}; entries = []; point_ids = set(); statistics = {}
    for scene in ("mainland", "academy"):
        core_path = "/map-data/" + scene + "/map-core.json"
        points_path = "/map-data/" + scene + "/map-points.json"
        if core_path not in data["data"] or points_path not in data["data"]:
            raise ResponseValidationError("Map logical dataset is missing")
        core_parts = [parts[title] for title in data["data"][core_path]]
        if not core_parts or not isinstance(core_parts[0], dict):
            raise ResponseValidationError("Map core source shape differs")
        core = core_parts[0]; details = {}
        for part in core_parts[1:]:
            if not isinstance(part, dict) or set(part).intersection(details):
                raise ResponseValidationError("Map detail shard IDs overlap")
            details.update(part)
        points = []
        for title in data["data"][points_path]:
            if not isinstance(parts[title], list):
                raise ResponseValidationError("Map point shard must be an array")
            points.extend(parts[title])
        current_ids = [point.get("id") for point in points]
        if (not current_ids or any(not isinstance(key, str) or not _POINT.fullmatch(key) for key in current_ids)
                or len(set(current_ids)) != len(current_ids) or set(current_ids) != set(details)
                or point_ids.intersection(current_ids)):
            raise ResponseValidationError("Map point/detail identity closure failed")
        point_ids.update(current_ids)
        layers = {layer["id"]: layer for layer in core.get("spatialLayers", [])}
        if len(layers) != len(core.get("spatialLayers", [])):
            raise ResponseValidationError("Map spatial layer IDs overlap")
        scenes[scene] = {"core": core, "details": details, "points": points}
        habitat_count = creature_count = 0
        for point in points:
            detail = details[point["id"]]
            habitat = detail.get("habitat")
            if habitat is None:
                continue
            if not isinstance(habitat, dict) or not isinstance(habitat.get("pets"), list):
                raise ResponseValidationError("Map habitat creature records are malformed")
            layer = layers.get(point.get("mapLayerId"))
            if layer is None or not isinstance(point.get("estimatedRegion"), bool):
                raise ResponseValidationError("Habitat layer or estimated-region evidence is missing")
            region = _text(point.get("largeRegion"), "habitat group")
            groups.setdefault(region, {"id": region, "title": region})
            creatures = []; links = []
            for pet in habitat["pets"]:
                name = _text(pet.get("name"), "habitat creature")
                form = pet.get("form")
                type_names = [value["name"] for value in pet.get("types", [])]
                line = name + (" · " + form if form else "")
                if type_names:
                    line += " · " + " / ".join(type_names)
                creatures.append(line)
                links.append(identities.habitat("habitats:" + point["id"], pet, data["assets"]))
            canonical_links = _unique_links(links)
            layer_name = layer.get("name") or layer.get("groupName") or layer["id"]
            type_names = [value["name"] for value in habitat.get("commonTypes", [])]
            decoration_type = next((name for name in type_names if name in identities.type_images), None)
            image = identities.images.get(canonical_links[0]["id"]) if canonical_links else identities.type_images.get(decoration_type)
            entry = _card(point["id"], point["name"], region,
                raw={"point": point, "detail": detail, "spatial_layer": layer,
                     "type_decoration": decoration_type if not canonical_links else None},
                sections=[_section("Habitat", habitat.get("belongCampName"),
                    " / ".join(value["name"] for value in habitat.get("commonTypes", []))),
                    _section("Creatures", creatures),
                    _section("Location notes", notes["area"], notes["estimated"] if point["estimatedRegion"] else None, layer_name)],
                links=canonical_links, subtitle=point.get("region"), image_path=image)
            entries.append(entry); habitat_count += 1; creature_count += len(habitat["pets"])
        statistics[scene] = {"points": len(points), "details": len(details), "habitat_areas": habitat_count, "creature_records": creature_count}
    if not entries:
        raise ResponseValidationError("Complete map source contains no habitat presentation")
    statistics.update({"entries": len(entries), "groups": len(groups),
                       "creature_records": sum(row["creature_records"] for row in statistics.values()),
                       "source_parts": len(parts), "map_media_downloaded": 0})
    return _document("habitats", lock, set(titles) | {"MediaWiki:WorldMap.js"}, list(groups.values()), entries), statistics, scenes


def _document(kind: str, lock: dict[str, Any], titles: set[str], groups: list[dict[str, Any]],
              entries: list[dict[str, Any]]) -> dict[str, Any]:
    if not groups or not entries or len({row["id"] for row in entries}) != len(entries):
        raise ResponseValidationError(f"Empty or duplicate reference presentation: {kind}")
    group_ids = {group["id"] for group in groups}
    if len(group_ids) != len(groups) or any(row["group_id"] not in group_ids for row in entries):
        raise ResponseValidationError(f"Reference group membership does not close: {kind}")
    for group in groups:
        image = next((row.get("image_path") for row in entries if row["group_id"] == group["id"] and row.get("image_path")), None)
        if image:
            group["image_path"] = image
    result = {"contract_version": 1, "dataset_id": lock["dataset_id"], "snapshot_id": lock["snapshot_id"],
              "kind": kind, "sources": _source_rows(lock, titles), "groups": groups, "entries": entries}
    if len(_bytes(result)) > 8 * 1024 * 1024:
        raise ResponseValidationError(f"Reference presentation exceeds native 8 MiB limit: {kind}")
    return result


def _build_reference_documents(snapshot: Path, config_path: Path, identity_path: Path, *,
        repository_root: Path = Path("."), unavailable_icons: set[str] | None = None
        ) -> tuple[dict[str, dict[str, Any]], dict[str, Any], dict[str, Any]]:
    config = reference_configuration(config_path)
    lock, content = load_reference_snapshot(snapshot, config)
    normalized_path = repository_root / config["normalized_catalog"]["path"]
    if hashlib.sha256(normalized_path.read_bytes()).hexdigest() != config["normalized_catalog"]["sha256"]:
        raise ResponseValidationError("Accepted normalized V3 identity artifact changed")
    normalized = _json(normalized_path)
    index = parse_data_table(content["Module:Pets/data/Index"], "Pets Index")
    identities = ReferenceIdentityReview(normalized, index, repository_root / "app/assets/wiki", _json(identity_path))
    unavailable = unavailable_icons or set()
    expected = config["expected_counts"]
    docs = {}; report = {"snapshot_id": lock["snapshot_id"], "counts": {}, "item_references": []}
    raw_sidecar: dict[str, Any] = {"snapshot_id": lock["snapshot_id"],
                                 "source_lock": "data/raw/" + lock["snapshot_id"] + "/sources.lock.json"}
    item_index = parse_data_table(content["Module:Items/data/Index"], "Items Index")
    catalog = parse_data_table(content["Module:Items/data/Catalog"], "Items Catalog")
    order = item_index.get("order", [])
    if (len(order) != expected["items"] or len(set(order)) != len(order) or set(order) != set(catalog)
            or set(item_index.get("shard_by_id", {})) != set(order) or set(item_index.get("titles", {})) != set(order)):
        raise ResponseValidationError("Items Index/Catalog identity closure failed")
    shard_names = set(item_index["shard_by_id"].values())
    declared = {title.removeprefix("Module:Items/data/Details/") for title in content if title.startswith("Module:Items/data/Details/")}
    if shard_names != declared or len(shard_names) != expected["item_detail_shards"]:
        raise ResponseValidationError("Items Details allowlist does not match the complete Index shard set")
    details = {}
    for shard in sorted(shard_names):
        title = "Module:Items/data/Details/" + shard
        records = parse_data_table(content[title], title)
        for key, row in records.items():
            if key in details or item_index["shard_by_id"].get(key) != shard or row.get("id") != key:
                raise ResponseValidationError("Item detail ID/shard membership conflict")
            details[key] = row
    if set(details) != set(order) or dict(Counter(row.get("group") for row in catalog.values())) != item_index["counts"]:
        raise ResponseValidationError("Item detail/reference/count closure failed")
    by_item_title: dict[str, set[str]] = defaultdict(set)
    by_reward: dict[tuple[str, str], set[str]] = defaultdict(set)
    for key in order:
        row = catalog[key]
        if not _ITEM.fullmatch(key) or row.get("id") != key or row.get("page_title") != item_index["titles"][key] or details[key].get("page_title") != row["page_title"]:
            raise ResponseValidationError("Explicit item identity or title changed")
        by_item_title[row["page_title"]].add(key)
        for variant in details[key].get("variants", []):
            by_reward[(variant.get("name", ""), variant.get("icon", ""))].add(key)
        by_reward[(row["name"], row.get("icon", ""))].add(key)

    def item_link(owner: str, reference: Any, candidates: set[str], method: str) -> dict[str, str] | None:
        report["item_references"].append({"owner": owner, "reference": reference, "method": method,
            "status": "mapped" if len(candidates) == 1 else "ambiguous" if candidates else "unmapped",
            "candidates": sorted(candidates)})
        if len(candidates) == 1:
            key = next(iter(candidates)); return {"kind": "item", "id": key, "name": catalog[key]["name"]}
        return None

    item_entries = []
    review = identities.review
    for key in order:
        row, detail = catalog[key], details[key]
        variants = detail.get("variants")
        if not isinstance(variants, list) or not variants:
            raise ResponseValidationError("Item variants are absent")
        sections = []; links = []
        for position, variant in enumerate(variants, 1):
            if not isinstance(variant.get("acquire"), list) or not isinstance(variant.get("related"), list):
                raise ResponseValidationError("Item acquisition/related variant lists are malformed")
            relations = []
            for reference in variant["related"]:
                title, label = reference.get("title"), reference.get("label")
                relations.append(str(label) + ": " + str(reference.get("name", title)))
                if label in review["pet_related_labels"]:
                    links.append(identities.title("items:" + key, _text(title, "item pet relation")))
                elif label in review["item_related_labels"]:
                    links.append(item_link("items:" + key, reference, by_item_title.get(title, set()), "exact_item_page_title"))
                else:
                    report["item_references"].append({"owner": "items:" + key, "reference": reference,
                        "status": "non_native_target_kind", "method": "reviewed_source_relation_label"})
            sections.append(_section("Variant", f"{position} / {len(variants)} · {variant.get('name', row['name'])}",
                variant.get("description"), variant.get("skill_description"), variant.get("flavor"), variant["acquire"], relations))
        item_entries.append(_card(key, row["name"], row["group"], raw={"catalog": row, "detail": detail},
            sections=sections, links=links, subtitle=row["category"], description=row.get("description"),
            image_path=_icon_path(row, unavailable)))
    groups = [{"id": key, "title": value} for key, value in item_index["groups"].items()]
    docs["items"] = _document("items", lock, {title for title in content if title.startswith("Module:Items/data/")}, groups, item_entries)
    report["counts"]["items"] = {"entries": len(item_entries), "groups": len(groups), "variants": sum(len(row["variants"]) for row in details.values())}

    books = parse_data_table(content["Module:Pets/data/Handbooks"], "Handbooks")
    defaults = {row["handbook_id"]: row["default_pet_id"] for row in normalized["handbook_display"]}
    research = []; groups = []
    for book_id, pet_id in defaults.items():
        book = books[book_id]; groups.append({"id": book_id, "title": book["entry_name"]})
        for topic in book.get("topics", []):
            progress_id = topic.get("progress_id")
            if not isinstance(progress_id, str) or not _PROGRESS.fullmatch(progress_id):
                raise ResponseValidationError("Research task has no explicit progress ID")
            rewards = []; links = [{"kind": "pet", "id": pet_id, "name": identities.pets[pet_id]["title"]}]
            for reward in topic.get("rewards", []):
                rewards.append(f"{reward.get('count')} × {reward.get('name')}")
                links.append(item_link("research:" + progress_id, reward,
                    by_reward.get((reward.get("name", ""), reward.get("icon", "")), set()), "exact_reward_name_and_icon"))
            research.append(_card(progress_id, topic["text"], book_id, raw={"handbook_id": book_id, "topic": topic},
                sections=[_section("Rewards", rewards)], links=links, subtitle=book["entry_name"],
                handbook_id=book_id, progress_id=progress_id, image_path=identities.images.get(pet_id)))
    if len(books) != expected["handbooks"] or len(research) != expected["research"]:
        raise ResponseValidationError("Research source count differs")
    docs["research"] = _document("research", lock, {"Module:Pets/data/Handbooks", "Module:Pets/data/Index"}, groups, research)
    report["counts"]["research"] = {"entries": len(research), "handbooks": len(groups), "rewards": sum(len(row["raw"]["topic"].get("rewards", [])) for row in research)}

    medal_catalog = parse_data_table(content["Module:Medals/data/Catalog"], "Medals Catalog")
    medal_index = parse_data_table(content["Module:Medals/data/Index"], "Medals Index")
    medal_config = parse_data_table(content["Module:Medals/data/Config"], "Medals Config")
    medal_order = medal_index.get("order", [])
    if len(medal_order) != expected["medals"] or len(set(medal_order)) != len(medal_order) or set(medal_order) != set(medal_catalog):
        raise ResponseValidationError("Medal Index/Catalog identity closure failed")
    medals = []
    for key in medal_order:
        row = medal_catalog[key]
        if row.get("id") != key or not re.fullmatch(r"medal_[0-9]+", key) or row.get("page_title") != medal_index["titles"][key]:
            raise ResponseValidationError("Medal identity/title conflict")
        visible = row.get("evidence_status") in config["public_medal_statuses"]
        active = [task.get("description") for task in row.get("tasks", []) if not task.get("deprecated")]
        old = [task.get("description") for task in row.get("tasks", []) if task.get("deprecated")]
        targets = medal_progress_targets(row)
        upgrades = []
        for tier in row.get("upgrade_tiers", []):
            upgrades.append(str(tier.get("label") or tier.get("rank")) + " · " + str(tier.get("description") or ""))
        links = []; bonds = []; species = []
        for bond in row.get("bonds", []):
            for pet in bond.get("pets", []):
                (species if bond.get("species_range") is True else bonds).append(pet.get("name"))
                links.append(identities.explicit_pet("medals:" + key, pet))
        entry = _card(key, row["name"], str(row["type"]), raw=row,
            sections=[_section("Acquisition", active), _section("Deprecated conditions", old),
                      _section("Bonds", bonds), _section("Species range", species), _section("Upgrades", upgrades),
                      _section("Progress targets", targets), _section("Prefix", row.get("prefix_text"), row.get("flavor_text"))],
            links=links, subtitle=row["quality_label"], description=row.get("description"),
            image_path=_icon_path(row, unavailable) if visible else None)
        entry["visible"] = visible; medals.append(entry)
    if sum(row["visible"] for row in medals) != expected["visible_medals"]:
        raise ResponseValidationError("Reviewed public medal status count changed")
    groups = [{"id": str(key), "title": value} for key, value in _numeric_mapping(medal_config["types"]).items()]
    docs["medals"] = _document("medals", lock, {"Module:Medals/data/" + part for part in ("Catalog", "Index", "Config")}, groups, medals)
    report["counts"]["medals"] = {"entries": len(medals), "visible": sum(row["visible"] for row in medals),
        "statuses": dict(Counter(row["raw"].get("evidence_status") for row in medals))}

    source_groups, cards = parse_trial_markup(content["Module:GrassTracker/Markup"], expected_count=expected["trials"])
    group_metadata = {group["id"]: group for group in source_groups}
    trials = []
    for card in cards:
        attrs = card["attributes"]; key = attrs["data-encounter-id"]
        titles = [match.group(1).split("|", 1)[0] for match in re.finditer(r"\[\[([^\]\n]+)\]\]", card["text"])
                  if not match.group(1).startswith(("File:", "\u6587\u4ef6:"))]
        if len(titles) != 1:
            raise ResponseValidationError("Trial card must have one explicit creature Wiki target")
        link = identities.title("trials:" + key, titles[0])
        trials.append(_card(key, attrs["data-encounter-name"], card["group_id"],
            raw={**card, "section": group_metadata[card["group_id"]]},
            sections=[_section("Encounter details", group_metadata[card["group_id"]].get("floor_context"),
                              attrs.get("data-species-name"), attrs.get("data-form-name"), attrs.get("data-encounter-types"))],
            links=[link], subtitle=attrs.get("data-form-name"), progress_id=key,
            image_path=identities.images.get(link["id"]) if link else None))
    docs["trials"] = _document("trials", lock, {"Module:GrassTracker/Markup"},
        [{"id": group["id"], "title": group["title"]} for group in source_groups], trials)
    report["counts"]["trials"] = {"entries": len(trials), "groups": len(source_groups)}
    raw_sidecar["trial_groups"] = source_groups
    docs["habitats"], map_report, raw_sidecar["map"] = _build_habitats(content, lock, config, identities)
    report["counts"]["habitats"] = map_report
    report["pet_references"] = identities.results
    report["reference_status_counts"] = {
        "pets": dict(Counter(row["status"] for row in identities.results)),
        "items": dict(Counter(row["status"] for row in report["item_references"]))}
    report["catalog_bytes"] = {kind: len(_bytes(document)) for kind, document in docs.items()}
    return docs, report, raw_sidecar


def build_reference_documents(snapshot: Path, config_path: Path, identity_path: Path, *,
        repository_root: Path = Path("."), unavailable_icons: set[str] | None = None
        ) -> tuple[dict[str, dict[str, Any]], dict[str, Any], dict[str, Any]]:
    try:
        return _build_reference_documents(snapshot, config_path, identity_path,
            repository_root=repository_root, unavailable_icons=unavailable_icons)
    except (KeyError, TypeError, ValueError, IndexError) as error:
        raise ResponseValidationError(f"Reference source field/shape is invalid: {error}") from error


def validate_reference_links(documents: dict[str, dict[str, Any]], normalized: dict[str, Any]) -> None:
    pet_ids = {row["pet_id"] for row in normalized["pets"]}
    item_ids = {row["id"] for row in documents["items"]["entries"]}
    for kind, document in documents.items():
        for entry in document["entries"]:
            if any(link["id"] not in (pet_ids if link["kind"] == "pet" else item_ids)
                   or link["kind"] not in {"pet", "item"} for link in entry["links"]):
                raise ResponseValidationError(f"Reference native link does not close: {kind}:{entry['id']}")
            if kind == "research" and (entry.get("progress_id") != entry["id"] or entry.get("handbook_id") != entry["group_id"]):
                raise ResponseValidationError("Research checklist membership is invalid")
            if kind == "trials" and entry.get("progress_id") != entry["id"]:
                raise ResponseValidationError("Trial checklist membership is invalid")


def publish_reference_catalogs(snapshot: Path, config_path: Path, identity_path: Path,
        output_path: Path, normalized_root: Path, reports_root: Path, media_root: Path,
        media_report_path: Path, *, repository_root: Path = Path(".")) -> dict[str, Any]:
    """Validate complete inputs, then assemble a new data/media-only immutable bundle."""
    config = reference_configuration(config_path)
    media_report = _json(media_report_path)
    declaration_path = normalized_root / "declared-media.json"
    declaration = _json(declaration_path)
    if (media_report.get("declaration_sha256") != hashlib.sha256(declaration_path.read_bytes()).hexdigest()
            or media_report.get("requested_count") != len(declaration["assets"])):
        raise ResponseValidationError("Reference media report does not match its declaration")
    unavailable_rows = media_report.get("unavailable", [])
    unavailable = {row["source_title"].removeprefix("File:") for row in unavailable_rows}
    docs, report, raw_sidecar = build_reference_documents(snapshot, config_path, identity_path,
        repository_root=repository_root, unavailable_icons=unavailable)
    normalized = _json(repository_root / config["normalized_catalog"]["path"])
    validate_reference_links(docs, normalized)
    manifest = _json(media_root / "asset-manifest.json")
    assets = manifest.get("assets", [])
    present = {"wiki/references/v1/" + row["local_path"]: row for row in assets}
    if len(present) != len(assets) or len(assets) != media_report.get("available_count"):
        raise ResponseValidationError("Reference media manifest/count differs")
    declared = {row["source_title"]: row for row in declaration["assets"]}
    if {row["source_title"] for row in assets} | {row["source_title"] for row in unavailable_rows} != set(declared):
        raise ResponseValidationError("Reference media availability does not close its declaration")
    for row in assets:
        path = media_root / row["local_path"]
        if (not row["local_path"].startswith("icons/") or ".." in row["local_path"]
                or path.suffix != ".png" or not path.is_file()
                or hashlib.sha256(path.read_bytes()).hexdigest() != row["local_sha256"]):
            raise ResponseValidationError("Reference media bytes/path failed final validation")
    reused = Counter(); referenced = Counter()
    for kind, document in docs.items():
        for record in document["groups"] + document["entries"]:
            image = record.get("image_path")
            if image is None:
                continue
            if image.startswith("wiki/references/v1/"):
                if image not in present:
                    raise ResponseValidationError("Presentation names unavailable new media")
                referenced[image] += 1
            elif image.startswith(("wiki/v4/", "wiki/tools/v2/")):
                if not (repository_root / "app/assets" / image).is_file():
                    raise ResponseValidationError("Presentation names unstaged reused media")
                reused[image] += 1
            else:
                raise ResponseValidationError("Presentation image is outside the active asset boundary")
    if set(present) != set(referenced):
        raise ResponseValidationError("Declared reference media has no presentation owner")
    report["media"] = {"available": len(assets), "unavailable": unavailable_rows,
        "new_bytes": sum(row["local_bytes"] for row in assets),
        "reused_active_paths": dict(sorted(reused.items())),
        "source_declared_reference_count": len(declaration["assets"])}
    report["limits"] = {
        "habitat_creature_links": "Map-specific avatar filenames do not match the accepted Index filenames. All unmatched records remain canonical text; no suffix or default-form inference is allowed.",
        "map": "Area/habitat index only; no tiles, exact-spawn claim, comments or account operations.",
        "media": "One missing upstream file is explicitly omitted; no substitute image.",
        "device": "This import does not prove native UI, physical-device or release acceptance."}
    report["source_snapshot"] = str(snapshot)
    report["source_count"] = len(_json(snapshot / "sources.lock.json")["sources"])
    report["closure"] = {"sources": True, "item_shards": True, "map_parts": True,
                         "native_links": True, "media": True, "raw_sidecar": True}
    for kind, document in docs.items():
        _write_new(normalized_root / (kind + ".json"), document)
    _write_new(normalized_root / "raw-sidecar.json", raw_sidecar)
    _write_new(reports_root / "identity-and-counts.json", report)
    _write_new(reports_root / "media-report.json", media_report)
    sources = {source["title"]: source for document in docs.values() for source in document["sources"]}
    attribution = ("Roco World Offline Handbook - Reference Supplement Attribution\n\n"
        "This is an independent, non-commercial, unofficial project.\n"
        "Data/text source: Roco Kingdom World BWIKI contributors.\n"
        "Data/text license: CC BY-NC-SA 4.0\n"
        "License URL: https://creativecommons.org/licenses/by-nc-sa/4.0/\n\n"
        "Game names, characters and artwork remain the property of their respective rights holders.\n"
        "This project claims no ownership, endorsement or affiliation with the game or BWIKI.\n"
        "The data license does not replace the rights attached to original game artwork.\n\n"
        "Changes: validated revision snapshots were safely parsed, cross-referenced and projected\n"
        "into offline JSON references. Source variants, recipes and uncertain mappings are preserved.\n"
        "Icons were resized by the upstream MediaWiki thumbnail service; no artwork was generated.\n"
        "Image provenance/hashes/dimensions: asset-manifest.json. Reused creature/type artwork\n"
        "retains the existing wiki/v4/asset-manifest.json attribution and immutable bytes.\n"
        "Unavailable upstream icon: File:Item_20000027.png; presented with the local placeholder.\n\n"
        "Frozen source revisions:\n" + "".join("- " + row["title"] + ": " + row["url"] + "\n" for row in sources.values()))
    output_path.parent.mkdir(parents=True, exist_ok=True)
    stage = Path(tempfile.mkdtemp(prefix=".reference-bundle.", dir=output_path.parent))
    try:
        shutil.copytree(media_root, stage, dirs_exist_ok=True)
        for kind, document in docs.items():
            _write_new(stage / (kind + ".json"), document)
        (stage / "ATTRIBUTION.txt").write_text(attribution)
        if any(path.suffix in {".lua", ".js"} for path in stage.rglob("*")):
            raise ResponseValidationError("Executable source is not permitted in the native reference bundle")
        if output_path.exists():
            expected_paths = {str(path.relative_to(stage)) for path in stage.rglob("*") if path.is_file()}
            actual_paths = {str(path.relative_to(output_path)) for path in output_path.rglob("*") if path.is_file()}
            if expected_paths != actual_paths or any((stage / path).read_bytes() != (output_path / path).read_bytes() for path in expected_paths):
                raise SnapshotWriteError("Existing immutable reference bundle differs")
        else:
            os.rename(stage, output_path)
    finally:
        if stage.exists():
            shutil.rmtree(stage)
    return report
