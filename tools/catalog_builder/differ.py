from __future__ import annotations

from pathlib import Path
import sqlite3
from typing import Any

from .errors import AdapterError


_ENTITIES = {
    "pet": ("pets", "pet_id"),
    "handbook": ("handbook_entries", "handbook_id"),
    "skill": ("skills", "skill_id"),
    "learnset": ("learnsets", "learnset_id"),
    "evolution_group": ("evolution_groups", "evolution_group_id"),
}


def diff_against_previous_catalog(
    normalized: dict[str, Any],
    previous_database: Path | None,
) -> dict[str, Any]:
    if previous_database is None:
        return {
            "baseline": True,
            "previous_database": None,
            "additions": {},
            "removals": {},
            "unreviewed_removal_count": 0,
        }
    if not previous_database.is_file():
        raise AdapterError(f"Previous Catalog database does not exist: {previous_database}")

    current = {
        "pet": {row["pet_id"] for row in normalized["pets"]},
        "handbook": {
            row["handbook_id"] for row in normalized["handbook_entries"]
        },
        "skill": {row["skill_id"] for row in normalized["skills"]},
        "learnset": {row["learnset_id"] for row in normalized["learnsets"]},
        "evolution_group": {
            row["evolution_group_id"] for row in normalized["evolution_groups"]
        },
    }
    try:
        connection = sqlite3.connect(
            f"file:{previous_database.resolve()}?mode=ro",
            uri=True,
        )
        previous = {
            kind: {
                row[0]
                for row in connection.execute(f"SELECT {column} FROM {table}")
            }
            for kind, (table, column) in _ENTITIES.items()
        }
        previous_version = connection.execute(
            "SELECT data_version FROM catalog_meta WHERE singleton = 1"
        ).fetchone()
        connection.close()
    except sqlite3.Error as error:
        raise AdapterError(f"Cannot inspect previous Catalog database: {error}") from error

    additions = {
        kind: sorted(current[kind] - previous[kind])
        for kind in _ENTITIES
        if current[kind] - previous[kind]
    }
    removals = {
        kind: sorted(previous[kind] - current[kind])
        for kind in _ENTITIES
        if previous[kind] - current[kind]
    }
    return {
        "baseline": False,
        "previous_database": str(previous_database),
        "previous_data_version": previous_version[0] if previous_version else None,
        "additions": additions,
        "removals": removals,
        "unreviewed_removal_count": sum(len(items) for items in removals.values()),
    }
