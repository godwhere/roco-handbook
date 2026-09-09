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
            "docs/evidence/environment-2026-09-09.md",
            "config/bwiki_sources.json",
            "config/identity_registry.json",
            "config/type_aliases.json",
            "config/handbook_display_overrides.json",
            "config/reviewed_exceptions.json",
            "schemas/catalog_v1.sql",
            "schemas/user_v1.sql",
            "schemas/manifests/bundled_catalog_v1.schema.json",
            "tools/pyproject.toml",
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

    def test_project_authored_text_is_english(self) -> None:
        checked_roots = [
            ROOT / "README.md",
            ROOT / "AGENTS.md",
            ROOT / "config",
            ROOT / "schemas",
            ROOT / "tools",
            ROOT / "tests",
            ROOT / "docs/decisions",
            ROOT / "docs/evidence",
            ROOT / "docs/implementation-reports",
            ROOT / "app/lib",
            ROOT / "app/README.md",
            ROOT / "app/pubspec.yaml",
        ]
        text_suffixes = {".dart", ".md", ".json", ".py", ".sql", ".toml", ".yaml"}
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
