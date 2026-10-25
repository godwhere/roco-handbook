"""Freeze the explicitly declared reference icons through the verified PNG pipeline."""
from __future__ import annotations

import hashlib
import json
from pathlib import Path, PurePosixPath
import re
import time
from typing import Any, Callable
from urllib.parse import urlencode

from .errors import InputError, ResponseValidationError
from .image_assets import (
    AssetSpec, UrlTransport, _config, _metadata_for_batch, _normalized_title,
    freeze_asset_specs,
)


def reference_asset_specs(path: Path) -> list[AssetSpec]:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeDecodeError, json.JSONDecodeError) as error:
        raise InputError(f"Cannot read reference media declaration: {error}") from error
    if (not isinstance(value, dict) or value.get("manifest_version") != 1
            or value.get("dataset_id") != "roco-world-zh-cn"
            or not isinstance(value.get("assets"), list) or not value["assets"]):
        raise InputError("Reference media declaration is invalid or empty")
    result: list[AssetSpec] = []
    for record in value["assets"]:
        if not isinstance(record, dict):
            raise InputError("Reference media records must be objects")
        identity, title, local = (record.get(key) for key in ("asset_id", "source_title", "local_path"))
        width, references = record.get("width"), record.get("catalog_ids")
        if not all(isinstance(text, str) and text and "\0" not in text for text in (identity, title, local)):
            raise InputError("Reference media identity, title or path is invalid")
        destination = PurePosixPath(local)
        if (not title.startswith("File:") or not title.endswith(".png")
                or len(title) <= 9 or any(part in title for part in ("/", "\\", "..", "|"))
                or destination.is_absolute() or destination.parts[0] != "icons"
                or len(destination.parts) != 2 or destination.suffix != ".png"
                or str(destination) != local or "\\" in local or ".." in local
                or not isinstance(width, int) or isinstance(width, bool) or not 1 <= width <= 192
                or not isinstance(references, list) or not references
                or not all(isinstance(item, str) and re.fullmatch(r"(?:items|medals):[A-Za-z0-9_]+", item) for item in references)
                or len(set(references)) != len(references)):
            raise InputError("Reference media request exceeds its icon/path/reference boundary")
        result.append(AssetSpec(identity, "reference_icon", title, local, width, tuple(sorted(references))))
    for label, values in (("IDs", [item.asset_id for item in result]),
                          ("paths", [item.local_path for item in result]),
                          ("source titles", [_normalized_title(item.source_title) for item in result])):
        if len(values) != len(set(values)):
            raise InputError(f"Reference media {label} must be unique")
    return sorted(result, key=lambda item: item.asset_id)


class _ObservedMetadataTransport:
    """Replay only observed metadata while the existing pipeline verifies/downloads PNGs."""
    def __init__(self, client: UrlTransport, endpoint: str, pages: dict[tuple[int, str], dict[str, Any]]) -> None:
        self.client, self.endpoint, self.pages = client, endpoint, pages
        self.originals: dict[str, tuple[str, int]] = {}
        for page in pages.values():
            info = page["imageinfo"][0]
            expected = (info["sha1"].lower(), info["size"])
            if info["url"] in self.originals and self.originals[info["url"]] != expected:
                raise ResponseValidationError("Reference original image metadata conflicts")
            self.originals[info["url"]] = expected

    def verify_original(self, url: str, payload: bytes) -> None:
        expected = self.originals.get(url)
        if expected is not None and (hashlib.sha1(payload).hexdigest(), len(payload)) != expected:
            raise ResponseValidationError("Reference original image does not match its upstream SHA-1 and size")

    def verify_cached_originals(self, root: Path | None) -> None:
        if root is not None:
            for url in self.originals:
                path = root / hashlib.sha256(url.encode("utf-8")).hexdigest()
                if path.is_file():
                    self.verify_original(url, path.read_bytes())

    def post_json(self, url: str, form: dict[str, str]) -> dict[str, Any]:
        if url != self.endpoint or form.get("prop") != "imageinfo":
            raise ResponseValidationError("Reference metadata replay requested an unobserved operation")
        try:
            width = int(form["iiurlwidth"])
            observed = [self.pages[(width, _normalized_title(title))] for title in form["titles"].split("|")]
        except (KeyError, ValueError) as error:
            raise ResponseValidationError("Reference metadata replay requested an unobserved image") from error
        return {"batchcomplete": True, "query": {"pages": observed}}

    def get_png(self, url: str) -> bytes:
        payload = self.client.get_png(url)
        self.verify_original(url, payload)
        return payload


def verify_reference_originals(root: Path) -> int:
    """Check original-file claims, including cached or reused immutable output."""
    manifest = json.loads((root / "asset-manifest.json").read_text(encoding="utf-8"))
    checked = 0
    for record in manifest["assets"]:
        if record["download_url"] != record["source_url"]:
            continue
        local = PurePosixPath(record["local_path"])
        if len(local.parts) != 2 or local.parts[0] != "icons" or ".." in local.parts or local.is_absolute():
            raise ResponseValidationError("Reference original image path is invalid")
        payload = (root / local).read_bytes()
        if (hashlib.sha1(payload).hexdigest() != record["source_sha1"].lower()
                or len(payload) != record["source_bytes"]):
            raise ResponseValidationError("Frozen reference original image differs from upstream SHA-1 or size")
        checked += 1
    return checked


def import_reference_media(
    declaration_path: Path,
    config_path: Path,
    output_root: Path,
    *,
    cache_root: Path | None = None,
    transport: UrlTransport | None = None,
    sleep: Callable[[float], None] = time.sleep,
) -> dict[str, Any]:
    config = _config(config_path)
    if (config.get("asset_version") != 1
            or config["api_endpoint"] != "https://wiki.biligame.com/nrc/api.php"
            or config["asset_host"] != "patchwiki.biligame.com"
            or config["asset_path_prefix"] != "/images/nrc/"
            or config.get("asset_path_prefixes", ["/images/nrc/"]) != ["/images/nrc/"]):
        raise InputError("Reference media configuration changed its fixed source boundary")
    specs = reference_asset_specs(declaration_path)
    policy = config["request_policy"]
    client = transport or UrlTransport(timeout_seconds=max(policy["connect_timeout_seconds"], policy["read_timeout_seconds"]),
                                       max_retries=policy["max_retries"])
    observed: dict[tuple[int, str], dict[str, Any]] = {}
    missing: set[str] = set()
    requests = 0
    for width in sorted({item.width for item in specs}):
        titles = sorted({item.source_title for item in specs if item.width == width})
        for start in range(0, len(titles), policy["api_batch_size"]):
            if requests:
                sleep(policy["api_minimum_interval_seconds"])
            requests += 1
            batch = titles[start:start + policy["api_batch_size"]]
            form = {"action": "query", "format": "json", "formatversion": "2", "prop": "imageinfo",
                    "titles": "|".join(batch), "iiprop": "url|sha1|size|mime|mediatype|timestamp", "iiurlwidth": str(width)}
            document = client.post_json(config["api_endpoint"], form) if hasattr(client, "post_json") else client.get_json(config["api_endpoint"] + "?" + urlencode(form))
            query = document.get("query")
            pages = query.get("pages") if isinstance(query, dict) else None
            if document.get("error") is not None or document.get("batchcomplete") is not True or not isinstance(pages, list):
                raise ResponseValidationError("Reference image metadata response is incomplete or failed")
            expected = {_normalized_title(title): title for title in batch}
            seen: set[str] = set()
            present = []
            for page in pages:
                if not isinstance(page, dict) or not isinstance(page.get("title"), str):
                    raise ResponseValidationError("Reference image metadata has an invalid page")
                normalized = _normalized_title(page["title"])
                if normalized not in expected or normalized in seen:
                    raise ResponseValidationError("Reference image metadata has an unexpected or duplicate page")
                seen.add(normalized)
                if page.get("missing") is True:
                    missing.add(expected[normalized])
                else:
                    present.append(page)
            if seen != set(expected):
                raise ResponseValidationError("Reference image metadata omitted requested pages")
            available = set(batch) - missing
            if available:
                metadata = _metadata_for_batch({"batchcomplete": True, "query": {"pages": present}}, available, width, config)
                if any(re.fullmatch(r"[0-9a-fA-F]{40}", item.source_sha1) is None for item in metadata.values()):
                    raise ResponseValidationError("Reference image metadata has an invalid source SHA-1")
                observed.update({(width, _normalized_title(page["title"])): page for page in present})
    accepted = [item for item in specs if item.source_title not in missing]
    if not accepted:
        raise ResponseValidationError("No declared reference icons are available; no empty media release was written")
    replay = _ObservedMetadataTransport(client, config["api_endpoint"], observed)
    replay.verify_cached_originals(cache_root)
    frozen = freeze_asset_specs(accepted, config_path, output_root, cache_root=cache_root,
                                transport=replay, sleep=sleep)
    verified_originals = verify_reference_originals(frozen.path)
    report = {"report_version": 1, "dataset_id": "roco-world-zh-cn", "path": str(frozen.path),
              "declaration_sha256": hashlib.sha256(declaration_path.read_bytes()).hexdigest(),
              "config_sha256": hashlib.sha256(config_path.read_bytes()).hexdigest(),
              "manifest_path": str(frozen.manifest_path), "requested_count": len(specs),
              "available_count": frozen.asset_count, "reference_count": frozen.reference_count,
              "total_bytes": frozen.total_bytes, "reused_existing": frozen.reused_existing,
              "verified_original_count": verified_originals,
              "unavailable": [{"source_title": item.source_title, "catalog_ids": list(item.catalog_ids)}
                              for item in specs if item.source_title in missing]}
    (output_root / "reference-media-report.json").write_text(json.dumps(report, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")
    return report
