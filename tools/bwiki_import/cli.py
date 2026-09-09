from __future__ import annotations

import argparse
import json
from pathlib import Path
import sys

from .errors import ImportToolError
from .rendered_snapshot import import_rendered_index_response
from .snapshot_store import import_local_snapshot


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
