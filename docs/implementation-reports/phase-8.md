# Phase 8 implementation report

- Status: complete for the ADR-0015 scope; all other Phase 8 release work deferred
- Date: 2026-09-10
- Workspace: `/Users/ethan/Documents/ChatGPT/roco-handbook`

## Declared boundary

Phase 8 is limited to the formal App identity and launch experience, bilingual `en-US` and `zh-CN` UI, frozen offline Wiki images for creatures, skills, features, and selected domain controls, source-backed total base stats and type relationships, plus iOS and Android store screenshots. ADR-0015 defines the ownership, source, offline, accessibility, and acceptance boundaries.

App signing, store account configuration, listing submission, upload, publication, logical patches, Catalog V2, live Phase 7 update evidence, and other release work are deferred.

## Changed files

- Governance and current-state documentation: `AGENTS.md`, root and App READMEs, ADR-0015, `docs/features/localized-visual-handbook.md`, the Phase 8 evidence record, this report, and focused structure checks
- Frozen source contracts: `config/ui_terminology_zh_cn.json`, `config/wiki_assets_v1.json`, `config/type_relations_v1.json`, `app/assets/wiki/type-relations-v1.json`, and `app/assets/wiki/v1/asset-manifest.json`
- Frozen visual library: 596 creature heads, 569 creature illustrations, 736 skill or feature icons, and 35 type, stat, or skill-category icons under `app/assets/wiki/v1/`
- Import and generation tools: `tools/bwiki_import/image_assets.py`, `tools/bwiki_import/type_relations.py`, their CLI commands, and `tools/brand/generate_brand_assets.swift`
- App domain and data: asset keys added to existing Catalog DTOs and repository mapping, plus the type-relationship contract and bundled-asset repository
- App presentation: centralized `en-US` and `zh-CN` strings; localized startup, navigation, Catalog, personal library, and Settings flows; accessible creature, skill, feature, type, stat, and category images; total base stats; incoming and outgoing type relationships
- Platform identity: Android and iOS display names, launcher and App icons, branded launch resources, and regenerated platform image slots
- Tests: focused image manifest, type relation, repository, localization, asset, and widget coverage
- Store evidence: four iOS screenshots at 1206 × 2622 and three Android screenshots at 1080 × 2424 under `docs/evidence/phase-8-store-screenshots/`

## Verification performed

```text
PYTHONDONTWRITEBYTECODE=1 PYTHONPATH=tools python3 -m unittest discover -s tests -p 'test_*.py'
Result: 88 tests passed.

cd app && dart format --output=none --set-exit-if-changed lib test tool
Result: 38 files checked; no changes required.

cd app && flutter analyze --no-pub
Result: no issues found.

cd app && flutter test --no-pub
Result: 91 tests passed.

Image manifest verification
Result: 1,936 unique files, 2,015 Catalog references, and 106,877,001 verified local bytes; manifest SHA-256 6433b65b637f752d68ec572c16696597db81fe4822e9626f6dfd9ff1d132fd0d.

Type relationship verification
Result: source revision 39538, 19 source types, eight reviewed inverse-list exceptions, and focused single-type plus dual-type ×3-cap tests passed.

cd app && flutter build ios --simulator
Result: passed; the rebuilt App was installed and launched on the iPhone 17 Pro simulator.

cd app && flutter build apk --debug
Result: passed; the rebuilt APK was installed and launched on the Android API 36 emulator.

cd app && flutter build appbundle --release
Result: passed; 167,411,505-byte AAB; SHA-256 8087d21c2023200ac2dce65aa8b3c3dadc5c8265601d1aea8bd251ccf007f8a5.

cd app && flutter build ios --release --no-codesign
Result: passed; 133,024 KiB App; embedded version 1.1.0 build 2; App framework SHA-256 e8d2d8df1f5639fdc3bf447bd27b1deb9c29bb1db8465bf5a27605617fd62642.

Virtual-platform visual review
Result: iOS and Android displayed localized navigation, creature heads, a full creature illustration, base stats, the calculated total, and type relationships. The repository owner separately observed the implemented skill imagery.

git diff --check
Result: passed.

GitHub Actions `Offline validation`
Result: passed for commit `94ee692d9fc30ef33f9937116c891773d425a489`; hosted run 34400308182 completed successfully.

shasum -a 256 docs/technical-spec-v1.md
Result: 343618b414b7b8d6262dd58f82010bfefb2f3fdb29711a9e86428e042dd81876; the provenance baseline is unchanged.
```

## Not run

- App signing, archive export with a distribution identity, store upload, review, or publication
- Physical-device visual, accessibility, launch, memory, and storage validation
- Real Catalog V2 import or Phase 7 production package update
- Logical incremental patch generation or installation
- Any Phase 8 work outside ADR-0015

## Remaining risks and next boundary

The measured package cost is material: the Android AAB is 167.4 MB and the iOS no-codesign App is 132.2 MB. This delivery intentionally retains the accepted complete offline-image design; no runtime image download, on-demand resource, or logical asset patch protocol was introduced.

Nine unavailable source head files use explicit same-record illustration fallbacks. A later Catalog or Wiki revision can add keys or change source files, but the installed App will not acquire them automatically; a new immutable image asset version and App release are required.

The next boundary is either the deferred Phase 7 real Catalog update test after an actual upstream data change, or a separately declared continuation of the remaining deferred Phase 8 release work. Neither boundary changes the missing physical-device, signing, upload, review, or publication evidence.
