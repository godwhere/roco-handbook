# Phase 8 implementation report

- Status: implementation complete for the ADR-0015 through ADR-0019 scopes; all other Phase 8 release work deferred
- Date: 2026-09-11
- Workspace: `/Users/ethan/Documents/ChatGPT/roco-handbook`

## Declared boundary

Phase 8 is limited to the formal App identity and launch experience, bilingual `en-US` and `zh-CN` UI, frozen offline Wiki images for original and shiny creatures, skills, features, selected domain controls, activity icons, and outfit previews; the full-illustration concrete-form catalog defined by ADR-0016; the creature and skill handbook presentation defined by ADR-0017; the filters and seven functional Tools routes defined by ADR-0018; the frozen display and numeric typography roles defined by ADR-0019; source-backed total base stats and type relationships; plus iOS and Android store screenshots. ADR-0015 through ADR-0019 define the ownership, source, offline, accessibility, and acceptance boundaries.

App signing, store account configuration, listing submission, upload, publication, logical patches, Catalog V2, live Phase 7 update evidence, and other release work are deferred.

## Changed files

- Governance and current-state documentation: `AGENTS.md`, root and App READMEs, ADR-0015 through ADR-0019, `docs/features/localized-visual-handbook.md`, `docs/features/offline-catalog-browser.md`, `design-qa.md`, the Phase 8 evidence records including the compact Tools and Egg groups simulator check, this report, and focused structure checks
- Frozen source contracts: `config/ui_terminology_zh_cn.json`, `config/wiki_assets_v2.json`, `config/wiki_fonts_v1.json`, `config/type_relations_v1.json`, `config/game_descriptions_v1.json`, `config/activity_timeline_v1.json`, `config/fashion_catalog_v1.json`, `config/wiki_tool_assets_v1.json`, the four matching bundled JSON contracts, the font manifest, and both image manifests
- Frozen visual library: 569 original creature illustrations covering all 596 active forms, 144 shiny illustrations covering 146 active references, 736 skill or feature icons, and 35 type, stat, or skill-category icons under active asset version 2; asset version 1 remains immutable and is not packaged by Flutter
- Compact Tool media: 53 activity icons and 220 gender-specific outfit previews under `app/assets/wiki/tools/v1/`, covering 749 references in 12,379,751 verified bytes
- Frozen typography: the 4,563,796-byte `RocoDisplay` face and 4,312-byte `RocoNumbers` face under `app/assets/fonts/v1/`, with exact source paths and SHA-256 values in the immutable manifest
- Import and generation tools: `tools/bwiki_import/image_assets.py`, `tools/bwiki_import/font_assets.py`, `tools/bwiki_import/type_relations.py`, `tools/bwiki_import/game_descriptions.py`, `tools/bwiki_import/tool_catalogs.py`, their CLI commands, `tools/brand/generate_brand_assets.swift`, and the atomic RGB store-screenshot normalizer
- App domain and data: the existing illustration key is projected into creature summaries and all summary queries, the upstream head key remains preserved in Catalog data, a null-preserving `PetDetail.totalBaseStats` contract, plus the type-relationship contract and bundled-asset repository
- App presentation: centralized `en-US` and `zh-CN` strings; localized startup, navigation, Catalog, Tools, personal library, and Settings flows; Wiki-matched display typography for headings, titles, and labels; a dedicated tabular numeric role for selected handbook values; platform body typography for long text; compact Sort/Filters/Search and Skill handbook/Skill filters/Skill query rows; a vertically grouped shiny/stage/form/season/type filter sheet; season-colored shiny-capable names; original/shiny detail art switching; 100-pixel contained full creature illustrations; inline muted form and `NO.<dex_no>` copy; accessible type icons; derived stage labels; detail-header favorites; categorized creature skills; a learnable-skill handbook with 42 combined filter choices; seven functional compact and unnumbered Tools cards, searchable and multi-select-filterable Egg groups, 54 game descriptions with relationships, a 547-occurrence activity timeline, and 110 gender-switchable outfits; accessible skill, feature, type, stat, category, activity, and outfit images; total base stats; and compact incoming type relationships
- Platform identity: the current ADR-0015 English and Chinese display names across Flutter, Android, and iOS; launcher and App icons; branded launch resources; and regenerated platform image slots
- Tests: focused core, Tool media, and font manifests; complete Catalog-to-Flutter original and shiny illustration resolution; exact creature and skill toolbar geometry and card copy; compact unnumbered Tools cards; combined source-backed creature filters; egg-group queries plus normal text search and multi-select filtering; shiny detail switching; every Tools route; game-description relationship closure; activity windows and categories; outfit variants and images; normal skill text input; detail-only favorite placement; derived stage and lord-evolution copy; combined skill filters; detail navigation; modal sort interaction; complete Catalog base-stat and type-combination audits; data-only Lua rejection; type relation; repository; source-grounded terminology; typography role separation; packaged font loading; literal UI-key completeness; fixed-copy localization-entry enforcement; Chinese top-level navigation rendering; frozen brand-source and output identities; store-screenshot eligibility; widget, integration, and iOS platform-identity coverage; the generated empty iOS example test was replaced
- Store evidence: four pre-typography iOS screenshots at 1206 × 2622 and four pre-typography Android screenshots at 1080 × 1920 under `docs/evidence/phase-8-store-screenshots/`; all eight are 8-bit RGB PNGs without alpha but must be regenerated before submission after ADR-0019

## Verification performed

```text
PYTHONDONTWRITEBYTECODE=1 PYTHONPATH=tools python3 -m unittest discover -s tests -p 'test_*.py'
Result: 101 tests passed, including the immutable font import, source-host confinement, changed-payload and tamper rejection, complete Tool source contracts, Tool media reference closure, executable-Lua rejection, exact screenshot inventory, dimensions, RGB color type, byte limit, and Android aspect-ratio checks.

cd app && dart format --output=none --set-exit-if-changed lib test integration_test test_driver tool
Result: 54 files checked; no changes required.

cd app && flutter analyze --no-pub
Result: no issues found.

cd app && flutter test --no-pub
Result: 115 tests passed, including display/body/number typography separation, packaged font loading, complete active Catalog original, shiny, activity, and outfit image packaging; accessible missing-asset fallbacks; adaptive complete single-line creature form labels; compact creature and skill card copy; compact unnumbered Tools cards; combined filter behavior; searchable and multi-select-filterable Egg groups; shiny detail switching; complete paged feature loading; all seven Tools routes; game-description relationships; activity and outfit repositories; normal text input; detail-only favorites; derived stage labels; modal sort interaction; base-stat totals; all active type combinations; the frozen terminology contract; literal Chinese UI-key completeness; fixed-copy localization-entry enforcement; and top-level Chinese navigation rendering.

Image manifest verification
Result: 1,484 unique files, 1,565 Catalog references, and 117,287,007 verified local bytes; manifest SHA-256 8e942ab4fa1c1c4f7b803454984009823bad4e20b240cc458c3e93bb0973a278.

Tool contract and media verification
Result: 54 game descriptions, 547 activity occurrences, 110 outfits, 220 gender variants, 273 compact images, 749 media references, and 12,379,751 verified local bytes; Tool manifest SHA-256 0c313dd46d84d7da93fb330b2f8e0df42752abe8cfc1f594c44e80e7eea6d8df.

Font asset verification
Result: two exact TrueType files and 4,568,108 verified local bytes; font manifest SHA-256 deeca1ff3faadc618a803c05892f443fb4c291b754984178f2085ef8bd11c20e.

Brand asset identity verification
Result: the frozen Dimo source plus all 24 declared iOS and Android icon or launch-image slots matched their exact inventories, dimensions, and reviewed SHA-256 values.

Tracked production placeholder audit
Result: no Flutter demo copy, Lorem Ipsum, sample-App text, temporary visual asset, default Flutter logo, or enabled debug banner remained. Development-only platform configuration and required storyboard infrastructure were distinguished from product content.

Type relationship verification
Result: source revision 39538, 19 source types, eight reviewed inverse-list exceptions, focused single-type and dual-type ×3-cap tests, and all 596 active Catalog type combinations passed.

Base-stat total verification
Result: 595 active forms produced totals from six present values; `pet_000535` retained six null values and no fabricated total.

cd app && flutter build ios --simulator --debug --no-pub
Result: passed; the current ADR-0019 App was rebuilt, installed, and launched on the iPhone 17 simulator. The bundled display and numeric fonts rendered successfully.

cd app && flutter drive --driver=test_driver/integration_test.dart --target=integration_test/phase_8_visual_test.dart -d 22A24FD1-B554-4683-A1A0-E454020C8F08 --no-pub
Result: passed; two integration-test results completed. The run captured the grouped creature filter sheet, compact unnumbered Tools destination, searchable Egg groups browser, complete 15-choice Egg-group filter sheet, Game descriptions and detail, Event timeline and detail, Outfit inspiration and detail, and shiny creature detail at 1206 x 2622. Headings, filters, card titles, labels, and bottom navigation used the display face without clipping; descriptions and explanatory copy retained the platform body face.

cd app/ios && xcodebuild test -workspace Runner.xcworkspace -scheme Runner -destination 'id=4DCEC9FD-FE44-4047-AE85-D481E03AD9D0' -only-testing:RunnerTests
Result: passed; the platform regression verified the published iOS display name and Bundle ID after replacing the generated empty example test.

cd app && flutter build apk --debug
Result: passed for the current ADR-0019 source; the bundled font files were accepted by the Android debug packaging path. Gradle emitted non-failing native-access and SDK XML tool-version warnings. Android visual review was not run because no Android emulator was connected.

cd app && flutter build appbundle --release --no-pub
Result: passed for the pre-Tool-media Phase 8 baseline; 158,152,015-byte AAB reported as 158.2 MB by Flutter; SHA-256 5ad3b961b314a2f6cbe6999e741554b92e5a5eab758d28d87f4bc8543ff16cd3. The current package requires a new release-size measurement.

cd app && flutter build ios --release --no-codesign --no-pub
Result: passed for the pre-Tool-media Phase 8 baseline; 122,644 KiB App reported as 122.8 MB by Flutter; embedded version 1.1.0 build 2; App framework SHA-256 6d0e0d6f848063dd9e5ea1397f91066d0378f7e09da28a9957a0a8abbdcd4b50. The current package requires a new release-size measurement.

Virtual-platform visual review
Result: the ADR-0019 source built, installed, and launched on the iOS simulator. Fresh 1206 × 2622 captures confirmed the game-facing display face on the App title, section titles, filters, Tool cards, creature detail controls, and bottom navigation while long descriptions retained the platform body face. The reviewed screens showed no clipped labels, obscured controls, or broken image composition.

git diff --check
Result: passed.

GitHub Actions `Offline validation`
Result: passed for the earlier Phase 8 commit `94ee692d9fc30ef33f9937116c891773d425a489`; hosted run 34400308182 completed successfully. Hosted validation of the current ADR-0019 typography revision has not run.

shasum -a 256 docs/technical-spec-v1.md
Result: 343618b414b7b8d6262dd58f82010bfefb2f3fdb29711a9e86428e042dd81876; the provenance baseline is unchanged.
```

## Not run

- App signing, archive export with a distribution identity, store upload, review, or publication
- Physical-device visual, accessibility, launch, memory, and storage validation
- Real Catalog V2 import or Phase 7 production package update
- Logical incremental patch generation or installation
- Android visual validation of the current ADR-0019 presentation revision
- Store screenshot regeneration after the ADR-0019 typography change
- Any Phase 8 work outside ADR-0015 through ADR-0019
- Hosted validation for the current ADR-0019 typography revision

## Remaining risks and next boundary

The measured package cost remains material because the complete original illustration, shiny illustration, skill, domain-icon, activity-icon, outfit-preview, and typography libraries ship offline. Asset version 2 adds 19,631,958 bytes of shiny art, Tool media version 1 adds 12,379,751 bytes, and font asset version 1 adds 4,568,108 bytes before platform packaging; the Android AAB and iOS release sizes must be remeasured before a later store candidate. Large activity posters were deliberately excluded because their source originals total about 436 MiB. No runtime image or font download, on-demand resource, or logical asset patch protocol was introduced.

A later Catalog or Wiki revision can add keys or change source files, but the installed App will not acquire them automatically; a new immutable image asset version and App release are required. The upstream `head_key` remains present only for source fidelity and is not a packaged runtime dependency.

The next boundary is either the deferred Phase 7 real Catalog update test after an actual upstream data change, or a separately declared continuation of the remaining deferred Phase 8 release work. Neither boundary changes the missing physical-device, signing, upload, review, or publication evidence.
