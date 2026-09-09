import hashlib
import json
from pathlib import Path
import tempfile
import unittest

from bwiki_import.errors import ResponseValidationError
from bwiki_import.models import SourceSpec
from bwiki_import.response_validator import validate_response
from tests.helpers import mediawiki_response_document


SPEC = SourceSpec(
    source_key="core",
    title="Module:PetData/Core",
    level="required",
    local_filenames=("core.json",),
)

class ResponseValidatorTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temp = tempfile.TemporaryDirectory()
        self.path = Path(self.temp.name) / "core.json"

    def tearDown(self) -> None:
        self.temp.cleanup()

    def write(self, document: object) -> None:
        self.path.write_text(json.dumps(document), encoding="utf-8")

    def test_valid_response_preserves_hashes_and_revision(self) -> None:
        self.write(mediawiki_response_document())
        result = validate_response(self.path, SPEC)
        self.assertEqual(20, result.revision_id)
        self.assertEqual(len(result.content.encode("utf-8")), result.content_bytes)
        self.assertEqual(
            hashlib.sha256(self.path.read_bytes()).hexdigest(),
            result.response_sha256,
        )

    def test_localized_namespace_is_accepted(self) -> None:
        self.write(mediawiki_response_document(title="Localized:PetData/Core"))
        result = validate_response(self.path, SPEC)
        self.assertEqual("Localized:PetData/Core", result.canonical_title)

    def test_html_is_not_accepted_as_json(self) -> None:
        self.path.write_text("<html>not an API response</html>", encoding="utf-8")
        with self.assertRaisesRegex(ResponseValidationError, "not valid UTF-8 JSON"):
            validate_response(self.path, SPEC)

    def test_api_error_is_rejected(self) -> None:
        self.write({"error": {"code": "permissiondenied"}})
        with self.assertRaisesRegex(ResponseValidationError, "MediaWiki API error"):
            validate_response(self.path, SPEC)

    def test_missing_page_is_rejected(self) -> None:
        document = mediawiki_response_document()
        document["query"]["pages"][0]["missing"] = True
        self.write(document)
        with self.assertRaisesRegex(ResponseValidationError, "missing or invalid"):
            validate_response(self.path, SPEC)

    def test_content_size_mismatch_is_rejected(self) -> None:
        document = mediawiki_response_document()
        document["query"]["pages"][0]["revisions"][0]["size"] += 1
        self.write(document)
        with self.assertRaisesRegex(ResponseValidationError, "byte length"):
            validate_response(self.path, SPEC)

    def test_content_hash_mismatch_is_rejected(self) -> None:
        document = mediawiki_response_document()
        document["query"]["pages"][0]["revisions"][0]["sha1"] = "0" * 40
        self.write(document)
        with self.assertRaisesRegex(ResponseValidationError, "SHA-1"):
            validate_response(self.path, SPEC)
