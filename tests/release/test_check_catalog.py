import copy
import json
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest

from tools.release.check_catalog import ReleaseCheckError, check_release


ROOT = Path(__file__).resolve().parents[2]
SOURCE_RELEASE = ROOT / "data/release/1"


class CatalogReleaseCheckTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory(prefix="roco-release-check-")
        self.root = Path(self.temporary.name)
        self.release = self.root / "1"
        shutil.copytree(SOURCE_RELEASE, self.release)

    def tearDown(self) -> None:
        self.temporary.cleanup()

    def test_current_release_passes_and_is_traceable(self) -> None:
        report = check_release(SOURCE_RELEASE)

        self.assertEqual("passed", report["status"])
        self.assertEqual(1, report["catalog_data_version"])
        self.assertEqual(10, report["database"]["source_revision_count"])
        self.assertEqual(596, report["database"]["table_counts"]["pets"])
        self.assertEqual(788, report["database"]["table_counts"]["skills"])

    def test_rejects_sqlite_sidecars(self) -> None:
        (self.release / "assets/catalog/catalog.db-wal").write_bytes(b"unsafe")

        with self.assertRaisesRegex(ReleaseCheckError, "REL-001"):
            check_release(self.release)

    def test_rejects_placeholder_release_text(self) -> None:
        attribution = self.release / "assets/catalog/ATTRIBUTION.txt"
        attribution.write_text(
            f"{attribution.read_text(encoding='utf-8')}\nreplace_with_actual\n",
            encoding="utf-8",
        )

        with self.assertRaisesRegex(ReleaseCheckError, "REL-002"):
            check_release(self.release)

    def test_rejects_false_required_coverage(self) -> None:
        manifest_path = self.release / "assets/catalog/bundled_catalog.json"
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
        manifest["coverage"]["pets"] = False
        manifest_path.write_text(json.dumps(manifest), encoding="utf-8")

        with self.assertRaisesRegex(ReleaseCheckError, "REL-003"):
            check_release(self.release)

    def test_rejects_failed_validation_blockers_and_unreviewed_removals(self) -> None:
        report_path = self.release / "build-report.json"
        original = json.loads(report_path.read_text(encoding="utf-8"))
        variants = []
        blockers = copy.deepcopy(original)
        blockers["validation"]["blocking_issues"] = [{"code": "blocked"}]
        variants.append(blockers)
        failed_validation = copy.deepcopy(original)
        failed_validation["validation"]["status"] = "failed"
        variants.append(failed_validation)
        removals = copy.deepcopy(original)
        removals["difference"]["unreviewed_removal_count"] = 1
        variants.append(removals)

        for variant in variants:
            with self.subTest(variant=variant):
                report_path.write_text(json.dumps(variant), encoding="utf-8")
                with self.assertRaises(ReleaseCheckError):
                    check_release(self.release)

    def test_command_returns_nonzero_for_a_hash_mismatch(self) -> None:
        database = self.release / "assets/catalog/catalog.db"
        changed = bytearray(database.read_bytes())
        changed[-1] ^= 1
        database.write_bytes(changed)

        completed = subprocess.run(
            [
                sys.executable,
                str(ROOT / "tools/release/check_catalog.py"),
                "--release",
                str(self.release),
            ],
            cwd=ROOT,
            check=False,
            capture_output=True,
            text=True,
        )

        self.assertNotEqual(0, completed.returncode)
        self.assertIn('"status": "failed"', completed.stderr)


if __name__ == "__main__":
    unittest.main()
