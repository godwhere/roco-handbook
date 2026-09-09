from __future__ import annotations

import argparse
import json
from pathlib import Path
import sys

from .errors import ImportToolError
from .image_assets import asset_preflight, import_image_assets
from .rendered_snapshot import import_rendered_index_response
from .snapshot_store import import_local_snapshot
from .type_relations import import_type_relations


def _parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(prog="bwiki_import")
    subparsers = parser.add_subparsers(dest="command", required=True)
    local = subparsers.add_parser(
        "import-local",
        help="Validate local MediaWiki responses and freeze an immutable snapshot.",
    )
    local.add_argument("--input-dir", type=Path, required=True)
    local.add_argument("--output", type=Path, required=True)
    local.add_argument("--config", type=Path, required=True)
    rendered = subparsers.add_parser(
        "import-rendered-index",
        help="Validate and freeze a rendered MediaWiki pet-index response.",
    )
    rendered.add_argument("--input", type=Path, required=True)
    rendered.add_argument("--output", type=Path, required=True)
    image_preflight = subparsers.add_parser(
        "preflight-image-assets",
        help="Validate Wiki image metadata and report the frozen asset scope.",
    )
    image_preflight.add_argument("--catalog", type=Path, required=True)
    image_preflight.add_argument("--config", type=Path, required=True)
    image_import = subparsers.add_parser(
        "import-image-assets",
        help="Validate, download, and freeze the offline Wiki image asset set.",
    )
    image_import.add_argument("--catalog", type=Path, required=True)
    image_import.add_argument("--config", type=Path, required=True)
    image_import.add_argument("--output", type=Path, required=True)
    image_import.add_argument("--cache", type=Path)
    type_relations = subparsers.add_parser(
        "import-type-relations",
        help="Validate and freeze the Wiki type relationship contract.",
    )
    type_relations.add_argument("--config", type=Path, required=True)
    type_relations.add_argument("--output", type=Path, required=True)
    return parser


def main(argv: list[str] | None = None) -> int:
    args = _parser().parse_args(argv)
    try:
        if args.command == "import-local":
            snapshot = import_local_snapshot(args.input_dir, args.output, args.config)
            print(
                json.dumps(
                    {
                        "snapshot_id": snapshot.snapshot_id,
                        "path": str(snapshot.path),
                        "source_keys": list(snapshot.source_keys),
                        "reused_existing": snapshot.reused_existing,
                    },
                    indent=2,
                    sort_keys=True,
                )
            )
            return 0
        if args.command == "import-rendered-index":
            snapshot = import_rendered_index_response(args.input, args.output)
            print(
                json.dumps(
                    {
                        "snapshot_id": snapshot.snapshot_id,
                        "path": str(snapshot.path),
                        "reused_existing": snapshot.reused_existing,
                    },
                    indent=2,
                    sort_keys=True,
                )
            )
            return 0
        if args.command == "preflight-image-assets":
            print(
                json.dumps(
                    asset_preflight(args.catalog, args.config),
                    indent=2,
                    sort_keys=True,
                )
            )
            return 0
        if args.command == "import-image-assets":
            frozen = import_image_assets(
                args.catalog,
                args.config,
                args.output,
                cache_root=args.cache,
            )
            print(
                json.dumps(
                    {
                        "asset_count": frozen.asset_count,
                        "manifest": str(frozen.manifest_path),
                        "path": str(frozen.path),
                        "reference_count": frozen.reference_count,
                        "reused_existing": frozen.reused_existing,
                        "total_bytes": frozen.total_bytes,
                    },
                    indent=2,
                    sort_keys=True,
                )
            )
            return 0
        if args.command == "import-type-relations":
            output = import_type_relations(args.config, args.output)
            print(json.dumps({"path": str(output)}, indent=2, sort_keys=True))
            return 0
    except ImportToolError as error:
        print(
            json.dumps(
                {"error": error.error_code, "message": error.message},
                sort_keys=True,
            ),
            file=sys.stderr,
        )
        return error.exit_code
    return 1
