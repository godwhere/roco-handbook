from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import sqlite3
import sys
from typing import Any
from urllib.parse import quote


ROOT = Path(__file__).resolve().parents[2]

MANIFEST_FIELDS = {
    "manifest_version",
    "dataset_id",
    "catalog_schema_version",
    "data_version",
    "snapshot_id",
    "database_asset",
    "database_bytes",
    "database_sha256",
    "coverage",
}

COVERAGE_FIELDS = {
    "pets",
    "skills",
    "evolutions",
    "topic_rewards",
    "skill_stone_topics",
    "description_note_definitions",
}

REQUIRED_TABLES = {
    "catalog_meta",
    "source_revisions",
    "handbook_entries",
    "types",
    "skills",
    "skill_description_notes",
    "pets",
    "handbook_display",
    "pet_aliases",
    "pet_types",
    "learnsets",
    "pet_learnsets",
    "learnset_native_skills",
    "learnset_blood_skills",
    "learnset_skill_stones",
    "learnset_legendary_skills",
    "evolution_groups",
    "pet_evolution_groups",
    "evolution_edges",
    "entity_sources",
}

REQUIRED_VIEWS = {"pet_skill_sources", "pet_feature_skills"}

PLACEHOLDER_MARKERS = {
    "replace_with_actual",
    "example-snapshot",
    "fixture-only",
    "test-only-release",
}


class ReleaseCheckError(RuntimeError):
    """A release candidate failed a blocking offline check."""


def _read_json(path: Path) -> dict[str, Any]:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError) as error:
        raise ReleaseCheckError(f"Cannot read JSON file {path}: {error}") from error
    if not isinstance(value, dict):
        raise ReleaseCheckError(f"JSON file {path} must contain an object.")
    return value


def _sha256(path: Path) -> str:
    digest = hashlib.sha256()
    try:
        with path.open("rb") as source:
            for chunk in iter(lambda: source.read(1024 * 1024), b""):
                digest.update(chunk)
    except OSError as error:
        raise ReleaseCheckError(f"Cannot hash file {path}: {error}") from error
    return digest.hexdigest()


def _require_regular_file(path: Path) -> None:
    if not path.is_file() or path.is_symlink():
        raise ReleaseCheckError(f"Required release file is missing or unsafe: {path}")


def _validate_manifest(manifest: dict[str, Any], release: Path) -> None:
    if set(manifest) != MANIFEST_FIELDS:
        raise ReleaseCheckError("REL-002: Catalog manifest fields do not match version 1.")
    coverage = manifest.get("coverage")
    if (
        manifest.get("manifest_version") != 1
        or manifest.get("dataset_id") != "roco-world-zh-cn"
        or manifest.get("catalog_schema_version") != 1
        or not isinstance(manifest.get("data_version"), int)
        or manifest["data_version"] < 1
        or not isinstance(manifest.get("snapshot_id"), str)
        or not manifest["snapshot_id"]
        or manifest.get("database_asset") != "assets/catalog/catalog.db"
        or not isinstance(manifest.get("database_bytes"), int)
        or manifest["database_bytes"] < 1
        or not isinstance(manifest.get("database_sha256"), str)
        or len(manifest["database_sha256"]) != 64
        or any(character not in "0123456789abcdef" for character in manifest["database_sha256"])
        or not isinstance(coverage, dict)
        or set(coverage) != COVERAGE_FIELDS
        or any(not isinstance(value, bool) for value in coverage.values())
    ):
        raise ReleaseCheckError("REL-002: Catalog manifest contract is invalid.")
    if release.name != str(manifest["data_version"]):
        raise ReleaseCheckError("Catalog data version does not match its release directory.")
    if not all(coverage[key] for key in ("pets", "skills", "evolutions")):
        raise ReleaseCheckError("REL-003: Required Catalog coverage is not enabled.")


def _validate_text_artifacts(paths: list[Path]) -> None:
    for path in paths:
        try:
            text = path.read_text(encoding="utf-8")
        except (OSError, UnicodeError) as error:
            raise ReleaseCheckError(f"Cannot read release text file {path}: {error}") from error
        lowered = text.lower()
        marker = next(
            (value for value in PLACEHOLDER_MARKERS if value in lowered), None
        )
        if marker is not None:
            raise ReleaseCheckError(
                f"REL-002: Placeholder marker {marker!r} is present in {path}."
            )


def _open_read_only(database: Path) -> sqlite3.Connection:
    uri = f"file:{quote(str(database.resolve()))}?mode=ro&immutable=1"
    try:
        connection = sqlite3.connect(uri, uri=True)
    except sqlite3.Error as error:
        raise ReleaseCheckError(f"Cannot open Catalog read-only: {error}") from error
    connection.row_factory = sqlite3.Row
    connection.execute("PRAGMA foreign_keys = ON")
    connection.execute("PRAGMA query_only = ON")
    return connection


def _validate_database(
    database_path: Path,
    manifest: dict[str, Any],
    build_report: dict[str, Any],
    source_lock: dict[str, Any],
) -> dict[str, Any]:
    connection = _open_read_only(database_path)
    try:
        integrity = [row[0] for row in connection.execute("PRAGMA integrity_check")]
        if integrity != ["ok"]:
            raise ReleaseCheckError(f"REL-001: integrity_check failed: {integrity}")
        foreign_keys = list(connection.execute("PRAGMA foreign_key_check"))
        if foreign_keys:
            raise ReleaseCheckError("Catalog contains foreign-key violations.")
        if connection.execute("PRAGMA user_version").fetchone()[0] != 1:
            raise ReleaseCheckError("Catalog PRAGMA user_version is not 1.")

        tables = {
            row[0]
            for row in connection.execute(
                "SELECT name FROM sqlite_master WHERE type = 'table' "
                "AND name NOT LIKE 'sqlite_%'"
            )
        }
        views = {
            row[0]
            for row in connection.execute("SELECT name FROM sqlite_master WHERE type = 'view'")
        }
        if not REQUIRED_TABLES.issubset(tables) or not REQUIRED_VIEWS.issubset(views):
            raise ReleaseCheckError("Catalog is missing required tables or views.")

        metadata = connection.execute(
            "SELECT dataset_id, schema_version, data_version, snapshot_id, "
            "adapter_version, builder_version, coverage_json "
            "FROM catalog_meta WHERE singleton = 1"
        ).fetchall()
        if len(metadata) != 1:
            raise ReleaseCheckError("Catalog must contain exactly one metadata row.")
        metadata_row = metadata[0]
        if (
            metadata_row["dataset_id"] != manifest["dataset_id"]
            or metadata_row["schema_version"] != manifest["catalog_schema_version"]
            or metadata_row["data_version"] != manifest["data_version"]
            or metadata_row["snapshot_id"] != manifest["snapshot_id"]
            or json.loads(metadata_row["coverage_json"]) != manifest["coverage"]
            or not metadata_row["adapter_version"]
            or not metadata_row["builder_version"]
        ):
            raise ReleaseCheckError("Catalog metadata does not match the manifest.")

        probe = connection.execute(
            "SELECT h.dex_no, f.skill_id FROM pets p "
            "JOIN handbook_entries h ON h.handbook_id = p.handbook_id "
            "JOIN pet_feature_skills f ON f.pet_id = p.pet_id "
            "WHERE p.pet_id = ?",
            ("pet_000007",),
        ).fetchall()
        if len(probe) != 1 or tuple(probe[0]) != ("004", "skill_000003"):
            raise ReleaseCheckError("Catalog failed its stable release probe.")

        counts = {
            table: connection.execute(f'SELECT count(*) FROM "{table}"').fetchone()[0]
            for table in sorted(REQUIRED_TABLES)
        }
        reported_counts = build_report.get("database", {}).get("table_counts")
        if counts != reported_counts:
            raise ReleaseCheckError("Catalog table counts do not match the build report.")
        if counts["pets"] < 1 or counts["skills"] < 1 or counts["evolution_groups"] < 1:
            raise ReleaseCheckError("REL-003: Required Catalog coverage has no records.")

        database_sources = {
            (row["source_key"], row["revision_id"], row["content_sha256"])
            for row in connection.execute(
                "SELECT source_key, revision_id, content_sha256 FROM source_revisions"
            )
        }
        locked_sources = {
            (source["source_key"], source["revision_id"], source["content_sha256"])
            for source in source_lock.get("sources", [])
            if isinstance(source, dict)
        }
        if database_sources != locked_sources or not database_sources:
            raise ReleaseCheckError("Catalog source revisions do not match the source lock.")

        return {
            "integrity_check": "ok",
            "foreign_key_check_count": 0,
            "tables": sorted(tables),
            "views": sorted(views),
            "table_counts": counts,
            "source_revision_count": len(database_sources),
        }
    except (json.JSONDecodeError, KeyError, sqlite3.Error) as error:
        raise ReleaseCheckError(f"Catalog database validation failed: {error}") from error
    finally:
        connection.close()


def _validate_build_report(
    build_report: dict[str, Any], manifest: dict[str, Any]
) -> None:
    if build_report.get("status") not in {"passed", "passed_with_warnings"}:
        raise ReleaseCheckError("Build report status is not releasable.")
    if build_report.get("data_version") != manifest["data_version"]:
        raise ReleaseCheckError("Build report data version does not match the manifest.")
    if build_report.get("manifest") != manifest:
        raise ReleaseCheckError("Build report manifest does not match the packaged manifest.")
    if build_report.get("normalized_snapshot_id") != manifest["snapshot_id"]:
        raise ReleaseCheckError("Build report snapshot does not match the manifest.")
    database = build_report.get("database")
    identity = build_report.get("identity_audit", {})
    validation = build_report.get("validation", {})
    difference = build_report.get("difference", {})
    if not all(
        isinstance(value, dict)
        for value in (database, identity, validation, difference)
    ):
        raise ReleaseCheckError("Build report sections are invalid.")
    if identity.get("status") not in {"passed", "passed_with_warnings"}:
        raise ReleaseCheckError("Identity audit did not pass.")
    if validation.get("status") not in {"passed", "passed_with_warnings"}:
        raise ReleaseCheckError("Catalog validation did not pass.")
    if not isinstance(identity.get("blocking_issues"), list) or not isinstance(
        validation.get("blocking_issues"), list
    ):
        raise ReleaseCheckError("Build report blocking-issue lists are invalid.")
    if identity["blocking_issues"] or validation["blocking_issues"]:
        raise ReleaseCheckError("Release contains unresolved blocking issues.")
    if identity.get("unreviewed_removal_count") != 0:
        raise ReleaseCheckError("Release contains unreviewed identity removals.")
    if difference.get("unreviewed_removal_count") != 0:
        raise ReleaseCheckError("Release contains unreviewed Catalog removals.")
    disabled = {key for key, enabled in manifest["coverage"].items() if not enabled}
    warnings = validation.get("warnings")
    if not isinstance(warnings, list):
        raise ReleaseCheckError("Build report validation warnings are invalid.")
    warning_features = {
        feature
        for warning in warnings
        if isinstance(warning, dict) and warning.get("code") == "disabled_coverage"
        for feature in warning.get("features", [])
    }
    if disabled != warning_features:
        raise ReleaseCheckError(
            "REL-003: Disabled coverage does not match the validation warnings."
        )


def _validate_attribution(
    attribution_path: Path,
    source_lock: dict[str, Any],
) -> None:
    attribution = attribution_path.read_text(encoding="utf-8")
    required_statements = {
        "independent, non-commercial, unofficial",
        "Roco World BWIKI contributors",
        "CC BY-NC-SA 4.0",
        "https://creativecommons.org/licenses/by-nc-sa/4.0/",
        "validated, safely parsed, normalized",
    }
    missing = [statement for statement in required_statements if statement not in attribution]
    if missing:
        raise ReleaseCheckError(f"Catalog attribution is missing statements: {missing}")
    for source in source_lock.get("sources", []):
        revision = f"revision {source['revision_id']}"
        if source["source_key"] not in attribution or revision not in attribution:
            raise ReleaseCheckError(
                f"Catalog attribution is missing {source['source_key']} {revision}."
            )


def check_release(release: Path, *, root: Path = ROOT) -> dict[str, Any]:
    release = release.resolve()
    required = {
        "database": release / "assets/catalog/catalog.db",
        "manifest": release / "assets/catalog/bundled_catalog.json",
        "attribution": release / "assets/catalog/ATTRIBUTION.txt",
        "build_report": release / "build-report.json",
    }
    for path in required.values():
        _require_regular_file(path)

    sidecars = sorted(
        str(path.relative_to(release))
        for path in release.rglob("*")
        if path.is_file()
        and (
            path.name.endswith("-wal")
            or path.name.endswith("-shm")
            or path.name.endswith("-journal")
        )
    )
    if sidecars:
        raise ReleaseCheckError(f"REL-001: SQLite sidecar files are present: {sidecars}")

    _validate_text_artifacts(
        [required["manifest"], required["attribution"], required["build_report"]]
    )
    manifest = _read_json(required["manifest"])
    build_report = _read_json(required["build_report"])
    _validate_manifest(manifest, release)
    _validate_build_report(build_report, manifest)

    database_size = required["database"].stat().st_size
    database_sha256 = _sha256(required["database"])
    if (
        database_size != manifest["database_bytes"]
        or database_sha256 != manifest["database_sha256"]
        or build_report.get("database", {}).get("database_bytes") != database_size
        or build_report.get("database", {}).get("database_sha256") != database_sha256
    ):
        raise ReleaseCheckError("Catalog bytes or SHA-256 do not match release metadata.")

    source_lock_path = root / "data/raw" / manifest["snapshot_id"] / "sources.lock.json"
    _require_regular_file(source_lock_path)
    source_lock = _read_json(source_lock_path)
    sources = source_lock.get("sources")
    if (
        source_lock.get("dataset_id") != manifest["dataset_id"]
        or source_lock.get("snapshot_id") != manifest["snapshot_id"]
        or source_lock.get("missing_adapter_review_sources") != []
        or not isinstance(sources, list)
        or not sources
        or any(not isinstance(source, dict) for source in sources)
        or any(
            not isinstance(source.get("source_key"), str)
            or not isinstance(source.get("revision_id"), int)
            or not isinstance(source.get("content_sha256"), str)
            or len(source["content_sha256"]) != 64
            for source in sources
        )
    ):
        raise ReleaseCheckError("Source lock does not match the release manifest.")

    _validate_attribution(required["attribution"], source_lock)
    database_report = _validate_database(
        required["database"], manifest, build_report, source_lock
    )

    normalized_path = (
        root
        / "data/normalized"
        / manifest["snapshot_id"]
        / f"catalog-v{manifest['data_version']}.json"
    )
    _require_regular_file(normalized_path)

    try:
        release_label = str(release.relative_to(root.resolve()))
    except ValueError:
        release_label = str(release)

    return {
        "check_version": 1,
        "status": "passed",
        "release": release_label,
        "dataset_id": manifest["dataset_id"],
        "catalog_schema_version": manifest["catalog_schema_version"],
        "catalog_data_version": manifest["data_version"],
        "snapshot_id": manifest["snapshot_id"],
        "database_bytes": database_size,
        "database_sha256": database_sha256,
        "source_lock": str(source_lock_path.relative_to(root)),
        "source_lock_sha256": _sha256(source_lock_path),
        "normalized_catalog": str(normalized_path.relative_to(root)),
        "normalized_catalog_sha256": _sha256(normalized_path),
        "attribution_sha256": _sha256(required["attribution"]),
        "database": database_report,
    }


def _parse_args(argv: list[str] | None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Validate one immutable offline Catalog release."
    )
    parser.add_argument("--release", required=True, type=Path)
    parser.add_argument("--output", type=Path)
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = _parse_args(argv)
    try:
        report = check_release(args.release)
        rendered = f"{json.dumps(report, ensure_ascii=False, indent=2, sort_keys=True)}\n"
        if args.output is not None:
            args.output.parent.mkdir(parents=True, exist_ok=True)
            args.output.write_text(rendered, encoding="utf-8")
    except (OSError, ReleaseCheckError) as error:
        print(json.dumps({"status": "failed", "error": str(error)}), file=sys.stderr)
        return 1
    print(rendered, end="")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
