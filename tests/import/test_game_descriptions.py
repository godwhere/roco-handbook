from __future__ import annotations

import hashlib
import json
from pathlib import Path
import sqlite3
from tempfile import TemporaryDirectory
import unittest

from bwiki_import.errors import ResponseValidationError
from bwiki_import.game_descriptions import (
    import_game_descriptions,
    parse_game_descriptions,
)


ROOT = Path(__file__).resolve().parents[2]


class _Transport:
    def __init__(self, document: dict[str, object]) -> None:
        self.document = document

    def get_json(self, url: str) -> dict[str, object]:
        self.url = url
        return self.document


class GameDescriptionImportTests(unittest.TestCase):
    def test_frozen_contract_keeps_the_reviewed_source(self) -> None:
        contract = json.loads(
            (ROOT / "app/assets/wiki/game-descriptions-v1.json").read_text(
                encoding="utf-8"
            )
        )

        self.assertEqual(7078, contract["source"]["revision_id"])
        self.assertEqual(54, len(contract["entries"]))
        self.assertEqual(
            "\u56de\u5408\u7ed3\u675f\u65f6\uff0c\u9020\u62103%\u751f\u547d\u7684\u6bd2\u7cfb\u4f24\u5bb3\u3002\uff08\u6bd2\u7cfb\u7cbe\u7075\u514d\u75ab\u6b64\u6548\u679c\uff09",
            contract["entries"][0]["description"],
        )
        database = sqlite3.connect(ROOT / "app/assets/catalog/catalog.db")
        try:
            referenced = {
                row[0]
                for row in database.execute(
                    "SELECT DISTINCT note_id FROM skill_description_notes"
                )
            }
        finally:
            database.close()
        self.assertEqual(
            set(),
            referenced.difference(
                entry["note_id"] for entry in contract["entries"]
            ),
        )

    def test_parses_only_data_records_and_preserves_ids(self) -> None:
        entries = parse_game_descriptions(
            'return {[1002]={desc="B",note="Beta"},[1001]={desc="A",note="Alpha"}}',
            source="Module:Terms",
            category_order=["status", "other"],
            category_terms={"status": ["Alpha"], "other": ["Beta"]},
        )

        self.assertEqual(["1001", "1002"], [entry["note_id"] for entry in entries])
        self.assertEqual(["status", "other"], [entry["category"] for entry in entries])

    def test_rejects_executable_or_unreviewed_source(self) -> None:
        with self.assertRaisesRegex(ResponseValidationError, "unsupported"):
            parse_game_descriptions(
                'return {[1001]={desc=build(),note="Alpha"}}',
                source="Module:Terms",
                category_order=["status"],
                category_terms={"status": ["Alpha"]},
            )
        with self.assertRaisesRegex(ResponseValidationError, "unclassified"):
            parse_game_descriptions(
                'return {[1001]={desc="A",note="Beta"}}',
                source="Module:Terms",
                category_order=["status"],
                category_terms={"status": ["Alpha"]},
            )

    def test_import_is_identity_checked_and_idempotent(self) -> None:
        content = 'return {[1001]={desc="A",note="Alpha"}}'
        revision = {
            "revid": 9,
            "timestamp": "2026-09-10T00:00:00Z",
            "sha1": hashlib.sha1(content.encode("utf-8")).hexdigest(),
            "slots": {
                "main": {"contentmodel": "Scribunto", "content": content}
            },
        }
        response = {
            "batchcomplete": True,
            "query": {
                "pages": [
                    {
                        "pageid": 7,
                        "title": "Module:Terms",
                        "revisions": [revision],
                    }
                ]
            },
        }
        config = {
            "config_version": 1,
            "dataset_id": "roco-world-zh-cn",
            "api_endpoint": "https://example.test/api.php",
            "source_title": "Module:Terms",
            "source_page_id": 7,
            "source_url_prefix": "https://example.test/?oldid=",
            "category_order": ["status"],
            "category_labels": {"status": "Status"},
            "category_terms": {"status": ["Alpha"]},
            "request_policy": {"timeout_seconds": 10, "max_retries": 1},
        }
        with TemporaryDirectory() as directory:
            root = Path(directory)
            config_path = root / "config.json"
            output_path = root / "asset.json"
            config_path.write_text(json.dumps(config), encoding="utf-8")
            transport = _Transport(response)

            self.assertEqual(
                output_path,
                import_game_descriptions(
                    config_path, output_path, transport=transport
                ),
            )
            first = output_path.read_bytes()
            self.assertEqual(
                output_path,
                import_game_descriptions(
                    config_path, output_path, transport=transport
                ),
            )
            self.assertEqual(first, output_path.read_bytes())


if __name__ == "__main__":
    unittest.main()
