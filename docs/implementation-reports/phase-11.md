# Phase 11 implementation report

- Date: 2026-10-25
- Status: implementation and local acceptance complete; scoped GitHub Desktop delivery
- Decision: [ADR-0031](../decisions/ADR-0031-roco-tools-and-settings.md)
- Evidence: [Tools and Settings](../evidence/phase-11-roco-tools-settings-2026-10-25.md)

## Boundary and implementation

The user requested a Roco Kingdom visual treatment for Tools and Settings after the separately committed/pushed Phase 10 data update. This phase is limited to these two home pages, scoped shared visual helpers, their bilingual copy, focused UI coverage, and mapped documentation. The existing seven destinations, settings preferences, update/recovery behavior, and personal-data guarantees remain intact.

The user subsequently requested smaller text. The final standard-text design uses smaller 21-point page headings, 16-point Tool titles, 17-point Settings section titles, 72-point art, reduced panel padding, and 64-point Tool card minimums. Accessibility text remains independently scaled; its compact header omits decorative brand/subtitle/artwork so real actions appear earlier.

- `ios/App/Components.swift`: add a palette with explicit light/dark variants and an illustrated notebook header, used only by these two pages.
- `ios/App/ToolsViews.swift`: replace the plain home List with seven full-width paper cards, localized subtitles, forest/gold icon badges, existing starter art, and compact native navigation. All child tools, route constructors, order, and accessibility IDs remain unchanged.
- `ios/App/SettingsViews.swift`: present Appearance, My library, Catalog, and About in paper panels; make both layout labels visible; retain native segmented controls for standard text and native menu Pickers at accessibility sizes; retain every existing action and its state/confirmation logic. Download and cancellation have explicit 44-point targets after independent review of the new ScrollView layout.
- Both native `Localizable.strings` files: eleven matching new header/subtitle entries; domain labels retain the frozen translations.
- `ios/UITests/RocoHandbookUITests.swift`: before/after Chinese captures, dark and accessibility-text coverage, explicit scroll-to-visible checks, and retained route/personal-data regressions.
- Root README, localized/browser features, ADR-0031, this report, and Phase 11 evidence/captures: document the resulting appearance, accessibility presentation, and acceptance limits.

No new resource, data import, source revision, Catalog/Tool JSON, schema, repository/model, dependency, network request path, signing, or publishing change is included. Update/recovery feature contracts require no operational revision because their implementation and authorization boundary are unchanged.

## Verification

The before capture case passed and both baseline images were visually reviewed. The final compact design passed four native packaging/localization checks plus the English-prose check, the generic iOS simulator build, four light-mode UI cases, and the same Chinese capture case once in actual dark mode. All seven final light/dark/accessibility screenshots were visually inspected, including independent review of the three accessibility captures. Seven routes, layout persistence, favorites/notes through recovery, 44-point targets, accessible menu fallback, confirmation cancellation, and lower Settings actions passed. Source-equivalence checks use the existing local validation mirror to avoid the known cloud-backed historical-file reads. The complete scoped diff and `git diff --check` passed; no Catalog, personal data, source, or runtime network code changed.

## Next boundary

Delivery uses a scoped English commit and push through GitHub Desktop. The next implementation boundary requires separate physical iOS/iOS 15 runtime, VoiceOver/device accessibility, signed-upgrade, low-storage/crash-durability, live signed-update, or store acceptance evidence; this phase does not imply any of those checks.
