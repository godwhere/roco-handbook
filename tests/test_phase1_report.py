import json
from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
REPORT_PATH = (
    ROOT
    / "data"
    / "reports"
    / "snapshot-19235f9b9b34dc4e"
    / "structure-report.json"
)
SAMPLES_PATH = REPORT_PATH.with_name("sample-mappings.json")


class PhaseOneReportTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.report = json.loads(REPORT_PATH.read_text(encoding="utf-8"))
        cls.samples = json.loads(SAMPLES_PATH.read_text(encoding="utf-8"))

    def test_report_has_complete_required_counts_and_no_blocker(self) -> None:
        modules = self.report["modules"]
        self.assertEqual("passed_with_warnings", self.report["status"])
        self.assertEqual([], self.report["blocking_issues"])
        self.assertEqual(596, modules["core"]["record_count"])
        self.assertEqual(442, modules["handbook"]["record_count"])
        self.assertEqual(788, modules["skill_catalog"]["record_count"])
        self.assertEqual(298, modules["learnsets"]["record_count"])
        self.assertEqual(242, modules["evolution"]["record_count"])

    def test_references_fields_and_handbook_evidence_are_closed(self) -> None:
        for value in self.report["references"].values():
            if isinstance(value, list):
                self.assertEqual([], value)
            else:
                self.assertTrue(all(not items for items in value.values()))
        for key in (
            "core",
            "handbook",
            "evolution",
            "skill_catalog",
            "learnsets",
        ):
            self.assertEqual([], self.report["modules"][key]["unknown_fields"])
        evidence = self.report["rendered_index_evidence"]
        self.assertEqual(442, evidence["main_form_count"])
        self.assertEqual(442, evidence["display_number_count"])
        self.assertEqual("004", evidence["display_numbers"]["handbook_000004"])
        self.assertEqual(
            442,
            self.report["handbook_default_display"]["resolved_count"],
        )

    def test_required_three_form_sample_remains_distinct_and_linked(self) -> None:
        sample = self.samples["three_form_creature"]
        self.assertTrue(sample["distinct_pet_ids"])
        self.assertTrue(sample["all_forms_share_handbook"])
        self.assertTrue(sample["base_core_and_learnset_feature_match"])
        self.assertEqual(
            {"pet_000007", "pet_000538", "pet_000595"},
            set(sample["pets"]),
        )


if __name__ == "__main__":
    unittest.main()
