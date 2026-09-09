from __future__ import annotations

import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import sqlite3
import tempfile
from typing import Any

from .differ import diff_against_previous_catalog
from .errors import AdapterError, BuildBlockedError
from .identity_resolver import audit_identity_registry
from .sqlite_writer import write_catalog_database
from .validator import validate_normalized_catalog


def read_normalized_catalog(path: Path) -> dict[str, Any]:
    try:
        document = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeDecodeError, json.JSONDecodeError) as error:
        raise AdapterError(f"Cannot read normalized Catalog {path}: {error}") from error
    if not isinstance(document, dict) or document.get("normalized_version") != 1:
        raise AdapterError("Normalized Catalog version is not supported")
    return document


def write_normalized_catalog(normalized: dict[str, Any], output_path: Path) -> None:
    if output_path.exists():
        raise AdapterError(f"Normalized Catalog already exists: {output_path}")
    output_path.parent.mkdir(parents=True, exist_ok=True)
    try:
        output_path.write_text(
            json.dumps(normalized, ensure_ascii=False, indent=2, sort_keys=True) + "\n",
            encoding="utf-8",
        )
    except OSError as error:
        raise AdapterError(f"Cannot write normalized Catalog {output_path}: {error}") from error


def _validate_manifest(manifest: dict[str, Any], schema_path: Path) -> None:
    try:
        schema = json.loads(schema_path.read_text(encoding="utf-8"))
    except (OSError, UnicodeDecodeError, json.JSONDecodeError) as error:
        raise AdapterError(f"Cannot read manifest schema {schema_path}: {error}") from error
    required = set(schema.get("required", []))
    properties = schema.get("properties", {})
    if set(manifest) != set(properties) or required - set(manifest):
        raise AdapterError("Manifest fields do not match the normative schema")
    for key, definition in properties.items():
        if "const" in definition and manifest[key] != definition["const"]:
            raise AdapterError(f"Manifest field {key} does not match its constant")
        if definition.get("type") == "integer" and (
            not isinstance(manifest[key], int) or isinstance(manifest[key], bool)
        ):
            raise AdapterError(f"Manifest field {key} must be an integer")
        if definition.get("type") == "string" and not isinstance(manifest[key], str):
            raise AdapterError(f"Manifest field {key} must be a string")
        if "pattern" in definition and not re.fullmatch(definition["pattern"], manifest[key]):
            raise AdapterError(f"Manifest field {key} does not match its pattern")
    coverage_schema = properties["coverage"]
    coverage = manifest["coverage"]
    if not isinstance(coverage, dict) or set(coverage) != set(coverage_schema["properties"]):
        raise AdapterError("Manifest coverage fields do not match the normative schema")
    if not all(isinstance(value, bool) for value in coverage.values()):
        raise AdapterError("Manifest coverage values must be booleans")


def _attribution(normalized: dict[str, Any]) -> str:
    rendered_revision = normalized["inspection_summary"]["rendered_index_evidence"][
        "page_revision_id"
    ]
    lines = [
        "Roco World Offline Handbook - Catalog Attribution",
        "",
        "This is an independent, non-commercial, unofficial project.",
        "",
        "Source: Roco World BWIKI contributors",
        "License: CC BY-NC-SA 4.0",
        "License URL: https://creativecommons.org/licenses/by-nc-sa/4.0/",
        "",
        "Changes: MediaWiki data was validated, safely parsed, normalized,",
        "cross-referenced, and packaged into an offline SQLite Catalog.",
        "",
        "Frozen source revisions:",
    ]
    for source in normalized["source_revisions"]:
        lines.append(
            f"- {source['source_key']}: revision {source['revision_id']} - "
            f"{source['source_url']}"
        )
    lines.extend(
        [
            "",
            "Rendered handbook evidence:",
            f"- Page revision {rendered_revision} - "
            "https://wiki.biligame.com/rocom/%E7%B2%BE%E7%81%B5%E5%9B%BE%E9%89%B4",
            "",
        ]
    )
    return "\n".join(lines)


def build_release_package(
    normalized: dict[str, Any],
    *,
    schema_path: Path,
    manifest_schema_path: Path,
    identity_registry_path: Path,
    reviewed_exceptions_path: Path,
    output_root: Path,
    previous_database: Path | None = None,
) -> Path:
    validation = validate_normalized_catalog(
        normalized,
        reviewed_exceptions_path=reviewed_exceptions_path,
    )
    identity = audit_identity_registry(identity_registry_path, normalized)
    difference = diff_against_previous_catalog(normalized, previous_database)
    blocking = [
        *validation["blocking_issues"],
        *identity["blocking_issues"],
    ]
    if difference["unreviewed_removal_count"]:
        blocking.append(
            {
                "code": "unreviewed_catalog_removals",
                "count": difference["unreviewed_removal_count"],
            }
        )
    if blocking:
        raise BuildBlockedError(
            json.dumps({"blocking_issues": blocking}, sort_keys=True)
        )

    data_version = normalized["data_version"]
    target = output_root / str(data_version)
    if target.exists():
        raise AdapterError(f"Release data version already exists: {target}")
    output_root.mkdir(parents=True, exist_ok=True)
    stage = Path(tempfile.mkdtemp(prefix=f".release-{data_version}.", dir=output_root))
    try:
        assets = stage / "assets" / "catalog"
        assets.mkdir(parents=True)
        database = assets / "catalog.db"
        database_report = write_catalog_database(
            normalized,
            schema_path=schema_path,
            output_path=database,
        )
        database_report["database_path"] = "assets/catalog/catalog.db"
        manifest = {
            "manifest_version": 1,
            "dataset_id": normalized["dataset_id"],
            "catalog_schema_version": normalized["schema_version"],
            "data_version": data_version,
            "snapshot_id": normalized["snapshot_id"],
            "database_asset": "assets/catalog/catalog.db",
            "database_bytes": database_report["database_bytes"],
            "database_sha256": database_report["database_sha256"],
            "coverage": normalized["coverage"],
        }
        _validate_manifest(manifest, manifest_schema_path)
        manifest_path = assets / "bundled_catalog.json"
        manifest_path.write_text(
            json.dumps(manifest, indent=2, sort_keys=True) + "\n",
            encoding="utf-8",
        )
        (assets / "ATTRIBUTION.txt").write_text(
            _attribution(normalized),
            encoding="utf-8",
        )

        try:
            read_only = sqlite3.connect(f"file:{database.resolve()}?mode=ro", uri=True)
            meta = read_only.execute(
                "SELECT schema_version, data_version, snapshot_id FROM catalog_meta"
            ).fetchone()
            read_only.close()
        except sqlite3.Error as error:
            raise AdapterError(f"Cannot reopen built Catalog read-only: {error}") from error
        expected_meta = (
            normalized["schema_version"],
            data_version,
            normalized["snapshot_id"],
        )
        if meta != expected_meta:
            raise AdapterError(f"Built Catalog metadata mismatch: {meta!r}")
        actual_database_hash = hashlib.sha256(database.read_bytes()).hexdigest()
        if actual_database_hash != manifest["database_sha256"]:
            raise AdapterError("Built Catalog hash changed after manifest creation")

        report = {
            "status": "passed_with_warnings"
            if validation["warnings"]
            else "passed",
            "normalized_snapshot_id": normalized["snapshot_id"],
            "data_version": data_version,
            "validation": validation,
            "identity_audit": identity,
            "difference": difference,
            "database": database_report,
            "manifest": manifest,
        }
        (stage / "build-report.json").write_text(
            json.dumps(report, ensure_ascii=False, indent=2, sort_keys=True) + "\n",
            encoding="utf-8",
        )
        os.rename(stage, target)
    except OSError as error:
        raise AdapterError(f"Cannot write release package: {error}") from error
    finally:
        if stage.exists():
            shutil.rmtree(stage)
    return target
