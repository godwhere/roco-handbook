# Phase 8 implementation report

- Status: implementation complete for the ADR-0015 and ADR-0016 scopes; all other Phase 8 release work deferred
- Date: 2026-09-10
- Workspace: `/Users/ethan/Documents/ChatGPT/roco-handbook`

## Declared boundary

Phase 8 is limited to the formal App identity and launch experience, bilingual `en-US` and `zh-CN` UI, frozen offline Wiki images for creatures, skills, features, and selected domain controls, the full-illustration concrete-form catalog defined by ADR-0016, source-backed total base stats and type relationships, plus iOS and Android store screenshots. ADR-0015 and ADR-0016 define the ownership, source, offline, accessibility, and acceptance boundaries.

App signing, store account configuration, listing submission, upload, publication, logical patches, Catalog V2, live Phase 7 update evidence, and other release work are deferred.

## Changed files

- Governance and current-state documentation: `AGENTS.md`, root and App READMEs, ADR-0015, ADR-0016, `docs/features/localized-visual-handbook.md`, the Phase 8 evidence record, this report, and focused structure checks
- Frozen source contracts: `config/ui_terminology_zh_cn.json`, `config/wiki_assets_v1.json`, `config/type_relations_v1.json`, `app/assets/wiki/type-relations-v1.json`, and `app/assets/wiki/v1/asset-manifest.json`
- Frozen visual library: 569 creature illustrations covering all 596 active forms, 736 skill or feature icons, and 35 type, stat, or skill-category icons under `app/assets/wiki/v1/`; 596 unused head files and their Flutter asset declaration were removed
- Import and generation tools: `tools/bwiki_import/image_assets.py`, `tools/bwiki_import/type_relations.py`, their CLI commands, `tools/brand/generate_brand_assets.swift`, and the atomic RGB store-screenshot normalizer
- App domain and data: the existing illustration key is projected into creature summaries and all summary queries, the upstream head key remains preserved in Catalog data, a null-preserving `PetDetail.totalBaseStats` contract, plus the type-relationship contract and bundled-asset repository
- App presentation: centralized `en-US` and `zh-CN` strings; localized startup, navigation, Catalog, personal library, and Settings flows; a compact Sort/Types/Search row with a rounded placeholder-only Search field; modal sort and type selectors; exact default and named-form card copy with the handbook number below each illustration; enlarged full illustrations; accessible skill, feature, type, stat, and category images; total base stats; incoming and outgoing type relationships
- Platform identity: Android and iOS display names, launcher and App icons, branded launch resources, and regenerated platform image slots
- Tests: focused image manifest, complete Catalog-to-Flutter illustration resolution, exact creature control-row geometry and card copy, modal sort interaction, complete Catalog base-stat and type-combination audits, type relation, repository, source-grounded terminology, literal UI-key completeness, fixed-copy localization-entry enforcement, Chinese top-level navigation rendering, frozen brand-source and output identities, store-screenshot eligibility, widget, and iOS platform-identity coverage; the generated empty iOS example test was replaced
- Store evidence: four iOS screenshots at 1206 × 2622 and four Android screenshots at 1080 × 1920 under `docs/evidence/phase-8-store-screenshots/`; all eight are 8-bit RGB PNGs without alpha

## Verification performed

```text
PYTHONDONTWRITEBYTECODE=1 PYTHONPATH=tools python3 -m unittest discover -s tests -p 'test_*.py'
Result: 89 tests passed, including exact screenshot inventory, dimensions, RGB color type, byte limit, and Android aspect-ratio checks.

cd app && dart format --output=none --set-exit-if-changed lib test tool
Result: 40 files checked; no changes required.

cd app && flutter analyze --no-pub
Result: no issues found.

cd app && flutter test --no-pub
Result: 100 tests passed, including complete active Catalog illustration packaging, accessible missing-asset fallbacks, exact creature card copy and control-row geometry, modal sort interaction, base-stat totals, all active type combinations, the frozen terminology contract, literal Chinese UI-key completeness, fixed-copy localization-entry enforcement, and top-level Chinese navigation rendering.

Image manifest verification
Result: 1,340 unique files, 1,419 Catalog references, and 97,655,049 verified local bytes; manifest SHA-256 414ef24f292b70cf4e48f1cddc716d7b7bd47afb7bde735f2feafcb291749756.

Brand asset identity verification
Result: the frozen Dimo source plus all 24 declared iOS and Android icon or launch-image slots matched their exact inventories, dimensions, and reviewed SHA-256 values.

Tracked production placeholder audit
Result: no Flutter demo copy, Lorem Ipsum, sample-App text, temporary visual asset, default Flutter logo, or enabled debug banner remained. Development-only platform configuration and required storyboard infrastructure were distinguished from product content.

Type relationship verification
Result: source revision 39538, 19 source types, eight reviewed inverse-list exceptions, focused single-type and dual-type ×3-cap tests, and all 596 active Catalog type combinations passed.

Base-stat total verification
Result: 595 active forms produced totals from six present values; `pet_000535` retained six null values and no fabricated total.

cd app && flutter build ios --simulator --debug --no-pub
Result: passed; the rebuilt App was installed and launched on the iPhone 17 simulator. Earlier Phase 8 visual evidence also passed on the iPhone 17 Pro simulator.

cd app/ios && xcodebuild test -workspace Runner.xcworkspace -scheme Runner -destination 'id=4DCEC9FD-FE44-4047-AE85-D481E03AD9D0' -only-testing:RunnerTests
Result: passed; the platform regression verified the published iOS display name and Bundle ID after replacing the generated empty example test.

cd app && flutter build apk --debug
Result: passed; the rebuilt APK was installed and launched on the Android API 36 emulator.

cd app && flutter build appbundle --release --no-pub
Result: passed; 158,152,015-byte AAB reported as 158.2 MB by Flutter; SHA-256 5ad3b961b314a2f6cbe6999e741554b92e5a5eab758d28d87f4bc8543ff16cd3.

cd app && flutter build ios --release --no-codesign --no-pub
Result: passed; 122,644 KiB App reported as 122.8 MB by Flutter; embedded version 1.1.0 build 2; App framework SHA-256 6d0e0d6f848063dd9e5ea1397f91066d0378f7e09da28a9957a0a8abbdcd4b50.

Virtual-platform visual review
Result: the current source built, installed, and launched on the iOS simulator and Android emulator, and updated Catalog captures passed the measured dimensions and RGB normalization checks. Final subjective acceptance of the Sort/Types/Search layout and number placement remains with the repository owner. Earlier Phase 8 review covered localized navigation, imagery, base stats, the calculated total, and type relationships.

git diff --check
Result: passed.

GitHub Actions `Offline validation`
Result: passed for the earlier Phase 8 commit `94ee692d9fc30ef33f9937116c891773d425a489`; hosted run 34400308182 completed successfully. Hosted validation of the current ADR-0016 UI revision is reserved for repository-owner confirmation.

shasum -a 256 docs/technical-spec-v1.md
Result: 343618b414b7b8d6262dd58f82010bfefb2f3fdb29711a9e86428e042dd81876; the provenance baseline is unchanged.
```

## Not run

- App signing, archive export with a distribution identity, store upload, review, or publication
- Physical-device visual, accessibility, launch, memory, and storage validation
- Real Catalog V2 import or Phase 7 production package update
- Logical incremental patch generation or installation
- Any Phase 8 work outside ADR-0015 and ADR-0016
- Hosted validation for the current ADR-0016 UI revision; the repository owner will confirm it separately

## Remaining risks and next boundary

The measured package cost remains material because the complete illustration, skill, and domain-icon library ships offline. Removing 596 unused heads reduces the source asset bundle by 9,221,952 bytes; the current Android AAB is 158,152,015 bytes and the iOS no-codesign App is 122,644 KiB. No runtime image download, on-demand resource, or logical asset patch protocol was introduced.

A later Catalog or Wiki revision can add keys or change source files, but the installed App will not acquire them automatically; a new immutable image asset version and App release are required. The upstream `head_key` remains present only for source fidelity and is not a packaged runtime dependency.

The next boundary is either the deferred Phase 7 real Catalog update test after an actual upstream data change, or a separately declared continuation of the remaining deferred Phase 8 release work. Neither boundary changes the missing physical-device, signing, upload, review, or publication evidence.
