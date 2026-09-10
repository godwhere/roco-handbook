from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import re
import shutil
import struct
import tempfile
import time
from typing import Any, Callable, Iterable
from urllib.parse import urlencode, urlparse
from urllib.request import Request, urlopen

from .errors import InputError, ResponseValidationError, SnapshotWriteError


_PNG_SIGNATURE = b"\x89PNG\r\n\x1a\n"
_FILE_NAMESPACES = ("File:", "\u6587\u4ef6:")


@dataclass(frozen=True)
class AssetSpec:
    asset_id: str
    kind: str
    source_title: str
    local_path: str
    width: int
    catalog_ids: tuple[str, ...]


@dataclass(frozen=True)
class ImageMetadata:
    page_id: int
    title: str
    source_sha1: str
    source_timestamp: str
    original_url: str
    original_bytes: int
    original_width: int
    original_height: int
    download_url: str
    requested_width: int


@dataclass(frozen=True)
class FrozenAssetSet:
    path: Path
    manifest_path: Path
    asset_count: int
    reference_count: int
    total_bytes: int
    reused_existing: bool


class UrlTransport:
    def __init__(self, *, timeout_seconds: int, max_retries: int) -> None:
        self.timeout_seconds = timeout_seconds
        self.max_retries = max_retries

    def get_json(self, url: str) -> dict[str, Any]:
        payload, content_type = self._get(url)
        return self._decode_json(payload, content_type)

    def post_json(self, url: str, form: dict[str, str]) -> dict[str, Any]:
        payload, content_type = self._get(
            url,
            data=urlencode(form).encode("utf-8"),
            content_type="application/x-www-form-urlencoded",
        )
        return self._decode_json(payload, content_type)

    @staticmethod
    def _decode_json(payload: bytes, content_type: str) -> dict[str, Any]:
        if "json" not in content_type.lower():
            raise ResponseValidationError(
                f"MediaWiki API returned unexpected Content-Type {content_type!r}"
            )
        try:
            document = json.loads(payload.decode("utf-8"))
        except (UnicodeDecodeError, json.JSONDecodeError) as error:
            raise ResponseValidationError(
                f"MediaWiki API returned invalid JSON: {error}"
            ) from error
        if not isinstance(document, dict):
            raise ResponseValidationError("MediaWiki API response must be an object")
        return document

    def get_png(self, url: str) -> bytes:
        payload, content_type = self._get(url)
        if "image/png" not in content_type.lower():
            raise ResponseValidationError(
                f"Image response returned unexpected Content-Type {content_type!r}"
            )
        return payload

    def _get(
        self,
        url: str,
        *,
        data: bytes | None = None,
        content_type: str | None = None,
    ) -> tuple[bytes, str]:
        last_error: Exception | None = None
        for attempt in range(self.max_retries):
            try:
                headers = {
                    "Accept": "application/json, image/png",
                    "User-Agent": (
                        "RocoWorldOfflineHandbook/1.0 (offline asset import)"
                    ),
                }
                if content_type is not None:
                    headers["Content-Type"] = content_type
                request = Request(url, data=data, headers=headers)
                with urlopen(request, timeout=self.timeout_seconds) as response:
                    return response.read(), response.headers.get_content_type()
            except OSError as error:
                last_error = error
                if attempt + 1 < self.max_retries:
                    time.sleep(2**attempt)
        raise ResponseValidationError(f"Request failed for {url}: {last_error}")


def _read_json(path: Path, label: str) -> dict[str, Any]:
    try:
        document = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeDecodeError, json.JSONDecodeError) as error:
        raise InputError(f"Cannot read {label} {path}: {error}") from error
    if not isinstance(document, dict):
        raise InputError(f"{label.capitalize()} must be a JSON object")
    return document


def _positive_int(value: Any, label: str) -> int:
    if not isinstance(value, int) or isinstance(value, bool) or value <= 0:
        raise InputError(f"{label} must be a positive integer")
    return value


def _positive_number(value: Any, label: str) -> float:
    if not isinstance(value, (int, float)) or isinstance(value, bool) or value < 0:
        raise InputError(f"{label} must be a non-negative number")
    return float(value)


def _config(path: Path) -> dict[str, Any]:
    config = _read_json(path, "image asset configuration")
    if config.get("config_version") != 1:
        raise InputError("Image asset configuration version must be 1")
    if config.get("dataset_id") != "roco-world-zh-cn":
        raise InputError("Image asset configuration has an unexpected dataset_id")
    endpoint = config.get("api_endpoint")
    host = config.get("asset_host")
    prefix = config.get("asset_path_prefix")
    if not isinstance(endpoint, str) or urlparse(endpoint).scheme != "https":
        raise InputError("Image asset API endpoint must use HTTPS")
    if not isinstance(host, str) or not host:
        raise InputError("Image asset host must be non-empty")
    if not isinstance(prefix, str) or not prefix.startswith("/"):
        raise InputError("Image asset path prefix must be absolute")
    policy = config.get("request_policy")
    widths = config.get("thumbnail_widths")
    if not isinstance(policy, dict) or not isinstance(widths, dict):
        raise InputError("Image asset request policy and thumbnail widths are required")
    for key in (
        "api_batch_size",
        "connect_timeout_seconds",
        "read_timeout_seconds",
        "max_retries",
        "max_asset_bytes",
    ):
        _positive_int(policy.get(key), f"request_policy.{key}")
    for key in (
        "api_minimum_interval_seconds",
        "download_minimum_interval_seconds",
    ):
        _positive_number(policy.get(key), f"request_policy.{key}")
    for key in ("pet_illustration", "skill_icon", "ui_icon"):
        _positive_int(widths.get(key), f"thumbnail_widths.{key}")
    return config


def _required_text(record: dict[str, Any], key: str, label: str) -> str:
    value = record.get(key)
    if not isinstance(value, str) or not value:
        raise InputError(f"{label} requires a non-empty {key}")
    return value


def _source_title(prefix: str, key: str) -> str:
    return f"File:{prefix}{key.replace('_', ' ')}.png"


def derive_asset_specs(catalog_path: Path, config_path: Path) -> list[AssetSpec]:
    catalog = _read_json(catalog_path, "normalized Catalog")
    config = _config(config_path)
    if catalog.get("dataset_id") != config["dataset_id"]:
        raise InputError("Catalog and image asset configuration dataset IDs differ")
    widths = config["thumbnail_widths"]
    grouped: dict[str, AssetSpec] = {}

    def add(
        *,
        asset_id: str,
        kind: str,
        source_title: str,
        local_path: str,
        width: int,
        catalog_id: str,
    ) -> None:
        path = PurePosixPath(local_path)
        if path.is_absolute() or ".." in path.parts or path.suffix.lower() != ".png":
            raise InputError(f"Unsafe image asset path: {local_path}")
        prior = grouped.get(local_path)
        if prior is None:
            grouped[local_path] = AssetSpec(
                asset_id=asset_id,
                kind=kind,
                source_title=source_title,
                local_path=local_path,
                width=width,
                catalog_ids=(catalog_id,),
            )
            return
        if (
            prior.kind != kind
            or prior.source_title != source_title
            or prior.width != width
        ):
            raise InputError(f"Conflicting image asset path: {local_path}")
        grouped[local_path] = AssetSpec(
            asset_id=prior.asset_id,
            kind=prior.kind,
            source_title=prior.source_title,
            local_path=prior.local_path,
            width=prior.width,
            catalog_ids=tuple(sorted((*prior.catalog_ids, catalog_id))),
        )

    pets = catalog.get("pets")
    skills = catalog.get("skills")
    if not isinstance(pets, list) or not isinstance(skills, list):
        raise InputError("Normalized Catalog requires pets and skills arrays")
    for raw in pets:
        if not isinstance(raw, dict) or raw.get("status") != "active":
            continue
        pet_id = _required_text(raw, "pet_id", "Active creature")
        illustration = _required_text(
            raw, "illustration_key", f"Creature {pet_id}"
        )
        add(
            asset_id=f"pet_illustration:{illustration}",
            kind="pet_illustration",
            source_title=_source_title("", illustration),
            local_path=f"pets/illustrations/{illustration}.png",
            width=widths["pet_illustration"],
            catalog_id=pet_id,
        )
        if raw.get("has_shiny") in (True, 1):
            shiny_key = f"{illustration}_yise"
            add(
                asset_id=f"pet_shiny_illustration:{shiny_key}",
                kind="pet_shiny_illustration",
                source_title=_source_title("", shiny_key),
                local_path=f"pets/shiny/{shiny_key}.png",
                width=widths["pet_illustration"],
                catalog_id=pet_id,
            )
    for raw in skills:
        if not isinstance(raw, dict) or raw.get("status") != "active":
            continue
        skill_id = _required_text(raw, "skill_id", "Active skill")
        icon = _required_text(raw, "icon_key", f"Skill {skill_id}")
        is_feature = raw.get("category") == "\u7279\u6027"
        filename = f"{'Feature' if is_feature else 'Skill'}_{icon}"
        add(
            asset_id=f"skill_icon:{filename}",
            kind="skill_icon",
            source_title=_source_title(
                "Feature " if is_feature else "Skill ", icon
            ),
            local_path=f"skills/{filename}.png",
            width=widths["skill_icon"],
            catalog_id=skill_id,
        )
    ui_assets = config.get("ui_assets")
    if not isinstance(ui_assets, list):
        raise InputError("Image asset configuration requires a ui_assets array")
    for raw in ui_assets:
        if not isinstance(raw, dict):
            raise InputError("Every UI image asset entry must be an object")
        asset_id = _required_text(raw, "asset_id", "UI image asset")
        add(
            asset_id=f"ui:{asset_id}",
            kind="ui_icon",
            source_title=_required_text(raw, "source_title", asset_id),
            local_path=_required_text(raw, "local_path", asset_id),
            width=widths["ui_icon"],
            catalog_id=asset_id,
        )
    asset_ids = [spec.asset_id for spec in grouped.values()]
    if len(asset_ids) != len(set(asset_ids)):
        raise InputError("Derived image asset IDs are not unique")
    return sorted(grouped.values(), key=lambda item: item.asset_id)


def _normalized_title(value: str) -> str:
    for namespace in _FILE_NAMESPACES:
        if value.startswith(namespace):
            return value[len(namespace) :].replace("_", " ")
    raise ResponseValidationError(f"Unexpected image namespace: {value}")


def _validate_asset_url(url: Any, config: dict[str, Any]) -> str:
    if not isinstance(url, str):
        raise ResponseValidationError("Image metadata requires a URL")
    parsed = urlparse(url)
    if (
        parsed.scheme != "https"
        or parsed.hostname != config["asset_host"]
        or not parsed.path.startswith(config["asset_path_prefix"])
        or parsed.query
        or parsed.fragment
    ):
        raise ResponseValidationError(f"Image URL is outside the allowlist: {url}")
    return url


def _metadata_for_batch(
    document: dict[str, Any],
    expected_titles: set[str],
    width: int,
    config: dict[str, Any],
) -> dict[str, ImageMetadata]:
    if document.get("batchcomplete") is not True:
        raise ResponseValidationError("Image metadata response is incomplete")
    query = document.get("query")
    pages = query.get("pages") if isinstance(query, dict) else None
    if not isinstance(pages, list):
        raise ResponseValidationError("Image metadata response requires query.pages")
    expected = {_normalized_title(title): title for title in expected_titles}
    result: dict[str, ImageMetadata] = {}
    missing: list[str] = []
    for page in pages:
        if not isinstance(page, dict):
            raise ResponseValidationError("Every image page must be an object")
        title = page.get("title")
        if not isinstance(title, str):
            raise ResponseValidationError("Image page requires a title")
        normalized = _normalized_title(title)
        requested = expected.get(normalized)
        if requested is None:
            raise ResponseValidationError(f"Unexpected image page: {title}")
        if requested in result:
            raise ResponseValidationError(f"Duplicate image page: {title}")
        if page.get("missing") is True:
            missing.append(requested)
            continue
        info_rows = page.get("imageinfo")
        if not isinstance(info_rows, list) or len(info_rows) != 1:
            raise ResponseValidationError(f"Image page has no single imageinfo: {title}")
        info = info_rows[0]
        if not isinstance(info, dict):
            raise ResponseValidationError(f"Invalid imageinfo for {title}")
        if info.get("mime") != "image/png" or info.get("mediatype") != "BITMAP":
            raise ResponseValidationError(f"Image is not a PNG bitmap: {title}")
        page_id = page.get("pageid")
        original_bytes = info.get("size")
        original_width = info.get("width")
        original_height = info.get("height")
        timestamp = info.get("timestamp")
        sha1 = info.get("sha1")
        if not isinstance(page_id, int) or page_id <= 0:
            raise ResponseValidationError(f"Invalid image page ID: {title}")
        if not all(
            isinstance(value, int) and not isinstance(value, bool) and value > 0
            for value in (original_bytes, original_width, original_height)
        ):
            raise ResponseValidationError(f"Invalid image dimensions or size: {title}")
        if original_bytes > config["request_policy"]["max_asset_bytes"]:
            raise ResponseValidationError(f"Image exceeds configured size limit: {title}")
        if not isinstance(timestamp, str) or not timestamp.endswith("Z"):
            raise ResponseValidationError(f"Invalid image timestamp: {title}")
        if not isinstance(sha1, str) or len(sha1) != 40:
            raise ResponseValidationError(f"Invalid image source SHA-1: {title}")
        original_url = _validate_asset_url(info.get("url"), config)
        download_url = _validate_asset_url(info.get("thumburl", original_url), config)
        result[requested] = ImageMetadata(
            page_id=page_id,
            title=title,
            source_sha1=sha1,
            source_timestamp=timestamp,
            original_url=original_url,
            original_bytes=original_bytes,
            original_width=original_width,
            original_height=original_height,
            download_url=download_url,
            requested_width=width,
        )
    unseen = expected_titles.difference(result).difference(missing)
    if unseen:
        raise ResponseValidationError(
            "Image metadata response omitted pages: " + ", ".join(sorted(unseen))
        )
    if missing:
        raise ResponseValidationError(
            "Image files are missing: " + ", ".join(sorted(missing))
        )
    return result


def fetch_asset_metadata(
    specs: Iterable[AssetSpec],
    config_path: Path,
    *,
    transport: UrlTransport | None = None,
    sleep: Callable[[float], None] = time.sleep,
) -> dict[str, ImageMetadata]:
    config = _config(config_path)
    policy = config["request_policy"]
    client = transport or UrlTransport(
        timeout_seconds=max(
            policy["connect_timeout_seconds"], policy["read_timeout_seconds"]
        ),
        max_retries=policy["max_retries"],
    )
    by_width: dict[int, set[str]] = {}
    for spec in specs:
        by_width.setdefault(spec.width, set()).add(spec.source_title)
    metadata: dict[str, ImageMetadata] = {}
    first_request = True
    for width in sorted(by_width):
        titles = sorted(by_width[width])
        batch_size = policy["api_batch_size"]
        for offset in range(0, len(titles), batch_size):
            if not first_request:
                sleep(policy["api_minimum_interval_seconds"])
            first_request = False
            batch = titles[offset : offset + batch_size]
            parameters = {
                "action": "query",
                "format": "json",
                "formatversion": "2",
                "prop": "imageinfo",
                "titles": "|".join(batch),
                "iiprop": "url|sha1|size|mime|mediatype|timestamp",
                "iiurlwidth": str(width),
            }
            if hasattr(client, "post_json"):
                document = client.post_json(config["api_endpoint"], parameters)
            else:
                document = client.get_json(
                    config["api_endpoint"] + "?" + urlencode(parameters)
                )
            metadata.update(_metadata_for_batch(document, set(batch), width, config))
    return metadata


def _png_dimensions(payload: bytes) -> tuple[int, int]:
    if (
        len(payload) < 24
        or payload[:8] != _PNG_SIGNATURE
        or payload[12:16] != b"IHDR"
    ):
        raise ResponseValidationError("Downloaded image is not a valid PNG")
    width, height = struct.unpack(">II", payload[16:24])
    if width <= 0 or height <= 0:
        raise ResponseValidationError("Downloaded PNG has invalid dimensions")
    return width, height


def asset_preflight(
    catalog_path: Path,
    config_path: Path,
    *,
    transport: UrlTransport | None = None,
    sleep: Callable[[float], None] = time.sleep,
) -> dict[str, Any]:
    specs = derive_asset_specs(catalog_path, config_path)
    metadata = fetch_asset_metadata(
        specs, config_path, transport=transport, sleep=sleep
    )
    return {
        "asset_count": len(specs),
        "reference_count": sum(len(spec.catalog_ids) for spec in specs),
        "original_bytes": sum(
            metadata[spec.source_title].original_bytes for spec in specs
        ),
        "kinds": {
            kind: sum(1 for spec in specs if spec.kind == kind)
            for kind in sorted({spec.kind for spec in specs})
        },
    }


def _manifest_without_time(
    specs: list[AssetSpec], records: list[dict[str, Any]], config: dict[str, Any]
) -> dict[str, Any]:
    return {
        "manifest_version": 1,
        "dataset_id": config["dataset_id"],
        "asset_version": config["asset_version"],
        "asset_count": len(records),
        "reference_count": sum(len(spec.catalog_ids) for spec in specs),
        "total_bytes": sum(record["local_bytes"] for record in records),
        "assets": records,
    }


def _verify_existing(
    target: Path, specs: list[AssetSpec], config: dict[str, Any]
) -> FrozenAssetSet:
    manifest_path = target / "asset-manifest.json"
    try:
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    except (OSError, UnicodeDecodeError, json.JSONDecodeError) as error:
        raise SnapshotWriteError(f"Existing image asset set is invalid: {error}") from error
    expected_reference_count = sum(len(spec.catalog_ids) for spec in specs)
    if (
        manifest.get("manifest_version") != 1
        or manifest.get("dataset_id") != config["dataset_id"]
        or manifest.get("asset_version") != config["asset_version"]
        or manifest.get("asset_count") != len(specs)
        or manifest.get("reference_count") != expected_reference_count
        or not isinstance(manifest.get("imported_at_utc"), str)
        or not manifest["imported_at_utc"].endswith("Z")
    ):
        raise SnapshotWriteError("Existing image asset manifest does not match the request")
    records = manifest.get("assets")
    if not isinstance(records, list) or len(records) != len(specs):
        raise SnapshotWriteError("Existing image asset manifest has no assets array")
    expected = {spec.asset_id: spec for spec in specs}
    seen: set[str] = set()
    total_bytes = 0
    for record in records:
        asset_id = record.get("asset_id") if isinstance(record, dict) else None
        if (
            not isinstance(asset_id, str)
            or asset_id not in expected
            or asset_id in seen
        ):
            raise SnapshotWriteError("Existing image asset manifest has an unknown asset")
        seen.add(asset_id)
        spec = expected[asset_id]
        if (
            record.get("kind") != spec.kind
            or record.get("catalog_ids") != list(spec.catalog_ids)
            or record.get("source_title") != spec.source_title
            or record.get("local_path") != spec.local_path
            or record.get("requested_width") != spec.width
        ):
            raise SnapshotWriteError(
                f"Existing image asset record changed: {asset_id}"
            )
        source_page_id = record.get("source_page_id")
        source_timestamp = record.get("source_timestamp")
        source_sha1 = record.get("source_sha1")
        numeric_fields = (
            "source_bytes",
            "source_width",
            "source_height",
            "local_bytes",
            "local_width",
            "local_height",
        )
        if (
            not isinstance(source_page_id, int)
            or isinstance(source_page_id, bool)
            or source_page_id <= 0
            or not isinstance(source_timestamp, str)
            or not source_timestamp.endswith("Z")
            or not isinstance(source_sha1, str)
            or re.fullmatch(r"[0-9a-f]{40}", source_sha1) is None
            or any(
                not isinstance(record.get(field), int)
                or isinstance(record.get(field), bool)
                or record[field] <= 0
                for field in numeric_fields
            )
        ):
            raise SnapshotWriteError(
                f"Existing image asset source metadata is invalid: {asset_id}"
            )
        try:
            _validate_asset_url(record.get("source_url"), config)
            _validate_asset_url(record.get("download_url"), config)
        except ResponseValidationError as error:
            raise SnapshotWriteError(
                f"Existing image asset URL is invalid: {asset_id}"
            ) from error
        path = target / spec.local_path
        try:
            payload = path.read_bytes()
        except OSError as error:
            raise SnapshotWriteError(f"Existing image asset is missing: {path}") from error
        local_sha256 = record.get("local_sha256")
        if (
            not isinstance(local_sha256, str)
            or re.fullmatch(r"[0-9a-f]{64}", local_sha256) is None
            or hashlib.sha256(payload).hexdigest() != local_sha256
            or len(payload) != record["local_bytes"]
            or _png_dimensions(payload)
            != (record["local_width"], record["local_height"])
        ):
            raise SnapshotWriteError(f"Existing image asset changed: {path}")
        total_bytes += len(payload)
    actual_files = {
        path.relative_to(target).as_posix()
        for path in target.rglob("*")
        if path.is_file()
    }
    expected_files = {spec.local_path for spec in specs} | {"asset-manifest.json"}
    if seen != set(expected) or actual_files != expected_files:
        raise SnapshotWriteError("Existing image asset manifest is incomplete")
    if manifest.get("total_bytes") != total_bytes:
        raise SnapshotWriteError("Existing image asset total byte count changed")
    return FrozenAssetSet(
        path=target,
        manifest_path=manifest_path,
        asset_count=len(records),
        reference_count=expected_reference_count,
        total_bytes=total_bytes,
        reused_existing=True,
    )


def import_image_assets(
    catalog_path: Path,
    config_path: Path,
    output_root: Path,
    *,
    cache_root: Path | None = None,
    transport: UrlTransport | None = None,
    sleep: Callable[[float], None] = time.sleep,
) -> FrozenAssetSet:
    specs = derive_asset_specs(catalog_path, config_path)
    return freeze_asset_specs(
        specs,
        config_path,
        output_root,
        cache_root=cache_root,
        transport=transport,
        sleep=sleep,
    )


def freeze_asset_specs(
    specs: Iterable[AssetSpec],
    config_path: Path,
    output_root: Path,
    *,
    cache_root: Path | None = None,
    transport: UrlTransport | None = None,
    sleep: Callable[[float], None] = time.sleep,
) -> FrozenAssetSet:
    config = _config(config_path)
    specs = sorted(specs, key=lambda item: item.asset_id)
    if not specs:
        raise InputError("Image asset request is empty")
    if len({spec.asset_id for spec in specs}) != len(specs):
        raise InputError("Image asset IDs must be unique")
    if len({spec.local_path for spec in specs}) != len(specs):
        raise InputError("Image asset paths must be unique")
    for spec in specs:
        path = PurePosixPath(spec.local_path)
        if path.is_absolute() or ".." in path.parts or path.suffix.lower() != ".png":
            raise InputError(f"Unsafe image asset path: {spec.local_path}")
    target = output_root / f"v{config['asset_version']}"
    if target.exists():
        return _verify_existing(target, specs, config)
    metadata = fetch_asset_metadata(
        specs, config_path, transport=transport, sleep=sleep
    )
    policy = config["request_policy"]
    client = transport or UrlTransport(
        timeout_seconds=max(
            policy["connect_timeout_seconds"], policy["read_timeout_seconds"]
        ),
        max_retries=policy["max_retries"],
    )
    output_root.mkdir(parents=True, exist_ok=True)
    if cache_root is not None:
        cache_root.mkdir(parents=True, exist_ok=True)
    stage = Path(tempfile.mkdtemp(prefix=".wiki-assets-v1.", dir=output_root))
    records: list[dict[str, Any]] = []
    try:
        for index, spec in enumerate(specs):
            info = metadata[spec.source_title]
            cache_path = None
            if cache_root is not None:
                cache_path = cache_root / hashlib.sha256(
                    info.download_url.encode("utf-8")
                ).hexdigest()
            payload: bytes
            if cache_path is not None and cache_path.is_file():
                payload = cache_path.read_bytes()
            else:
                if index:
                    sleep(policy["download_minimum_interval_seconds"])
                payload = client.get_png(info.download_url)
                if cache_path is not None:
                    cache_path.write_bytes(payload)
            if len(payload) > policy["max_asset_bytes"]:
                raise ResponseValidationError(
                    f"Downloaded image exceeds configured size limit: {spec.source_title}"
                )
            local_width, local_height = _png_dimensions(payload)
            destination = stage / spec.local_path
            destination.parent.mkdir(parents=True, exist_ok=True)
            destination.write_bytes(payload)
            records.append(
                {
                    "asset_id": spec.asset_id,
                    "kind": spec.kind,
                    "catalog_ids": list(spec.catalog_ids),
                    "source_title": spec.source_title,
                    "source_page_id": info.page_id,
                    "source_timestamp": info.source_timestamp,
                    "source_sha1": info.source_sha1,
                    "source_url": info.original_url,
                    "source_bytes": info.original_bytes,
                    "source_width": info.original_width,
                    "source_height": info.original_height,
                    "download_url": info.download_url,
                    "requested_width": info.requested_width,
                    "local_path": spec.local_path,
                    "local_bytes": len(payload),
                    "local_width": local_width,
                    "local_height": local_height,
                    "local_sha256": hashlib.sha256(payload).hexdigest(),
                }
            )
        manifest = _manifest_without_time(specs, records, config)
        manifest["imported_at_utc"] = datetime.now(timezone.utc).isoformat().replace(
            "+00:00", "Z"
        )
        (stage / "asset-manifest.json").write_text(
            json.dumps(manifest, ensure_ascii=False, indent=2, sort_keys=True) + "\n",
            encoding="utf-8",
        )
        os.rename(stage, target)
    except OSError as error:
        raise SnapshotWriteError(f"Cannot freeze image assets: {error}") from error
    finally:
        if stage.exists():
            shutil.rmtree(stage)
    return FrozenAssetSet(
        path=target,
        manifest_path=target / "asset-manifest.json",
        asset_count=len(records),
        reference_count=manifest["reference_count"],
        total_bytes=manifest["total_bytes"],
        reused_existing=False,
    )
