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
        "asset_version": 2,
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
    def test_store_screenshots_are_submission_eligible_rgb_pngs(self) -> None:
        screenshot_root = ROOT / "docs/evidence/phase-8-store-screenshots"
        expected = {
            "ios": {
                "dimensions": (1206, 2622),
                "names": {
                    "01-creature-catalog.png",
                    "02-creature-detail-stats.png",
                    "03-type-relationships.png",
                    "04-skill-catalog.png",
                },
            },
            "android": {
                "dimensions": (1080, 1920),
                "names": {
                    "01-creature-catalog.png",
                    "02-creature-detail-stats.png",
                    "03-type-relationships.png",
                    "04-skill-catalog.png",
                },
            },
        }

        for platform, contract in expected.items():
            paths = sorted((screenshot_root / platform).glob("*.png"))
            self.assertEqual(contract["names"], {path.name for path in paths})
            for path in paths:
                with self.subTest(platform=platform, path=path.name):
                    payload = path.read_bytes()
                    dimensions = _png_dimensions(payload)
                    self.assertEqual(contract["dimensions"], dimensions)
                    self.assertEqual(8, payload[24], "PNG must use 8-bit channels")
                    self.assertEqual(2, payload[25], "PNG must be RGB without alpha")
                    self.assertLessEqual(len(payload), 8 * 1024 * 1024)
                    if platform == "android":
                        self.assertLessEqual(max(dimensions), 2 * min(dimensions))

    def test_platform_brand_assets_replace_flutter_placeholders(self) -> None:
        cases = {
            ROOT
            / "app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@1x.png": (
                (20, 20),
                "3b8334e60415e87b76a88fb73291d282bba0c96c4aa49fad068c2794358d3673",
            ),
            ROOT
            / "app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@2x.png": (
                (40, 40),
                "bc49fecccb1cc89ddf84aea83911264b6c9ba140b2076794ea2353f35f15f267",
            ),
            ROOT
            / "app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@3x.png": (
                (60, 60),
                "e035e9aa734f2a6c1b1e472f9bd5d86622d5fbcccf8fd863da0c401701ae7e22",
            ),
            ROOT
            / "app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@1x.png": (
                (29, 29),
                "9ed785e8c71f689befa555c8c76f0e3bf5f331b6eb1b1ca3e6a34803b4ca92dd",
            ),
            ROOT
            / "app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@2x.png": (
                (58, 58),
                "fc063794049f6ed1754085d2afd029b5814f8646635b6253ead94d02a70e1278",
            ),
            ROOT
            / "app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@3x.png": (
                (87, 87),
                "fc0bd89031b58f9b8c09306d8e15c41fb114ec5500849e1b28b9d8f33c330b86",
            ),
            ROOT
            / "app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@1x.png": (
                (40, 40),
                "bc49fecccb1cc89ddf84aea83911264b6c9ba140b2076794ea2353f35f15f267",
            ),
            ROOT
            / "app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@2x.png": (
                (80, 80),
                "f38796252485ad58dbe207a3bff706ba75923121479a74302b36234696fa32c7",
            ),
            ROOT
            / "app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@3x.png": (
                (120, 120),
                "d24c3aba70954261d7ca9b06249912099c669f1d8fd9b5b8b75c121e4b0b32ed",
            ),
            ROOT
            / "app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@2x.png": (
                (120, 120),
                "d24c3aba70954261d7ca9b06249912099c669f1d8fd9b5b8b75c121e4b0b32ed",
            ),
            ROOT
            / "app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@3x.png": (
                (180, 180),
                "37ff2f8251e95b738444a79c1a49434d21ee1a7bfc85e7144412f71d16b52c57",
            ),
            ROOT
            / "app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@1x.png": (
                (76, 76),
                "3094dbb43384ea5900b6a451b1c01165470ee565c71b3c22e081bd749cd7691d",
            ),
            ROOT
            / "app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@2x.png": (
                (152, 152),
                "394d6048a2e1edb960d2fe39889fc9ce54f9dee734d6aaccfbe2d1a51f9b360d",
            ),
            ROOT
            / "app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-83.5x83.5@2x.png": (
                (167, 167),
                "1c4eb88b619ec452588d58de4d0f0951e13a9edc6bb69333866c310849c91fb0",
            ),
            ROOT
            / "app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png": (
                (1024, 1024),
                "b6d3277e8eba499b6d81a47108f5959b283b01e7755b80051e515f7dace4ab89",
            ),
            ROOT
            / "app/ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage.png": (
                (200, 200),
                "b3d667c107248482e4d9726a0fa05bfffd6d7d253c98f4d2ae0df5691806d49e",
            ),
            ROOT
            / "app/ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@2x.png": (
                (400, 400),
                "294d51f1669dd234de4f46117323ddeaa4ad989e6e49b2e1c1f5df97f369bda1",
            ),
            ROOT
            / "app/ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@3x.png": (
                (600, 600),
                "29750876e644a50ebb4fc830f0eec2251c8340ccde2a70af66f910a6bd51d24a",
            ),
            ROOT
            / "app/android/app/src/main/res/mipmap-mdpi/ic_launcher.png": (
                (48, 48),
                "c4d710a857ffefc7e9f8fec1956c89bf9d054d68ffdbe802435d965b0844ab54",
            ),
            ROOT
            / "app/android/app/src/main/res/mipmap-hdpi/ic_launcher.png": (
                (72, 72),
                "c1a082911f64d1714f124e82800a1360763f635e4477d4080e6a81a3c7403a4c",
            ),
            ROOT
            / "app/android/app/src/main/res/mipmap-xhdpi/ic_launcher.png": (
                (96, 96),
                "d41f74055c558ae20f55c2f7cd9d039a531b7014b77e98e22b50a0e05de1a45a",
            ),
            ROOT
            / "app/android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png": (
                (144, 144),
                "ab9f7f057e64f9613e187f59747920965ed8eaf1f3cb0a67b14539e133c9b462",
            ),
            ROOT
            / "app/android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png": (
                (192, 192),
                "b6c9d5481836160ed5af1ec73acb8914907b404381bff662aa47b54ddddb4076",
            ),
            ROOT
            / "app/android/app/src/main/res/drawable-nodpi/launch_image.png": (
                (384, 384),
                "062afaefdc8993ba61a5d30cbf014f947c7fa375da8a6c175c21f031fdd1eafe",
            ),
        }
        actual_platform_pngs = {
            *(
                ROOT / "app/ios/Runner/Assets.xcassets/AppIcon.appiconset"
            ).glob("*.png"),
            *(
                ROOT / "app/ios/Runner/Assets.xcassets/LaunchImage.imageset"
            ).glob("*.png"),
            *(
                ROOT / "app/android/app/src/main/res"
            ).glob("mipmap-*/ic_launcher.png"),
            ROOT
            / "app/android/app/src/main/res/drawable-nodpi/launch_image.png",
        }
        self.assertEqual(set(cases), actual_platform_pngs)
        for path, (expected_dimensions, expected_sha256) in cases.items():
            with self.subTest(path=path):
                payload = path.read_bytes()
                self.assertEqual(expected_dimensions, _png_dimensions(payload))
                self.assertEqual(expected_sha256, hashlib.sha256(payload).hexdigest())
                self.assertGreater(path.stat().st_size, 1000)

        brand_source = (
            ROOT / "app/assets/wiki/v2/pets/illustrations/JL_dimo.png"
        ).read_bytes()
        self.assertEqual(
            "485d76e697b8f75d63a4036cf534c146b7d22addde663b831f80900e7018eb77",
            hashlib.sha256(brand_source).hexdigest(),
        )
        self.assertIn(
            "app/assets/wiki/v2/pets/illustrations/JL_dimo.png",
            (ROOT / "tools/brand/generate_brand_assets.swift").read_text(
                encoding="utf-8"
            ),
        )

        display_name = "\u6d1b\u514b\u624b\u518c"
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
        root = ROOT / "app/assets/wiki/v2"
        manifest = json.loads(
            (root / "asset-manifest.json").read_text(encoding="utf-8")
        )
        records = manifest["assets"]

        self.assertEqual(1484, manifest["asset_count"])
        self.assertEqual(1565, manifest["reference_count"])
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
            ROOT / "config/wiki_assets_v2.json",
        )

        counts = {
            kind: sum(1 for item in specs if item.kind == kind)
            for kind in {item.kind for item in specs}
        }
        self.assertEqual(
            {
                "pet_illustration": 569,
                "pet_shiny_illustration": 144,
                "skill_icon": 736,
                "ui_icon": 35,
            },
            counts,
        )
        self.assertEqual(1565, sum(len(item.catalog_ids) for item in specs))
        self.assertIn(
            "File:JL dimo.png",
            {item.source_title for item in specs},
        )
        self.assertIn(
            "File:JL emolang yise.png",
            {item.source_title for item in specs},
        )
        self.assertIn(
            "File:Feature 200076.png",
            {item.source_title for item in specs},
        )
        self.assertIn(
            "pet_000004",
            {
                catalog_id
                for item in specs
                if item.asset_id == "pet_illustration:JL_dimo"
                for catalog_id in item.catalog_ids
            },
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
                    "has_shiny": 1,
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
                {
                    "pet_illustration",
                    "pet_shiny_illustration",
                    "skill_icon",
                    "ui_icon",
                },
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
