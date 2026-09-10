from __future__ import annotations

import json
from pathlib import Path
import unittest

from bwiki_import.errors import ResponseValidationError
from bwiki_import.tool_catalogs import (
    derive_tool_asset_specs,
    parse_activity_catalog,
    parse_fashion_catalog,
)


ROOT = Path(__file__).resolve().parents[2]


class ToolCatalogImportTests(unittest.TestCase):
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

        self.assertEqual(10044, activity["source"]["revision_id"])
        self.assertEqual(547, len(activity["entries"]))
        self.assertEqual(
            {"gifts": 47, "pets": 329, "challenge": 77, "fashion": 35, "events": 59},
            {
                category: sum(
                    entry["category"] == category
                    for entry in activity["entries"]
                )
                for category in activity["category_order"]
            },
        )
        self.assertEqual(12224, fashion["source"]["revision_id"])
        self.assertEqual(110, len(fashion["entries"]))
        self.assertEqual(
            220,
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
            ROOT / "config/wiki_tool_assets_v1.json",
        )
        manifest = json.loads(
            (
                ROOT
                / "app/assets/wiki/tools/v1/asset-manifest.json"
            ).read_text(encoding="utf-8")
        )

        self.assertEqual(273, len(specs))
        self.assertEqual(273, manifest["asset_count"])
        self.assertEqual(749, manifest["reference_count"])
        self.assertEqual(
            {spec.local_path for spec in specs},
            {record["local_path"] for record in manifest["assets"]},
        )
        for spec in specs:
            self.assertTrue((ROOT / "app/assets/wiki/tools/v1" / spec.local_path).is_file())

    def test_activity_parser_preserves_source_and_rejects_bad_windows(self) -> None:
        content = (
            'return {activity_1={category="gifts",description="Details",'
            'id="activity_1",kind="kind",kind_label="Gifts",name="Event",'
            'page_title="Event",prerequisite=nil,related={},relation_targets={},'
            'returning_player_only=false,reward_overviews=nil,'
            'season_spanning_single=false,series_id="series_1",shop_ids={},'
            'source_id=1,stages={},summary="Summary",'
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
            'style_key="001",variants={female={acquire={"Shop"},'
            'card_image="Female.png",description="FD",gender="female",'
            'gender_label="Female",item_count=5,main_image="FemaleMain.png",'
            'name="Female Outfit",piece_ids={1},quality=4,series_id=1,'
            'source_id=2,source_ids={2}},male={acquire={"Shop"},'
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
