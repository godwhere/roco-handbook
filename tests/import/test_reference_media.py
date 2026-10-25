from __future__ import annotations

import copy
import hashlib
import json
from pathlib import Path
import struct
import tempfile
import unittest
import zlib

from bwiki_import.errors import InputError, ResponseValidationError
from bwiki_import.reference_media import import_reference_media, reference_asset_specs


ROOT = Path(__file__).resolve().parents[2]


def icon_png(color: bytes = b"\xff\x80\0\xff") -> bytes:
    def chunk(kind: bytes, payload: bytes) -> bytes:
        return struct.pack(">I", len(payload)) + kind + payload + struct.pack(">I", zlib.crc32(kind + payload))
    return (b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", 2, 1, 8, 6, 0, 0, 0))
            + chunk(b"IDAT", zlib.compress(b"\0" + color * 2)) + chunk(b"IEND", b""))


class OwnedTransport:
    def __init__(self, mode: str = "valid") -> None:
        self.mode = mode
        self.payload = icon_png()
        self.downloads: list[str] = []
        self.requests: list[dict[str, str]] = []

    def post_json(self, url: str, form: dict[str, str]) -> dict:
        self.requests.append(dict(form))
        pages = []
        for index, title in enumerate(form["titles"].split("|")):
            if self.mode == "missing" and "Missing" in title or self.mode == "all_missing":
                pages.append({"title": title, "missing": True})
                continue
            pages.append({"pageid": index + 1, "title": title, "imageinfo": [{
                "mime": "image/png", "mediatype": "BITMAP", "size": len(self.payload),
                "width": 2, "height": 1, "timestamp": "2026-10-26T00:00:00Z",
                "sha1": hashlib.sha1(self.payload).hexdigest(),
                "url": "https://patchwiki.biligame.com/images/nrc/1/12/" + title[5:],
            }]})
        if self.mode == "omitted":
            pages.pop()
        if self.mode == "duplicate":
            pages.append(copy.deepcopy(pages[0]))
        if self.mode == "wrong_host":
            pages[0]["imageinfo"][0]["url"] = "https://example.invalid/icon.png"
        return {"batchcomplete": self.mode != "incomplete", "query": {"pages": pages},
                **({"error": {"code": "owned_failure"}} if self.mode == "error" else {})}

    def get_png(self, url: str) -> bytes:
        self.downloads.append(url)
        if self.mode == "wrong_original":
            return icon_png(b"\0\x80\xff\xff")
        return self.payload if self.mode != "bad_png" else b"not a PNG"


class ReferenceMediaTests(unittest.TestCase):
    def declaration(self, root: Path) -> Path:
        document = {"manifest_version": 1, "dataset_id": "roco-world-zh-cn", "assets": [
            {"asset_id": "first", "source_title": "File:Owned.png", "local_path": "icons/owned.png",
             "width": 192, "catalog_ids": ["items:item_000000000001", "items:item_000000000002"]},
            {"asset_id": "second", "source_title": "File:Missing.png", "local_path": "icons/missing.png",
             "width": 192, "catalog_ids": ["medals:medal_1001"]},
        ]}
        path = root / "declared.json"
        path.write_text(json.dumps(document), encoding="utf-8")
        return path

    def test_declared_icons_freeze_with_verified_bytes_and_reference_closure(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            declaration = self.declaration(root)
            client = OwnedTransport()
            report = import_reference_media(declaration, ROOT / "config/reference_media_v1.json", root / "out",
                                            transport=client, sleep=lambda _: None)
            self.assertEqual((2, 2, 3), (report["requested_count"], report["available_count"], report["reference_count"]))
            self.assertEqual([], report["unavailable"])
            self.assertEqual(2, report["verified_original_count"])
            self.assertEqual(1, len(client.requests))
            self.assertEqual(2, len(client.downloads))
            manifest = json.loads(Path(report["manifest_path"]).read_text())
            for record in manifest["assets"]:
                payload = (Path(report["path"]) / record["local_path"]).read_bytes()
                self.assertEqual(hashlib.sha256(payload).hexdigest(), record["local_sha256"])
                self.assertEqual((2, 1), (record["local_width"], record["local_height"]))
            second = OwnedTransport()
            repeated = import_reference_media(declaration, ROOT / "config/reference_media_v1.json", root / "out",
                                              transport=second, sleep=lambda _: None)
            self.assertTrue(repeated["reused_existing"])
            self.assertEqual([], second.downloads)

    def test_explicit_missing_file_is_reported_without_a_fake_or_wrong_image(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            report = import_reference_media(self.declaration(root), ROOT / "config/reference_media_v1.json", root / "out",
                                            transport=OwnedTransport("missing"), sleep=lambda _: None)
            self.assertEqual(1, report["available_count"])
            self.assertEqual([{"source_title": "File:Missing.png", "catalog_ids": ["medals:medal_1001"]}], report["unavailable"])
            self.assertFalse((Path(report["path"]) / "icons/missing.png").exists())

    def test_failed_incomplete_or_untrusted_metadata_never_creates_a_release(self) -> None:
        for mode in ("error", "incomplete", "omitted", "duplicate", "wrong_host", "all_missing", "bad_png", "wrong_original"):
            with self.subTest(mode=mode), tempfile.TemporaryDirectory() as directory:
                root = Path(directory)
                with self.assertRaises(ResponseValidationError):
                    import_reference_media(self.declaration(root), ROOT / "config/reference_media_v1.json", root / "out",
                                           transport=OwnedTransport(mode), sleep=lambda _: None)
                self.assertFalse((root / "out/v1").exists())

    def test_valid_but_wrong_cached_original_is_rejected_without_overwriting_cache(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            cache = root / "cache"
            cache.mkdir()
            url = "https://patchwiki.biligame.com/images/nrc/1/12/Owned.png"
            path = cache / hashlib.sha256(url.encode()).hexdigest()
            wrong = icon_png(b"\0\x80\xff\xff")
            path.write_bytes(wrong)
            with self.assertRaises(ResponseValidationError):
                import_reference_media(self.declaration(root), ROOT / "config/reference_media_v1.json", root / "out",
                                       cache_root=cache, transport=OwnedTransport(), sleep=lambda _: None)
            self.assertEqual(wrong, path.read_bytes())
            self.assertFalse((root / "out/v1").exists())

    def test_declaration_rejects_unsafe_paths_unbounded_images_and_duplicate_identity(self) -> None:
        for field, value in (("local_path", "icons/../escape.png"), ("source_title", "File:../escape.png"),
                             ("source_title", "File:Owned.jpg"), ("width", 193), ("width", True),
                             ("catalog_ids", ["habitats:p-0000000000000000"]), ("catalog_ids", []),
                             ("asset_id", "second"), ("local_path", "icons/missing.png"),
                             ("source_title", "File:Missing.png")):
            with self.subTest(field=field, value=value), tempfile.TemporaryDirectory() as directory:
                root = Path(directory)
                path = self.declaration(root)
                document = json.loads(path.read_text())
                document["assets"][0][field] = value
                path.write_text(json.dumps(document))
                with self.assertRaises(InputError):
                    reference_asset_specs(path)


if __name__ == "__main__":
    unittest.main()
