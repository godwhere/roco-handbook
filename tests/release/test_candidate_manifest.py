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

    def test_app_version_matches_pubspec_and_platform_metadata(self) -> None:
        pubspec = (ROOT / "app/pubspec.yaml").read_text(encoding="utf-8")
        version = re.search(
            r"^version: ([0-9]+\.[0-9]+\.[0-9]+)\+([0-9]+)$", pubspec, re.M
        )
        self.assertIsNotNone(version)
        self.assertEqual(version.group(1), self.candidate["app"]["version"])
        self.assertEqual(int(version.group(2)), self.candidate["app"]["build_number"])
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

    def test_candidate_does_not_claim_signing_devices_or_publication(self) -> None:
        android = self.candidate["platforms"]["android"]
        ios = self.candidate["platforms"]["ios"]
        publication = self.candidate["publication"]

        self.assertFalse(android["artifact"]["signed"])
        self.assertFalse(ios["artifact"]["codesigned"])
        self.assertEqual("not_run", android["device_gate"]["status"])
        self.assertEqual("not_run", ios["device_gate"]["status"])
        self.assertFalse(publication["store_ready"])
        self.assertFalse(publication["uploaded"])
        self.assertEqual("not_authorized", publication["status"])

    def test_release_source_manifests_do_not_request_sensitive_access(self) -> None:
        android_manifest = (
            ROOT / "app/android/app/src/main/AndroidManifest.xml"
        ).read_text(encoding="utf-8")
        ios_plist = (ROOT / "app/ios/Runner/Info.plist").read_text(encoding="utf-8")

        self.assertNotIn("uses-permission", android_manifest)
        self.assertNotIn("android.permission.INTERNET", android_manifest)
        self.assertIsNone(re.search(r"NS[A-Za-z]+UsageDescription", ios_plist))


if __name__ == "__main__":
    unittest.main()
