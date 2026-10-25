from __future__ import annotations

import base64
import gzip
import hashlib
import json
from pathlib import Path
import tempfile
import unittest

from bwiki_import.errors import ResponseValidationError, SnapshotWriteError
from bwiki_import.reference_catalogs import (
    ReferenceIdentityReview,
    _head_rows,
    _write_new,
    decode_map_part,
    freeze_reference_sources,
    load_reference_snapshot,
    map_configuration,
    medal_progress_targets,
    parse_data_table,
    parse_trial_markup,
    reference_configuration,
    validate_reference_links,
)

ROOT = Path(__file__).resolve().parents[2]
FIXTURES = Path(__file__).parent / "fixtures/references"


def wrapper(title: str, payload: bytes) -> str:
    encoded = "gz1:" + base64.b64encode(gzip.compress(payload, mtime=0)).decode()
    return "window.NrcWorldMap.receive(" + json.dumps(title) + "," + json.dumps(encoded) + ");"


class ReferenceCatalogTests(unittest.TestCase):
    def test_data_only_parser_keeps_variants_unknown_null_and_rejects_execution(self) -> None:
        raw = parse_data_table((FIXTURES / "items.lua").read_text(), "owned-items")
        record = raw["item_000000000001"]
        self.assertEqual(2, len(record["variants"]))
        self.assertIsNone(record["unknown"]["condition"])
        self.assertFalse(record["unknown"]["flag"])
        self.assertEqual([], record["variants"][0]["acquire"])
        self.assertEqual(3, record["variants"][1]["condition"]["count"])
        for invalid in ('return require("Module:Other")', 'return {a=1,a=2}', 'return {}'):
            with self.subTest(invalid=invalid), self.assertRaises(ResponseValidationError):
                parse_data_table(invalid, "owned-invalid")

    def test_map_wrapper_rejects_wrong_identity_code_duplicate_keys_and_gzip_bombs(self) -> None:
        title = "MediaWiki:WorldMap/data/owned.js"
        value = {"points": [{"id": "p-1111111111111111", "unknown": None}]}
        self.assertEqual(value, decode_map_part(wrapper(title, json.dumps(value).encode()), title, max_bytes=1024))
        for content in (
                wrapper("MediaWiki:Wrong.js", b"[]"),
                wrapper(title, b"[]") + "alert(1);",
                wrapper(title, b'{"x":1,"x":2}'),
                wrapper(title, b'"' + b"x" * 2048 + b'"'),
                'window.NrcWorldMap.receive("x",require("x"));'):
            with self.subTest(content=content[:80]), self.assertRaises(ResponseValidationError):
                decode_map_part(content, title, max_bytes=1024)

    def test_map_config_reads_only_the_initial_literal_without_running_loader(self) -> None:
        content = '/* owned */\n  const config = {"data":{}};\n  const config = computeLater();'
        self.assertEqual({"data": {}}, map_configuration(content))
        for invalid in ('  const config = load();', '  const config = {"a":1,"a":2};', 'let config={};'):
            with self.assertRaises(ResponseValidationError):
                map_configuration(invalid)

    def test_trial_markup_keeps_explicit_form_targets_and_rejects_duplicate_ids(self) -> None:
        text = (FIXTURES / "trial.lua").read_text()
        groups, cards = parse_trial_markup(text, expected_count=2)
        self.assertEqual("Owned region", groups[0]["title"])
        self.assertEqual("Owned floors 1 and 3", groups[0]["floor_context"])
        self.assertEqual("Form A", cards[0]["attributes"]["data-form-name"])
        self.assertIn("Owned creature (form B)", cards[1]["text"])
        for invalid in (text.replace("gt_2222222222222222", "gt_1111111111111111"),
                        text.replace('data-encounter-total="2"', 'data-encounter-total="1"'),
                        text.replace("</div></div></div>]=]}", "</div></div>]=]}")):
            with self.assertRaises(ResponseValidationError):
                parse_trial_markup(invalid, expected_count=2)

    def test_shared_avatar_never_selects_a_default_or_strips_map_suffix(self) -> None:
        pets = [{"pet_id": "pet_000001", "title": "Owned A", "name": "Owned", "form": "A", "description": "Text"},
                {"pet_id": "pet_000002", "title": "Owned B", "name": "Owned", "form": "B", "description": "Text"}]
        index = {"titles": {p["pet_id"]: p["title"] for p in pets},
                 "avatars": {p["pet_id"]: "Owned.png" for p in pets}}
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary); (root / "v4").mkdir()
            (root / "v4/asset-manifest.json").write_text('{"assets":[]}')
            identities = ReferenceIdentityReview({"pets": pets}, index, root, {})
            self.assertIsNone(identities.habitat("habitats:p-1111111111111111",
                {"name": "Owned", "form": "A", "description": "Text", "icon": "/owned"}, {"/owned": "Owned.png"}))
            self.assertEqual("ambiguous", identities.results[-1]["status"])
            self.assertIsNone(identities.habitat("habitats:p-1111111111111111",
                {"name": "Owned", "form": "A", "description": "Text", "icon": "/owned"}, {"/owned": "Owned_Map.png"}))
            self.assertEqual("unmapped", identities.results[-1]["status"])

    def test_incomplete_or_wrong_identity_head_fails(self) -> None:
        expected = [{"key": "owned", "title": "Module:Items/data/Catalog", "page_id": 1}]
        for document in ({"batchcomplete": True, "query": {"pages": []}},
                         {"batchcomplete": True, "query": {"pages": [{"pageid": 2}]}},
                         {"query": {"pages": []}}):
            with self.assertRaises(ResponseValidationError):
                _head_rows(document, expected)

    def test_live_freeze_rejects_head_drift_and_detects_frozen_corruption(self) -> None:
        body = 'return {owned={id="owned",unknown=nil}}'

        class Transport:
            def __init__(self, drift=False): self.drift = drift; self.head_count = 0
            def post_json(self, endpoint, form):
                self.assert_endpoint = endpoint
                if form["rvprop"] == "ids":
                    self.head_count += 1
                    rev = 2 if self.drift and self.head_count > 1 else 1
                    return {"batchcomplete": True, "query": {"pages": [{"pageid": 1,
                        "title": "Module:Items/data/Catalog", "revisions": [{"revid": rev}]}]}}
                return {"batchcomplete": True, "query": {"pages": [{"pageid": 1,
                    "title": "Module:Items/data/Catalog", "revisions": [{"revid": 1,
                    "timestamp": "2026-10-26T00:00:00Z", "sha1": hashlib.sha1(body.encode()).hexdigest(),
                    "size": len(body.encode()), "slots": {"main": {"contentmodel": "Scribunto", "content": body}}}]}]}}

        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            config = json.loads((ROOT / "config/reference_sources_v1.json").read_text())
            config["sources"] = [{"key": "owned", "title": "Module:Items/data/Catalog", "page_id": 1, "content_model": "Scribunto"}]
            config["frozen_inputs"] = []; config["request_policy"]["minimum_interval_seconds"] = 0
            path = root / "config.json"; path.write_text(json.dumps(config))
            with self.assertRaisesRegex(ResponseValidationError, "heads changed"):
                freeze_reference_sources(path, root / "drift", transport=Transport(True), sleep=lambda _: None)
            self.assertFalse((root / "drift").exists())
            snapshot = freeze_reference_sources(path, root / "valid", transport=Transport(), sleep=lambda _: None)
            load_reference_snapshot(snapshot.path, reference_configuration(path))
            (snapshot.path / "content/owned.lua").write_text(body + "\n")
            with self.assertRaises(ResponseValidationError):
                load_reference_snapshot(snapshot.path, reference_configuration(path))

    def test_immutable_writer_and_native_link_closure_reject_incorrect_results(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            path = Path(temporary) / "owned.json"
            _write_new(path, {"value": 1}); _write_new(path, {"value": 1})
            with self.assertRaises(SnapshotWriteError): _write_new(path, {"value": 2})
        documents = {"items": {"entries": [{"id": "item_111111111111", "links": [{"kind": "pet", "id": "pet_000002"}]}]}}
        with self.assertRaises(ResponseValidationError):
            validate_reference_links(documents, {"pets": [{"pet_id": "pet_000001"}]})

    def test_packaged_real_contract_preserves_counts_variants_recipes_and_media_gap(self) -> None:
        root = ROOT / "app/assets/wiki/references/v1"
        documents = {kind: json.loads((root / (kind + ".json")).read_text())
                     for kind in ("items", "research", "medals", "trials", "habitats")}
        self.assertEqual([1534, 2351, 60, 726, 109], [len(value["entries"]) for value in documents.values()])
        self.assertEqual(56, sum(row["visible"] for row in documents["medals"]["entries"]))
        self.assertEqual(1835, sum(len(row["raw"]["detail"]["variants"]) for row in documents["items"]["entries"]))
        self.assertEqual(1545, sum(len(row["raw"]["detail"]["habitat"]["pets"]) for row in documents["habitats"]["entries"]))
        self.assertTrue(all(row["raw"]["section"]["floor_context"] in row["sections"][0]["lines"] for row in documents["trials"]["entries"]))
        self.assertTrue(any(str(reward["name"]).startswith("\u914d\u65b9-") for row in documents["research"]["entries"] for reward in row["raw"]["topic"]["rewards"]))
        missing = next(row for row in documents["items"]["entries"] if row["id"] == "item_a73c5a669658")
        self.assertNotIn("image_path", missing)
        for kind, document in documents.items():
            self.assertLess((root / (kind + ".json")).stat().st_size, 8 * 1024 * 1024)
            self.assertEqual(len(document["entries"]), len({row["id"] for row in document["entries"]}))
            for row in document["entries"] + document["groups"]:
                if row.get("image_path"):
                    self.assertTrue((ROOT / "app/assets" / row["image_path"]).is_file())
        self.assertFalse(any(path.suffix in {".js", ".lua"} for path in root.rglob("*")))

    def test_medal_acquisition_presents_tiers_targets_and_scope_without_serialized_objects(self) -> None:
        document = json.loads((ROOT / "app/assets/wiki/references/v1/medals.json").read_text())
        upgraded = next(row for row in document["entries"] if row["id"] == "medal_4011")
        sections = {section["title"]: section["lines"] for section in upgraded["sections"]}
        self.assertEqual(3, len(sections["Upgrades"]))
        self.assertTrue(all(not line.startswith("{") for line in sections["Upgrades"]))
        self.assertTrue(any("9000" in line for line in sections["Progress targets"]))
        self.assertTrue(any("9900" in line for line in sections["Progress targets"]))
        bond = next(row for row in document["entries"] if row["id"] == "medal_1017")
        species = next(section for section in bond["sections"] if section["title"] == "Species range")
        self.assertEqual(4, len(species["lines"]))

    def test_medal_target_one_is_not_swallowed_by_description_containing_ten(self) -> None:
        record = {"name": "Owned target fixture", "tasks": [
            {"condition_label": "Completion", "count": 1, "description": "Learn 10 skills", "deprecated": False},
            {"condition_label": "Old goal", "count": 1, "description": "Learn 10 skills", "deprecated": True}],
            "upgrade_tiers": [{"label": "Silver", "progress_target": 1, "description": "Win 10 battles"}]}
        self.assertEqual(["Completion · 1", "Silver · 1"], medal_progress_targets(record))
        document = json.loads((ROOT / "app/assets/wiki/references/v1/medals.json").read_text())
        for identifier in ("medal_1009", "medal_1010"):
            entry = next(row for row in document["entries"] if row["id"] == identifier)
            targets = next(section["lines"] for section in entry["sections"] if section["title"] == "Progress targets")
            self.assertEqual(medal_progress_targets(entry["raw"]), targets)
            self.assertTrue(any(line.endswith(" · 1") for line in targets))


if __name__ == "__main__":
    unittest.main()
