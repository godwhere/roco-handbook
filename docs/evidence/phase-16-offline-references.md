# Phase 16 offline references and checklist evidence

- Date: 2026-10-26, Asia/Shanghai
- Baseline: `eee2a25`
- Source snapshot: `references-3ad202f604caf1d1`
- Native validation: iPhone 17 Pro simulator, iOS 27, unsigned local build

## Source, identity and artifacts

The [complete snapshot](../../data/raw/references-3ad202f604caf1d1/sources.lock.json) freezes 46 live NRC sources and the two accepted V3 Handbooks/Index sources. Canonical title/page/revision/model and content hashes were validated, and live heads matched before/after acquisition. This is stability during that import, not a claim of an atomic upstream release. Exact response/content files are tracked for offline reproduction through the single documented raw-storage exception.

| Catalog | Preserved content | Normal browsing |
| --- | --- | --- |
| Items | 1,534 records, 1,835 detail variants, ten source groups | Includes common items, fruit, eggs, stones and recipes |
| Research | 468 handbooks, 2,351 unique progress IDs, 4,976 rewards | Recipes retained, shared form progress |
| Medals | 60 records with evidence status, targets, tiers and scope | 56 source-reviewed public records |
| Trial encounters | 726 explicit IDs, six chapter/normal-boss groups | Exact source shared floor context, manual marks |
| Habitats | 109 areas, eight groups, 1,545 creature-condition rows | Area/layer reference and source uncertainty |

The map decoder validates nineteen complete data parts: 7,519 mainland points/details and twenty academy points/details. Only the habitat projection is bundled; full geometry remains in [raw-sidecar.json](../../data/normalized/references-v1/raw-sidecar.json). No map-base/tile media was acquired. Exact title/ID/filename/name/form/description mappings produce 8,638 native links, all closed against accepted Catalog/item identities. Unmapped or ambiguous references remain canonical noninteractive text and explicit review results. `_Map` suffixes are never stripped to guess IDs. See [identity and counts](../../data/reports/references-v1/identity-and-counts.json).

The [media manifest](../../app/assets/wiki/references/v1/asset-manifest.json) contains 1,589 available icons from 1,590 declared references, totaling 33,091,988 bytes. `File:Item_20000027.png` is explicitly missing for `item_a73c5a669658`; no substitute creature/image is generated. Existing V4 artwork remains byte-identical. All 2,163 distinct presentation image paths resolve in the staged bundle. [Original-media proof](../../data/reports/references-v1/original-media-validation.json) checks upstream SHA-1 and byte length for all 1,159 original-file records; thumbnail local hashes/dimensions are separate. Owned negative tests reject wrong valid PNG downloads and poisoned original caches. Attribution is included in the new supplement and Settings' existing source route.

## Commands and results

Validation uses `/tmp/roco-phase16-validation`, a fresh `git archive HEAD` mirror with copied, byte-verified changed inputs and source/artifact files. The final [native/resource receipt](phase-16/native-inputs.json) records 1,608 source/resource hashes. No personal database, cookie, credential, proxy state or fake release artifact is included.

| Check | Result | Local evidence |
| --- | --- | --- |
| Complete source freeze/head/hash closure | Passed, 48 sources | `/tmp/roco-phase16-source-import.log`, source lock |
| Owned reference source regressions | 11 passed | `/tmp/roco-phase16-reference-tests.log` |
| Owned media regressions | Five passed | `/tmp/roco-phase16-media-final-tests.log` |
| Full default offline Python suite | 147 passed | `/tmp/roco-phase16-offline-final.log` |
| Final Swift package suite | 40 passed | `/tmp/roco-phase16-swift-settled.log` |
| Native packaging/localization/generator checks | Four passed; also covered by default suite | `/tmp/roco-phase16-packaging.log` |
| Final generic simulator build | Passed, `CODE_SIGNING_ALLOWED=NO` | `/tmp/roco-phase16-final-build.log` |
| Initial selected native run | One pass, three failed cases/seven assertions | `/tmp/roco-phase16-ui.log`, `/tmp/roco-phase16-native.xcresult` |
| Final selected native run | Four cases passed | `/tmp/roco-phase16-final-ui.log`, `/tmp/roco-phase16-final-native.xcresult` |
| Immutable offline CLI replay | Passed, complete unchanged version | `/tmp/roco-phase16-doc-replay.log` |
| Actual original-file SHA-1/size | 1,159 checked in scratch and App output | `/tmp/roco-phase16-original-media-proof.log` |
| English-prose, source/resource equivalence and scoped whitespace | Passed | `/tmp/roco-phase16-prose.log`, receipts and `git diff --check` |
| Independent source/native post-fix review | Passed, no remaining actionable finding | Final code, reports and captures |

The default command is `PYTHONDONTWRITEBYTECODE=1 PYTHONPATH=tools python3 -m unittest discover -s tests -p 'test_*.py'`. The final Core command is `swift test --package-path ios --scratch-path /tmp/roco-phase16-spm`. The replay command is documented and executed from the [reference feature contract](../features/offline-references.md).

Native commands use `ios/RocoHandbook.xcodeproj`, scheme `RocoHandbook`, derived data `/tmp/roco-phase16-xcode`, and either `generic/platform=iOS Simulator` for build or `platform=iOS Simulator,id=53209D2A-B509-4FC9-B464-7DB15A446055` for UI. UI flags include `-parallel-testing-enabled NO`, `-collect-test-diagnostics never`, a unique result bundle, and these four selectors:

- `testAllDestinationsAndThirteenToolRoutes`
- `testChineseReferenceVariantsLinksMedalVisibilityAndHabitatNotes`
- `testResearchAndTrialProgressSurviveRestartAndRestoreWithPersonalData`
- `testChineseReferenceControlsRemainReachableWithAccessibilityText`

## Repairs and evidence limits

Original-checkout full-suite attempts blocked on historical Cloud File Provider V3 image reads after 45 completed tests. Only their invocation-owned processes were stopped. The full 147-test run then passed in the local archive mirror; no historical image, system setting or network configuration was changed, and no test was excluded.

The initial native hierarchy showed a real identifier propagation problem: a TextField retained its correct placeholder but inherited `reference.items.catalog`, overriding its own leaf identifier. Removing three outer container identifiers preserved all leaf identifiers and unchanged assertions. The final run verified actual controls and interactions. Progress readers now check cancellation and captured user revision before publishing success/errors; detail refresh also avoids overwriting an active save. The save/restart/recovery flow passed, while deterministic scheduling stress and physical accessibility remain separate acceptance layers.

Source review preserved the exact shared floor header in trial details, replaced serialized medal tiers with prepared conditions, and ensured structured target 1 is not suppressed by text containing 10. Media review added original-file SHA-1/size checks for downloads, cache and reused output; current original bytes all match. These are recorded repairs, not claims that initial candidates had zero issues.

## Final native captures

- Normal: [item variants](phase-16/reference-item-variants-zh.png), [medal](phase-16/reference-medal-zh.png), [habitat area](phase-16/reference-habitat-zh.png), [frozen sources](phase-16/reference-source-zh.png).
- Maximum accessibility text: [item list](phase-16/reference-items-large-text-zh.png), [item detail](phase-16/reference-item-detail-large-text-zh.png), [research completion](phase-16/reference-research-large-text-zh.png), [habitat notice](phase-16/reference-habitats-large-text-zh.png), [source controls](phase-16/reference-source-large-text-zh.png).

All nine captures were inspected with no remaining actionable clipping or overlap. They show real native UI and original game media, not a generated mockup. Automated 44-point and non-overlap checks complement the screenshots.

Physical iOS/iOS 15, spoken VoiceOver, signed upgrades, live signed Catalog update behavior, store signing/upload/review/publication, exact-spawn validation and full interactive map delivery remain unrun. Signed Catalog updates still replace only Catalog; auxiliary references ship with App builds. Personal favorites, notes, collection marks, layouts and language are retained; the new checklists are independently persisted without schema changes. The next boundary is separately scoped device/accessibility acceptance or better source-reviewed mappings/map presentation.
