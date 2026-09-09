import hashlib
import json
from pathlib import Path
import re
import unittest


ROOT = Path(__file__).resolve().parents[2]
CANDIDATE_PATH = ROOT / "release/1.0.0+1/release-candidate.json"


def _sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


class ReleaseCandidateManifestTests(unittest.TestCase):
    def setUp(self) -> None:
        self.candidate = json.loads(CANDIDATE_PATH.read_text(encoding="utf-8"))

    def test_candidate_app_version_matches_its_platform_metadata(self) -> None:
        pubspec = (ROOT / "app/pubspec.yaml").read_text(encoding="utf-8")
        version = re.search(
            r"^version: ([0-9]+\.[0-9]+\.[0-9]+)\+([0-9]+)$", pubspec, re.M
        )
        self.assertIsNotNone(version)
        self.assertEqual(("1.1.0", "2"), version.groups())
        self.assertEqual("1.0.0", self.candidate["app"]["version"])
        self.assertEqual(1, self.candidate["app"]["build_number"])
        app_version = (ROOT / "app/lib/app_version.dart").read_text(
            encoding="utf-8"
        )
        self.assertIn("static const name = '1.1.0';", app_version)
        self.assertIn("static const buildNumber = 2;", app_version)
        self.assertEqual(
            self.candidate["app"]["version"],
            self.candidate["platforms"]["android"]["manifest"]["version_name"],
        )
        self.assertEqual(
            self.candidate["app"]["version"],
            self.candidate["platforms"]["ios"]["info"]["version"],
        )

    def test_catalog_and_user_schema_hashes_match_tracked_inputs(self) -> None:
        catalog = self.candidate["catalog"]
        catalog_check = json.loads(
            (ROOT / catalog["catalog_check"]).read_text(encoding="utf-8")
        )
        database = ROOT / catalog["release"] / "assets/catalog/catalog.db"
        self.assertEqual(database.stat().st_size, catalog["database_bytes"])
        self.assertEqual(_sha256(database), catalog["database_sha256"])
        self.assertEqual(
            _sha256(ROOT / catalog["catalog_check"]),
            catalog["catalog_check_sha256"],
        )
        self.assertEqual("passed", catalog_check["status"])
        for candidate_key, check_key in {
            "attribution_sha256": "attribution_sha256",
            "data_version": "catalog_data_version",
            "database_bytes": "database_bytes",
            "database_sha256": "database_sha256",
            "normalized_catalog_sha256": "normalized_catalog_sha256",
            "schema_version": "catalog_schema_version",
            "snapshot_id": "snapshot_id",
            "source_lock_sha256": "source_lock_sha256",
        }.items():
            with self.subTest(candidate_key=candidate_key):
                self.assertEqual(catalog[candidate_key], catalog_check[check_key])
        self.assertEqual(
            _sha256(ROOT / catalog["release"] / "assets/catalog/bundled_catalog.json"),
            catalog["manifest_sha256"],
        )
        self.assertEqual(
            _sha256(ROOT / "schemas/user_v1.sql"),
            self.candidate["user_database"]["schema_sha256"],
        )

    def test_candidate_records_device_waiver_without_claiming_evidence(self) -> None:
        android = self.candidate["platforms"]["android"]
        ios = self.candidate["platforms"]["ios"]
        publication = self.candidate["publication"]
        acceptance = self.candidate["acceptance"]
        waiver = acceptance["waiver"]

        self.assertEqual(2, self.candidate["candidate_manifest_version"])
        self.assertEqual("complete_with_device_test_waiver", acceptance["status"])
        self.assertEqual("PHASE6-PHYSICAL-DEVICE-001", waiver["id"])
        self.assertEqual("not_run", waiver["evidence_status"])
        self.assertEqual(
            {
                "android_physical_device_validation",
                "ios_physical_device_validation",
            },
            set(waiver["scope"]),
        )
        self.assertFalse(android["artifact"]["signed"])
        self.assertFalse(ios["artifact"]["codesigned"])
        self.assertEqual("not_run", android["device_gate"]["status"])
        self.assertEqual("not_run", ios["device_gate"]["status"])
        self.assertEqual(
            "phase_6_complete_with_device_test_waiver",
            self.candidate["status"],
        )
        self.assertFalse(publication["store_ready"])
        self.assertFalse(publication["uploaded"])
        self.assertEqual("not_authorized", publication["status"])

    def test_release_source_manifests_request_only_approved_access(self) -> None:
        android_manifest = (
            ROOT / "app/android/app/src/main/AndroidManifest.xml"
        ).read_text(encoding="utf-8")
        ios_plist = (ROOT / "app/ios/Runner/Info.plist").read_text(encoding="utf-8")

        self.assertEqual(
            ["android.permission.INTERNET"],
            re.findall(r'<uses-permission android:name="([^"]+)"', android_manifest),
        )
        self.assertIsNone(re.search(r"NS[A-Za-z]+UsageDescription", ios_plist))


if __name__ == "__main__":
    unittest.main()
