import copy
import json
from pathlib import Path
import tempfile
import unittest

from bwiki_import.live_snapshot import import_live_snapshot
from bwiki_import.errors import InputError, ResponseValidationError
from tests.helpers import mediawiki_response_document


class _Transport:
    def __init__(self, documents=None) -> None:
        self.forms = []
        self.documents = documents or [_head(), mediawiki_response_document(), _head()]

    def post_json(self, url, form):
        self.forms.append((url, form))
        document = self.documents[len(self.forms) - 1]
        if isinstance(document, Exception):
            raise document
        return copy.deepcopy(document)


def _head(*, title="Module:PetData/Core", page_id=10, revision_id=20):
    return {"query": {"pages": [{
        "pageid": page_id,
        "title": title,
        "revisions": [{"revid": revision_id}],
    }]}}


class LiveSnapshotTests(unittest.TestCase):
    def setUp(self) -> None:
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name)
        self.config = self.root / "sources.json"
        self.config.write_text(
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

    def freeze(self, transport):
        return import_live_snapshot(
            self.root / "output", self.config, transport=transport, sleep=lambda _: None,
        )

    def assert_no_snapshot(self):
        self.assertFalse((self.root / "output").exists())

    def test_fetches_frozen_revision_and_rechecks_head_before_writing(self) -> None:
        transport = _Transport()
        frozen = self.freeze(transport)
        lock = json.loads(frozen.lock_path.read_text(encoding="utf-8"))
        self.assertEqual("mediawiki_api", lock["import_mode"])
        self.assertEqual("bwiki.test", lock["source_system"])
        self.assertTrue(lock["revision_set_verified"])
        forms = [form for _, form in transport.forms]
        self.assertEqual("ids", forms[0]["rvprop"])
        self.assertEqual("20", forms[1]["revids"])
        self.assertNotIn("titles", forms[1])
        self.assertEqual(forms[0], forms[2])
        self.assertTrue((frozen.path / "content/core.lua").is_file())

    def test_freezes_all_heads_before_fetching_any_body(self) -> None:
        config = json.loads(self.config.read_text())
        config["request_policy"]["minimum_interval_seconds"] = 1
        config["sources"].append({
            "source_key": "skills", "title": "Module:PetData/Skills", "level": "required",
        })
        self.config.write_text(json.dumps(config))
        second_head = _head(title="Module:PetData/Skills", page_id=11, revision_id=21)
        second_body = mediawiki_response_document(title="Module:PetData/Skills")
        second_body["query"]["pages"][0]["pageid"] = 11
        second_body["query"]["pages"][0]["revisions"][0]["revid"] = 21
        transport = _Transport([
            _head(), second_head, mediawiki_response_document(), second_body,
            _head(), second_head,
        ])
        pauses = []
        frozen = import_live_snapshot(
            self.root / "output", self.config, transport=transport, sleep=pauses.append,
        )
        forms = [form for _, form in transport.forms]
        self.assertEqual(["20", "21"], [form["revids"] for form in forms[2:4]])
        self.assertTrue(all("titles" in form for form in forms[:2] + forms[4:]))
        self.assertEqual([1.0] * 5, pauses)
        self.assertEqual(("core", "skills"), frozen.source_keys)

    def test_changed_head_does_not_freeze_or_reuse_snapshot(self) -> None:
        documents = [_head(), mediawiki_response_document(), _head(revision_id=21)]
        with self.assertRaisesRegex(ResponseValidationError, "heads changed"):
            self.freeze(_Transport(documents))
        self.assert_no_snapshot()
        original = self.freeze(_Transport())
        original_lock = original.lock_path.read_bytes()
        with self.assertRaisesRegex(ResponseValidationError, "heads changed"):
            self.freeze(_Transport(documents))
        self.assertEqual(original_lock, original.lock_path.read_bytes())
        self.assertEqual([original.path], list((self.root / "output").iterdir()))

    def test_unexpected_body_revision_or_page_is_rejected(self) -> None:
        for key, value in (("revid", 21), ("pageid", 11)):
            with self.subTest(key=key):
                body = mediawiki_response_document()
                page = body["query"]["pages"][0]
                (page if key == "pageid" else page["revisions"][0])[key] = value
                with self.assertRaisesRegex(ResponseValidationError, "frozen revision"):
                    self.freeze(_Transport([_head(), body]))
                self.assert_no_snapshot()

    def test_invalid_initial_or_final_heads_are_rejected(self) -> None:
        malformed = [
            {"error": {"code": "unavailable"}},
            {},
            {"query": {"pages": []}},
            {"query": {"pages": [{"missing": True}]}},
            {"query": {"pages": [{"invalid": True}]}},
            _head(title="Module:Other"),
            _head(page_id=True),
            _head(revision_id=True),
        ]
        for document in malformed:
            for final in (False, True):
                with self.subTest(document=document, final=final):
                    documents = [_head(), mediawiki_response_document(), document] if final else [document]
                    with self.assertRaises(ResponseValidationError):
                        self.freeze(_Transport(documents))
                    self.assert_no_snapshot()

    def test_failed_final_query_does_not_freeze_snapshot(self) -> None:
        with self.assertRaisesRegex(ResponseValidationError, "offline"):
            self.freeze(_Transport([
                _head(), mediawiki_response_document(), ResponseValidationError("offline"),
            ]))
        self.assert_no_snapshot()

    def test_empty_or_non_lua_body_is_rejected(self) -> None:
        empty = mediawiki_response_document(" ")
        non_lua = mediawiki_response_document()
        non_lua["query"]["pages"][0]["revisions"][0]["slots"]["main"]["contentmodel"] = "wikitext"
        for body in (empty, non_lua):
            with self.subTest(body=body):
                with self.assertRaisesRegex(ResponseValidationError, "non-empty Scribunto"):
                    self.freeze(_Transport([_head(), body]))
                self.assert_no_snapshot()

    def test_stable_reimport_preserves_immutable_lock_and_import_time(self) -> None:
        original = self.freeze(_Transport())
        original_lock = original.lock_path.read_bytes()
        transport = _Transport()
        reused = self.freeze(transport)
        self.assertTrue(reused.reused_existing)
        self.assertEqual(original.path, reused.path)
        self.assertEqual(original_lock, reused.lock_path.read_bytes())
        self.assertEqual(3, len(transport.forms))

    def test_empty_import_configuration_is_rejected(self) -> None:
        config = json.loads(self.config.read_text())
        config["sources"] = []
        self.config.write_text(json.dumps(config))
        with self.assertRaisesRegex(InputError, "no importable modules"):
            self.freeze(_Transport())
        self.assert_no_snapshot()


if __name__ == "__main__":
    unittest.main()
