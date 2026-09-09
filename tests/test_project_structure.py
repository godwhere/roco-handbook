import base64
import hashlib
import json
from pathlib import Path
import re
import unittest


ROOT = Path(__file__).resolve().parents[1]


class ProjectStructureTests(unittest.TestCase):
    def test_phase_zero_contract_files_exist(self) -> None:
        expected = [
            "README.md",
            "AGENTS.md",
            "docs/technical-spec-v1.md",
            "docs/decisions/ADR-0001-v1-delivery-scope.md",
            "docs/decisions/ADR-0008-phase-6-release-candidate.md",
            "docs/decisions/ADR-0010-phase-7-inception.md",
            "docs/decisions/ADR-0011-phase-7-signed-manifest-contract.md",
            "docs/features/independent-catalog-updates.md",
            "docs/implementation-reports/phase-7.md",
            "docs/evidence/environment-2026-09-09.md",
            "docs/evidence/phase-7-signed-manifest-2026-09-09.md",
            "config/bwiki_sources.json",
            "config/identity_registry.json",
            "config/type_aliases.json",
            "config/handbook_display_overrides.json",
            "config/reviewed_exceptions.json",
            "schemas/catalog_v1.sql",
            "schemas/user_v1.sql",
            "schemas/manifests/bundled_catalog_v1.schema.json",
            "schemas/manifests/catalog_trust_store_v1.schema.json",
            "schemas/manifests/remote_catalog_envelope_v1.schema.json",
            "schemas/manifests/remote_catalog_payload_v1.schema.json",
            "app/lib/data/catalog/remote_catalog_manifest.dart",
            "app/test/data/remote_catalog_manifest_test.dart",
            "app/test/fixtures/catalog_update/catalog_trust_store_v1.json",
            "app/test/fixtures/catalog_update/remote_catalog_envelope_v1.json",
            "app/test/fixtures/catalog_update/remote_catalog_payload_v1.json",
            "tools/pyproject.toml",
            "tools/release/check_catalog.py",
            ".github/workflows/offline-validation.yml",
            "licenses/DATA_ATTRIBUTION.md",
            "licenses/THIRD_PARTY_NOTICES.md",
            "release/1.0.0+1/release-candidate.json",
            "release/1.0.0+1/catalog-check.json",
            "release/1.0.0+1/RELEASE_NOTES.md",
            "release/1.0.0+1/KNOWN_LIMITATIONS.md",
        ]
        missing = [path for path in expected if not (ROOT / path).is_file()]
        self.assertEqual([], missing)

    def test_json_configuration_is_valid_and_scoped_to_one_dataset(self) -> None:
        paths = [
            ROOT / "config/bwiki_sources.json",
            ROOT / "config/identity_registry.json",
            ROOT / "config/type_aliases.json",
            ROOT / "config/handbook_display_overrides.json",
            ROOT / "config/reviewed_exceptions.json",
        ]
        documents = [json.loads(path.read_text(encoding="utf-8")) for path in paths]
        self.assertEqual(
            {"roco-world-zh-cn"},
            {document["dataset_id"] for document in documents},
        )

    def test_required_source_keys_match_v1_contract(self) -> None:
        config = json.loads(
            (ROOT / "config/bwiki_sources.json").read_text(encoding="utf-8")
        )
        required = {
            source["source_key"]
            for source in config["sources"]
            if source["level"] == "required"
        }
        self.assertEqual(
            {
                "core",
                "index",
                "handbook",
                "evolution",
                "skill_catalog",
                "learnsets",
                "learnset_catalog",
            },
            required,
        )

    def test_remote_catalog_fixtures_match_the_frozen_schema_shapes(self) -> None:
        manifest_root = ROOT / "schemas" / "manifests"
        fixture_root = ROOT / "app" / "test" / "fixtures" / "catalog_update"
        cases = [
            ("catalog_trust_store_v1.schema.json", "catalog_trust_store_v1.json"),
            (
                "remote_catalog_envelope_v1.schema.json",
                "remote_catalog_envelope_v1.json",
            ),
            (
                "remote_catalog_payload_v1.schema.json",
                "remote_catalog_payload_v1.json",
            ),
        ]

        documents: dict[str, dict[str, object]] = {}
        for schema_name, fixture_name in cases:
            with self.subTest(fixture=fixture_name):
                schema = json.loads(
                    (manifest_root / schema_name).read_text(encoding="utf-8")
                )
                document = json.loads(
                    (fixture_root / fixture_name).read_text(encoding="utf-8")
                )
                self.assertFalse(schema["additionalProperties"])
                self.assertEqual(set(schema["required"]), set(document))
                for field, field_schema in schema["properties"].items():
                    if "const" in field_schema:
                        self.assertEqual(field_schema["const"], document[field])
                documents[fixture_name] = document

        envelope = documents["remote_catalog_envelope_v1.json"]
        payload_text = (
            fixture_root / "remote_catalog_payload_v1.json"
        ).read_text(encoding="utf-8").strip()
        encoded_payload = str(envelope["payload"])
        padding = "=" * (-len(encoded_payload) % 4)
        self.assertEqual(
            payload_text,
            base64.urlsafe_b64decode(encoded_payload + padding).decode("utf-8"),
        )

        payload = documents["remote_catalog_payload_v1.json"]
        payload_schema = json.loads(
            (manifest_root / "remote_catalog_payload_v1.schema.json").read_text(
                encoding="utf-8"
            )
        )
        for field in ("coverage", "package"):
            nested_schema = payload_schema["properties"][field]
            self.assertFalse(nested_schema["additionalProperties"])
            self.assertEqual(set(nested_schema["required"]), set(payload[field]))

    def test_baseline_spec_is_preserved_verbatim(self) -> None:
        copied = (ROOT / "docs/technical-spec-v1.md").read_bytes()
        self.assertEqual(
            "343618b414b7b8d6262dd58f82010bfefb2f3fdb29711a9e86428e042dd81876",
            hashlib.sha256(copied).hexdigest(),
        )

    def test_flutter_assets_match_the_validated_catalog_release(self) -> None:
        names = ["catalog.db", "bundled_catalog.json", "ATTRIBUTION.txt"]
        for name in names:
            with self.subTest(name=name):
                released = ROOT / "data" / "release" / "1" / "assets" / "catalog" / name
                bundled = ROOT / "app" / "assets" / "catalog" / name
                self.assertEqual(released.read_bytes(), bundled.read_bytes())

    def test_flutter_uses_the_normative_user_schema_asset(self) -> None:
        normative = ROOT / "schemas" / "user_v1.sql"
        bundled = ROOT / "app" / "assets" / "database" / "user_v1.sql"
        self.assertEqual(normative.read_bytes(), bundled.read_bytes())

    def test_flutter_version_has_one_repository_source_of_truth(self) -> None:
        pubspec = (ROOT / "app/pubspec.yaml").read_text(encoding="utf-8")
        version_source = (ROOT / "app/lib/app_version.dart").read_text(
            encoding="utf-8"
        )
        pubspec_match = re.search(r"^version: ([0-9]+\.[0-9]+\.[0-9]+)\+([0-9]+)$", pubspec, re.M)
        name_match = re.search(r"static const name = '([^']+)';", version_source)
        build_match = re.search(r"static const buildNumber = ([0-9]+);", version_source)

        self.assertIsNotNone(pubspec_match)
        self.assertIsNotNone(name_match)
        self.assertIsNotNone(build_match)
        self.assertEqual(pubspec_match.group(1), name_match.group(1))
        self.assertEqual(pubspec_match.group(2), build_match.group(1))

    def test_ci_is_read_only_and_pins_third_party_actions(self) -> None:
        workflow = (
            ROOT / ".github/workflows/offline-validation.yml"
        ).read_text(encoding="utf-8")
        uses = re.findall(r"^\s*uses:\s*([^\s#]+)", workflow, re.M)

        self.assertIn("permissions:\n  contents: read", workflow)
        self.assertEqual(4, len(uses))
        self.assertEqual(3, len(set(uses)))
        self.assertEqual(2, workflow.count("persist-credentials: false"))
        for action in uses:
            with self.subTest(action=action):
                self.assertRegex(action, r"^[^@]+@[0-9a-f]{40}$")
        self.assertNotIn("secrets.", workflow)
        self.assertNotIn("bwiki", workflow.lower())

    def test_project_authored_text_is_english(self) -> None:
        checked_roots = [
            ROOT / "README.md",
            ROOT / "AGENTS.md",
            ROOT / "config",
            ROOT / "schemas",
            ROOT / "tools",
            ROOT / "tests",
            ROOT / ".github",
            ROOT / "licenses",
            ROOT / "release",
            ROOT / "docs/decisions",
            ROOT / "docs/evidence",
            ROOT / "docs/implementation-reports",
            ROOT / "app/lib",
            ROOT / "app/README.md",
            ROOT / "app/pubspec.yaml",
        ]
        text_suffixes = {
            ".dart",
            ".md",
            ".json",
            ".py",
            ".sql",
            ".toml",
            ".yaml",
            ".yml",
        }
        excluded = {ROOT / "docs/technical-spec-v1.md"}
        violations: list[str] = []

        for root in checked_roots:
            paths = [root] if root.is_file() else root.rglob("*")
            for path in paths:
                if not path.is_file() or path in excluded or path.suffix not in text_suffixes:
                    continue
                text = path.read_text(encoding="utf-8")
                if re.search(r"[\u3400-\u9fff]", text):
                    violations.append(str(path.relative_to(ROOT)))

        self.assertEqual([], violations)


if __name__ == "__main__":
    unittest.main()
