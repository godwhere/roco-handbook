import copy
import hashlib
import json
from pathlib import Path
import sqlite3
import tempfile
import unittest

from catalog_builder.errors import AdapterError
from catalog_builder.nrc_identity import apply_reviewed_nrc_identities


class ReviewedNrcIdentityTests(unittest.TestCase):
    def setUp(self) -> None:
        temporary = tempfile.TemporaryDirectory(prefix="roco-nrc-identity-")
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name)
        self.previous = self.root / "previous.db"
        sqlite3.connect(self.previous).close()
        self.review_path = self.root / "review.json"
        self.review = {
            "config_version": 1,
            "dataset_id": "owned-fixture",
            "snapshot_id": "owned-snapshot",
            "previous_catalog_sha256": hashlib.sha256(self.previous.read_bytes()).hexdigest(),
            "mappings": {
                "skill": {"skill_000001": "skill_000002", "skill_000002": "skill_000001"},
                "learnset": {"learnset_000000000001": "learnset_000000000002"},
                "evolution_group": {"evolution_000000000001": "evolution_000000000002"},
            },
        }
        self.normalized = {
            "dataset_id": "owned-fixture",
            "snapshot_id": "owned-snapshot",
            "skills": [
                {"skill_id": value, "extra_json": {"raw_reference": value}}
                for value in ("skill_000001", "skill_000002")
            ],
            "skill_description_notes": [{"skill_id": "skill_000002", "note_id": "fixture-note"}],
            "pets": [{
                "pet_id": "pet_000001", "feature_skill_id": "skill_000001",
                "source_evolution_group_ids": ["evolution_000000000001"],
                "extra_json": {"raw_skill": "skill_000001"},
            }],
            "learnsets": [{"learnset_id": "learnset_000000000001", "feature_skill_id": "skill_000001"}],
            "pet_learnsets": [{"pet_id": "pet_000001", "learnset_id": "learnset_000000000001"}],
            "evolution_groups": [{"evolution_group_id": "evolution_000000000001"}],
            "pet_evolution_groups": [{"pet_id": "pet_000001", "evolution_group_id": "evolution_000000000001"}],
            "evolution_edges": [{
                "evolution_group_id": "evolution_000000000001",
                "from_pet_id": "pet_000001", "to_pet_id": "pet_000002",
                "condition_text": "Owned condition", "level_requirement": 26,
            }],
            "inspection_summary": {
                "evolution_type_mismatches": [{"evolution_group_id": "evolution_000000000001", "pet_id": "pet_000001"}],
            },
            "entity_sources": [
                {"entity_kind": kind, "entity_id": value, "source_record_key": value, "source_ref": "fixture:10:20"}
                for kind, value in (
                    ("skill", "skill_000001"), ("skill", "skill_000002"),
                    ("learnset", "learnset_000000000001"),
                    ("evolution_group", "evolution_000000000001"), ("pet", "pet_000001"),
                )
            ],
        }
        for table in (
            "learnset_native_skills", "learnset_blood_skills", "learnset_skill_stones", "learnset_legendary_skills",
        ):
            self.normalized[table] = [{
                "learnset_id": "learnset_000000000001", "skill_id": "skill_000002",
                "ordinal": 0, "raw_condition": "Owned condition",
            }]

    def apply(self, *, previous=True) -> None:
        self.review_path.write_text(json.dumps(self.review), encoding="utf-8")
        apply_reviewed_nrc_identities(
            self.normalized, self.review_path, self.previous if previous else None,
        )

    def test_remaps_all_typed_references_without_changing_raw_source_keys(self) -> None:
        before = copy.deepcopy(self.normalized)
        self.apply()
        self.assertEqual(
            ["skill_000002", "skill_000001"],
            [row["extra_json"]["raw_reference"] for row in self.normalized["skills"]],
        )
        self.assertEqual("skill_000001", self.normalized["skill_description_notes"][0]["skill_id"])
        self.assertEqual("skill_000002", self.normalized["pets"][0]["feature_skill_id"])
        self.assertEqual("skill_000002", self.normalized["learnsets"][0]["feature_skill_id"])
        self.assertEqual("learnset_000000000002", self.normalized["learnsets"][0]["learnset_id"])
        self.assertEqual("learnset_000000000002", self.normalized["pet_learnsets"][0]["learnset_id"])
        for table in (
            "learnset_native_skills", "learnset_blood_skills", "learnset_skill_stones", "learnset_legendary_skills",
        ):
            self.assertEqual({
                "learnset_id": "learnset_000000000002", "skill_id": "skill_000001",
                "ordinal": 0, "raw_condition": "Owned condition",
            }, self.normalized[table][0])
        for table in ("evolution_groups", "pet_evolution_groups", "evolution_edges"):
            self.assertEqual("evolution_000000000002", self.normalized[table][0]["evolution_group_id"])
        self.assertEqual(["evolution_000000000002"], self.normalized["pets"][0]["source_evolution_group_ids"])
        self.assertEqual("evolution_000000000002", self.normalized["inspection_summary"]["evolution_type_mismatches"][0]["evolution_group_id"])
        for old, new in zip(before["entity_sources"], self.normalized["entity_sources"]):
            mapping = self.review["mappings"].get(old["entity_kind"], {})
            self.assertEqual(mapping.get(old["entity_id"], old["entity_id"]), new["entity_id"])
            self.assertEqual(old["source_record_key"], new["source_record_key"])
            self.assertEqual(old["source_ref"], new["source_ref"])
        self.assertEqual(before["pets"][0]["extra_json"], self.normalized["pets"][0]["extra_json"])
        self.assertEqual("Owned condition", self.normalized["evolution_edges"][0]["condition_text"])
        recorded = self.normalized["inspection_summary"]["identity_review"]
        self.assertEqual(hashlib.sha256(self.review_path.read_bytes()).hexdigest(), recorded["review_sha256"])
        self.assertEqual({"skill": 2, "learnset": 1, "evolution_group": 1}, recorded["mapping_counts"])

    def test_stale_snapshot_dataset_or_previous_hash_is_rejected_before_mutation(self) -> None:
        original = copy.deepcopy(self.review)
        for field, value in (
            ("snapshot_id", "different-snapshot"), ("dataset_id", "different-dataset"),
            ("previous_catalog_sha256", "0" * 64), ("config_version", 2),
        ):
            with self.subTest(field=field):
                self.review = copy.deepcopy(original)
                self.review[field] = value
                before = copy.deepcopy(self.normalized)
                with self.assertRaisesRegex(AdapterError, "does not match"):
                    self.apply()
                self.assertEqual(before, self.normalized)

    def test_previous_catalog_is_required(self) -> None:
        with self.assertRaisesRegex(AdapterError, "does not match"):
            self.apply(previous=False)

    def test_colliding_mapping_including_unmapped_identity_is_rejected(self) -> None:
        self.review["mappings"]["skill"] = {"skill_000001": "skill_000002"}
        before = copy.deepcopy(self.normalized)
        with self.assertRaisesRegex(AdapterError, "merges distinct skill"):
            self.apply()
        self.assertEqual(before, self.normalized)

    def test_unknown_source_and_invalid_target_are_rejected(self) -> None:
        for mapping in ({"skill_000999": "skill_000001"}, {"skill_000001": "invalid"}, []):
            with self.subTest(mapping=mapping):
                self.review["mappings"]["skill"] = mapping
                before = copy.deepcopy(self.normalized)
                with self.assertRaisesRegex(AdapterError, "invalid skill mappings"):
                    self.apply()
                self.assertEqual(before, self.normalized)

    def test_missing_mapping_kind_is_rejected(self) -> None:
        del self.review["mappings"]["learnset"]
        with self.assertRaisesRegex(AdapterError, "requires skill, learnset, and evolution"):
            self.apply()


class NrcCatalogIdentityCompatibilityTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        root = Path(__file__).resolve().parents[2]
        cls.previous = json.loads(
            (root / "data/normalized/snapshot-dad7cd7d5ce73236/catalog-v2.json").read_text()
        )
        cls.current = json.loads(
            (root / "data/normalized/snapshot-a7dec7b598109dc2/catalog-v3.json").read_text()
        )

    def test_every_previous_skill_keeps_its_game_identity_and_local_id(self) -> None:
        current = {row["skill_id"]: row for row in self.current["skills"]}
        for previous in self.previous["skills"]:
            with self.subTest(skill_id=previous["skill_id"]):
                retained = current[previous["skill_id"]]
                self.assertEqual(
                    tuple(previous[key] for key in ("upstream_numeric_id", "name", "category")),
                    tuple(retained[key] for key in ("upstream_numeric_id", "name", "category")),
                )
        source = next(
            row for row in self.current["entity_sources"]
            if row["entity_kind"] == "skill" and row["entity_id"] == "skill_000208"
        )
        self.assertEqual("skill_000209", source["source_record_key"])

    def test_all_previous_learning_conditions_and_shared_assignments_are_preserved(self) -> None:
        for table in (
            "learnsets", "pet_learnsets", "learnset_native_skills", "learnset_blood_skills",
            "learnset_skill_stones", "learnset_legendary_skills",
        ):
            with self.subTest(table=table):
                previous = {json.dumps(row, sort_keys=True) for row in self.previous[table]}
                current = {json.dumps(row, sort_keys=True) for row in self.current[table]}
                self.assertTrue(previous <= current)

    def test_previous_pet_handbook_and_evolution_membership_ids_remain_stable(self) -> None:
        current_pets = {row["pet_id"]: row for row in self.current["pets"]}
        for previous in self.previous["pets"]:
            retained = current_pets[previous["pet_id"]]
            self.assertEqual(previous["extra_json"]["game_id"], retained["extra_json"]["game_id"])
            self.assertEqual(previous["handbook_id"], retained["handbook_id"])
        for table in ("handbook_entries", "evolution_groups", "pet_evolution_groups"):
            with self.subTest(table=table):
                previous = {json.dumps(row, sort_keys=True) for row in self.previous[table]}
                current = {json.dumps(row, sort_keys=True) for row in self.current[table]}
                self.assertTrue(previous <= current)


if __name__ == "__main__":
    unittest.main()
