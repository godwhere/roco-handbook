# ADR-0027: Centered creature identity and illustrated skill users

- Status: Accepted
- Date: 2026-10-15
- Phase: 9

## Boundary

Implement the user's three detail-screen corrections: center the creature name and types within their identity module, prevent scrolled panels from showing through the navigation title area, and replace text-only skill-user links with illustrated creature cards. The baseline is clean, synchronized `main` at `3ab21d6620dba0fc7bb0a099859e0c7a14d20efb`.

Allowed paths are `ios/App/DetailViews.swift`, both native `Localizable.strings` resources, `ios/UITests/RocoHandbookUITests.swift`, the root README, `docs/features/localized-visual-handbook.md`, this decision, the Phase 9 report, and new detail-polish evidence/captures. Reuse the existing `PetSummary`, `SkillUser`, `PetCard`, acquisition renderer, asset resolver, and native navigation stack. No source import, immutable asset, Catalog record, schema, identity, repository/model, query, setting, dependency, runtime network, signing, or release change is authorized.

Stop if the fix requires destructive personal-data operations, discarded or merged source conditions, new dependencies, or changes outside the allowlist. Complete after appropriate focused/retained UI regressions, reviewed Chinese captures, simulator builds and installation, personal-record preservation, complete scoped diff review, and a GitHub Desktop commit/push.

## Decisions

- Center the creature name, form subtitle, and type row within the identity module in both expanded and compact states. Preserve the large-to-small artwork transition, original/shiny state, constant scroll inset, concrete-form identity, and pinned tabs.
- Clip the creature scroll presentation to its safe content viewport and extend its opaque adaptive surface behind the native navigation area. Keep system navigation controls and their material; do not replace the navigation bar or change global appearance.
- When visible skill-result identities change while browsing, restore the panel start beneath the compact header. Dismiss the skill-search keyboard before presenting filters so closing the sheet reveals the results. Preserve filter semantics and the saved skill density.
- Render each skill-user record with the existing compact `PetCard` and its exact acquisition conditions. Each card shows the stored illustration, name, handbook number, form subtitle, and type icons, and opens the concrete `pet.id`. Preserve feature ownership separately from learning sources and preserve the existing `pet.id:relationship:ordinal` identity for each record.
- Use lazy card rendering for long source lists. Full descriptions, learning levels, source stages, raw bloodline conditions, requirements, favorites, and sources remain reachable. Add stable accessibility identifiers for identity geometry and source-card navigation without changing visible copy.
- Localize the existing dynamic learning-source and feature-user headings in English and Simplified Chinese; preserve frozen creature/feature terminology.

## Acceptance

Add UI regression coverage for centered expanded/compact identity and concrete-form navigation from an illustrated skill-user record. Capture Chinese dual-type identity, scrolled dark skill cards below the navigation area, learning-source cards, and independent feature-user cards. Retain regressions for scroll restoration/shiny state, detail tabs/search/egg groups, skill-density/source conditions, and personal records across recovery.

```sh
xcodebuild -project ios/RocoHandbook.xcodeproj -scheme RocoHandbook -destination 'platform=iOS Simulator,id=SIMULATOR_ID' -derivedDataPath /tmp/roco-handbook-layout-build -parallel-testing-enabled NO -collect-test-diagnostics never test
xcodebuild -project ios/RocoHandbook.xcodeproj -scheme RocoHandbook -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/roco-handbook-layout-build CODE_SIGNING_ALLOWED=NO build
git diff --check
```

Use only the selected affected UI cases for this view-only follow-up; core/pipeline contracts are unchanged. Verify the final installed executable/debug library against the build and compare logical personal-table digests, counts, schema version, integrity, and references without including personal data in Git. Physical iPhone, iOS 15 runtime, exhaustive accessibility, signed-upgrade, and store acceptance remain separate layers.
