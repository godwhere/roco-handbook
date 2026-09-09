from pathlib import Path
import sqlite3
import unittest


ROOT = Path(__file__).resolve().parents[2]

CATALOG_TABLES = {
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
    "evolution_groups",
    "pet_evolution_groups",
    "evolution_edges",
    "entity_sources",
}
CATALOG_VIEWS = {"pet_skill_sources", "pet_feature_skills"}
USER_TABLES = {
    "user_meta",
    "favorites",
    "collection_marks",
    "notes",
    "settings",
}


def open_schema(relative_path: str) -> sqlite3.Connection:
    connection = sqlite3.connect(":memory:")
    sql = (ROOT / relative_path).read_text(encoding="utf-8")
    connection.executescript(sql)
    return connection


def object_names(connection: sqlite3.Connection, object_type: str) -> set[str]:
    rows = connection.execute(
        "SELECT name FROM sqlite_master WHERE type = ? AND name NOT LIKE 'sqlite_%'",
        (object_type,),
    ).fetchall()
    return {row[0] for row in rows}


class CatalogSchemaTests(unittest.TestCase):
    def setUp(self) -> None:
        self.db = open_schema("schemas/catalog_v1.sql")

    def tearDown(self) -> None:
        self.db.close()

    def test_catalog_contract_shape(self) -> None:
        self.assertEqual(1, self.db.execute("PRAGMA user_version").fetchone()[0])
        self.assertEqual(CATALOG_TABLES, object_names(self.db, "table"))
        self.assertEqual(CATALOG_VIEWS, object_names(self.db, "view"))

    def test_catalog_integrity_and_foreign_keys(self) -> None:
        self.assertEqual([("ok",)], self.db.execute("PRAGMA integrity_check").fetchall())
        self.assertEqual([], self.db.execute("PRAGMA foreign_key_check").fetchall())
        self.assertEqual(1, self.db.execute("PRAGMA foreign_keys").fetchone()[0])

    def test_negative_stat_is_rejected(self) -> None:
        with self.assertRaises(sqlite3.IntegrityError):
            self.db.execute(
                "INSERT INTO pets (pet_id, name, title, hp) VALUES (?, ?, ?, ?)",
                ("pet_test", "Test Pet", "Test Title", -1),
            )

    def test_missing_skill_reference_is_rejected(self) -> None:
        with self.assertRaises(sqlite3.IntegrityError):
            self.db.execute(
                "INSERT INTO pets (pet_id, name, title, feature_skill_id) "
                "VALUES (?, ?, ?, ?)",
                ("pet_test", "Test Pet", "Test Title", "skill_missing"),
            )


class UserSchemaTests(unittest.TestCase):
    def setUp(self) -> None:
        self.db = open_schema("schemas/user_v1.sql")

    def tearDown(self) -> None:
        self.db.close()

    def test_user_contract_shape(self) -> None:
        self.assertEqual(1, self.db.execute("PRAGMA user_version").fetchone()[0])
        self.assertEqual(USER_TABLES, object_names(self.db, "table"))
        self.assertEqual(set(), object_names(self.db, "view"))

    def test_invalid_favorite_object_type_is_rejected(self) -> None:
        with self.assertRaises(sqlite3.IntegrityError):
            self.db.execute(
                "INSERT INTO favorites "
                "(dataset_id, object_type, object_id, name_snapshot, created_at_utc) "
                "VALUES (?, ?, ?, ?, ?)",
                ("roco-world-zh-cn", "unknown", "x", "Test", "2026-09-09T00:00:00Z"),
            )

    def test_personal_rows_do_not_require_catalog_foreign_keys(self) -> None:
        self.db.execute(
            "INSERT INTO notes "
            "(note_id, dataset_id, object_type, object_id, name_snapshot, content, "
            "created_at_utc, updated_at_utc) VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
            (
                "note-1",
                "roco-world-zh-cn",
                "pet",
                "pet_retired",
                "Retired object",
                "Keep personal notes",
                "2026-09-09T00:00:00Z",
                "2026-09-09T00:00:00Z",
            ),
        )
        self.assertEqual(1, self.db.execute("SELECT count(*) FROM notes").fetchone()[0])


if __name__ == "__main__":
    unittest.main()
