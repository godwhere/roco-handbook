# Phase 9 implementation report

- Status: native implementation and local acceptance complete; physical upgrade and release acceptance remain open
- Date: 2026-10-09
- Workspace: `/Users/ethan/Documents/ChatGPT/roco-handbook`
- Decision: [ADR-0023](../decisions/ADR-0023-native-swift-ios-client.md)

## Offline CI repair, 2026-10-15

[Offline validation run 29](https://github.com/godwhere/roco-handbook/actions/runs/38751322820)
failed its Python job because the NRC normalization test depended on ignored raw
Lua content. Swift tests and the simulator build passed. [ADR-0028](../decisions/ADR-0028-checkout-independent-nrc-tests.md)
limits this Phase 9 repair to `tests/builder/test_nrc_pipeline.py`, owned test
fixtures under `tests/builder/fixtures/nrc/`, that decision, this report, and
[CI repair evidence](../evidence/phase-9-offline-ci-2026-10-15.md).

The test now normalizes a tracked synthetic snapshot, checks deterministic
output and acquisition conditions, and rejects missing required metadata or
content. Validation of the complete committed Catalog is retained. Production
code, UI, imports, schemas, identities, immutable data, workflow, commands, and
dependencies are unchanged; the README therefore needs no update. The focused
four-case NRC suite and immutable release 2 check pass. A tracked-files-plus-patch
copy without raw content passes all 111 Python tests and the release check; the
working-copy full run was interrupted during slow frozen-image reads and is not
claimed as a pass. All 13 changed paths match the allowlist, and `git diff --check`
passes. Logs and the corrected initial English-text failure are recorded in the
linked evidence. GitHub Desktop commit/push and hosted follow-up complete the
repository boundary; physical iOS, signed upgrades, accessibility, live updates,
and store acceptance remain separate.

## Declared boundary

The user requested Swift and iOS-only delivery. This phase replaces the active Flutter client with Swift/SwiftUI for iOS 15 and later, preserving the offline Catalog and personal-data contracts. Allowed paths are `ios/`, `AGENTS.md`, the root and historical App READMEs, the offline CI workflow, focused native packaging and CI assertions under `tests/`, ADR-0023, the six affected feature documents, this report, and Phase 9 evidence.

Imports, source revisions, normalized data, identities, both normative SQL files, immutable Catalog and visual assets, signing keys, network configuration, store accounts, and repository visibility are outside this phase. Android is excluded from active implementation and release acceptance. The prior client remains a migration reference; its assets remain the single immutable packaging source.

Stopping conditions were an incompatible personal schema, immutable-asset drift, a required unapproved dependency, or an installer unable to preserve personal data. None occurred. No source import or live Catalog update was initiated.

## Changed files and resulting behavior

- `ios/Package.swift`, `Sources/CSystem/`, and `Sources/HandbookCore/`: platform SQLite/zlib, typed domain records, actor-owned Catalog and personal repositories, frozen asset/Tool repositories, Catalog install/recovery, Ed25519 validation, bounded explicit transport, and strict complete-package ZIP decoding. No third-party Swift dependency was added.
- `ios/App/`: native SwiftUI presentation, four destinations, creature and skill search/filter/sort/paging, explicit concrete-form details and source references, original/shiny illustrations, seven Tool routes, favorites, collection marks, notes, layout persistence, source attribution, recovery, and manually initiated Catalog updates. Existing source terms are reused in English and Simplified Chinese resources. Current Apple system navigation is used; iOS 15 has a navigation fallback.
- `ios/RocoHandbook.xcodeproj/`, `generate_project.py`, and `prepare_resources.py`: deterministic local-package Xcode project, shared scheme, version `1.2.0` build `3`, unchanged bundle ID `world.roco.rocoHandbook`, and exact active asset staging. The personal SQL is compared with its normative source before packaging. Historical image versions are excluded.
- `ios/Tests/HandbookCoreTests/`, `ios/UITests/`, and `tests/test_native_ios.py`: focused compatibility, identity, source, asset closure, lifecycle, signature/archive, native configuration, bilingual literal/error-copy completeness, frozen terminology, and actual UI regression coverage. `tests/test_project_structure.py` now expects only the two pinned action kinds used by the active Python and native CI jobs.
- `.github/workflows/offline-validation.yml`: retain offline Python validation, check active Catalog release 2, and replace Flutter CI with Mac-host Swift tests and a native iOS simulator build. Actions remain pinned, checkout credentials are not persisted, and repository permissions remain read-only.
- `AGENTS.md`, both READMEs, ADR-0023, six feature documents, this report, and [Phase 9 evidence](../evidence/phase-9-swift-ios-2026-10-09.md): declare the active language/platform, local commands, compatibility, conservative cleanup, current presentation, and honest acceptance limits. The Chinese provenance specification remains unchanged.

## Compatibility and preservation

The native client retains `Library/Application Support/user/user.db`, user schema version 1, saved stable identities, note IDs, name snapshots, and the JSON `pet_catalog_layout` value. Unknown or damaged personal databases are preserved and block startup. Catalog restoration keeps the same personal repository.

Existing active/previous pointer paths, pointer version 2, compatible legacy pointers, versioned Catalog basenames, attribution basenames, installer lock, and replay-state path are supported. A newer validated Catalog remains selected during App startup. Restore does not lower the accepted release-sequence floor. Cleanup removes invocation-owned staging files and may repair the exact damaged candidate basename; it does not sweep older files or touch the personal directory.

Catalog data version 2 remains 621 concrete forms, 466 handbook entries, 824 skills, 311 Learnsets, and 273 evolution groups. All 621 original-image references, 193 shiny references, and 824 skill/feature-image references close over existing packaged files. The source response/parser/normalizer/database chain was reused without a schema or identity change.

## Verification

Host: Xcode 27.0 (`27A266a`), Swift 6.4, iOS SDK 27.0. UI tests used a newly created, invocation-owned iPhone 18 Pro simulator, iOS 27.0. Existing simulators and personal application data were not reset.

| Check | Result |
| --- | --- |
| `PYTHONDONTWRITEBYTECODE=1 PYTHONPATH=tools python3 -m unittest discover -s tests -p 'test_*.py'` | Passed: 109 tests |
| `PYTHONDONTWRITEBYTECODE=1 PYTHONPATH=tools python3 tools/release/check_catalog.py --release data/release/2` | Passed: exact release identity, metadata, source lock, schema, integrity, and references |
| `swift test --package-path ios --scratch-path /tmp/roco-handbook-spm` | Passed: 22 offline XCTest cases |
| `xcodebuild -project ios/RocoHandbook.xcodeproj -scheme RocoHandbook -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/roco-handbook-xcode CODE_SIGNING_ALLOWED=NO build` | Passed: native simulator application |
| `xcodebuild -project ios/RocoHandbook.xcodeproj -scheme RocoHandbook -destination 'platform=iOS Simulator,id=59C3C5B8-DC7B-418A-84D7-8C0B165A5B8A' -derivedDataPath /tmp/roco-handbook-ui -resultBundlePath /tmp/roco-native-ui-tests-final.xcresult -parallel-testing-enabled NO test` | Passed: 4 UI tests, zero failures |
| Chinese Catalog capture | Native installed simulator UI reviewed at 1206 × 2622; stored in Phase 9 evidence |
| Frozen specification and phase diff | Baseline specification unchanged; only declared paths changed; `git diff --check` passed |

Swift coverage includes concrete-form/default identity, the documented three-form case, independent feature source references, shared Learnsets and acquisition conditions, search escaping and filters, missing saved-object snapshots, literal prior-client pointers and personal paths, recovery, unknown personal schema preservation, cross-object note edit rejection, replay protection, signed fixture rejection, and stored/deflated ZIP validation. Owned remote fixtures are test-only; none were placed in production resources.

UI coverage includes all four destinations and all seven Tools routes, detail navigation, a source-backed shiny switch, favorites and notes surviving Catalog restoration, and the selected list layout surviving process restart. These flows do not issue an update request. A separate Chinese capture confirms the localized Catalog presentation; exhaustive localization and accessibility acceptance are not implied.

Initial host test signing failed when a test bundle inherited Documents resource-fork metadata. Moving derived/test products to `/tmp` resolved it without changing host security or networking. A simulator test build initially selected a mismatched package architecture; Debug now uses the active architecture. The first UI run exposed inherited parent accessibility identifiers hiding child controls; the parent identifiers were removed, and final UI tests passed. The stale CI action-count assertion was updated for the intentional removal of the Flutter setup action, and all Python tests then passed. Non-failing App Intents metadata extraction notes remain.

## Artifacts

- Active source project: `ios/RocoHandbook.xcodeproj`
- Native debug App: `/tmp/roco-handbook-xcode/Build/Products/Debug-iphonesimulator/RocoHandbook.app`
- UI results: `/tmp/roco-native-ui-tests-final.xcresult`
- Full local logs: `/tmp/roco-python-tests.log`, `/tmp/roco-swift-tests.log`, `/tmp/roco-catalog-check.log`, `/tmp/roco-ios-build.log`, `/tmp/roco-ios-ui-tests.log`
- Reviewed capture: `docs/evidence/phase-9-swift-ios/catalog-zh-cn.png`

Temporary products are local validation artifacts, not signed release deliverables. No credentials, cookies, personal databases, generated releases, or build products are included in the phase delivery. GitHub Desktop is the required commit/push route; remote synchronization is checked after delivery.

## Not run and remaining risks

- Signed Flutter-to-Swift upgrade on a physical iPhone, physical offline first launch, or personal-data migration on hardware
- iOS 15 runtime acceptance, VoiceOver, largest accessibility text sizes, exhaustive localization, power-loss durability, or low-storage behavior
- A live signed discovery/download/install, the unpublished data version 2 remote package, or an actual server response matrix
- Distribution signing, Release archive/export, store screenshots for submission, App Store upload, review, or publication
- Hosted CI for this revision at the time of local acceptance; the changed workflow is checked locally but its future hosted result must be observed separately
- Archived Flutter and Android builds or tests; they are not active delivery targets

Conservative Catalog retention can use additional storage. Physical upgrade and recovery acceptance should precede any broader cleanup policy or removal of the historical client.

## Next allowed boundary

Configure the user's iOS signing team and validate an ordinary signed upgrade from the prior client, including existing favorites, notes, collection marks, layout settings, and Catalog pointers. Then validate supported-device/runtime accessibility and recovery before distribution. Any live update publication or App Store upload requires its own explicit scope and evidence.

## Native layout follow-up, 2026-10-15

The user requested a status-bar-covering Catalog hero, a single row for sort/filter/search, a default three-column creature layout, and creature details following four supplied reference screens. [ADR-0024](../decisions/ADR-0024-native-catalog-and-detail-layout.md) declares the Phase 9 allowlist, acceptance commands, non-goals, and stopping conditions. No stopping condition has occurred.

Changed files are `ios/App/{AppModel,CatalogViews,Components,DetailViews,SettingsViews}.swift`, both native `Localizable.strings` resources, `ios/Sources/HandbookCore/{Models,CatalogRepository,UserRepository}.swift`, focused core/UI tests, the root README, the localized-visual feature document, ADR-0024, this report, and the new evidence document/captures. No project generator, dependency, schema, source snapshot, Catalog release, or immutable asset changed.

The root hero extends behind system status information while preserving a safe content inset. Sort/filter icon controls and search share one row. Three-column cards size illustrations to their available width; two-column and list preferences remain available and compatible. The new default uses the existing personal setting without replacing user data.

Creature details have a warm illustration header, rounded surface, and Overview, Skills, Type relationships, and Egg groups tabs. The overview has colored stat bars, the independent feature card, existing egg measurements, and basic facts. Skills keep source selectors, text search, filters, and every acquisition condition. Relationship direction is explicit and existing multiplier rules remain intact. Egg-group links use the existing Catalog filter. The toolbar preserves favorites, personal records, evolution, and source access; source-backed shiny switching remains available. The repository maps existing egg metadata into typed DTOs without changing the database or inventing missing fields.

Verification and artifacts are recorded in [native layout evidence](../evidence/phase-9-native-layout-2026-10-15.md). Local acceptance passed: 109 Python tests, 24 Swift tests, seven UI cases, a focused Catalog regression, the final Chinese capture regression, the final generic simulator build, scoped diff review, and `git diff --check`. Five original 1206 × 2622 captures are retained under `docs/evidence/phase-9-native-layout/`. The initial hero accessibility identifier issue was corrected before the full passing UI run; final visual refinements were checked with a new capture run and build. No personal database, input reference screenshot, build product, credential, or fabricated release data is included.

The next allowed boundary remains physical iOS/accessibility and signed-upgrade validation; no live import, update publication, or store operation is part of this follow-up. GitHub Desktop commit/push completes the scoped repository delivery, with the observed synchronization result reported in the final handoff.

## Scroll-linked artwork and symbol filters, 2026-10-15

The next user request adds large artwork on creature detail entry, contraction while browsing, multi-column creature/skill filter options, and more visual symbols informed by the public BWIKI gallery. [ADR-0025](../decisions/ADR-0025-scrollable-artwork-and-symbol-filters.md) declares this Phase 9 boundary. Changed paths are `ios/App/{CatalogViews,Components,DetailViews}.swift`, both native localization resources, `ios/UITests/RocoHandbookUITests.swift`, the root README, the localized-visual feature document, ADR-0025, this report, and the new evidence/captures. Source imports, assets, Catalog records, schemas, identities, repositories, dependencies, runtime networking, and release settings remain unchanged.

The same source-backed artwork contracts from an expanded presentation to a compact pinned identity header. The header lives inside the native scroll view with a constant content inset, allowing vertical drags from artwork, tabs, and content without a resize feedback loop. Returning to the top restores the large image. Tab changes restore the new panel's content start while retaining a compact browsing header. Short tabs and original/shiny selection remain usable. Reduce Motion selects endpoint layouts without interpolated scaling.

Creature and skill filter sheets use adaptive choice grids with existing type and classification images, short names, and non-color selection checks. Native reset/completion symbols have localized accessible labels. Detail skill filters reuse the same choices over loaded DTOs, including multiple existing elements and classifications. Detail tabs, source selectors, and base-stat labels add native or bundled symbols while retaining required names and acquisition meaning. The final hero uses a darker warm gradient for readable white metadata.

Local regression passed: 24 Swift tests, 109 Python tests, and the complete nine-case UI suite. New coverage asserts large/compact/restored image geometry, shiny selection across scrolling and short tabs, multiple choices sharing a row, combined selections, reset behavior, and actual filtered creature/skill results. The retained suite includes all destinations and Tools, Catalog layout persistence, source-backed shiny switching, detail search and relationship/egg-group navigation, and favorites/notes surviving Catalog recovery. Final Chinese visual review, native builds, simulator installation, personal-data preservation, logs, and captures are recorded in [symbol UI evidence](../evidence/phase-9-symbol-ui-2026-10-15.md).

Final capture review additionally found an early-opened skill sheet retaining an empty type list. Both sheets now observe the parent list through bindings and show loading progress until icons arrive. Two focused filter/capture cases passed after this correction and the final contrast refinement; the final four-case native packaging check and generic/destination simulator builds also passed. Nine original Chinese captures were reviewed and retained. Installation onto the original Roco Swift Migration simulator succeeded; the installed executable matches the build, and all personal table digests/counts, schema version, integrity, and references remain unchanged.

Early focused runs exposed discarded chip accessibility identifiers, scroll-offset propagation, and a viewport overlay intercepting vertical drags. These were corrected before the passing complete run. No personal records, input reference screenshots, credentials, generated release data, or build products are included. The next boundary remains physical iOS/accessibility and signed-upgrade validation; no source update or store action is authorized by this visual follow-up. Complete the scoped repository delivery through GitHub Desktop and verify the resulting remote synchronization.

## Neutral artwork and compact skill cards, 2026-10-15

The user requested a creature illustration background matching the page and compact skill cards with two or three items per row, while retaining the detailed-description presentation as an option. The final correction places skill names in their own top row above the image and metrics. [ADR-0026](../decisions/ADR-0026-neutral-hero-and-compact-skills.md) declares this Phase 9 boundary. Changed paths are `ios/App/{AppModel,CatalogViews,Components,DetailViews,SettingsViews}.swift`, both native localization resources, `ios/Sources/HandbookCore/{Models,UserRepository}.swift`, focused core/UI tests, the root README, the localized-visual feature document, ADR-0026, this report, and the new evidence/captures. Source imports, immutable assets, Catalog records, SQL schemas, identities, dependencies, runtime networking, and release settings remain unchanged.

The artwork header now uses the existing adaptive surface with primary text, preserving scrolling and source-backed shiny selection. Skill and feature catalogs and creature skill tabs share a saved two-column, three-column, or detailed layout; two columns are the default. Settings and accessible symbol menus update the same independent JSON preference through the existing personal repository. Accessibility text sizes select the full-width detailed renderer without changing the saved density.

Compact cards retain contained artwork, a top-aligned name, classification/type icons, raw or numeric energy/power, and learning levels only when recorded. Feature cards receive no invented combat values. Complete descriptions remain reachable by tapping a card or choosing detailed mode. Creature-origin skill details place the exact acquisition record near the top using the existing source-kind, level, stage, bloodline, and requirement renderer.

Local regression passed: 25 Swift tests, 109 Python tests, four final native packaging/localization tests, and the complete 11-case UI suite. After the final title-only rearrangement, two focused layout/capture cases and generic/destination simulator builds passed. Eight final Chinese captures were visually reviewed. Installation without uninstalling onto the original Roco Swift Migration simulator passed; its executable matches the build, and every personal table digest/count and schema version remains unchanged with valid integrity and references. Logs, captures, and verification limits are recorded in [compact skill evidence](../evidence/phase-9-compact-skills-2026-10-15.md). All 24 changed paths match the declared allowlist and `git diff --check` passed. The next allowed boundary remains physical iOS/accessibility and signed-upgrade validation, with scoped repository delivery through GitHub Desktop.

## Centered skill card clarification, 2026-10-15

The user clarified that both the skill name and type/power pill belong to the right of the illustration, with the two modules vertically centered. This supersedes the preceding full-width title arrangement. The existing `CompactSkillCard` now uses a centered horizontal stack, larger 60/40-point artwork for two/three columns, a naturally sized right-hand name/metric stack, and separately reserved lower-right learning levels. Long names can wrap within the right-hand module. The existing detailed renderer, accessible summaries, energy badge, classification symbol, source conditions, settings, and routes are reused.

The [ADR-0026 clarification](../decisions/ADR-0026-neutral-hero-and-compact-skills.md#centered-card-clarification-2026-10-15) limits changes to `ios/App/Components.swift`, the root README, the feature document, that decision, this report, and new centered-card evidence/four captures. No data, schema, repository/model, dependency, network, or release contract changes. Two existing focused UI cases and generic/destination builds passed; four final Chinese captures were visually reviewed. Installation without uninstalling onto the original simulator passed, with matching executable/debug-library hashes and unchanged logical personal records/schema. Integrity and references remain valid. The full ten-path diff and `git diff --check` passed. Commands, logs, installation review limits, and the checks intentionally not rerun are recorded in [centered skill evidence](../evidence/phase-9-centered-skills-2026-10-15.md). Physical iOS/accessibility and signed-upgrade acceptance remain the next boundary; GitHub Desktop remains the commit/push route.

## Centered detail identity and illustrated skill users, 2026-10-15

The user requested centered creature names/types, removal of scrolled content showing through the native navigation title area, and illustrated creature links in skill details. [ADR-0027](../decisions/ADR-0027-centered-detail-and-visual-skill-users.md) declares this Phase 9 boundary. Allowed changes are `ios/App/DetailViews.swift`, both native localization resources, `ios/UITests/RocoHandbookUITests.swift`, the root README, the feature document, that decision, this report, and new detail-polish evidence/five captures. No repository/model/query, setting, source, asset, Catalog/schema, dependency, runtime network, or release contract changes.

The expanded and compact identity module centers its name, form subtitle, and type row. A clipped content viewport and adaptive opaque top surface isolate scrolled panels from the native navigation material while retaining system controls, the constant scroll inset, artwork/shiny state, and tabs. Skill-result changes restore the browsing start, and filters dismiss the search keyboard. Skill details reuse compact `PetCard` illustrations, names, numbers, forms, and type icons for both feature ownership and learning sources, with localized section headings, the existing acquisition renderer, and concrete-pet routes. Lazy rendering preserves distinct source records through their existing ordinal-aware identity.

Two new and four retained UI cases passed after the search/filter regression was corrected; coverage includes centered identity, concrete-form card navigation, scroll restoration/shiny selection, reachable search/filter results, tabs/egg groups, skill density/source conditions, and personal records across recovery. Four native packaging/localization tests and generic/destination simulator builds passed using a byte-matching local build mirror after cloud-cache delays. Five final Chinese captures were visually reviewed. Installation without uninstalling onto the original simulator passed with matching executable/debug-library hashes and unchanged personal table digests/counts/schema, valid integrity, and no foreign-key violations. The complete 14-path diff and `git diff --check` passed. Logs, source-equivalence receipts, cache-recovery and early failure details, captures, and unrun layers are recorded in [detail-polish evidence](../evidence/phase-9-detail-polish-2026-10-15.md). Physical iOS/accessibility and signed-upgrade acceptance remain the next boundary, with scoped repository delivery through GitHub Desktop.
