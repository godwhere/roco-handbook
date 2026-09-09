from __future__ import annotations

from datetime import datetime
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import stat
import tempfile
from typing import Any
from urllib.parse import unquote, urlsplit
import zipfile

from tools.release.check_catalog import ReleaseCheckError, check_release

from .errors import AdapterError


_ARCHIVE_ENTRIES = (
    "assets/catalog/bundled_catalog.json",
    "assets/catalog/catalog.db",
    "assets/catalog/ATTRIBUTION.txt",
)

_ENTRY_LIMITS = {
    "assets/catalog/bundled_catalog.json": 64 * 1024,
    "assets/catalog/catalog.db": 128 * 1024 * 1024,
    "assets/catalog/ATTRIBUTION.txt": 256 * 1024,
}

_FIXED_ZIP_TIMESTAMP = (1980, 1, 1, 0, 0, 0)
_VERSION_PATTERN = re.compile(r"^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$")
_UTC_PATTERN = re.compile(r"^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$")
_GITHUB_RELEASE_PACKAGE_PATTERN = re.compile(
    r"^/godwhere/roco-handbook/releases/download/"
    r"catalog-data-v([1-9][0-9]*)/catalog-v([1-9][0-9]*)\.zip$"
)


def _sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for chunk in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def _require_archive_entry(path: Path, archive_path: str) -> None:
    if not path.is_file() or path.is_symlink():
        raise AdapterError(f"Catalog update entry is missing or unsafe: {archive_path}")
    size = path.stat().st_size
    if size < 1 or size > _ENTRY_LIMITS[archive_path]:
        raise AdapterError(
            f"Catalog update entry is outside its size limit: {archive_path}"
        )


def _require_outside_repository(
    path: Path,
    repository_root: Path,
    *,
    label: str,
) -> None:
    candidate = path.parent.resolve() / path.name
    try:
        candidate.relative_to(repository_root.resolve())
    except ValueError:
        return
    raise AdapterError(f"{label} must remain outside the repository")


def _write_archive_entry(
    archive: zipfile.ZipFile,
    *,
    archive_path: str,
    source_path: Path,
) -> None:
    info = zipfile.ZipInfo(archive_path, date_time=_FIXED_ZIP_TIMESTAMP)
    info.compress_type = zipfile.ZIP_DEFLATED
    info.create_system = 3
    info.create_version = 20
    info.extract_version = 20
    info.external_attr = (stat.S_IFREG | 0o644) << 16
    info.extra = b""
    info.comment = b""
    with source_path.open("rb") as source, archive.open(
        info,
        mode="w",
        force_zip64=False,
    ) as target:
        shutil.copyfileobj(source, target, length=1024 * 1024)


def _validate_written_archive(archive_path: Path, release: Path) -> None:
    with zipfile.ZipFile(archive_path, mode="r") as archive:
        if archive.comment or tuple(archive.namelist()) != _ARCHIVE_ENTRIES:
            raise AdapterError("The generated Catalog update ZIP has an invalid shape")
        if archive.testzip() is not None:
            raise AdapterError("The generated Catalog update ZIP failed CRC validation")
        for name in _ARCHIVE_ENTRIES:
            info = archive.getinfo(name)
            source = release / name
            mode = info.external_attr >> 16
            if (
                info.filename != name
                or info.compress_type != zipfile.ZIP_DEFLATED
                or info.extract_version > 20
                or info.flag_bits & ~0x0808
                or info.extra
                or info.comment
                or not stat.S_ISREG(mode)
                or info.file_size != source.stat().st_size
                or info.file_size > _ENTRY_LIMITS[name]
            ):
                raise AdapterError(
                    f"The generated Catalog update ZIP entry is invalid: {name}"
                )
            with archive.open(info, mode="r") as packaged, source.open("rb") as expected:
                while True:
                    packaged_chunk = packaged.read(1024 * 1024)
                    expected_chunk = expected.read(1024 * 1024)
                    if packaged_chunk != expected_chunk:
                        raise AdapterError(
                            f"The generated Catalog update ZIP changed entry bytes: {name}"
                        )
                    if not packaged_chunk:
                        break


def build_complete_update_archive(
    release: Path,
    output_path: Path,
    *,
    repository_root: Path,
) -> dict[str, Any]:
    """Build one immutable complete-Catalog ZIP without signing or publishing it."""

    release = release.resolve()
    output_path = output_path.absolute()
    if output_path.suffix.lower() != ".zip":
        raise AdapterError("Catalog update output must use the .zip extension")
    _require_outside_repository(
        output_path,
        repository_root,
        label="Catalog update archive",
    )
    if output_path.exists() or output_path.is_symlink():
        raise AdapterError(f"Catalog update archive already exists: {output_path}")

    try:
        release_report = check_release(release, root=repository_root.resolve())
    except (OSError, ReleaseCheckError) as error:
        raise AdapterError(
            f"Catalog release is not eligible for update packaging: {error}"
        ) from error

    sources = {name: release / name for name in _ARCHIVE_ENTRIES}
    for name, path in sources.items():
        _require_archive_entry(path, name)

    output_path.parent.mkdir(parents=True, exist_ok=True)
    descriptor, temporary_name = tempfile.mkstemp(
        prefix=f".{output_path.name}.",
        suffix=".tmp",
        dir=output_path.parent,
    )
    os.close(descriptor)
    temporary = Path(temporary_name)
    owns_temporary = True
    owns_output = False
    archive_bytes = 0
    archive_sha256 = ""
    try:
        with zipfile.ZipFile(
            temporary,
            mode="w",
            compression=zipfile.ZIP_DEFLATED,
            compresslevel=9,
            allowZip64=False,
            strict_timestamps=True,
        ) as archive:
            archive.comment = b""
            for name in _ARCHIVE_ENTRIES:
                _write_archive_entry(
                    archive,
                    archive_path=name,
                    source_path=sources[name],
                )
        _validate_written_archive(temporary, release)
        archive_bytes = temporary.stat().st_size
        archive_sha256 = _sha256(temporary)
        try:
            os.link(temporary, output_path)
        except FileExistsError as error:
            raise AdapterError(
                f"Catalog update archive already exists: {output_path}"
            ) from error
        owns_output = True
        temporary.unlink()
        owns_temporary = False
        owns_output = False
    except (OSError, zipfile.BadZipFile, zipfile.LargeZipFile) as error:
        if owns_output and output_path.exists():
            output_path.unlink()
        raise AdapterError(f"Cannot build Catalog update archive: {error}") from error
    finally:
        if owns_temporary and temporary.exists():
            temporary.unlink()

    return {
        "status": "passed",
        "output": str(output_path),
        "dataset_id": release_report["dataset_id"],
        "catalog_schema_version": release_report["catalog_schema_version"],
        "data_version": release_report["catalog_data_version"],
        "snapshot_id": release_report["snapshot_id"],
        "archive_format": "zip",
        "archive_bytes": archive_bytes,
        "archive_sha256": archive_sha256,
        "entries": list(_ARCHIVE_ENTRIES),
    }


def build_remote_manifest_payload(
    release: Path,
    archive_path: Path,
    output_path: Path,
    *,
    package_url: str,
    release_sequence: int,
    minimum_app_version: str,
    published_at_utc: str,
    repository_root: Path,
) -> dict[str, Any]:
    """Build canonical unsigned metadata for a validated complete-Catalog ZIP."""

    release = release.resolve()
    archive_path = archive_path.resolve()
    output_path = output_path.absolute()
    if output_path.suffix.lower() != ".json":
        raise AdapterError("Catalog manifest payload output must use the .json extension")
    _require_outside_repository(
        archive_path,
        repository_root,
        label="Catalog update archive",
    )
    _require_outside_repository(
        output_path,
        repository_root,
        label="Catalog manifest payload",
    )
    if output_path.exists() or output_path.is_symlink():
        raise AdapterError(f"Catalog manifest payload already exists: {output_path}")
    if (
        not isinstance(release_sequence, int)
        or isinstance(release_sequence, bool)
        or release_sequence < 1
    ):
        raise AdapterError("Catalog release sequence must be a positive integer")
    if _VERSION_PATTERN.fullmatch(minimum_app_version) is None:
        raise AdapterError("Catalog minimum App version is invalid")
    if _UTC_PATTERN.fullmatch(published_at_utc) is None:
        raise AdapterError("Catalog publication time must use canonical UTC seconds")
    try:
        datetime.strptime(published_at_utc, "%Y-%m-%dT%H:%M:%SZ")
    except ValueError as error:
        raise AdapterError("Catalog publication time is not a real UTC date") from error
    try:
        release_report = check_release(release, root=repository_root.resolve())
    except (OSError, ReleaseCheckError) as error:
        raise AdapterError(
            f"Catalog release is not eligible for manifest creation: {error}"
        ) from error
    if release_report["catalog_data_version"] < 2:
        raise AdapterError(
            "A remote Catalog payload must advance the bundled base data version"
        )
    _validate_package_url(
        package_url,
        data_version=release_report["catalog_data_version"],
    )
    if not archive_path.is_file() or archive_path.is_symlink():
        raise AdapterError("The complete Catalog update archive is missing or unsafe")
    try:
        _validate_written_archive(archive_path, release)
        manifest = json.loads(
            (release / "assets/catalog/bundled_catalog.json").read_text(
                encoding="utf-8"
            )
        )
    except (OSError, UnicodeError, json.JSONDecodeError, zipfile.BadZipFile) as error:
        raise AdapterError(f"Cannot validate the complete Catalog archive: {error}") from error

    payload: dict[str, Any] = {
        "catalog_schema_version": release_report["catalog_schema_version"],
        "coverage": manifest["coverage"],
        "data_version": release_report["catalog_data_version"],
        "dataset_id": release_report["dataset_id"],
        "minimum_app_version": minimum_app_version,
        "minimum_protocol_version": 1,
        "package": {
            "archive_bytes": archive_path.stat().st_size,
            "archive_format": "zip",
            "archive_sha256": _sha256(archive_path),
            "kind": "complete_catalog",
            "url": package_url,
        },
        "protocol_version": 1,
        "published_at_utc": published_at_utc,
        "release_sequence": release_sequence,
        "snapshot_id": release_report["snapshot_id"],
    }
    payload_bytes = json.dumps(
        payload,
        ensure_ascii=False,
        allow_nan=False,
        separators=(",", ":"),
        sort_keys=True,
    ).encode("utf-8")
    if len(payload_bytes) > 64 * 1024:
        raise AdapterError("Catalog manifest payload exceeds its size limit")
    _write_new_bytes(output_path, payload_bytes)
    return {
        "status": "passed",
        "output": str(output_path),
        "dataset_id": payload["dataset_id"],
        "catalog_schema_version": payload["catalog_schema_version"],
        "data_version": payload["data_version"],
        "release_sequence": release_sequence,
        "payload_bytes": len(payload_bytes),
        "payload_sha256": hashlib.sha256(payload_bytes).hexdigest(),
        "package_url": package_url,
        "archive_bytes": payload["package"]["archive_bytes"],
        "archive_sha256": payload["package"]["archive_sha256"],
    }


def _validate_package_url(value: str, *, data_version: int) -> None:
    try:
        parsed = urlsplit(value)
        port = parsed.port
    except ValueError as error:
        raise AdapterError("Catalog package URL is invalid") from error
    decoded_segments = [unquote(segment) for segment in parsed.path.split("/")]
    release_match = _GITHUB_RELEASE_PACKAGE_PATTERN.fullmatch(parsed.path)
    if (
        parsed.scheme != "https"
        or parsed.hostname != "github.com"
        or parsed.username is not None
        or parsed.password is not None
        or port not in (None, 443)
        or parsed.query
        or parsed.fragment
        or any(segment in {".", ".."} for segment in decoded_segments)
        or release_match is None
        or int(release_match.group(1)) != data_version
        or int(release_match.group(2)) != data_version
    ):
        raise AdapterError("Catalog package URL violates the GitHub Release contract")


def _write_new_bytes(path: Path, content: bytes) -> None:
    if path.exists() or path.is_symlink():
        raise AdapterError(f"Output already exists: {path}")
    path.parent.mkdir(parents=True, exist_ok=True)
    descriptor, temporary_name = tempfile.mkstemp(
        prefix=f".{path.name}.",
        suffix=".tmp",
        dir=path.parent,
    )
    temporary = Path(temporary_name)
    owns_temporary = True
    try:
        with os.fdopen(descriptor, "wb") as output:
            output.write(content)
            output.flush()
            os.fsync(output.fileno())
        try:
            os.link(temporary, path)
        except FileExistsError as error:
            raise AdapterError(f"Output already exists: {path}") from error
        temporary.unlink()
        owns_temporary = False
    except OSError as error:
        raise AdapterError(f"Cannot write output {path}: {error}") from error
    finally:
        if owns_temporary and temporary.exists():
            temporary.unlink()
