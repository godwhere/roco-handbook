import json
from pathlib import Path
import tempfile
import unittest

from bwiki_import.live_snapshot import import_live_snapshot
from tests.helpers import mediawiki_response_document


class _Transport:
    def __init__(self) -> None:
        self.forms = []

    def post_json(self, url, form):
        self.forms.append((url, form))
        return mediawiki_response_document()


class LiveSnapshotTests(unittest.TestCase):
    def test_fetches_validates_and_freezes_required_modules(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            config = root / "sources.json"
            config.write_text(
                json.dumps(
                    {
                        "dataset_id": "test-dataset",
                        "source_system": "bwiki.test",
                        "endpoint": "https://wiki.example.test/api.php",
                        "request_policy": {
                            "minimum_interval_seconds": 0,
                            "connect_timeout_seconds": 1,
                            "read_timeout_seconds": 1,
                            "max_retries": 1,
                        },
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
            transport = _Transport()
            frozen = import_live_snapshot(
                root / "output",
                config,
                transport=transport,
                sleep=lambda _: None,
            )
            lock = json.loads(frozen.lock_path.read_text(encoding="utf-8"))
            self.assertEqual("mediawiki_api", lock["import_mode"])
            self.assertEqual("bwiki.test", lock["source_system"])
            self.assertEqual(1, len(transport.forms))
            self.assertTrue((frozen.path / "content/core.lua").is_file())


if __name__ == "__main__":
    unittest.main()
