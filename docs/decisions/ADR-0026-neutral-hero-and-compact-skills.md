# ADR-0026: Neutral artwork header and compact skill layouts

- Status: Accepted
- Date: 2026-10-15
- Phase: 9

## Boundary

Replace the red creature artwork background with the existing adaptive page surface and implement compact skill cards informed by the user-supplied reference. Allow two or three cards per row and retain the existing detailed descriptions as a selectable mode. Allowed paths are `ios/App/{AppModel,CatalogViews,Components,DetailViews,SettingsViews}.swift`, both native localization resources, `ios/Sources/HandbookCore/{Models,UserRepository}.swift`, focused Swift/UI tests, the root README, `docs/features/localized-visual-handbook.md`, this decision, the Phase 9 report, and new Phase 9 evidence/captures.

Source imports, immutable assets, Catalog records, SQL schemas, identities, query semantics, dependencies, runtime networking, release settings, and publication are excluded. Stop if this requires fabricated metrics or levels, destructive personal-data operations, schema changes, or an additional dependency. Complete after focused and retained regressions, visual review, simulator installation, scoped diff review, and a GitHub Desktop commit/push.

## Decisions

- Use the existing adaptive surface for the expanded and compact creature header, with primary text and a tonal number badge. Preserve scroll contraction, top restoration, shiny selection, navigation, and offline artwork paths.
- Add a shared skill layout preference with `twoColumn` (default), `threeColumn`, and `detailed`. Store it as a JSON string in the existing `settings` table under `skill_catalog_layout`; missing, malformed, and unknown values fall back to two columns. Do not alter the creature layout key or either SQL schema.
- Expose the skill layout in Settings and accessible symbol menus beside skill catalog/detail controls. Use it in skill and feature catalogs and creature skill tabs. Reading contexts, including individual skill details and glossary references, retain full descriptions. Accessibility text sizes use the full-width detailed presentation while retaining the user's saved preference.
- Compact cards use two vertically centered modules: enlarged contained artwork on the left and a name/type-power stack on the right. The energy badge belongs to the artwork; the classification symbol occupies the upper-right corner. Creature learning cards show a lower-right level badge only when `LearnableSkill.learnLevel` exists. Reserve space for that badge without changing the alignment between the two modules. Preserve raw textual metrics and unknown values; feature cards must not acquire invented power or energy values.
- Tapping a compact card opens the complete skill detail. Creature-origin routes additionally show their exact acquisition record near the top, preserving source kind, level, source stage, bloodline values, and requirements. Detailed mode retains the previous description and acquisition rows.

## Acceptance

Verify preference defaults, corruption fallback, persistence, and independence from creature layout; native two/three-column geometry, mode switching, full descriptions, creature learning context, search/filter retention, and retained artwork/shiny/personal flows. Review Chinese simulator captures for the neutral header and both card densities. Build and install without uninstalling; verify personal-data preservation. Run `git diff --check` and review the complete allowed diff.

```sh
swift test --package-path ios --scratch-path /tmp/roco-handbook-spm
PYTHONDONTWRITEBYTECODE=1 PYTHONPATH=tools python3 -m unittest discover -s tests -p 'test_*.py'
xcodebuild -project ios/RocoHandbook.xcodeproj -scheme RocoHandbook -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/roco-handbook-layout-build CODE_SIGNING_ALLOWED=NO build
xcodebuild -project ios/RocoHandbook.xcodeproj -scheme RocoHandbook -destination 'platform=iOS Simulator,id=SIMULATOR_ID' -derivedDataPath /tmp/roco-handbook-layout-build -parallel-testing-enabled NO -collect-test-diagnostics never test
git diff --check
```

Physical hardware, iOS 15 runtime behavior, exhaustive accessibility, signed upgrades, and store delivery remain separate acceptance layers.

## Centered card clarification, 2026-10-15

The latest user reference supersedes the preceding full-width title row: both the name and type/power pill belong to the right of the illustration, with the illustration and text stack vertically centered against each other. Increase artwork from 48 to 60 points in two-column cards and from 32 to 40 points in three-column cards.

This follow-up is limited to `ios/App/Components.swift`, the root README, this decision, `docs/features/localized-visual-handbook.md`, the Phase 9 report, and new centered-card evidence with four captures. Repository/model/settings contracts, queries, detail routes, full descriptions, source conditions, assets, imports, Catalog records, schemas, identities, dependencies, networking, and release operations are excluded. Reuse the two existing focused skill-layout/Chinese-capture UI tests, then perform generic/destination builds, visual review, installation without uninstalling, personal-record comparison, `git diff --check`, scoped diff review, and GitHub Desktop commit/push. Stop if the requested presentation requires changes outside this allowlist or data loss; complete after the rendered two/three-column cards and installed App agree with the clarified reference.
