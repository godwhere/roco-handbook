from __future__ import annotations

import json
import hashlib
from pathlib import Path
import struct
import tempfile
import unittest
from urllib.parse import parse_qs, urlparse

from bwiki_import.errors import ResponseValidationError, SnapshotWriteError
from bwiki_import.image_assets import (
    _metadata_for_batch,
    _png_dimensions,
    derive_asset_specs,
    import_image_assets,
)


ROOT = Path(__file__).resolve().parents[2]


def _png(width: int = 8, height: int = 6) -> bytes:
    return b"\x89PNG\r\n\x1a\n" + struct.pack(
        ">I4sII", 13, b"IHDR", width, height
    ) + b"\x08\x06\x00\x00\x00"


def _config() -> dict[str, object]:
    return {
        "config_version": 1,
        "dataset_id": "roco-world-zh-cn",
        "asset_version": 1,
        "api_endpoint": "https://wiki.example.test/api.php",
        "asset_host": "assets.example.test",
        "asset_path_prefix": "/images/rocom/",
        "request_policy": {
            "api_batch_size": 50,
            "api_minimum_interval_seconds": 0,
            "download_minimum_interval_seconds": 0,
            "connect_timeout_seconds": 1,
            "read_timeout_seconds": 1,
            "max_retries": 1,
            "max_asset_bytes": 100000,
        },
        "thumbnail_widths": {
            "pet_head": 128,
            "pet_illustration": 512,
            "skill_icon": 128,
            "ui_icon": 64,
        },
        "ui_assets": [
            {
                "asset_id": "navigation",
                "source_title": "File:Navigation.png",
                "local_path": "ui/navigation.png",
            }
        ],
    }


class _Transport:
    def __init__(self) -> None:
        self.png = _png()

    def get_json(self, url: str) -> dict[str, object]:
        query = parse_qs(urlparse(url).query)
        width = int(query["iiurlwidth"][0])
        pages = []
        for index, title in enumerate(query["titles"][0].split("|"), start=1):
            canonical = "\u6587\u4ef6:" + title.removeprefix("File:")
            stem = title.removeprefix("File:").replace(" ", "_")
            pages.append(
                {
                    "pageid": index,
                    "ns": 6,
                    "title": canonical,
                    "imageinfo": [
                        {
                            "timestamp": "2026-09-10T00:00:00Z",
                            "size": 1000,
                            "width": 1024,
                            "height": 1024,
                            "thumburl": (
                                "https://assets.example.test/images/rocom/thumb/"
                                f"{width}px-{stem}"
                            ),
                            "url": (
                                "https://assets.example.test/images/rocom/"
                                f"{stem}"
                            ),
                            "sha1": f"{index:040x}",
                            "mime": "image/png",
                            "mediatype": "BITMAP",
                        }
                    ],
                }
            )
        return {"batchcomplete": True, "query": {"pages": pages}}

    def get_png(self, url: str) -> bytes:
        return self.png


class ImageAssetTests(unittest.TestCase):
    def test_platform_brand_assets_replace_flutter_placeholders(self) -> None:
        cases = {
            ROOT
            / "app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png": (
                1024,
                1024,
            ),
            ROOT
            / "app/ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@3x.png": (
                600,
                600,
            ),
            ROOT
            / "app/android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png": (
                192,
                192,
            ),
            ROOT
            / "app/android/app/src/main/res/drawable-nodpi/launch_image.png": (
                384,
                384,
            ),
        }
        for path, expected in cases.items():
            with self.subTest(path=path):
                self.assertEqual(expected, _png_dimensions(path.read_bytes()))
                self.assertGreater(path.stat().st_size, 1000)

        display_name = "\u6d1b\u514b\u738b\u56fd\uff1a\u4e16\u754c\u56fe\u9274"
        self.assertIn(
            display_name,
            (ROOT / "app/ios/Runner/Info.plist").read_text(encoding="utf-8"),
        )
        self.assertIn(
            display_name,
            (
                ROOT / "app/android/app/src/main/AndroidManifest.xml"
            ).read_text(encoding="utf-8"),
        )

    def test_frozen_asset_manifest_matches_every_bundled_png(self) -> None:
        root = ROOT / "app/assets/wiki/v1"
        manifest = json.loads(
            (root / "asset-manifest.json").read_text(encoding="utf-8")
        )
        records = manifest["assets"]

        self.assertEqual(1936, manifest["asset_count"])
        self.assertEqual(2015, manifest["reference_count"])
        self.assertEqual(
            manifest["total_bytes"],
            sum(record["local_bytes"] for record in records),
        )
        recorded_paths = {record["local_path"] for record in records}
        actual_paths = {
            path.relative_to(root).as_posix() for path in root.rglob("*.png")
        }
        self.assertEqual(recorded_paths, actual_paths)
        for record in records:
            with self.subTest(asset_id=record["asset_id"]):
                payload = (root / record["local_path"]).read_bytes()
                self.assertEqual(record["local_bytes"], len(payload))
                self.assertEqual(
                    record["local_sha256"], hashlib.sha256(payload).hexdigest()
                )

    def test_derives_complete_current_catalog_scope(self) -> None:
        specs = derive_asset_specs(
            ROOT / "data/normalized/snapshot-19235f9b9b34dc4e/catalog-v1.json",
            ROOT / "config/wiki_assets_v1.json",
        )

        counts = {
            kind: sum(1 for item in specs if item.kind == kind)
            for kind in {item.kind for item in specs}
        }
        self.assertEqual(
            {
                "pet_head": 596,
                "pet_illustration": 569,
                "skill_icon": 736,
                "ui_icon": 35,
            },
            counts,
        )
        self.assertEqual(2015, sum(len(item.catalog_ids) for item in specs))
        self.assertIn(
            "File:Head 3001.png",
            {item.source_title for item in specs},
        )
        self.assertIn(
            "File:Feature 200076.png",
            {item.source_title for item in specs},
        )
        by_id = {item.asset_id: item for item in specs}
        self.assertEqual(
            "File:Head 4079.png",
            by_id["pet_head:Head_5001"].source_title,
        )
        self.assertEqual(
            "File:JL baomizai.png",
            by_id["pet_head:Head_3759"].source_title,
        )

    def test_rejects_missing_and_non_allowlisted_metadata(self) -> None:
        config = _config()
        title = "File:Head 3001.png"
        missing = {
            "batchcomplete": True,
            "query": {
                "pages": [
                    {"ns": 6, "title": "\u6587\u4ef6:Head 3001.png", "missing": True}
                ]
            },
        }
        with self.assertRaisesRegex(ResponseValidationError, "missing"):
            _metadata_for_batch(missing, {title}, 128, config)

        invalid = _Transport().get_json(
            "https://wiki.example.test/api.php?"
            "titles=File%3AHead+3001.png&iiurlwidth=128"
        )
        invalid["query"]["pages"][0]["imageinfo"][0]["url"] = (
            "https://evil.example/images/rocom/head.png"
        )
        with self.assertRaisesRegex(ResponseValidationError, "allowlist"):
            _metadata_for_batch(invalid, {title}, 128, config)

    def test_validates_png_signature_and_dimensions(self) -> None:
        self.assertEqual((8, 6), _png_dimensions(_png()))
        with self.assertRaisesRegex(ResponseValidationError, "valid PNG"):
            _png_dimensions(b"not a png")

    def test_freezes_and_reuses_a_verified_asset_set(self) -> None:
        catalog = {
            "dataset_id": "roco-world-zh-cn",
            "pets": [
                {
                    "status": "active",
                    "pet_id": "pet_1",
                    "head_key": "Head_1",
                    "illustration_key": "JL_one",
                }
            ],
            "skills": [
                {
                    "status": "active",
                    "skill_id": "skill_1",
                    "category": "\u7279\u6027",
                    "icon_key": "200001",
                }
            ],
        }
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            catalog_path = root / "catalog.json"
            config_path = root / "config.json"
            catalog_path.write_text(json.dumps(catalog), encoding="utf-8")
            config_path.write_text(json.dumps(_config()), encoding="utf-8")
            transport = _Transport()

            frozen = import_image_assets(
                catalog_path,
                config_path,
                root / "assets",
                transport=transport,
                sleep=lambda _: None,
            )
            reused = import_image_assets(
                catalog_path,
                config_path,
                root / "assets",
                transport=transport,
                sleep=lambda _: None,
            )

            self.assertEqual(4, frozen.asset_count)
            self.assertEqual(4, frozen.reference_count)
            self.assertFalse(frozen.reused_existing)
            self.assertTrue(reused.reused_existing)
            manifest = json.loads(frozen.manifest_path.read_text(encoding="utf-8"))
            self.assertEqual(4, manifest["asset_count"])
            self.assertEqual(
                {"pet_head", "pet_illustration", "skill_icon", "ui_icon"},
                {item["kind"] for item in manifest["assets"]},
            )

            manifest["assets"][0]["catalog_ids"] = ["different_id"]
            frozen.manifest_path.write_text(
                json.dumps(manifest), encoding="utf-8"
            )
            with self.assertRaisesRegex(SnapshotWriteError, "record changed"):
                import_image_assets(
                    catalog_path,
                    config_path,
                    root / "assets",
                    transport=transport,
                    sleep=lambda _: None,
                )


if __name__ == "__main__":
    unittest.main()
