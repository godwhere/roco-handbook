import json
from pathlib import Path
import tempfile
import unittest

from bwiki_import.errors import SnapshotWriteError
from bwiki_import.rendered_snapshot import import_rendered_index_response


class RenderedSnapshotTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary.name)
        self.input_path = self.root / "rendered.json"
        self.output_root = self.root / "output"
        self.input_path.write_text(
            json.dumps(
                {
                    "parse": {
                        "title": "Pet Index",
                        "pageid": 1,
                        "revid": 2,
                        "text": "<div>Rendered</div>",
                    }
                }
            ),
            encoding="utf-8",
        )

    def tearDown(self) -> None:
        self.temporary.cleanup()

    def test_freeze_is_idempotent_for_identical_rendered_response(self) -> None:
        first = import_rendered_index_response(self.input_path, self.output_root)
        second = import_rendered_index_response(self.input_path, self.output_root)
        self.assertFalse(first.reused_existing)
        self.assertTrue(second.reused_existing)
        self.assertEqual(first.path, second.path)

    def test_existing_rendered_response_mutation_is_detected(self) -> None:
        snapshot = import_rendered_index_response(self.input_path, self.output_root)
        (snapshot.path / "responses/pet_index.json").write_text(
            "changed",
            encoding="utf-8",
        )
        with self.assertRaisesRegex(SnapshotWriteError, "differs"):
            import_rendered_index_response(self.input_path, self.output_root)


if __name__ == "__main__":
    unittest.main()
