"""Verify the native source candidate without building, signing, or networking."""
from __future__ import annotations

import hashlib
import importlib.util
import json
from pathlib import Path
import plistlib
import re

from check_catalog import check_release

ROOT = Path(__file__).resolve().parents[2]
CANDIDATE = ROOT / 'release/1.2.0+3/release-candidate.json'


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ValueError(message)


def digest(path: Path) -> str:
    require(path.is_file() and not path.is_symlink(), f'Missing or linked file: {path}')
    return hashlib.sha256(path.read_bytes()).hexdigest()


def check() -> None:
    candidate = json.loads(CANDIDATE.read_text())
    app = candidate['app']
    for path in ['ios/generate_project.py', 'ios/RocoHandbook.xcodeproj/project.pbxproj']:
        text = (ROOT / path).read_text()
        for key, value in {'MARKETING_VERSION': app['version'],
                           'CURRENT_PROJECT_VERSION': app['build_number'],
                           'PRODUCT_BUNDLE_IDENTIFIER': app['bundle_id'],
                           'IPHONEOS_DEPLOYMENT_TARGET': app['minimum_ios']}.items():
            require(re.search(rf'{key}\s*=\s*{re.escape(str(value))}\s*;', text) is not None,
                    f'{path}: {key} differs from candidate')
    plist = plistlib.loads((ROOT / 'ios/App/Info.plist').read_bytes())
    require(plist['CFBundleDisplayName'] == app['display_name'], 'Display name drift')
    require(plist['CFBundleShortVersionString'] == '$(MARKETING_VERSION)', 'Version substitution drift')
    require(plist['CFBundleVersion'] == '$(CURRENT_PROJECT_VERSION)', 'Build substitution drift')
    require(not any(k.endswith('UsageDescription') for k in plist), 'Permission metadata drift')
    require('NSAppTransportSecurity' not in plist, 'ATS metadata drift')
    ci = candidate['evidence']['ci']
    receipt_path = ROOT / ci['receipt']
    require(digest(receipt_path) == ci['receipt_sha256'], 'CI receipt digest drift')
    receipt = json.loads(receipt_path.read_text())
    run = receipt['run']
    for key, expected in {'id': ci['run_id'], 'run_number': ci['run_number'],
                          'run_attempt': ci['run_attempt'],
                          'head_sha': candidate['source']['ci_commit'],
                          'conclusion': 'success', 'status': 'completed'}.items():
        require(run[key] == expected, f'CI {key} mismatch')
    require([(j['id'], j['name'], j['conclusion']) for j in receipt['jobs']] ==
            [(j['id'], j['name'], j['conclusion']) for j in ci['jobs']], 'CI job mismatch')
    catalog = candidate['catalog']
    report = check_release(ROOT / catalog['release'])
    recorded = ROOT / catalog['catalog_check']
    require(report == json.loads(recorded.read_text()), 'Catalog report drift')
    require(digest(recorded) == catalog['catalog_check_sha256'], 'Catalog report digest drift')
    manifest = ROOT / 'app/assets/catalog/bundled_catalog.json'
    for key, value in json.loads(manifest.read_text()).items():
        require(catalog[key] == value, f'Bundled Catalog {key} drift')
    require(digest(manifest) == catalog['manifest_sha256'], 'Manifest digest drift')
    for name in ['catalog.db', 'bundled_catalog.json', 'ATTRIBUTION.txt']:
        require((ROOT / 'app/assets/catalog' / name).read_bytes() ==
                (ROOT / catalog['release'] / 'assets/catalog' / name).read_bytes(),
                f'Bundled/release mismatch: {name}')
    for key in ['attribution_sha256', 'normalized_catalog_sha256', 'source_lock_sha256']:
        require(catalog[key] == report[key], f'{key} drift')
    spec = importlib.util.spec_from_file_location('native_resources', ROOT / 'ios/prepare_resources.py')
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    resources = candidate['resources']
    inventory_path = ROOT / resources['inventory']
    require(digest(inventory_path) == resources['inventory_sha256'], 'Inventory digest drift')
    inventory = json.loads(inventory_path.read_text())
    require(inventory['roots'] == list(module.ACTIVE), 'Active roots drift')
    actual = []
    for relative in module.ACTIVE:
        source = ROOT / 'app/assets' / relative
        require(source.exists() and not source.is_symlink(), f'Missing root: {relative}')
        for file in sorted(source.rglob('*')) if source.is_dir() else [source]:
            require(not file.is_symlink(), f'Linked resource: {file}')
            if file.is_file():
                actual.append({'path':str(file.relative_to(ROOT / 'app/assets')),
                               'bytes':file.stat().st_size, 'sha256':digest(file)})
    actual.sort(key=lambda row:row['path'])
    require(actual == inventory['files'], 'Resource closure, size, or digest drift')
    for obj in [inventory, resources]:
        require(obj['file_count'] == len(actual), 'Resource count drift')
        require(obj['total_bytes'] == sum(row['bytes'] for row in actual), 'Resource bytes drift')
    schema = ROOT / 'schemas/user_v1.sql'
    require(digest(schema) == candidate['user_database']['schema_sha256'], 'User SQL drift')
    require(schema.read_bytes() == (ROOT / 'app/assets/database/user_v1.sql').read_bytes(), 'Packaged user SQL drift')
    require(candidate['app']['client'] == 'Swift/SwiftUI', 'Client boundary drift')
    require(candidate['historical_waiver_inherited'] is False, 'Historical waiver inherited')
    require(candidate['artifact']['sha256'] is None and not candidate['artifact']['signed'], 'Unexpected binary claim')
    require(all(gate['status'] == 'not_run' for gate in candidate['gates'].values()), 'Unreviewed acceptance claim')
    require(not candidate['publication']['store_ready'] and not candidate['publication']['uploaded'], 'Unexpected store claim')


if __name__ == '__main__':
    try:
        check()
    except (ValueError, OSError, KeyError) as error:
        raise SystemExit(f'Native candidate verification failed: {error}')
    print('Native source candidate verified; physical, signing, upgrade, and store gates remain open.')
