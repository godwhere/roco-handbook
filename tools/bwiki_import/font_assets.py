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
from typing import Any
from urllib.parse import urlparse

from .errors import InputError, ResponseValidationError, SnapshotWriteError
from .image_assets import UrlTransport


_SHA256 = re.compile(r"[0-9a-f]{64}")
_SFNT_SIGNATURES = {b"\x00\x01\x00\x00", b"OTTO"}


@dataclass(frozen=True)
class FontAssetSpec:
    font_id: str
    family: str
    role: str
    source_url: str
    local_path: str
    source_bytes: int
    source_sha256: str


@dataclass(frozen=True)
class FrozenFontSet:
    path: Path
    manifest_path: Path
    font_count: int
    total_bytes: int
    reused_existing: bool


def _read_config(path: Path) -> dict[str, Any]:
    try:
        document = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeDecodeError, json.JSONDecodeError) as error:
        raise InputError(
            f"Cannot read font asset configuration {path}: {error}"
        ) from error
    if not isinstance(document, dict):
        raise InputError("Font asset configuration must be a JSON object")
    if document.get("config_version") != 1:
        raise InputError("Font asset configuration version must be 1")
    if document.get("dataset_id") != "roco-world-zh-cn":
        raise InputError("Font asset configuration has an unexpected dataset_id")
    asset_version = document.get("asset_version")
    if (
        not isinstance(asset_version, int)
        or isinstance(asset_version, bool)
        or asset_version < 1
    ):
        raise InputError("Font asset version must be a positive integer")
    host = document.get("asset_host")
    prefix = document.get("asset_path_prefix")
    stylesheet = document.get("source_stylesheet")
    if not isinstance(host, str) or not host:
        raise InputError("Font asset host must be non-empty")
    if not isinstance(prefix, str) or not prefix.startswith("/"):
        raise InputError("Font asset path prefix must be absolute")
    if not isinstance(stylesheet, str) or urlparse(stylesheet).scheme != "https":
        raise InputError("Font source stylesheet must use HTTPS")
    policy = document.get("request_policy")
    if not isinstance(policy, dict):
        raise InputError("Font asset request policy is required")
    for key in (
        "connect_timeout_seconds",
        "read_timeout_seconds",
        "max_retries",
        "max_font_bytes",
    ):
        value = policy.get(key)
        if not isinstance(value, int) or isinstance(value, bool) or value < 1:
            raise InputError(f"request_policy.{key} must be a positive integer")
    return document


def _validate_source_url(value: Any, config: dict[str, Any]) -> str:
    if not isinstance(value, str):
        raise InputError("Font source URL must be a string")
    parsed = urlparse(value)
    if (
        parsed.scheme != "https"
        or parsed.hostname != config["asset_host"]
        or not parsed.path.startswith(config["asset_path_prefix"])
        or parsed.query
        or parsed.fragment
    ):
        raise InputError(f"Font source URL is outside the configured boundary: {value}")
    return value


def _specs(config: dict[str, Any]) -> list[FontAssetSpec]:
    records = config.get("fonts")
    if not isinstance(records, list) or not records:
        raise InputError("Font asset configuration requires a non-empty fonts array")
    specs: list[FontAssetSpec] = []
    for record in records:
        if not isinstance(record, dict):
            raise InputError("Each font asset record must be an object")
        font_id = record.get("font_id")
        family = record.get("family")
        role = record.get("role")
        local_path = record.get("local_path")
        source_bytes = record.get("source_bytes")
        source_sha256 = record.get("source_sha256")
        if any(
            not isinstance(value, str) or not value
            for value in (font_id, family, role)
        ):
            raise InputError("Font IDs, families, and roles must be non-empty strings")
        if role not in {"display", "numbers"}:
            raise InputError(f"Font asset role is unsupported: {role}")
        path = PurePosixPath(local_path) if isinstance(local_path, str) else None
        if (
            path is None
            or path.is_absolute()
            or ".." in path.parts
            or path.suffix.lower() != ".ttf"
        ):
            raise InputError(f"Unsafe font asset path: {local_path}")
        if (
            not isinstance(source_bytes, int)
            or isinstance(source_bytes, bool)
            or source_bytes < 1
        ):
            raise InputError(f"Font source byte count is invalid: {font_id}")
        if (
            not isinstance(source_sha256, str)
            or _SHA256.fullmatch(source_sha256) is None
        ):
            raise InputError(f"Font source SHA-256 is invalid: {font_id}")
        specs.append(
            FontAssetSpec(
                font_id=font_id,
                family=family,
                role=role,
                source_url=_validate_source_url(record.get("source_url"), config),
                local_path=local_path,
                source_bytes=source_bytes,
                source_sha256=source_sha256,
            )
        )
    if len({spec.font_id for spec in specs}) != len(specs):
        raise InputError("Font asset IDs must be unique")
    if len({spec.family for spec in specs}) != len(specs):
        raise InputError("Font asset families must be unique")
    if len({spec.local_path for spec in specs}) != len(specs):
        raise InputError("Font asset paths must be unique")
    if len(specs) != 2 or {spec.role for spec in specs} != {"display", "numbers"}:
        raise InputError("Font asset roles must contain display and numbers exactly once")
    return sorted(specs, key=lambda spec: spec.font_id)


def _validate_font(payload: bytes, spec: FontAssetSpec, max_bytes: int) -> None:
    if len(payload) != spec.source_bytes:
        raise ResponseValidationError(
            f"Font byte count changed for {spec.font_id}: {len(payload)}"
        )
    if len(payload) > max_bytes:
        raise ResponseValidationError(
            f"Font exceeds the configured size limit: {spec.font_id}"
        )
    if hashlib.sha256(payload).hexdigest() != spec.source_sha256:
        raise ResponseValidationError(f"Font SHA-256 changed for {spec.font_id}")
    if len(payload) < 12 or payload[:4] not in _SFNT_SIGNATURES:
        raise ResponseValidationError(
            f"Font has an invalid SFNT header: {spec.font_id}"
        )
    table_count = struct.unpack(">H", payload[4:6])[0]
    if table_count < 1 or 12 + 16 * table_count > len(payload):
        raise ResponseValidationError(
            f"Font has an invalid SFNT table directory: {spec.font_id}"
        )


def _record(spec: FontAssetSpec) -> dict[str, Any]:
    return {
        "family": spec.family,
        "font_id": spec.font_id,
        "local_bytes": spec.source_bytes,
        "local_path": spec.local_path,
        "local_sha256": spec.source_sha256,
        "role": spec.role,
        "source_url": spec.source_url,
    }


def _verify_existing(
    target: Path,
    config: dict[str, Any],
    specs: list[FontAssetSpec],
) -> FrozenFontSet:
    manifest_path = target / "font-manifest.json"
    try:
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    except (OSError, UnicodeDecodeError, json.JSONDecodeError) as error:
        raise SnapshotWriteError(
            f"Existing font asset set is invalid: {error}"
        ) from error
    records = manifest.get("fonts")
    expected_records = [_record(spec) for spec in specs]
    if (
        manifest.get("manifest_version") != 1
        or manifest.get("dataset_id") != config["dataset_id"]
        or manifest.get("asset_version") != config["asset_version"]
        or manifest.get("source_stylesheet") != config["source_stylesheet"]
        or manifest.get("font_count") != len(specs)
        or records != expected_records
        or not isinstance(manifest.get("imported_at_utc"), str)
        or not manifest["imported_at_utc"].endswith("Z")
    ):
        raise SnapshotWriteError("Existing font asset manifest does not match the request")
    total_bytes = 0
    for spec in specs:
        path = target / spec.local_path
        try:
            payload = path.read_bytes()
        except OSError as error:
            raise SnapshotWriteError(f"Existing font asset is missing: {path}") from error
        try:
            _validate_font(payload, spec, config["request_policy"]["max_font_bytes"])
        except ResponseValidationError as error:
            raise SnapshotWriteError(f"Existing font asset changed: {path}") from error
        total_bytes += len(payload)
    actual_files = {
        path.relative_to(target).as_posix()
        for path in target.rglob("*")
        if path.is_file()
    }
    expected_files = {spec.local_path for spec in specs} | {"font-manifest.json"}
    if actual_files != expected_files or manifest.get("total_bytes") != total_bytes:
        raise SnapshotWriteError("Existing font asset set is incomplete")
    return FrozenFontSet(
        path=target,
        manifest_path=manifest_path,
        font_count=len(specs),
        total_bytes=total_bytes,
        reused_existing=True,
    )


def import_font_assets(
    config_path: Path,
    output_root: Path,
    *,
    transport: UrlTransport | None = None,
) -> FrozenFontSet:
    config = _read_config(config_path)
    specs = _specs(config)
    target = output_root / f"v{config['asset_version']}"
    if target.exists():
        return _verify_existing(target, config, specs)
    policy = config["request_policy"]
    client = transport or UrlTransport(
        timeout_seconds=max(
            policy["connect_timeout_seconds"], policy["read_timeout_seconds"]
        ),
        max_retries=policy["max_retries"],
    )
    output_root.mkdir(parents=True, exist_ok=True)
    stage = Path(tempfile.mkdtemp(prefix=".wiki-fonts-v1.", dir=output_root))
    try:
        for spec in specs:
            payload = client.get_font(spec.source_url)
            _validate_font(payload, spec, policy["max_font_bytes"])
            destination = stage / spec.local_path
            destination.parent.mkdir(parents=True, exist_ok=True)
            destination.write_bytes(payload)
        manifest = {
            "asset_version": config["asset_version"],
            "dataset_id": config["dataset_id"],
            "font_count": len(specs),
            "fonts": [_record(spec) for spec in specs],
            "imported_at_utc": datetime.now(timezone.utc)
            .isoformat()
            .replace("+00:00", "Z"),
            "manifest_version": 1,
            "source_stylesheet": config["source_stylesheet"],
            "total_bytes": sum(spec.source_bytes for spec in specs),
        }
        (stage / "font-manifest.json").write_text(
            json.dumps(manifest, ensure_ascii=False, indent=2, sort_keys=True) + "\n",
            encoding="utf-8",
        )
        os.rename(stage, target)
    except OSError as error:
        raise SnapshotWriteError(f"Cannot freeze font assets: {error}") from error
    finally:
        if stage.exists():
            shutil.rmtree(stage)
    return FrozenFontSet(
        path=target,
        manifest_path=target / "font-manifest.json",
        font_count=len(specs),
        total_bytes=manifest["total_bytes"],
        reused_existing=False,
    )
