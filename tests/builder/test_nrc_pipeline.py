import json
from pathlib import Path
import unittest

from catalog_builder.nrc_normalizer import normalize_nrc_snapshot
from catalog_builder.validator import validate_normalized_catalog


ROOT = Path(__file__).resolve().parents[2]
SNAPSHOT = ROOT / "data/raw/snapshot-dad7cd7d5ce73236"
NORMALIZED = (
    ROOT / "data/normalized/snapshot-dad7cd7d5ce73236/catalog-v2.json"
)


class NrcPipelineTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.normalized = json.loads(NORMALIZED.read_text(encoding="utf-8"))

    def test_current_snapshot_normalizes_deterministically(self) -> None:
        rebuilt = normalize_nrc_snapshot(
            SNAPSHOT,
            type_aliases_path=ROOT / "config/type_aliases.json",
            previous_catalog_path=ROOT / "data/release/1/assets/catalog/catalog.db",
            data_version=2,
            built_at_utc="2026-09-14T00:00:00Z",
        )
        self.assertEqual(self.normalized, rebuilt)

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
