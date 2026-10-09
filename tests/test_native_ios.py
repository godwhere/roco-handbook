import importlib.util
import json
from pathlib import Path
import plistlib
import re
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]


def load_script(name: str):
    path = ROOT / "ios" / f"{name}.py"
    spec = importlib.util.spec_from_file_location(name, path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


class NativeIOSPackagingTests(unittest.TestCase):
    def test_native_interface_and_error_copy_have_both_localizations(self) -> None:
        pattern = re.compile(r'^"((?:[^"\\]|\\.)*)"\s*=\s*"((?:[^"\\]|\\.)*)";', re.M)
        localized = {}
        for language in ("en", "zh-Hans"):
            source = (ROOT / f"ios/App/{language}.lproj/Localizable.strings").read_text()
            entries = [
                (json.loads(f'"{key}"'), json.loads(f'"{value}"'))
                for key, value in pattern.findall(source)
            ]
            self.assertEqual(len(entries), len(dict(entries)))
            localized[language] = dict(entries)
        self.assertEqual(localized["en"].keys(), localized["zh-Hans"].keys())
        required = set()
        for path in (ROOT / "ios/App").glob("*.swift"):
            source = path.read_text()
            for expression in (r'tr\("([^"\\]*)"\)', r'(?:title|text): "([^"\\]*)"'):
                required.update(re.findall(expression, source))
        for path in (ROOT / "ios/Sources/HandbookCore").glob("*.swift"):
            required.update(re.findall(r'HandbookError\("[^"\\]*", "([^"\\]*)"\)', path.read_text()))
        for key in sorted(required):
            with self.subTest(key=key):
                self.assertIn(key, localized["en"])
                self.assertIn(key, localized["zh-Hans"])
                self.assertNotEqual(key, localized["zh-Hans"][key])
        terms = json.loads((ROOT / "config/ui_terminology_zh_cn.json").read_text())["terms"]
        for key, term in (("Base stats", "base_stats"), ("Feature", "feature"), ("Energy", "energy"), ("Power", "power")):
            self.assertEqual(terms[term], localized["zh-Hans"][key])

    def test_native_bundle_identity_permissions_and_local_dependencies(self) -> None:
        with (ROOT / "ios/App/Info.plist").open("rb") as file:
            info = plistlib.load(file)
        self.assertFalse(any(key.endswith("UsageDescription") for key in info))
        self.assertNotIn("NSAppTransportSecurity", info)
        self.assertNotIn("UIBackgroundModes", info)
        project = (ROOT / "ios/RocoHandbook.xcodeproj/project.pbxproj").read_text()
        self.assertIn("PRODUCT_BUNDLE_IDENTIFIER = world.roco.rocoHandbook;", project)
        self.assertIn("IPHONEOS_DEPLOYMENT_TARGET = 15.0;", project)
        self.assertIn("MARKETING_VERSION = 1.2.0;", project)
        self.assertNotIn("Flutter", project)
        package = (ROOT / "ios/Package.swift").read_text()
        self.assertNotIn(".package(url:", package)

    def test_native_staging_closes_asset_paths_without_mutating_sources(self) -> None:
        script = load_script("prepare_resources")
        with tempfile.TemporaryDirectory(prefix="roco-native-packaging-") as directory:
            destination = Path(directory) / "assets"
            script.stage(destination)
            for name in ("catalog.db", "bundled_catalog.json", "ATTRIBUTION.txt"):
                self.assertEqual(
                    (ROOT / "data/release/2/assets/catalog" / name).read_bytes(),
                    (destination / "catalog" / name).read_bytes(),
                )
            self.assertEqual(
                (ROOT / "schemas/user_v1.sql").read_bytes(),
                (destination / "database/user_v1.sql").read_bytes(),
            )
            self.assertTrue((destination / "wiki/v3/asset-manifest.json").is_file())
            self.assertFalse((destination / "wiki/v1").exists())
            self.assertFalse((destination / "wiki/v2").exists())
            self.assertFalse(list(destination.rglob("*.dart")))

    def test_native_project_matches_generator(self) -> None:
        paths = [
            ROOT / "ios/RocoHandbook.xcodeproj/project.pbxproj",
            ROOT / "ios/RocoHandbook.xcodeproj/xcshareddata/xcschemes/RocoHandbook.xcscheme",
        ]
        before = [path.read_bytes() for path in paths]
        with tempfile.TemporaryDirectory(prefix="roco-native-project-") as directory:
            generated = Path(directory) / "RocoHandbook.xcodeproj"
            load_script("generate_project").generate(generated)
            self.assertEqual(before, [
                (generated / "project.pbxproj").read_bytes(),
                (generated / "xcshareddata/xcschemes/RocoHandbook.xcscheme").read_bytes(),
            ])
