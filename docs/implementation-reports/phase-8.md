# Phase 8 implementation report

- Status: implementation complete for the ADR-0015 through ADR-0022 scopes; all other Phase 8 release work deferred
- Date: 2026-09-14
- Workspace: `/Users/ethan/Documents/ChatGPT/roco-handbook`

## Declared boundary

Phase 8 is limited to the formal App identity and launch experience, bilingual `en-US` and `zh-CN` UI, frozen offline Wiki images for original and shiny creatures, skills, features, selected domain controls, activity icons, and outfit previews; the full-illustration concrete-form catalog defined by ADR-0016; the creature and skill handbook presentation defined by ADR-0017; the filters and seven functional Tools routes defined by ADR-0018; the frozen display and numeric typography roles defined by ADR-0019; the pre-release NRC data and image baseline defined by ADR-0020; the persisted grid/list creature Catalog choice defined by ADR-0021; the platform-native navigation materials defined by ADR-0022; source-backed total base stats and type relationships; plus iOS and Android store screenshots. ADR-0015 through ADR-0022 define the ownership, source, offline, accessibility, and acceptance boundaries.

App signing, store account configuration, listing submission, upload, publication, logical patches, a signed and published data version 2 Phase 7 package, live Phase 7 update evidence, and other release work are deferred.

## Changed files

- Governance and current-state documentation: `AGENTS.md`, root and App READMEs, ADR-0015 through ADR-0022, `docs/features/localized-visual-handbook.md`, `docs/features/offline-catalog-browser.md`, `design-qa.md`, the Phase 8 evidence records including the NRC Catalog refresh, creature-grid simulator capture, branded Catalog header, type-background comparisons, and platform-navigation captures, this report, and focused structure checks
- Frozen source contracts: the NRC source configuration and 1,911-entry identity registry; `config/ui_terminology_zh_cn.json`, `config/wiki_assets_v3.json`, `config/wiki_fonts_v1.json`, `config/type_relations_v1.json`, `config/game_descriptions_v1.json`, `config/activity_timeline_v1.json`, `config/fashion_catalog_v1.json`, `config/wiki_tool_assets_v1.json`; the matching bundled JSON contracts; and the active image, Tool, and font manifests
- Frozen Catalog baseline: snapshot `snapshot-dad7cd7d5ce73236`, deterministic normalized data version 2, and release 2 with 621 creature forms, 466 handbook entries, 824 skills, 311 Learnsets, 273 evolution groups, and a complete source and build audit
- Frozen visual library: 595 original creature illustrations covering all 621 active forms, 191 shiny illustrations covering 193 active references, 773 skill or feature icons covering 824 active records, and 35 preserved type, stat, or skill-category icons under active asset version 3; earlier image versions remain immutable historical evidence and are not packaged by Flutter
- Compact Tool media: 53 activity icons and 220 gender-specific outfit previews under `app/assets/wiki/tools/v1/`, covering 749 references in 12,379,751 verified bytes
- Frozen typography: the 4,563,796-byte `RocoDisplay` face and 4,312-byte `RocoNumbers` face under `app/assets/fonts/v1/`, with exact source paths and SHA-256 values in the immutable manifest
- Import and generation tools: the bounded live snapshot importer, NRC normalizer, source-system-aware identity resolver, preserved-image reuse support, `tools/bwiki_import/image_assets.py`, `tools/bwiki_import/font_assets.py`, `tools/bwiki_import/type_relations.py`, `tools/bwiki_import/game_descriptions.py`, `tools/bwiki_import/tool_catalogs.py`, their CLI commands, `tools/brand/generate_brand_assets.swift`, and the atomic RGB store-screenshot normalizer
- App domain and data: bundled Catalog data version 2; active NRC image asset version 3; source-filename-aware original and shiny illustration mapping; the existing illustration key projected into creature summaries and all summary queries; the upstream head key preserved in Catalog data; a null-preserving `PetDetail.totalBaseStats` contract; plus the type-relationship contract and bundled-asset repository
- App presentation: centralized `en-US` and `zh-CN` strings; localized startup, navigation, Catalog, Tools, personal library, and Settings flows; a branded creature-root hero using one generated decorative background with live title, data, information, sort, type, and search controls; Wiki-matched display typography for headings, titles, and labels; a dedicated tabular numeric role for selected handbook values; platform body typography for long text; iOS 26 system Liquid Glass navigation through native UIKit views with an older-iOS system-material fallback; Android M3 Expressive app bars, sheets, and a safe-area-aware labeled floating stadium bottom navigation; body content extended behind both floating navigation implementations with dynamic final-result clearance and a seven-layer shared blur that strengthens toward the screen edge; opaque or tonal reading surfaces on both platforms; compact Sort/Filters/Search and Skill handbook/Skill filters/Skill query rows; a vertically grouped shiny/stage/form/season/type filter sheet; a default responsive two-column phone creature grid with a three-column wide layout and a Settings-controlled persisted compact-list alternative; code-native thematic backgrounds with 18 distinct type palettes, dual-type blending, and restrained watermarks and motifs; season-colored shiny-capable names; original/shiny detail art switching; contained full creature illustrations; inline muted form and `NO.<dex_no>` copy; accessible type icons; derived stage labels; detail-header favorites; categorized creature skills; a learnable-skill handbook with 42 combined filter choices; seven functional compact and unnumbered Tools cards, searchable and multi-select-filterable Egg groups, 54 game descriptions with relationships, a 547-occurrence activity timeline, and 110 gender-switchable outfits; accessible skill, feature, type, stat, category, activity, and outfit images; total base stats; and compact incoming type relationships
- Platform identity: the current ADR-0015 English and Chinese display names across Flutter, Android, and iOS; launcher and App icons; branded launch resources; regenerated platform image slots; the registered UIKit navigation platform view; and the Android M3 Expressive theme and floating-navigation contract
- Tests: focused core, Tool media, and font manifests; complete Catalog-to-Flutter original and shiny illustration resolution; exact creature and skill toolbar geometry and card copy; all 18 active type-background accents plus the warm-light variant; list and grid background presence; compact unnumbered Tools cards; combined source-backed creature filters; the grid-default and list-switch preference contract, phone two-column geometry, App-restart persistence, and Settings localization; distinct iOS and Android navigation-shell selection plus iOS fallback interaction; root body extension on both platforms; Android floating-navigation safe-area margin, stadium shape, clipping, elevation, inner transparency, visible labels and keys, and M3 sizing; egg-group queries plus normal text search and multi-select filtering; shiny detail switching; every Tools route; game-description relationship closure; activity windows and categories; outfit variants and images; normal skill text input; detail-only favorite placement; derived stage labels; modal sort interaction; complete Catalog base-stat and type-combination audits; data-only Lua rejection; type relation; repository; source-grounded terminology; typography role separation; packaged font loading; literal UI-key completeness; fixed-copy localization-entry enforcement; Chinese top-level navigation rendering; frozen brand-source and output identities; store-screenshot eligibility; widget, integration, and iOS platform-identity coverage; the generated empty iOS example test was replaced
- Store and working evidence: four pre-typography and pre-rename iOS screenshots at 1206 × 2622 and four pre-typography and pre-rename Android screenshots at 1080 × 1920 under `docs/evidence/phase-8-store-screenshots/`; all eight are 8-bit RGB PNGs without alpha but must be regenerated before submission after ADR-0019, ADR-0022, and the current ADR-0015 product-name revision. Current working captures under `docs/evidence/phase-8-platform-navigation/` record the iOS 26.5 native Liquid Glass and Android 16 M3 Expressive home states but are not store-submission assets.

## Verification performed

```text
PYTHONDONTWRITEBYTECODE=1 PYTHONPATH=tools python3 -m unittest discover -s tests -p 'test_*.py'
Result: 105 tests passed, including live NRC snapshot freezing, deterministic NRC normalization, the required S4 sample, source-reference closure, active image version 3, source-host confinement, changed-payload and tamper rejection, executable-Lua rejection, complete Tool source contracts, immutable font import, platform display-name contracts, and store-screenshot checks.

cd app && dart format --output=none --set-exit-if-changed lib test integration_test test_driver tool
Result: 55 files checked; no changes required.

cd app && flutter analyze --no-pub
Result: no issues found.

cd app && flutter test --no-pub
Result: 119 tests passed, including the current Chinese product title, display/body/number typography separation, packaged font loading, complete active Catalog original, shiny, activity, and outfit image packaging; accessible missing-asset fallbacks; adaptive complete single-line creature form labels; distinct accents for all 18 combat types and the reviewed warm-light variant; list and grid background presence; the default two-column creature grid, Settings-controlled compact-list alternative, and persisted local layout preference; distinct iOS and Android navigation shells with body extension; Android floating-navigation safe-area margin, stadium shape, clipping, elevation, inner transparency, visible labels and keys, and M3 sizing; compact creature and skill card copy; compact unnumbered Tools cards; combined filter behavior; searchable and multi-select-filterable Egg groups; shiny detail switching; complete paged feature loading; all seven Tools routes; game-description relationships; activity and outfit repositories; normal text input; detail-only favorites; derived stage labels; modal sort interaction; base-stat totals; all active type combinations; the frozen terminology contract; literal Chinese UI-key completeness; fixed-copy localization-entry enforcement; and top-level Chinese navigation rendering.

Image manifest verification
Result: 1,594 unique files, 1,673 Catalog references, and 124,766,985 verified local bytes; manifest SHA-256 0a38eea8a313ce72f910b6f5c914d82d3250d2db816f16e109cd2120d06f9373.

Tool contract and media verification
Result: 54 game descriptions, 547 activity occurrences, 110 outfits, 220 gender variants, 273 compact images, 749 media references, and 12,379,751 verified local bytes; Tool manifest SHA-256 0c313dd46d84d7da93fb330b2f8e0df42752abe8cfc1f594c44e80e7eea6d8df.

Font asset verification
Result: two exact TrueType files and 4,568,108 verified local bytes; font manifest SHA-256 deeca1ff3faadc618a803c05892f443fb4c291b754984178f2085ef8bd11c20e.

Brand asset identity verification
Result: the frozen Dimo source plus all 24 declared iOS and Android icon or launch-image slots matched their exact inventories, dimensions, and reviewed SHA-256 values.

Tracked production placeholder audit
Result: no Flutter demo copy, Lorem Ipsum, sample-App text, temporary visual asset, default Flutter logo, or enabled debug banner remained. Development-only platform configuration and required storyboard infrastructure were distinguished from product content.

Type relationship verification
Result: source revision 39538, 19 source types, eight reviewed inverse-list exceptions, focused single-type and dual-type ×3-cap tests, and all 621 active Catalog type combinations passed.

Base-stat total verification
Result: all 621 active NRC forms produced totals from six present values; the null-safe calculation remains covered for future incomplete records.

cd app && flutter build ios --simulator --debug --no-pub
Result: passed; the current App was rebuilt for the iPhone 17 simulator. After all integration testing, `simctl install` and `simctl launch` performed an ordinary persistent installation, and `simctl get_app_container` resolved the installed bundle. The creature root rendered its branded hero and thematic type cards, while the iOS 26.5 system rendered Liquid Glass for the native bottom navigation. The ordinary-install capture contains no integration pointer overlay.

cd app && flutter drive --driver=test_driver/integration_test.dart --target=integration_test/phase_8_visual_test.dart -d 22A24FD1-B554-4683-A1A0-E454020C8F08 --no-pub
Result: passed; two integration-test results completed. The run changed all four destinations through the labeled hit regions over the native UIKit tab bar, explicitly selected and captured both the compact list and responsive grid, and completed the grouped creature filter sheet, compact unnumbered Tools destination, searchable Egg groups browser, complete 15-choice Egg-group filter sheet, Game descriptions and detail, Event timeline and detail, Outfit inspiration and detail, and shiny creature detail at 1206 x 2622.

cd app && flutter drive --driver=test_driver/integration_test.dart --target=integration_test/phase_8_visual_test.dart -d emulator-5554 --no-pub
Result: passed; two integration-test results completed on the Android 16 API 36 emulator after enabling Flutter-surface screenshot capture. The labeled floating Material navigation changed all four destinations, both creature layouts were explicitly selected and captured, the Catalog visibly extended behind its surface, and the same Phase 8 filter, Tool, search-input, detail, and shiny flow completed without a failed assertion.

cd app/ios && xcodebuild test -workspace Runner.xcworkspace -scheme Runner -destination 'id=22A24FD1-B554-4683-A1A0-E454020C8F08' -only-testing:RunnerTests
Result: passed; the platform regression verified the current iOS Chinese display name and unchanged Bundle ID, while the Runner target compiled and linked the registered native navigation view.

cd app && flutter build apk --debug --no-pub
Result: passed for the current source. The debug APK includes the branded Catalog hero, thematic type-card backgrounds, complete labeled floating M3 stadium navigation, and shared bottom boundary treatment. Gradle emitted a non-failing native-access warning.

cd app && flutter build appbundle --release --no-pub
Result: passed for the pre-Tool-media Phase 8 baseline; 158,152,015-byte AAB reported as 158.2 MB by Flutter; SHA-256 5ad3b961b314a2f6cbe6999e741554b92e5a5eab758d28d87f4bc8543ff16cd3. The current package requires a new release-size measurement.

cd app && flutter build ios --release --no-codesign --no-pub
Result: passed for the pre-Tool-media Phase 8 baseline; 122,644 KiB App reported as 122.8 MB by Flutter; embedded version 1.1.0 build 2; App framework SHA-256 6d0e0d6f848063dd9e5ea1397f91066d0378f7e09da28a9957a0a8abbdcd4b50. The current package requires a new release-size measurement.

Virtual-platform visual review
Result: the current source built, installed, launched, and was captured on the iOS 26.5 and Android 16 simulators. The branded header comparison and focused list/grid comparisons preserve the requested hierarchy, 18-type visual system, dual-type blending, frozen creature art, readable copy, and live controls. The iOS view uses system Liquid Glass only for native navigation; Android uses a complete labeled floating M3 stadium. Both platforms extend Catalog content behind the floating bar, retain bottom scroll clearance, and use only a restrained shared blur at the former safe-area boundary. No clipped icon, obscured control, broken image composition, or glass-backed reading surface was observed.

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
- Signed Catalog data version 2 Phase 7 package generation, GitHub Release upload, or live update installation
- Logical incremental patch generation or installation
- Store screenshot regeneration after the ADR-0019 typography, ADR-0022 navigation, and current ADR-0015 product-name changes
- Any Phase 8 work outside ADR-0015 through ADR-0022
- Hosted validation for the current ADR-0019 typography revision

## Remaining risks and next boundary

The measured package cost remains material because the complete original illustration, shiny illustration, skill, domain-icon, activity-icon, outfit-preview, and typography libraries ship offline. Active image asset version 3 contains 124,766,985 bytes, Tool media version 1 adds 12,379,751 bytes, and font asset version 1 adds 4,568,108 bytes before platform packaging; the Android AAB and iOS release sizes must be remeasured before a later store candidate. Large activity posters were deliberately excluded because their source originals total about 436 MiB. No runtime image or font download, on-demand resource, or logical asset patch protocol was introduced.

A later Catalog or Wiki revision can add keys or change source files, but the installed App will not acquire them automatically; a new immutable image asset version and App release are required. The upstream `head_key` remains present only for source fidelity and is not a packaged runtime dependency.

The next boundary is either the deferred Phase 7 signing and live installation test for the real Catalog data version 2 package, regenerated store-candidate screenshots after the accepted platform-navigation treatment, or a separately declared continuation of the remaining deferred Phase 8 release work. None of these boundaries changes the missing physical-device, signing, upload, review, or publication evidence.
