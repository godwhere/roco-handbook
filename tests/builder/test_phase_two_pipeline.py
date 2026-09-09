import copy
import hashlib
import json
from pathlib import Path
import sqlite3
import tempfile
import unittest

from catalog_builder.differ import diff_against_previous_catalog
from catalog_builder.errors import AdapterError
from catalog_builder.identity_resolver import (
    audit_identity_registry,
    initialize_identity_registry,
)
from catalog_builder.package_writer import (
    build_release_package,
    read_normalized_catalog,
)
from catalog_builder.validator import validate_normalized_catalog


ROOT = Path(__file__).resolve().parents[2]
NORMALIZED_PATH = (
    ROOT
    / "data"
    / "normalized"
    / "snapshot-19235f9b9b34dc4e"
    / "catalog-v1.json"
)
RELEASE_ROOT = ROOT / "data" / "release" / "1"
DATABASE_PATH = RELEASE_ROOT / "assets" / "catalog" / "catalog.db"


class PhaseTwoValidationTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.normalized = read_normalized_catalog(NORMALIZED_PATH)

    def test_normalized_catalog_passes_with_declared_warnings(self) -> None:
        result = validate_normalized_catalog(
            self.normalized,
            reviewed_exceptions_path=ROOT / "config" / "reviewed_exceptions.json",
        )
        self.assertEqual("passed_with_warnings", result["status"])
        self.assertEqual([], result["blocking_issues"])
        self.assertEqual(6, result["counts"]["legendary_skill_sources"])
        self.assertEqual(
            "evolution-member-types-core-43006-evolution-42851",
            result["reviewed_evolution_type_exception_id"],
        )

    def test_unreviewed_evolution_type_differences_are_blocking(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            exceptions = Path(temporary) / "exceptions.json"
            exceptions.write_text('{"exceptions": []}\n', encoding="utf-8")
            result = validate_normalized_catalog(
                self.normalized,
                reviewed_exceptions_path=exceptions,
            )
        self.assertIn(
            "unreviewed_evolution_type_mismatches",
            {item["code"] for item in result["blocking_issues"]},
        )

    def test_invalid_default_handbook_pet_is_blocking(self) -> None:
        changed = copy.deepcopy(self.normalized)
        changed["handbook_display"][0]["default_pet_id"] = "pet_missing"
        result = validate_normalized_catalog(
            changed,
            reviewed_exceptions_path=ROOT / "config" / "reviewed_exceptions.json",
        )
        self.assertIn(
            "invalid_handbook_display",
            {item["code"] for item in result["blocking_issues"]},
        )

    def test_current_identity_registry_is_complete(self) -> None:
        result = audit_identity_registry(
            ROOT / "config" / "identity_registry.json",
            self.normalized,
        )
        self.assertEqual("passed", result["status"])
        self.assertEqual(1826, result["mapping_count"])
        self.assertEqual(0, result["unreviewed_removal_count"])


class IdentityInitializationTests(unittest.TestCase):
    def test_initialization_is_explicit_and_detects_later_removal(self) -> None:
        normalized = {
            "dataset_id": "roco-world-zh-cn",
            "source_revisions": [
                {"source_key": "core", "revision_id": 1},
                {"source_key": "handbook", "revision_id": 2},
                {"source_key": "skill_catalog", "revision_id": 3},
            ],
            "pets": [
                {
                    "pet_id": "pet_000001",
                    "name": "Alpha",
                    "title": "Alpha",
                    "handbook_id": "handbook_000001",
                    "form": None,
                    "stage": 1,
                }
            ],
            "handbook_entries": [
                {
                    "handbook_id": "handbook_000001",
                    "dex_no": "001",
                    "display_name": "Alpha",
                }
            ],
            "skills": [
                {
                    "skill_id": "skill_000001",
                    "upstream_numeric_id": 1,
                    "name": "Pulse",
                    "category": "Feature",
                }
            ],
        }
        with tempfile.TemporaryDirectory() as temporary:
            registry = Path(temporary) / "identity.json"
            registry.write_text(
                json.dumps(
                    {
                        "registry_version": 1,
                        "dataset_id": "roco-world-zh-cn",
                        "mappings": [],
                    }
                ),
                encoding="utf-8",
            )
            self.assertEqual(3, initialize_identity_registry(registry, normalized))
            self.assertEqual("passed", audit_identity_registry(registry, normalized)["status"])
            with self.assertRaisesRegex(AdapterError, "already initialized"):
                initialize_identity_registry(registry, normalized)
            removed = copy.deepcopy(normalized)
            removed["skills"] = []
            audit = audit_identity_registry(registry, removed)
        self.assertIn(
            "identity_removal_candidates",
            {item["code"] for item in audit["blocking_issues"]},
        )

    def test_unreviewed_fingerprint_change_is_blocking(self) -> None:
        normalized = read_normalized_catalog(NORMALIZED_PATH)
        changed = copy.deepcopy(normalized)
        changed["pets"][0]["name"] = "Changed identity fingerprint"
        audit = audit_identity_registry(
            ROOT / "config" / "identity_registry.json",
            changed,
        )
        self.assertEqual("blocked", audit["status"])
        self.assertIn(
            "identity_fingerprint_changes",
            {item["code"] for item in audit["blocking_issues"]},
        )


class ReleasePackageTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.normalized = read_normalized_catalog(NORMALIZED_PATH)

    def test_tracked_release_matches_manifest_and_database_contract(self) -> None:
        manifest = json.loads(
            (RELEASE_ROOT / "assets" / "catalog" / "bundled_catalog.json").read_text(
                encoding="utf-8"
            )
        )
        database_bytes = DATABASE_PATH.read_bytes()
        self.assertEqual(len(database_bytes), manifest["database_bytes"])
        self.assertEqual(
            hashlib.sha256(database_bytes).hexdigest(),
            manifest["database_sha256"],
        )
        connection = sqlite3.connect(f"file:{DATABASE_PATH.resolve()}?mode=ro", uri=True)
        try:
            self.assertEqual([("ok",)], connection.execute("PRAGMA integrity_check").fetchall())
            self.assertEqual([], connection.execute("PRAGMA foreign_key_check").fetchall())
            with self.assertRaisesRegex(sqlite3.OperationalError, "readonly"):
                connection.execute("DELETE FROM pets")
            self.assertEqual(596, connection.execute("SELECT count(*) FROM pets").fetchone()[0])
            self.assertEqual(
                6,
                connection.execute(
                    "SELECT count(*) FROM learnset_legendary_skills"
                ).fetchone()[0],
            )
            sample = connection.execute(
                "SELECT p.handbook_id, h.dex_no, f.skill_id "
                "FROM pets p JOIN handbook_entries h USING (handbook_id) "
                "JOIN pet_feature_skills f USING (pet_id) WHERE p.pet_id = ?",
                ("pet_000007",),
            ).fetchone()
            self.assertEqual(("handbook_000004", "004", "skill_000003"), sample)
        finally:
            connection.close()

    def test_difference_against_identical_release_has_no_change(self) -> None:
        result = diff_against_previous_catalog(self.normalized, DATABASE_PATH)
        self.assertEqual({}, result["additions"])
        self.assertEqual({}, result["removals"])
        self.assertEqual(0, result["unreviewed_removal_count"])

    def test_release_builder_is_end_to_end_and_never_overwrites_version(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            output = Path(temporary) / "release"
            built = build_release_package(
                self.normalized,
                schema_path=ROOT / "schemas" / "catalog_v1.sql",
                manifest_schema_path=(
                    ROOT / "schemas" / "manifests" / "bundled_catalog_v1.schema.json"
                ),
                identity_registry_path=ROOT / "config" / "identity_registry.json",
                reviewed_exceptions_path=ROOT / "config" / "reviewed_exceptions.json",
                output_root=output,
            )
            self.assertTrue((built / "assets" / "catalog" / "catalog.db").is_file())
            with self.assertRaisesRegex(AdapterError, "already exists"):
                build_release_package(
                    self.normalized,
                    schema_path=ROOT / "schemas" / "catalog_v1.sql",
                    manifest_schema_path=(
                        ROOT
                        / "schemas"
                        / "manifests"
                        / "bundled_catalog_v1.schema.json"
                    ),
                    identity_registry_path=ROOT / "config" / "identity_registry.json",
                    reviewed_exceptions_path=(
                        ROOT / "config" / "reviewed_exceptions.json"
                    ),
                    output_root=output,
                )


if __name__ == "__main__":
    unittest.main()
