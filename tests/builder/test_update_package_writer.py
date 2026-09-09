import copy
from contextlib import redirect_stdout
import hashlib
import io
import json
from pathlib import Path
import shutil
import stat
import tempfile
import unittest
import zipfile

from catalog_builder.cli import main as catalog_builder_main
from catalog_builder.errors import AdapterError
from catalog_builder.package_writer import build_release_package, read_normalized_catalog
from catalog_builder.update_package_writer import (
    build_complete_update_archive,
    build_remote_manifest_payload,
)


ROOT = Path(__file__).resolve().parents[2]
RELEASE = ROOT / "data" / "release" / "1"
NORMALIZED = (
    ROOT
    / "data"
    / "normalized"
    / "snapshot-19235f9b9b34dc4e"
    / "catalog-v1.json"
)
ENTRIES = (
    "assets/catalog/bundled_catalog.json",
    "assets/catalog/catalog.db",
    "assets/catalog/ATTRIBUTION.txt",
)


class CompleteUpdatePackageTests(unittest.TestCase):
    def test_refuses_update_artifacts_inside_or_linked_into_the_repository(
        self,
    ) -> None:
        direct_output = ROOT / "phase-7-forbidden-update.zip"
        with self.assertRaisesRegex(AdapterError, "outside the repository"):
            build_complete_update_archive(
                RELEASE,
                direct_output,
                repository_root=ROOT,
            )
        self.assertFalse(direct_output.exists())

        with tempfile.TemporaryDirectory() as temporary:
            repository_alias = Path(temporary) / "repository-alias"
            repository_alias.symlink_to(ROOT, target_is_directory=True)
            linked_output = repository_alias / "phase-7-forbidden-update.zip"
            with self.assertRaisesRegex(AdapterError, "outside the repository"):
                build_complete_update_archive(
                    RELEASE,
                    linked_output,
                    repository_root=ROOT,
                )
            self.assertFalse(direct_output.exists())

    def test_complete_update_command_builds_the_requested_archive(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            output = Path(temporary) / "catalog-v1.zip"
            stdout = io.StringIO()

            with redirect_stdout(stdout):
                exit_code = catalog_builder_main(
                    [
                        "build-complete-update",
                        "--release",
                        str(RELEASE),
                        "--output",
                        str(output),
                    ]
                )

            self.assertEqual(0, exit_code)
            self.assertTrue(output.is_file())
            self.assertEqual(str(output), json.loads(stdout.getvalue())["output"])

    def test_builds_a_reproducible_exact_archive_without_overwriting(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            first = root / "catalog-v1-a.zip"
            second = root / "catalog-v1-b.zip"

            first_report = build_complete_update_archive(
                RELEASE,
                first,
                repository_root=ROOT,
            )
            second_report = build_complete_update_archive(
                RELEASE,
                second,
                repository_root=ROOT,
            )

            self.assertEqual(first.read_bytes(), second.read_bytes())
            self.assertEqual(first.stat().st_size, first_report["archive_bytes"])
            self.assertEqual(
                hashlib.sha256(first.read_bytes()).hexdigest(),
                first_report["archive_sha256"],
            )
            self.assertEqual(list(ENTRIES), first_report["entries"])
            self.assertNotIn("signature", first_report)
            self.assertNotIn("url", first_report)

            with zipfile.ZipFile(first) as archive:
                self.assertEqual(list(ENTRIES), archive.namelist())
                self.assertEqual(b"", archive.comment)
                self.assertIsNone(archive.testzip())
                for name in ENTRIES:
                    info = archive.getinfo(name)
                    self.assertEqual(zipfile.ZIP_DEFLATED, info.compress_type)
                    self.assertLessEqual(info.extract_version, 20)
                    self.assertEqual(b"", info.extra)
                    self.assertEqual(b"", info.comment)
                    self.assertTrue(stat.S_ISREG(info.external_attr >> 16))
                    self.assertEqual((RELEASE / name).read_bytes(), archive.read(name))

            with self.assertRaisesRegex(AdapterError, "already exists"):
                build_complete_update_archive(
                    RELEASE,
                    first,
                    repository_root=ROOT,
                )

    def test_builds_canonical_unsigned_payload_for_a_validated_update(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            repository_root = Path(temporary) / "repository"
            release = _build_version_two_release(repository_root)
            archive = Path(temporary) / "catalog-v2.zip"
            build_complete_update_archive(
                release,
                archive,
                repository_root=repository_root,
            )
            payload_path = Path(temporary) / "remote-catalog-payload-v2.json"

            with self.assertRaisesRegex(AdapterError, "outside the repository"):
                build_remote_manifest_payload(
                    release,
                    archive,
                    repository_root / "forbidden-payload.json",
                    package_url=(
                        "https://updates.example.test/releases/catalog-v2.zip"
                    ),
                    release_sequence=2,
                    minimum_app_version="1.0.0",
                    published_at_utc="2026-09-09T23:45:00Z",
                    repository_root=repository_root,
                )

            report = build_remote_manifest_payload(
                release,
                archive,
                payload_path,
                package_url=(
                    "https://updates.example.test/releases/catalog-v2.zip"
                ),
                release_sequence=2,
                minimum_app_version="1.0.0",
                published_at_utc="2026-09-09T23:45:00Z",
                repository_root=repository_root,
            )

            payload_bytes = payload_path.read_bytes()
            payload = json.loads(payload_bytes)
            self.assertEqual(
                json.dumps(
                    payload,
                    ensure_ascii=False,
                    allow_nan=False,
                    separators=(",", ":"),
                    sort_keys=True,
                ).encode("utf-8"),
                payload_bytes,
            )
            self.assertEqual(2, payload["data_version"])
            self.assertEqual(2, payload["release_sequence"])
            self.assertEqual(archive.stat().st_size, payload["package"]["archive_bytes"])
            self.assertEqual(
                hashlib.sha256(archive.read_bytes()).hexdigest(),
                payload["package"]["archive_sha256"],
            )
            self.assertEqual(len(payload_bytes), report["payload_bytes"])

            with self.assertRaisesRegex(AdapterError, "URL"):
                build_remote_manifest_payload(
                    release,
                    archive,
                    Path(temporary) / "invalid-url.json",
                    package_url="https://updates.example.test/%2e%2e/catalog-v2.zip",
                    release_sequence=2,
                    minimum_app_version="1.0.0",
                    published_at_utc="2026-09-09T23:45:00Z",
                    repository_root=repository_root,
                )

    def test_rejects_an_unsafe_release_before_creating_output(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            copied_release = root / "1"
            shutil.copytree(RELEASE, copied_release)
            attribution = copied_release / "assets/catalog/ATTRIBUTION.txt"
            attribution.unlink()
            attribution.symlink_to(RELEASE / "assets/catalog/ATTRIBUTION.txt")
            output = root / "catalog-v1.zip"

            with self.assertRaisesRegex(AdapterError, "not eligible"):
                build_complete_update_archive(
                    copied_release,
                    output,
                    repository_root=ROOT,
                )
            self.assertFalse(output.exists())
def _build_version_two_release(repository_root: Path) -> Path:
    normalized = copy.deepcopy(read_normalized_catalog(NORMALIZED))
    normalized["data_version"] = 2
    snapshot_id = normalized["snapshot_id"]
    normalized_path = (
        repository_root
        / "data"
        / "normalized"
        / snapshot_id
        / "catalog-v2.json"
    )
    normalized_path.parent.mkdir(parents=True)
    normalized_path.write_text(
        json.dumps(normalized, ensure_ascii=False, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    source_lock = ROOT / "data" / "raw" / snapshot_id / "sources.lock.json"
    copied_lock = repository_root / "data" / "raw" / snapshot_id / "sources.lock.json"
    copied_lock.parent.mkdir(parents=True)
    shutil.copy2(source_lock, copied_lock)
    return build_release_package(
        normalized,
        schema_path=ROOT / "schemas/catalog_v1.sql",
        manifest_schema_path=(
            ROOT / "schemas/manifests/bundled_catalog_v1.schema.json"
        ),
        identity_registry_path=ROOT / "config/identity_registry.json",
        reviewed_exceptions_path=ROOT / "config/reviewed_exceptions.json",
        output_root=repository_root / "data/release",
        previous_database=RELEASE / "assets/catalog/catalog.db",
    )


if __name__ == "__main__":
    unittest.main()
