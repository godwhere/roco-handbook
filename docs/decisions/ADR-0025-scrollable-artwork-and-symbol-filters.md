# ADR-0025: Scroll-linked artwork and symbol-led filters

- Status: Accepted
- Date: 2026-10-15
- Phase: 9

## Boundary

Implement the requested large creature artwork that contracts while browsing, multi-column creature and skill filters, and symbol-led native presentation informed by the public BWIKI gallery. Allowed paths are `ios/App/{CatalogViews,Components,DetailViews}.swift`, both native `Localizable.strings` resources, `ios/UITests/RocoHandbookUITests.swift`, the root README, `docs/features/localized-visual-handbook.md`, this decision, the Phase 9 implementation report, and new Phase 9 evidence and captures.

Do not change source imports, immutable artwork, Catalog records, schemas, stable identities, repository query semantics, personal-data lifecycle, dependencies, runtime networking, signing, or publication. Public Wiki browsing is visual research only. Stop if implementation requires invented source semantics, a migration, new dependencies, or destructive personal-data operations. Complete after focused and retained regressions, visual review, a scoped diff, and a GitHub Desktop commit/push.

## Decisions

- Open creature details with contained large original artwork. A scroll-linked header reduces the same artwork to a compact identity header while content advances. Returning to the top restores the expanded presentation. Keep header and tabs reachable even on short tabs. Use a constant scroll-content inset so header resizing cannot feed back into the measured scroll offset.
- Keep the pinned header inside the native scroll view so a vertical drag beginning on artwork or a tab can browse content. Switching tabs while already browsing brings the new panel to its start below the compact header.
- Respect Reduce Motion by switching between the two endpoint presentations without interpolated scaling. Keep source-backed original/shiny switching, favorites, detail tabs, personal records, evolution, and attribution available.
- Present existing filter values as adaptive multi-column buttons. Reuse bundled type and skill-category icons; retain short names for recognition, accessible labels, and a visible selection checkmark. Accessibility text sizes use wider options. Preserve the existing multi-select query and reset semantics.
- Use native symbols for common actions and detail tabs. Preserve canonical names, acquisition requirements, metric labels, and explanatory content where symbols alone would lose meaning. Detail skill filters use the same visual selection language as the skill catalog.
- Take grouping, compact choices, and type-icon emphasis from the public BWIKI gallery. Do not import new game records, artwork, counts, or filter meanings from the live site.

## Acceptance

Run the existing offline Python and Swift suites, a native simulator build, retained UI regressions, and new UI checks for expanded/compact/restored artwork, retained shiny state, multi-option row geometry, selection/reset behavior, and actual filtered results. Capture Chinese creature and skill filters plus both artwork states. Review the complete phase diff and run `git diff --check`.

```sh
swift test --package-path ios --scratch-path /tmp/roco-handbook-spm
PYTHONDONTWRITEBYTECODE=1 PYTHONPATH=tools python3 -m unittest discover -s tests -p 'test_*.py'
xcodebuild -project ios/RocoHandbook.xcodeproj -scheme RocoHandbook -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/roco-handbook-layout-build CODE_SIGNING_ALLOWED=NO build
xcodebuild -project ios/RocoHandbook.xcodeproj -scheme RocoHandbook -destination 'platform=iOS Simulator,id=SIMULATOR_ID' -derivedDataPath /tmp/roco-handbook-layout-build -parallel-testing-enabled NO test
git diff --check
```

Physical hardware, iOS 15 rendering, VoiceOver, signed upgrades, store delivery, and live Catalog updates remain separate acceptance layers.
