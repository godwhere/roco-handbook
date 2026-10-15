# ADR-0024: Native Catalog density and tabbed creature details

- Status: Accepted
- Date: 2026-10-15
- Phase: 9

## Boundary

Implement the requested native iOS presentation changes: extend the Catalog hero behind the status bar, place sort/filter/search in one row, add a default three-column layout, and use the supplied screenshots as the visual reference for creature details. Allowed paths are `ios/App/`, the affected domain DTO and repository files in `ios/Sources/HandbookCore/`, focused native tests in `ios/Tests/` and `ios/UITests/`, the root README, `docs/features/localized-visual-handbook.md`, this decision, the Phase 9 report, and new Phase 9 evidence/captures.

Source import, immutable assets, schemas, stable IDs, Catalog generation, network behavior, dependencies, signing, and release publication are excluded. Stop if the UI requires fabricated data, a schema migration, an unapproved dependency, or loss of personal data. Complete with a reviewed scoped diff and GitHub Desktop commit/push.

Acceptance commands, run from the repository root:

```sh
swift test --package-path ios --scratch-path /tmp/roco-handbook-spm
PYTHONDONTWRITEBYTECODE=1 PYTHONPATH=tools python3 -m unittest discover -s tests -p 'test_*.py'
xcodebuild -project ios/RocoHandbook.xcodeproj -scheme RocoHandbook -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/roco-handbook-layout-build CODE_SIGNING_ALLOWED=NO build
xcodebuild -project ios/RocoHandbook.xcodeproj -scheme RocoHandbook -destination 'platform=iOS Simulator,id=SIMULATOR_ID' -derivedDataPath /tmp/roco-handbook-layout-build -parallel-testing-enabled NO test
git diff --check
```

## Decisions

- The root hero background covers the upper safe area; title and controls remain clear of system status content. Sort and filter use labeled accessible icon buttons beside the search field.
- Add `threeColumn` to `PetCatalogLayout`. Missing, malformed, and unsupported preferences now fall back to that value. Existing `grid` and `list` values retain their meaning. Persist all choices in the existing `pet_catalog_layout` setting. This supersedes ADR-0021's default without changing either schema.
- Three-column cards size illustrations to available width. Accessibility text retains the single-column fallback. Settings exposes three columns, two columns, and list mode.
- Creature details use a warm illustration hero, rounded content surface, and Overview, Skills, Type relationships, and Egg groups tabs. Overview contains colored stat bars, independent feature information, recorded egg measurements, and basic facts. Skills retain separate source groups, search, filters, and all acquisition conditions. Type relationships separate outgoing and incoming directions; retain the existing frozen damage rules.
- Evolution, personal records, and source references remain reachable from the detail toolbar. Original/shiny switching and favorites remain available.
- Map existing `extra_json.egg_group` and optional `extra_json.egg_size` into typed detail DTOs in the Catalog repository. Preserve raw units, missing fields, and thresholds. UI never reads raw JSON. Do not infer egg height, thresholds, or breeding rules from the reference screenshots. No database write or migration is required.

## Acceptance limits

Regression coverage must prove default/persisted layout compatibility, source-backed egg mapping, shared toolbar geometry, actual three-column card geometry, tab switching, skill search, both relationship directions, and retained personal/shiny flows. Review Chinese simulator captures against the references. Physical hardware, iOS 15 rendering, VoiceOver, signed upgrades, live updates, and store delivery remain separate acceptance layers.
