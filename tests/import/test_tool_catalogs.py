from __future__ import annotations

import json
from pathlib import Path
import struct
import tempfile
import unittest
from urllib.parse import parse_qs, urlparse

from bwiki_import.errors import ResponseValidationError, SnapshotWriteError
from bwiki_import.tool_catalogs import (
    derive_tool_asset_specs,
    import_tool_assets,
    parse_activity_catalog,
    parse_fashion_catalog,
)


ROOT = Path(__file__).resolve().parents[2]


class ToolCatalogImportTests(unittest.TestCase):
    def test_new_tool_asset_version_reuses_verified_bytes_and_rejects_corruption(self) -> None:
        class Transport:
            def __init__(self, allow_download):
                self.allow_download = allow_download

            def get_json(self, url):
                title = parse_qs(urlparse(url).query)["titles"][0]
                return {"batchcomplete": True, "query": {"pages": [{
                    "pageid": 1, "title": title, "ns": 6,
                    "imageinfo": [{
                        "timestamp": "2026-10-25T00:00:00Z", "size": 1000,
                        "width": 256, "height": 256, "sha1": "a" * 40,
                        "mime": "image/png", "mediatype": "BITMAP",
                        "url": "https://assets.example.test/images/tool/Icon.png",
                        "thumburl": "https://assets.example.test/images/tool/thumb/96px-Icon.png",
                    }],
                }]}}

            def get_png(self, url):
                if not self.allow_download:
                    raise AssertionError("Verified prior Tool images must not be downloaded again")
                return b"\x89PNG\r\n\x1a\n" + struct.pack(
                    ">I4sII", 13, b"IHDR", 8, 6
                ) + b"\x08\x06\x00\x00\x00"

        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            activity = root / "activity.json"
            fashion = root / "fashion.json"
            activity.write_text(json.dumps({
                "contract_version": 1, "dataset_id": "roco-world-zh-cn",
                "entries": [{"activity_id": "activity_1", "source_icon": "Icon.png",
                             "icon_path": "activities/icons/Icon.png"}],
            }))
            fashion.write_text(json.dumps({
                "contract_version": 1, "dataset_id": "roco-world-zh-cn", "entries": [],
            }))
            config = json.loads((ROOT / "config/wiki_tool_assets_v2.json").read_text())
            config.update(api_endpoint="https://wiki.example.test/api.php",
                          asset_host="assets.example.test", asset_path_prefix="/images/tool/")
            config["request_policy"].update(api_minimum_interval_seconds=0,
                                           download_minimum_interval_seconds=0)
            config_path = root / "config.json"
            config_path.write_text(json.dumps(config))
            original = import_tool_assets(activity, fashion, config_path, root / "output",
                                          transport=Transport(True))
            config["asset_version"] += 1
            config_path.write_text(json.dumps(config))
            reused = import_tool_assets(activity, fashion, config_path, root / "output",
                                        reuse_root=original.path, transport=Transport(False))
            relative = "activities/icons/Icon.png"
            self.assertEqual((original.path / relative).read_bytes(),
                             (reused.path / relative).read_bytes())
            (original.path / relative).write_bytes(b"corrupt")
            config["asset_version"] += 1
            config_path.write_text(json.dumps(config))
            with self.assertRaisesRegex(SnapshotWriteError, "Reusable image asset changed"):
                import_tool_assets(activity, fashion, config_path, root / "output",
                                   reuse_root=original.path, transport=Transport(False))

    def test_frozen_activity_and_fashion_contracts_are_complete(self) -> None:
        activity = json.loads(
            (ROOT / "app/assets/wiki/activity-timeline-v1.json").read_text(
                encoding="utf-8"
            )
        )
        fashion = json.loads(
            (ROOT / "app/assets/wiki/fashion-catalog-v1.json").read_text(
                encoding="utf-8"
            )
        )

        self.assertEqual(18960, activity["source"]["revision_id"])
        self.assertEqual(552, len(activity["entries"]))
        self.assertEqual(
            {"gifts": 46, "pets": 338, "challenge": 80, "fashion": 41, "events": 47},
            {
                category: sum(
                    entry["category"] == category
                    for entry in activity["entries"]
                )
                for category in activity["category_order"]
            },
        )
        self.assertEqual(18962, fashion["source"]["revision_id"])
        self.assertEqual(124, len(fashion["entries"]))
        self.assertEqual(
            248,
            sum(len(entry["variants"]) for entry in fashion["entries"]),
        )
        self.assertTrue(
            all("source_record" in entry for entry in activity["entries"])
        )
        self.assertTrue(
            all("source_record" in entry for entry in fashion["entries"])
        )

    def test_tool_media_manifest_closes_every_normalized_reference(self) -> None:
        specs = derive_tool_asset_specs(
            ROOT / "app/assets/wiki/activity-timeline-v1.json",
            ROOT / "app/assets/wiki/fashion-catalog-v1.json",
            ROOT / "config/wiki_tool_assets_v2.json",
        )
        manifest = json.loads(
            (
                ROOT
                / "app/assets/wiki/tools/v2/asset-manifest.json"
            ).read_text(encoding="utf-8")
        )

        self.assertEqual(307, len(specs))
        self.assertEqual(307, manifest["asset_count"])
        self.assertEqual(796, manifest["reference_count"])
        self.assertEqual(
            {spec.local_path for spec in specs},
            {record["local_path"] for record in manifest["assets"]},
        )
        for spec in specs:
            self.assertTrue((ROOT / "app/assets/wiki/tools/v2" / spec.local_path).is_file())

    def test_activity_parser_preserves_source_and_rejects_bad_windows(self) -> None:
        content = (
            'return {activity_1={category="gifts",description="Details",'
            'id="activity_1",kind="kind",kind_label="Gifts",name="Event",'
            'page_title="Event",prerequisite=nil,related={},relation_targets={},'
            'returning_player_only=false,reward_overviews=nil,'
            'season_spanning_single=false,series_id="series_1",shop_ids={},'
            'source_id=1,stages={},summary="Summary",'
            'arrivals={1},collection_rewards={reward="Item"},letters={},'
            'missions={{id=3}},paid_bundles=nil,clues={"Hint"},'
            'newspapers={edition=2},opponents={{pet="pet_1"}},'
            'visual={icon="Activity.png",poster=nil,posters=nil},'
            'window={end="2026-09-02 03:59:59",'
            'start="2026-09-01 04:00:00",timezone="UTC+8"}}}'
        )
        entries = parse_activity_catalog(
            content,
            source="Module:Activities",
            categories=["gifts"],
            expected_count=1,
        )

        self.assertEqual("activity_1", entries[0]["activity_id"])
        self.assertEqual("2026-09-01T04:00:00+08:00", entries[0]["start_at"])
        self.assertEqual("Details", entries[0]["source_record"]["description"])
        self.assertEqual([1], entries[0]["source_record"]["arrivals"])
        self.assertEqual({"reward": "Item"}, entries[0]["source_record"]["collection_rewards"])
        self.assertEqual([{"id": 3}], entries[0]["source_record"]["missions"])
        self.assertIsNone(entries[0]["source_record"]["paid_bundles"])
        self.assertEqual({"edition": 2}, entries[0]["source_record"]["newspapers"])
        self.assertEqual([{"pet": "pet_1"}], entries[0]["source_record"]["opponents"])
        with self.assertRaisesRegex(ResponseValidationError, "unexpected fields"):
            parse_activity_catalog(
                content.replace('summary="Summary"', 'summary="Summary",unsupported_field=1'),
                source="Module:Activities", categories=["gifts"], expected_count=1,
            )
        with self.assertRaisesRegex(ResponseValidationError, "reversed"):
            parse_activity_catalog(
                content.replace(
                    "2026-09-02 03:59:59", "2026-08-31 03:59:59"
                ),
                source="Module:Activities",
                categories=["gifts"],
                expected_count=1,
            )

    def test_fashion_parser_preserves_variants_and_rejects_code(self) -> None:
        content = (
            'return {fashion_000001={description="D",genders={"male","female"},'
            'grade=1,grade_name="Grade",id="fashion_000001",name="Outfit",'
            'page_title="Outfit",quality=4,series_id=1,source_ids={1,2},'
            'same_name_ids={"fashion_000002"},title_suffix="Edition",'
            'style_key="001",variants={female={acquire={"Shop"},'
            'card_image="Female.png",description="FD",gender="female",'
            'gender_label="Female",item_count=5,main_image="FemaleMain.png",'
            'name="Female Outfit",piece_ids={1},quality=4,series_id=1,'
            'source_id=2,source_ids={2},pet={id=30},bonus_ids={4}},male={acquire={"Shop"},'
            'card_image="Male.png",description="MD",gender="male",'
            'gender_label="Male",item_count=5,main_image="MaleMain.png",'
            'name="Male Outfit",piece_ids={2},quality=4,series_id=1,'
            'source_id=1,source_ids={1}}}}}'
        )
        entries = parse_fashion_catalog(
            content,
            source="Module:Fashions",
            expected_count=1,
            gender_order=["female", "male"],
            image_overrides={},
        )

        self.assertEqual(["female", "male"], [v["gender"] for v in entries[0]["variants"]])
        self.assertEqual(["Shop"], entries[0]["variants"][0]["acquisition"])
        self.assertEqual(["fashion_000002"], entries[0]["source_record"]["same_name_ids"])
        self.assertEqual("Edition", entries[0]["source_record"]["title_suffix"])
        self.assertEqual({"id": 30}, entries[0]["source_record"]["variants"]["female"]["pet"])
        self.assertEqual([4], entries[0]["source_record"]["variants"]["female"]["bonus_ids"])
        with self.assertRaisesRegex(ResponseValidationError, "unexpected fields"):
            parse_fashion_catalog(
                content.replace('style_key="001"', 'style_key="001",unsupported_field=1'),
                source="Module:Fashions", expected_count=1,
                gender_order=["female", "male"], image_overrides={},
            )
        with self.assertRaisesRegex(ResponseValidationError, "unsupported"):
            parse_fashion_catalog(
                content.replace('name="Outfit"', "name=build()"),
                source="Module:Fashions",
                expected_count=1,
                gender_order=["female", "male"],
                image_overrides={},
            )


if __name__ == "__main__":
    unittest.main()
