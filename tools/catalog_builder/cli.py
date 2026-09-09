from __future__ import annotations

import argparse
import json
from pathlib import Path
import sys

from .errors import CatalogToolError
from .inspection import write_inspection_report


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
