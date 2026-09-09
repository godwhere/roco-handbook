from __future__ import annotations

import argparse
from datetime import datetime, timezone
import json
from pathlib import Path
import sys

from .errors import CatalogToolError
from .identity_resolver import initialize_identity_registry
from .inspection import write_inspection_report
from .normalizer import normalize_snapshot
from .package_writer import (
    build_release_package,
    read_normalized_catalog,
    write_normalized_catalog,
)


def _parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(prog="catalog_builder")
    subparsers = parser.add_subparsers(dest="command", required=True)
    inspect = subparsers.add_parser(
        "inspect",
        help="Parse a frozen snapshot and write structure and reference reports.",
    )
    inspect.add_argument("--snapshot", type=Path, required=True)
    inspect.add_argument("--output", type=Path, required=True)
    inspect.add_argument("--display-overrides", type=Path)
    inspect.add_argument("--rendered-index-response", type=Path)

    normalize = subparsers.add_parser(
        "normalize",
        help="Normalize a validated snapshot into the Catalog V1 build contract.",
    )
    normalize.add_argument("--snapshot", type=Path, required=True)
    normalize.add_argument("--rendered-index-response", type=Path, required=True)
    normalize.add_argument("--display-overrides", type=Path, required=True)
    normalize.add_argument("--type-aliases", type=Path, required=True)
    normalize.add_argument("--data-version", type=int, required=True)
    normalize.add_argument("--built-at-utc")
    normalize.add_argument("--output", type=Path, required=True)

    identity = subparsers.add_parser(
        "initialize-identity",
        help="Initialize the first stable identity registry from normalized data.",
    )
    identity.add_argument("--normalized", type=Path, required=True)
    identity.add_argument("--registry", type=Path, required=True)

    release = subparsers.add_parser(
        "build-release",
        help="Build and verify a versioned SQLite Catalog package.",
    )
    release.add_argument("--normalized", type=Path, required=True)
    release.add_argument("--schema", type=Path, required=True)
    release.add_argument("--manifest-schema", type=Path, required=True)
    release.add_argument("--identity-registry", type=Path, required=True)
    release.add_argument("--reviewed-exceptions", type=Path, required=True)
    release.add_argument("--output", type=Path, required=True)
    release.add_argument("--previous-database", type=Path)
    return parser


def main(argv: list[str] | None = None) -> int:
    args = _parser().parse_args(argv)
    try:
        if args.command == "inspect":
            output = write_inspection_report(
                args.snapshot,
                args.output,
                display_overrides_path=args.display_overrides,
                rendered_index_response_path=args.rendered_index_response,
            )
            report = json.loads(
                (output / "structure-report.json").read_text(encoding="utf-8")
            )
            print(
                json.dumps(
                    {
                        "output": str(output),
                        "snapshot_id": report["snapshot_id"],
                        "status": report["status"],
                        "blocking_issue_count": len(report["blocking_issues"]),
                        "warning_count": len(report["warnings"]),
                    },
                    indent=2,
                    sort_keys=True,
                )
            )
            return 0 if not report["blocking_issues"] else 4
        if args.command == "normalize":
            built_at_utc = args.built_at_utc or datetime.now(timezone.utc).isoformat().replace(
                "+00:00", "Z"
            )
            normalized = normalize_snapshot(
                args.snapshot,
                rendered_index_response_path=args.rendered_index_response,
                display_overrides_path=args.display_overrides,
                type_aliases_path=args.type_aliases,
                data_version=args.data_version,
                built_at_utc=built_at_utc,
            )
            write_normalized_catalog(normalized, args.output)
            print(
                json.dumps(
                    {
                        "output": str(args.output),
                        "snapshot_id": normalized["snapshot_id"],
                        "data_version": normalized["data_version"],
                    },
                    indent=2,
                    sort_keys=True,
                )
            )
            return 0
        if args.command == "initialize-identity":
            normalized = read_normalized_catalog(args.normalized)
            count = initialize_identity_registry(args.registry, normalized)
            print(
                json.dumps(
                    {"registry": str(args.registry), "mapping_count": count},
                    indent=2,
                    sort_keys=True,
                )
            )
            return 0
        if args.command == "build-release":
            normalized = read_normalized_catalog(args.normalized)
            output = build_release_package(
                normalized,
                schema_path=args.schema,
                manifest_schema_path=args.manifest_schema,
                identity_registry_path=args.identity_registry,
                reviewed_exceptions_path=args.reviewed_exceptions,
                output_root=args.output,
                previous_database=args.previous_database,
            )
            report = json.loads((output / "build-report.json").read_text(encoding="utf-8"))
            print(
                json.dumps(
                    {
                        "output": str(output),
                        "status": report["status"],
                        "data_version": report["data_version"],
                        "database_sha256": report["manifest"]["database_sha256"],
                    },
                    indent=2,
                    sort_keys=True,
                )
            )
            return 0
    except CatalogToolError as error:
        print(
            json.dumps(
                {"error": error.error_code, "message": error.message},
                sort_keys=True,
            ),
            file=sys.stderr,
        )
        return error.exit_code
    return 1
