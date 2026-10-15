# Native Catalog and creature detail layout evidence

- Date: 2026-10-15
- Phase: 9 follow-up
- Decision: [ADR-0024](../decisions/ADR-0024-native-catalog-and-detail-layout.md)

## Scope and data path

The four requested UI changes are confined to native presentation, the persisted layout enum/default, and read-only mapping of existing egg metadata. The clean starting checkout was `main`. The user-supplied screenshots are visual references; their creature values and rules are not imported.

The frozen NRC snapshot is already normalized by `tools/catalog_builder/nrc_normalizer.py`, which preserves `egg_group` and optional `egg_size` in `pets.extra_json`. The immutable Catalog remains data version 2. `CatalogRepository.petDetail` now decodes those fields into `PetDetail.eggGroups` and optional `EggSize`; the UI receives typed records. All 621 active concrete forms have array-valued groups, 574 contain egg size metadata in `g`, and 47 lack that metadata. No egg height is inferred. No schema, source revision, identity, asset, or Catalog artifact changed.

The `threeColumn`, existing `grid`, and existing `list` choices use the same `user.db.settings` key. Missing/malformed/unsupported settings select three columns; explicitly saved earlier choices remain valid. No personal data is cleared to apply a default.

## Environment and commands

Xcode 27.0 (`27A266a`), iOS 27.0 simulator runtime. A new invocation-owned iPhone 18 Pro simulator, `Roco Catalog Layout 2026-10-15` (`CC001E44-E80A-41FC-BB23-EC55BA1CFB97`), isolates UI test data from existing simulators and personal records.

Full logs are written to `/tmp/roco-layout-swift.log`, `/tmp/roco-layout-python.log`, `/tmp/roco-layout-build-final.log`, `/tmp/roco-layout-ui-focused.log`, `/tmp/roco-layout-ui-final.log`, and `/tmp/roco-layout-ui-reviewed.log`. Build products remain outside the checkout. UI builds reuse `/tmp/roco-handbook-layout-build`. The complete suite is recorded in `/tmp/roco-layout-ui-final.xcresult`; final presentation captures are in `/tmp/roco-layout-ui-reviewed.xcresult`.

| Check | Result |
| --- | --- |
| `swift test --package-path ios --scratch-path /tmp/roco-handbook-spm` | Passed: 24 tests, zero failures |
| `PYTHONDONTWRITEBYTECODE=1 PYTHONPATH=tools python3 -m unittest discover -s tests -p 'test_*.py'` | Passed: 109 tests, zero failures |
| Final focused `test_native_ios.py` regression | Passed after the final visual refinements: 4 packaging/localization/configuration tests, zero failures |
| `xcodebuild -project ios/RocoHandbook.xcodeproj -scheme RocoHandbook -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/roco-handbook-layout-build CODE_SIGNING_ALLOWED=NO build` | Passed again after the final visual refinements |
| Native simulator UI suite | Passed: 7 tests, zero failures; `/tmp/roco-layout-ui-final.xcresult` |
| Focused Catalog UI regression | Passed: one test, zero failures; actual toolbar/card frames, sort/filter actions, two/three-column switch, restart persistence |
| Chinese simulator capture review | Passed: focused capture test, zero failures; five original 1206 × 2622 PNGs inspected |
| Scoped diff and `git diff --check` | Passed; only the declared paths changed; shared fact/acquisition helpers and skill detail code retained exactly |
| GitHub Desktop commit and push | Required after this reviewed local acceptance; observed delivery outcome is recorded in the final handoff |

The core regression tests exercise all layout values, independent reopen/persistence, invalid JSON types/unsupported values, and exact source-backed egg values across every active concrete form. Existing tests retain source conditions, feature ownership, frozen type rules, Catalog recovery, and personal-data isolation.

The first full UI run exposed an inherited hero accessibility identifier hiding child search/control identifiers. That run was interrupted, the unnecessary parent identifier was removed, and the focused Catalog test passed. Dense cards also reserve a scaled name area and use top-aligned grid items so non-default form subtitles do not displace the first row. Initial offline resource copying was slow; source files, networking settings, and immutable assets were not changed to bypass it.

The complete UI suite passed after that correction. It covers all four destinations and seven Tools, detail tabs, native/bloodline separation, skill search and clearing, outgoing/incoming selection, egg-group navigation, Evolution and Source sheets, favorites/notes through Catalog restore, layout persistence, and source-backed shiny switching. Subsequent visual-only refinements darken the warm hero and number badge, outline skill cards, and extend the white background on short detail pages. A focused Chinese capture run and a final generic build passed after those refinements. Captures explicitly select three-column mode; default selection and preservation of saved choices are tested independently.

## Reviewed native captures

These are original XCTest attachments copied byte-for-byte from the final capture result. They use actual bundled records and assets, including concrete form `pet_000558` for the reference-style detail examples. The stored Undiscovered egg group is displayed as group 1; the reference screenshot's empty state does not replace that recorded value.

| Capture | Reviewed result |
| --- | --- |
| [Catalog](phase-9-native-layout/catalog-zh.png) | Blue hero background reaches the status bar, safe title placement, one-row controls, and three contained illustrations per row |
| [Overview](phase-9-native-layout/detail-overview-zh.png) | Warm hero, recorded form/type, rounded tab strip, six distinct stat bars, exact total, and independent feature card |
| [Skills](phase-9-native-layout/detail-skills-zh.png) | Source selectors, local search/filter controls, outlined icon cards, recorded metrics, and retained acquisition conditions |
| [Type relationships](phase-9-native-layout/detail-types-zh.png) | Explicit direction, grouped multiplier cards, type badges, and frozen dual-type cap explanation |
| [Egg groups](phase-9-native-layout/detail-eggs-zh.png) | Recorded group, same-group navigation, and a full white short-content surface |

## Unrun layers

Physical devices, iOS 15 runtime rendering, VoiceOver, largest accessibility sizes, signed migration from the historical client, low-storage/crash durability, live BWIKI import, remote signed updates, hosted CI for this revision, distribution signing, store upload, review, and publication are not established by these local checks. The retained Flutter client and Android are outside this UI task.
