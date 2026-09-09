import json
from pathlib import Path
import tempfile
import unittest

from bwiki_import.errors import InputError, SnapshotWriteError
from bwiki_import.snapshot_store import import_local_snapshot
from tests.helpers import mediawiki_response_document


class SnapshotStoreTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)
        self.input_dir = self.root / "input"
        self.output_dir = self.root / "output"
        self.input_dir.mkdir()
        self.config_path = self.root / "sources.json"
        self.config_path.write_text(
            json.dumps(
                {
                    "dataset_id": "test-dataset",
                    "sources": [
                        {
                            "source_key": "core",
                            "title": "Module:PetData/Core",
                            "level": "required",
                            "local_filenames": ["core.json"],
                        }
                    ],
                }
            ),
            encoding="utf-8",
        )

    def tearDown(self) -> None:
        self.temp.cleanup()

    def write_response(self) -> None:
        (self.input_dir / "core.json").write_text(
            json.dumps(mediawiki_response_document()),
            encoding="utf-8",
        )

    def test_freeze_is_idempotent_for_identical_input(self) -> None:
        self.write_response()
        first = import_local_snapshot(
            self.input_dir,
            self.output_dir,
            self.config_path,
        )
        second = import_local_snapshot(
            self.input_dir,
            self.output_dir,
            self.config_path,
        )
        self.assertFalse(first.reused_existing)
        self.assertTrue(second.reused_existing)
        self.assertEqual(first.path, second.path)
        self.assertTrue((first.path / "responses/core.json").is_file())
        self.assertTrue((first.path / "content/core.lua").is_file())

    def test_existing_snapshot_mutation_is_detected(self) -> None:
        self.write_response()
        snapshot = import_local_snapshot(
            self.input_dir,
            self.output_dir,
            self.config_path,
        )
        (snapshot.path / "responses/core.json").write_text("changed", encoding="utf-8")
        with self.assertRaisesRegex(SnapshotWriteError, "Frozen response changed"):
            import_local_snapshot(
                self.input_dir,
                self.output_dir,
                self.config_path,
            )

    def test_missing_required_response_is_rejected(self) -> None:
        with self.assertRaisesRegex(InputError, "Missing required"):
            import_local_snapshot(
                self.input_dir,
                self.output_dir,
                self.config_path,
            )
