"""Stage only the active offline assets for the native iOS application."""
from __future__ import annotations

import argparse
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "app/assets"
ACTIVE = (
    "brand/v1", "catalog", "database", "fonts/v1", "wiki/v4",
    "wiki/tools/v2", "wiki/type-relations-v1.json", "wiki/game-descriptions-v1.json",
    "wiki/activity-timeline-v1.json", "wiki/fashion-catalog-v1.json",
    "wiki/references/v1",
)


def stage(output: Path) -> None:
    if (ASSETS / "database/user_v1.sql").read_bytes() != (
        ROOT / "schemas/user_v1.sql"
    ).read_bytes():
        raise ValueError("The packaged personal schema differs from the normative SQL.")
    output.mkdir(parents=True, exist_ok=True)
    for relative in ACTIVE:
        source = ASSETS / relative
        if not source.exists() or source.is_symlink():
            raise ValueError(f"Missing or linked offline asset: {relative}")
        files = sorted(source.rglob("*")) if source.is_dir() else [source]
        for file in files:
            if file.is_symlink():
                raise ValueError("Offline assets must not contain symlinks.")
            if file.is_file():
                target = output / file.relative_to(ASSETS)
                target.parent.mkdir(parents=True, exist_ok=True)
                shutil.copyfile(file, target)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, required=True)
    stage(parser.parse_args().output)
