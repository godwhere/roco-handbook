from __future__ import annotations

import hashlib
import json
import os
from pathlib import Path
import sqlite3
import tempfile
from typing import Any, Iterable

from .errors import AdapterError


def _json_text(value: Any) -> str:
    return json.dumps(value, ensure_ascii=False, sort_keys=True, separators=(",", ":"))


def _insert_rows(
    connection: sqlite3.Connection,
    table: str,
    columns: tuple[str, ...],
    rows: Iterable[dict[str, Any]],
    *,
    json_columns: set[str] | None = None,
) -> int:
    json_columns = json_columns or set()
    placeholders = ", ".join("?" for _ in columns)
    sql = f"INSERT INTO {table} ({', '.join(columns)}) VALUES ({placeholders})"
    values = []
    for row in rows:
        values.append(
            tuple(
                _json_text(row.get(column))
                if column in json_columns
                else row.get(column)
                for column in columns
            )
        )
    connection.executemany(sql, values)
    return len(values)


def write_catalog_database(
    normalized: dict[str, Any],
    *,
    schema_path: Path,
    output_path: Path,
) -> dict[str, Any]:
    if output_path.exists():
        raise AdapterError(f"Catalog database already exists: {output_path}")
    try:
        schema = schema_path.read_text(encoding="utf-8")
    except (OSError, UnicodeDecodeError) as error:
        raise AdapterError(f"Cannot read Catalog schema {schema_path}: {error}") from error

    output_path.parent.mkdir(parents=True, exist_ok=True)
    file_descriptor, temporary_name = tempfile.mkstemp(
        prefix=".catalog.",
        suffix=".db",
        dir=output_path.parent,
    )
    os.close(file_descriptor)
    temporary_path = Path(temporary_name)
    connection: sqlite3.Connection | None = None
    table_counts: dict[str, int] = {}
    try:
        connection = sqlite3.connect(temporary_path)
        connection.execute("PRAGMA foreign_keys = ON")
        connection.execute("PRAGMA journal_mode = DELETE")
        connection.executescript(schema)
        connection.execute("BEGIN")

        connection.execute(
            "INSERT INTO catalog_meta "
            "(singleton, dataset_id, schema_version, data_version, snapshot_id, "
            "adapter_version, builder_version, built_at_utc, coverage_json) "
            "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)",
            (
                1,
                normalized["dataset_id"],
                normalized["schema_version"],
                normalized["data_version"],
                normalized["snapshot_id"],
                normalized["adapter_version"],
                normalized["builder_version"],
                normalized["built_at_utc"],
                _json_text(normalized["coverage"]),
            ),
        )
        table_counts["catalog_meta"] = 1

        definitions = (
            (
                "source_revisions",
                (
                    "source_ref",
                    "source_key",
                    "source_name",
                    "requested_title",
                    "canonical_title",
                    "page_id",
                    "revision_id",
                    "revised_at_utc",
                    "fetched_at_utc",
                    "content_bytes",
                    "api_sha1",
                    "content_sha256",
                    "source_url",
                    "attribution_text",
                    "license_id",
                ),
                set(),
            ),
            (
                "handbook_entries",
                ("handbook_id", "dex_no", "display_name", "sort_order", "status"),
                set(),
            ),
            ("types", ("type_id", "name"), set()),
            (
                "skills",
                (
                    "skill_id",
                    "upstream_numeric_id",
                    "name",
                    "category",
                    "element_raw",
                    "type_id",
                    "description",
                    "energy_value",
                    "energy_text",
                    "power_value",
                    "power_text",
                    "target_text",
                    "icon_key",
                    "extra_json",
                    "status",
                ),
                {"extra_json"},
            ),
            (
                "skill_description_notes",
                ("skill_id", "ordinal", "note_id"),
                set(),
            ),
            (
                "pets",
                (
                    "pet_id",
                    "handbook_id",
                    "name",
                    "title",
                    "form",
                    "class_name",
                    "description",
                    "stage",
                    "belong_season_raw",
                    "starlight",
                    "review_gold",
                    "height_text",
                    "weight_text",
                    "can_double_ride",
                    "has_shiny",
                    "is_lord_evolution",
                    "hide_entry_name",
                    "show_topics",
                    "feature_skill_id",
                    "hp",
                    "atk",
                    "def",
                    "spa",
                    "spd",
                    "spe",
                    "illustration_key",
                    "head_key",
                    "extra_json",
                    "status",
                ),
                {"extra_json"},
            ),
            (
                "handbook_display",
                ("handbook_id", "default_pet_id", "selection_reason"),
                set(),
            ),
            ("pet_aliases", ("pet_id", "alias", "alias_kind"), set()),
            ("pet_types", ("pet_id", "slot", "type_id"), set()),
            ("learnsets", ("learnset_id", "feature_skill_id", "extra_json"), {"extra_json"}),
            ("pet_learnsets", ("pet_id", "learnset_id"), set()),
            (
                "learnset_native_skills",
                ("learnset_id", "ordinal", "skill_id", "learn_level", "source_stage"),
                set(),
            ),
            (
                "learnset_blood_skills",
                (
                    "learnset_id",
                    "ordinal",
                    "skill_id",
                    "blood_raw",
                    "blood_type_id",
                    "learn_level",
                ),
                set(),
            ),
            (
                "learnset_skill_stones",
                ("learnset_id", "ordinal", "skill_id"),
                set(),
            ),
            (
                "learnset_legendary_skills",
                ("learnset_id", "ordinal", "skill_id", "requirement_text"),
                set(),
            ),
            (
                "evolution_groups",
                ("evolution_group_id", "label", "status"),
                set(),
            ),
            (
                "pet_evolution_groups",
                ("evolution_group_id", "pet_id", "source_order"),
                set(),
            ),
            (
                "evolution_edges",
                (
                    "evolution_group_id",
                    "ordinal",
                    "from_pet_id",
                    "to_pet_id",
                    "method_code",
                    "level_requirement",
                    "condition_text",
                    "condition_json",
                ),
                {"condition_json"},
            ),
            (
                "entity_sources",
                ("entity_kind", "entity_id", "source_ref", "source_record_key"),
                set(),
            ),
        )
        for table, columns, json_columns in definitions:
            rows = normalized[table]
            if table == "evolution_edges":
                rows = [
                    {
                        **row,
                        "method_code": row["edge_kind"],
                        "condition_json": {},
                    }
                    for row in rows
                ]
            table_counts[table] = _insert_rows(
                connection,
                table,
                columns,
                rows,
                json_columns=json_columns,
            )

        connection.commit()
        integrity = connection.execute("PRAGMA integrity_check").fetchall()
        foreign_keys = connection.execute("PRAGMA foreign_key_check").fetchall()
        if integrity != [("ok",)] or foreign_keys:
            raise AdapterError(
                f"Catalog database validation failed: integrity={integrity!r}, "
                f"foreign_keys={foreign_keys!r}"
            )
        sample = connection.execute(
            "SELECT p.pet_id, p.handbook_id, h.dex_no, f.skill_id "
            "FROM pets p "
            "JOIN handbook_entries h ON h.handbook_id = p.handbook_id "
            "JOIN pet_feature_skills f ON f.pet_id = p.pet_id "
            "WHERE p.pet_id = ?",
            ("pet_000007",),
        ).fetchone()
        if sample != ("pet_000007", "handbook_000004", "004", "skill_000003"):
            raise AdapterError(f"Required Catalog sample query failed: {sample!r}")
        legendary_count = connection.execute(
            "SELECT count(*) FROM learnset_legendary_skills"
        ).fetchone()[0]
        if legendary_count != len(normalized["learnset_legendary_skills"]):
            raise AdapterError("Legendary skill source count changed during database build")
        connection.execute("VACUUM")
        connection.close()
        connection = None
        os.replace(temporary_path, output_path)
    except (OSError, sqlite3.Error) as error:
        raise AdapterError(f"Cannot build Catalog database: {error}") from error
    finally:
        if connection is not None:
            connection.close()
        if temporary_path.exists():
            temporary_path.unlink()

    raw = output_path.read_bytes()
    return {
        "database_path": str(output_path),
        "database_bytes": len(raw),
        "database_sha256": hashlib.sha256(raw).hexdigest(),
        "integrity_check": "ok",
        "foreign_key_check_count": 0,
        "table_counts": table_counts,
    }
