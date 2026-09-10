# Phase 8 implementation report

- Status: implementation complete for the ADR-0015 through ADR-0018 scopes; all other Phase 8 release work deferred
- Date: 2026-09-10
- Workspace: `/Users/ethan/Documents/ChatGPT/roco-handbook`

## Declared boundary

Phase 8 is limited to the formal App identity and launch experience, bilingual `en-US` and `zh-CN` UI, frozen offline Wiki images for original and shiny creatures, skills, features, selected domain controls, activity icons, and outfit previews; the full-illustration concrete-form catalog defined by ADR-0016; the creature and skill handbook presentation defined by ADR-0017; the filters and seven functional Tools routes defined by ADR-0018; source-backed total base stats and type relationships; plus iOS and Android store screenshots. ADR-0015 through ADR-0018 define the ownership, source, offline, accessibility, and acceptance boundaries.

App signing, store account configuration, listing submission, upload, publication, logical patches, Catalog V2, live Phase 7 update evidence, and other release work are deferred.

## Changed files

- Governance and current-state documentation: `AGENTS.md`, root and App READMEs, ADR-0015 through ADR-0018, `docs/features/localized-visual-handbook.md`, `docs/features/offline-catalog-browser.md`, `design-qa.md`, the Phase 8 evidence records, this report, and focused structure checks
- Frozen source contracts: `config/ui_terminology_zh_cn.json`, `config/wiki_assets_v2.json`, `config/type_relations_v1.json`, `config/game_descriptions_v1.json`, `config/activity_timeline_v1.json`, `config/fashion_catalog_v1.json`, `config/wiki_tool_assets_v1.json`, the four matching bundled JSON contracts, and both image manifests
- Frozen visual library: 569 original creature illustrations covering all 596 active forms, 144 shiny illustrations covering 146 active references, 736 skill or feature icons, and 35 type, stat, or skill-category icons under active asset version 2; asset version 1 remains immutable and is not packaged by Flutter
- Compact Tool media: 53 activity icons and 220 gender-specific outfit previews under `app/assets/wiki/tools/v1/`, covering 749 references in 12,379,751 verified bytes
- Import and generation tools: `tools/bwiki_import/image_assets.py`, `tools/bwiki_import/type_relations.py`, `tools/bwiki_import/game_descriptions.py`, `tools/bwiki_import/tool_catalogs.py`, their CLI commands, `tools/brand/generate_brand_assets.swift`, and the atomic RGB store-screenshot normalizer
- App domain and data: the existing illustration key is projected into creature summaries and all summary queries, the upstream head key remains preserved in Catalog data, a null-preserving `PetDetail.totalBaseStats` contract, plus the type-relationship contract and bundled-asset repository
- App presentation: centralized `en-US` and `zh-CN` strings; localized startup, navigation, Catalog, Tools, personal library, and Settings flows; compact Sort/Filters/Search and Skill handbook/Skill filters/Skill query rows; a vertically grouped shiny/stage/form/season/type filter sheet; season-colored shiny-capable names; original/shiny detail art switching; 100-pixel contained full creature illustrations; inline muted form and `NO.<dex_no>` copy; accessible type icons; derived stage labels; detail-header favorites; categorized creature skills; a learnable-skill handbook with 42 combined filter choices; seven functional Tools routes including 54 game descriptions with relationships, a 547-occurrence activity timeline, and 110 gender-switchable outfits; accessible skill, feature, type, stat, category, activity, and outfit images; total base stats; and compact incoming type relationships
- Platform identity: Android and iOS display names, launcher and App icons, branded launch resources, and regenerated platform image slots
- Tests: focused core and Tool media manifests, complete Catalog-to-Flutter original and shiny illustration resolution, exact creature and skill toolbar geometry and card copy, combined source-backed creature filters, egg-group queries, shiny detail switching, every Tools route, game-description relationship closure, activity windows and categories, outfit variants and images, normal skill text input, detail-only favorite placement, derived stage and lord-evolution copy, combined skill filters, detail navigation, modal sort interaction, complete Catalog base-stat and type-combination audits, data-only Lua rejection, type relation, repository, source-grounded terminology, literal UI-key completeness, fixed-copy localization-entry enforcement, Chinese top-level navigation rendering, frozen brand-source and output identities, store-screenshot eligibility, widget, integration, and iOS platform-identity coverage; the generated empty iOS example test was replaced
- Store evidence: four iOS screenshots at 1206 × 2622 and four Android screenshots at 1080 × 1920 under `docs/evidence/phase-8-store-screenshots/`; all eight are 8-bit RGB PNGs without alpha

## Verification performed

```text
PYTHONDONTWRITEBYTECODE=1 PYTHONPATH=tools python3 -m unittest discover -s tests -p 'test_*.py'
Result: 97 tests passed, including complete Tool source contracts, Tool media reference closure, executable-Lua rejection, exact screenshot inventory, dimensions, RGB color type, byte limit, and Android aspect-ratio checks.

cd app && dart format --output=none --set-exit-if-changed lib test integration_test test_driver tool
Result: 52 files checked; no changes required.

cd app && flutter analyze --no-pub
Result: no issues found.

cd app && flutter test --no-pub
Result: 113 tests passed, including complete active Catalog original, shiny, activity, and outfit image packaging; accessible missing-asset fallbacks; adaptive complete single-line creature form labels; compact creature and skill card copy; combined filter behavior; shiny detail switching; complete paged feature loading; all seven Tools routes; game-description relationships; activity and outfit repositories; normal skill text input; detail-only favorites; derived stage labels; modal sort interaction; base-stat totals; all active type combinations; the frozen terminology contract; literal Chinese UI-key completeness; fixed-copy localization-entry enforcement; and top-level Chinese navigation rendering.

Image manifest verification
Result: 1,484 unique files, 1,565 Catalog references, and 117,287,007 verified local bytes; manifest SHA-256 8e942ab4fa1c1c4f7b803454984009823bad4e20b240cc458c3e93bb0973a278.

Tool contract and media verification
Result: 54 game descriptions, 547 activity occurrences, 110 outfits, 220 gender variants, 273 compact images, 749 media references, and 12,379,751 verified local bytes; Tool manifest SHA-256 0c313dd46d84d7da93fb330b2f8e0df42752abe8cfc1f594c44e80e7eea6d8df.

Brand asset identity verification
Result: the frozen Dimo source plus all 24 declared iOS and Android icon or launch-image slots matched their exact inventories, dimensions, and reviewed SHA-256 values.

Tracked production placeholder audit
Result: no Flutter demo copy, Lorem Ipsum, sample-App text, temporary visual asset, default Flutter logo, or enabled debug banner remained. Development-only platform configuration and required storyboard infrastructure were distinguished from product content.

Type relationship verification
Result: source revision 39538, 19 source types, eight reviewed inverse-list exceptions, focused single-type and dual-type ×3-cap tests, and all 596 active Catalog type combinations passed.

Base-stat total verification
Result: 595 active forms produced totals from six present values; `pet_000535` retained six null values and no fabricated total.

cd app && flutter build ios --simulator --debug --no-pub
Result: passed; the current ADR-0018 App was rebuilt, installed, and launched on the iPhone 17 simulator after the integration runner. Creature filters, Game descriptions, Event timeline, Outfit inspiration, shiny detail, creature catalog, complete adaptive form subtitle, creature header, skill catalog, and skill detail captures were visually reviewed against the supplied references. Earlier Phase 8 visual evidence also passed on the iPhone 17 Pro simulator.

cd app && flutter drive --driver=test_driver/integration_test.dart --target=integration_test/phase_8_visual_test.dart -d 22A24FD1-B554-4683-A1A0-E454020C8F08 --no-pub
Result: passed; two integration-test results completed. The run captured the grouped filter sheet, vertical Tools destination, Game descriptions and detail, Event timeline and detail, Outfit inspiration and detail, and shiny creature detail at 1206 x 2622. It also confirmed normal text entry through the App search contract.

cd app/ios && xcodebuild test -workspace Runner.xcworkspace -scheme Runner -destination 'id=4DCEC9FD-FE44-4047-AE85-D481E03AD9D0' -only-testing:RunnerTests
Result: passed; the platform regression verified the published iOS display name and Bundle ID after replacing the generated empty example test.

cd app && flutter build apk --debug
Result: passed; the rebuilt APK was installed and launched on the Android API 36 emulator.

cd app && flutter build appbundle --release --no-pub
Result: passed for the pre-Tool-media Phase 8 baseline; 158,152,015-byte AAB reported as 158.2 MB by Flutter; SHA-256 5ad3b961b314a2f6cbe6999e741554b92e5a5eab758d28d87f4bc8543ff16cd3. The current package requires a new release-size measurement.

cd app && flutter build ios --release --no-codesign --no-pub
Result: passed for the pre-Tool-media Phase 8 baseline; 122,644 KiB App reported as 122.8 MB by Flutter; embedded version 1.1.0 build 2; App framework SHA-256 6d0e0d6f848063dd9e5ea1397f91066d0378f7e09da28a9957a0a8abbdcd4b50. The current package requires a new release-size measurement.

Virtual-platform visual review
Result: the ADR-0018 source built, installed, and launched on the iOS simulator. The grouped creature filters, vertical Tools cards, Game descriptions, 74-entry September timeline view, activity detail, 110-outfit grid, outfit detail and gender switch, frozen shiny detail art and switch, compact creature cards, adaptive complete single-line form label, fixed inline number, unbacked detail type icons, derived stage and lord-evolution copy, detail-header favorites, skill handbook, and skill cards passed focused visual review. Earlier Phase 8 source built and launched on both iOS and Android virtual platforms and passed the store-capture checks.

git diff --check
Result: passed.

GitHub Actions `Offline validation`
Result: passed for the earlier Phase 8 commit `94ee692d9fc30ef33f9937116c891773d425a489`; hosted run 34400308182 completed successfully. Hosted validation of the current ADR-0017 UI revision is reserved for repository-owner confirmation.

shasum -a 256 docs/technical-spec-v1.md
Result: 343618b414b7b8d6262dd58f82010bfefb2f3fdb29711a9e86428e042dd81876; the provenance baseline is unchanged.
```

## Not run

- App signing, archive export with a distribution identity, store upload, review, or publication
- Physical-device visual, accessibility, launch, memory, and storage validation
- Real Catalog V2 import or Phase 7 production package update
- Logical incremental patch generation or installation
- Android visual or build validation of the current ADR-0018 presentation revision
- Any Phase 8 work outside ADR-0015 through ADR-0018
- Hosted validation for the current ADR-0018 UI revision; the repository owner will confirm it separately

## Remaining risks and next boundary

The measured package cost remains material because the complete original illustration, shiny illustration, skill, domain-icon, activity-icon, and outfit-preview library ships offline. Asset version 2 adds 19,631,958 bytes of shiny art and Tool media version 1 adds 12,379,751 bytes before platform packaging; the Android AAB and iOS release sizes must be remeasured before a later store candidate. Large activity posters were deliberately excluded because their source originals total about 436 MiB. No runtime image download, on-demand resource, or logical asset patch protocol was introduced.

A later Catalog or Wiki revision can add keys or change source files, but the installed App will not acquire them automatically; a new immutable image asset version and App release are required. The upstream `head_key` remains present only for source fidelity and is not a packaged runtime dependency.

The next boundary is either the deferred Phase 7 real Catalog update test after an actual upstream data change, or a separately declared continuation of the remaining deferred Phase 8 release work. Neither boundary changes the missing physical-device, signing, upload, review, or publication evidence.
