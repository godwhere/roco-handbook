from contextlib import closing
import hashlib
import json
from pathlib import Path
import shutil
import sqlite3
import tempfile
import unittest

from catalog_builder.errors import AdapterError
from catalog_builder.nrc_normalizer import normalize_nrc_snapshot
from catalog_builder.validator import validate_normalized_catalog


ROOT = Path(__file__).resolve().parents[2]
FIXTURE = ROOT / "tests/builder/fixtures/nrc"
NORMALIZED = (
    ROOT / "data/normalized/snapshot-dad7cd7d5ce73236/catalog-v2.json"
)


class NrcNormalizationTests(unittest.TestCase):
    def setUp(self) -> None:
        temporary = tempfile.TemporaryDirectory(prefix="roco-nrc-fixture-")
        self.addCleanup(temporary.cleanup)
        self.snapshot = Path(temporary.name) / "nrc-fixture"
        shutil.copytree(FIXTURE, self.snapshot)
        self.lock = {
            "snapshot_id": self.snapshot.name,
            "dataset_id": "roco-world-zh-cn",
            "source_system": "bwiki.nrc",
            "api_endpoint": "https://wiki.example.test/api.php",
            "imported_at_utc": "2026-10-15T00:00:00Z",
            "sources": [],
        }
        for ordinal, path in enumerate(sorted(self.snapshot.glob("*.lua")), start=1):
            content = path.read_bytes()
            self.lock["sources"].append(
                {
                    "source_key": path.stem,
                    "content_file": path.name,
                    "page_id": ordinal,
                    "revision_id": 100 + ordinal,
                    "requested_title": f"Module:Fixture/{path.stem}",
                    "canonical_title": f"Module:Fixture/{path.stem}",
                    "content_bytes": len(content),
                    "api_sha1": hashlib.sha1(content).hexdigest(),
                    "content_sha256": hashlib.sha256(content).hexdigest(),
                }
            )
        self.lock_path = self.snapshot / "sources.lock.json"
        self.lock_path.write_text(json.dumps(self.lock), encoding="utf-8")

    def normalize(self, previous_catalog=None) -> dict:
        return normalize_nrc_snapshot(
            self.snapshot,
            type_aliases_path=ROOT / "config/type_aliases.json",
            previous_catalog_path=previous_catalog or ROOT / "data/release/1/assets/catalog/catalog.db",
            data_version=2,
            built_at_utc="2026-10-15T00:00:00Z",
        )

    def test_owned_snapshot_normalizes_deterministically(self) -> None:
        rebuilt = self.normalize()
        self.lock["sources"].reverse()
        self.lock_path.write_text(json.dumps(self.lock), encoding="utf-8")
        self.assertEqual(rebuilt, self.normalize())
        self.assertEqual(8, len(rebuilt["source_revisions"]))
        self.assertEqual(
            {"pet_id": "pet_000598", "number": "454"},
            rebuilt["inspection_summary"]["sample_mappings"]["s4_creature"],
        )
        self.assertEqual(
            [{
                "handbook_id": "handbook_000454",
                "default_pet_id": "pet_000598",
                "selection_reason": "nrc_handbook_order",
            }],
            rebuilt["handbook_display"],
        )
        self.assertEqual(
            [
                {"pet_id": pet_id, "learnset_id": "learnset_000000000001"}
                for pet_id in ("pet_000598", "pet_999001")
            ],
            rebuilt["pet_learnsets"],
        )
        self.assertEqual(
            [
                {"learnset_id": "learnset_000000000001", "ordinal": 0,
                 "skill_id": "skill_000002", "learn_level": 5, "source_stage": 1},
                {"learnset_id": "learnset_000000000001", "ordinal": 1,
                 "skill_id": "skill_000002", "learn_level": 10, "source_stage": 2},
            ],
            rebuilt["learnset_native_skills"],
        )
        self.assertEqual("\u866b", rebuilt["learnset_blood_skills"][0]["blood_raw"])
        self.assertEqual(12, rebuilt["learnset_blood_skills"][0]["learn_level"])
        self.assertEqual("skill_000002", rebuilt["learnset_skill_stones"][0]["skill_id"])
        self.assertEqual(
            "Fixture condition", rebuilt["learnset_legendary_skills"][0]["requirement_text"]
        )
        self.assertEqual("Level condition", rebuilt["evolution_edges"][0]["condition_text"])
        validation = validate_normalized_catalog(
            rebuilt, reviewed_exceptions_path=ROOT / "config/reviewed_exceptions.json"
        )
        self.assertEqual([], validation["blocking_issues"])

    def test_missing_required_module_is_rejected(self) -> None:
        self.lock["sources"] = [
            source for source in self.lock["sources"] if source["source_key"] != "core"
        ]
        self.lock_path.write_text(json.dumps(self.lock), encoding="utf-8")
        with self.assertRaisesRegex(AdapterError, "NRC snapshot is incomplete: core"):
            self.normalize()

    def test_missing_module_content_is_rejected(self) -> None:
        (self.snapshot / "core.lua").unlink()
        with self.assertRaisesRegex(AdapterError, "Cannot read NRC module core"):
            self.normalize()

    def test_nrc_refresh_preserves_existing_local_illustration_aliases(self) -> None:
        previous = ROOT / "data/release/2/assets/catalog/catalog.db"
        rebuilt = self.normalize(previous)
        pet = next(row for row in rebuilt["pets"] if row["pet_id"] == "pet_000598")
        with closing(sqlite3.connect(f"file:{previous}?mode=ro", uri=True)) as connection:
            expected = connection.execute(
                "SELECT illustration_key FROM pets WHERE pet_id = 'pet_000598'"
            ).fetchone()[0]
        self.assertEqual(expected, pet["illustration_key"])
        self.assertEqual(3542, pet["extra_json"]["game_id"])
        self.assertEqual([], rebuilt["inspection_summary"]["warnings"])

    def test_invalid_explicit_game_id_cannot_fall_back_to_head_filename(self) -> None:
        previous = self.snapshot / "previous.db"
        with closing(sqlite3.connect(previous)) as connection:
            connection.execute(
                "CREATE TABLE pets (head_key TEXT, illustration_key TEXT, extra_json TEXT, status TEXT)"
            )
            connection.execute(
                "INSERT INTO pets VALUES (?, ?, ?, 'active')",
                ("Head_3542", "RetainedImage", json.dumps({"game_id": True})),
            )
            connection.commit()
        with self.assertRaisesRegex(AdapterError, "invalid image alias record"):
            self.normalize(previous)


class NrcPipelineTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.normalized = json.loads(NORMALIZED.read_text(encoding="utf-8"))

    def test_current_snapshot_has_closed_references_and_s4_sample(self) -> None:
        validation = validate_normalized_catalog(
            self.normalized,
            reviewed_exceptions_path=ROOT / "config/reviewed_exceptions.json",
        )
        self.assertEqual("passed_with_warnings", validation["status"])
        self.assertEqual(621, validation["counts"]["pets"])
        self.assertEqual(824, validation["counts"]["skills"])
        unfinished = next(
            pet
            for pet in self.normalized["pets"]
            if pet["name"] == "\u672a\u5b8c\u866b"
        )
        self.assertEqual("pet_000598", unfinished["pet_id"])
        self.assertEqual("4", unfinished["belong_season_raw"])
        self.assertEqual(1, unfinished["has_shiny"])


if __name__ == "__main__":
    unittest.main()
