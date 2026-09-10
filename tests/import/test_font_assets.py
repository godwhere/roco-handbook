from __future__ import annotations

import hashlib
import json
from pathlib import Path
import tempfile
import unittest

from bwiki_import.errors import (
    InputError,
    ResponseValidationError,
    SnapshotWriteError,
)
from bwiki_import.font_assets import import_font_assets


ROOT = Path(__file__).resolve().parents[2]


def _font(marker: bytes) -> bytes:
    header = b"\x00\x01\x00\x00\x00\x01\x00\x10\x00\x00\x00\x00"
    table = b"name\x00\x00\x00\x00\x00\x00\x00\x1c\x00\x00\x00\x01"
    return header + table + marker


class _Transport:
    def __init__(self, payloads: dict[str, bytes]) -> None:
        self.payloads = payloads
        self.requested: list[str] = []

    def get_font(self, url: str) -> bytes:
        self.requested.append(url)
        return self.payloads[url]


def _config(payloads: dict[str, bytes]) -> dict[str, object]:
    fonts = []
    for index, (url, payload) in enumerate(payloads.items(), start=1):
        fonts.append(
            {
                "family": f"TestFamily{index}",
                "font_id": f"font-{index}",
                "local_path": f"font-{index}.ttf",
                "role": "display" if index == 1 else "numbers",
                "source_bytes": len(payload),
                "source_sha256": hashlib.sha256(payload).hexdigest(),
                "source_url": url,
            }
        )
    return {
        "asset_host": "assets.example.test",
        "asset_path_prefix": "/images/rocom/",
        "asset_version": 1,
        "config_version": 1,
        "dataset_id": "roco-world-zh-cn",
        "fonts": fonts,
        "request_policy": {
            "connect_timeout_seconds": 1,
            "max_font_bytes": 1000,
            "max_retries": 1,
            "read_timeout_seconds": 1,
        },
        "source_stylesheet": "https://wiki.example.test/styles.css",
    }


class FontAssetTests(unittest.TestCase):
    def test_import_freezes_exact_fonts_and_reuses_an_unchanged_version(self) -> None:
        payloads = {
            "https://assets.example.test/images/rocom/fonts/display.ttf": _font(b"A"),
            "https://assets.example.test/images/rocom/fonts/numbers.ttf": _font(b"B"),
        }
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            config_path = root / "fonts.json"
            config_path.write_text(
                json.dumps(_config(payloads)),
                encoding="utf-8",
            )
            transport = _Transport(payloads)

            frozen = import_font_assets(
                config_path,
                root / "output",
                transport=transport,
            )

            self.assertFalse(frozen.reused_existing)
            self.assertEqual(2, frozen.font_count)
            self.assertEqual(sum(map(len, payloads.values())), frozen.total_bytes)
            self.assertEqual(sorted(payloads), sorted(transport.requested))
            manifest = json.loads(frozen.manifest_path.read_text(encoding="utf-8"))
            self.assertEqual(
                ["font-1", "font-2"],
                [item["font_id"] for item in manifest["fonts"]],
            )
            self.assertEqual(
                payloads["https://assets.example.test/images/rocom/fonts/display.ttf"],
                (frozen.path / "font-1.ttf").read_bytes(),
            )

            reused = import_font_assets(
                config_path,
                root / "output",
                transport=_Transport({}),
            )
            self.assertTrue(reused.reused_existing)

    def test_import_rejects_an_untrusted_source_url(self) -> None:
        payloads = {
            "https://assets.example.test/images/rocom/fonts/display.ttf": _font(b"A"),
            "https://assets.example.test/images/rocom/fonts/numbers.ttf": _font(b"B"),
        }
        config = _config(payloads)
        config["fonts"][0]["source_url"] = "https://outside.example/fonts/display.ttf"
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            config_path = root / "fonts.json"
            config_path.write_text(json.dumps(config), encoding="utf-8")
            with self.assertRaises(InputError):
                import_font_assets(
                    config_path,
                    root / "output",
                    transport=_Transport({}),
                )

    def test_import_rejects_changed_payload_and_existing_tampering(self) -> None:
        url = "https://assets.example.test/images/rocom/fonts/display.ttf"
        numbers_url = "https://assets.example.test/images/rocom/fonts/numbers.ttf"
        expected = _font(b"A")
        numbers = _font(b"N")
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            config_path = root / "fonts.json"
            config_path.write_text(
                json.dumps(_config({url: expected, numbers_url: numbers})),
                encoding="utf-8",
            )
            with self.assertRaises(ResponseValidationError):
                import_font_assets(
                    config_path,
                    root / "changed",
                    transport=_Transport({url: _font(b"B"), numbers_url: numbers}),
                )

            frozen = import_font_assets(
                config_path,
                root / "output",
                transport=_Transport({url: expected, numbers_url: numbers}),
            )
            (frozen.path / "font-1.ttf").write_bytes(_font(b"B"))
            with self.assertRaises(SnapshotWriteError):
                import_font_assets(
                    config_path,
                    root / "output",
                    transport=_Transport({}),
                )

    def test_tracked_font_assets_match_the_frozen_contract(self) -> None:
        config_path = ROOT / "config/wiki_fonts_v1.json"
        output = ROOT / "app/assets/fonts"
        frozen = import_font_assets(config_path, output, transport=_Transport({}))

        self.assertTrue(frozen.reused_existing)
        self.assertEqual(2, frozen.font_count)
        self.assertEqual(4568108, frozen.total_bytes)


if __name__ == "__main__":
    unittest.main()
