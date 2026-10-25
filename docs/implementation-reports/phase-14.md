# Phase 14 native interface language selection

- Date: 2026-10-25 through 2026-10-26, Asia/Shanghai
- Status: native implementation and local validation complete; scoped GitHub Desktop delivery
- Baseline: `237b17c`

## Authorization and boundary

The user requested a language-switching control in Settings. Implement Follow System, Simplified Chinese, and English using the existing bundled localizations. Persist the selected mode in the existing personal settings table, update App-owned interface strings immediately, retain the active Settings tab and operation state, and preserve the choice across restart and Catalog recovery. Canonical game names/descriptions and source identities remain unchanged. A separate read-only Wiki content review requested during this work may produce source-linked recommendations, but does not authorize new imports or feature implementation.

Allowed paths: new `ios/Sources/HandbookCore/InterfaceLanguage.swift`, language preference methods in `UserRepository.swift`, focused Core tests, `ios/App/Components.swift` translation entry, `AppModel.swift`, `RocoHandbookApp.swift`, the language control in `SettingsViews.swift`, both existing `Localizable.strings` resources, focused UI tests, README/localization/personal-library documentation, ADR-0033, this report, and Phase 14 evidence. Temporary validation archives/logs are invocation-owned.

Non-goals: schemas/migrations, Catalog/source data/IDs, immutable game images/fonts, system language or AppleLanguages mutation, method swizzling, new dependencies, update/install/recovery implementations, account/network authority, signing, or publication. Use explicit bundled-language lookup and native controls; no first-launch download or web runtime.

## Acceptance and stopping conditions

Verify mode defaults, invalid persisted JSON fallback, independent persistence without changing layouts/favorites/notes, actual English/Chinese bundle lookup, and missing-key English fallback in focused Swift tests. Verify immediate Settings/tab translation, staying on Settings, restart persistence under a different launch locale, Catalog-recovery persistence, return to Follow System, and maximum-text language-control reachability with iOS UI tests. Preserve the seven Tool routes and existing recovery notices/actions. Build the native target, run focused packaging/localization and English-prose checks, inspect language-menu captures, review all scoped changes and `git diff --check`, then commit/push through GitHub Desktop. Report physical-device/iOS 15/VoiceOver/release limits separately. Record read-only Wiki recommendations separately from implemented scope.

## Changes and artifacts

- Core: the three-mode `InterfaceLanguage` contract, explicit thread-safe bundled translation lookup, and independent JSON preference methods in the existing personal repository. No schema or migration changed.
- App: load and save the preference, update the SwiftUI locale and translation helper after storage succeeds, retain the selected Settings tab and operation state, and rebuild the other three navigation roots on language changes.
- Settings: a native menu at the start of Appearance, recognizable language names, an accessible current value, a 44-point minimum target, and stacking at accessibility sizes. Language and skill-layout controls refresh their identities with the language; all other Settings state remains intact.
- Tests: language matching and fallback, persistence and isolation from both layouts/favorites/collection marks/notes, actual bundled resources, unchanged system language, immediate interface/control labels, restart and recovery, and maximum-text reachability.
- README, localized-handbook and personal-library feature documents, and ADR-0033 describe the effective behavior. Phase 14 evidence records native results and a separate read-only Wiki content review. Recommended Wiki additions have not been imported or implemented.

## Validation status

The initial Swift package suite passed 28 tests; all four native packaging/localization tests and the generic simulator build passed. The final two matching interface-language tests passed with collection-mark isolation included. The first selected native run passed three cases (normal Chinese capture, language lifecycle, and maximum-text reachability). A separate seven-route case passed. These tests initially missed cached English skill-layout option labels after an immediate Chinese switch; screenshot inspection found that defect. The two affected controls now refresh with the language, and the strengthened lifecycle test asserts both translated skill options and the immediate menu contents.

The repaired language/accessibility pair passed. The English Detailed label was then shortened to fit the existing native segments; the final language lifecycle and skill-layout preservation cases both passed, and all four packaging tests passed again. Final captures and independent review found no actionable issue. English-prose, current-input equivalence, complete scoped review, and whitespace checks passed. Logs, final commands and retained before/after captures are recorded in [native evidence](../evidence/phase-14-native-interface-language.md); the separate [Wiki review](../evidence/phase-14-wiki-content-review.md) records six ranked proposals and an unverified Nature candidate.

No Catalog, SQL, immutable asset, dependency lock, credential, real personal database, proxy/network setting, or release artifact is included. Full unrelated Python/UI suites, physical iOS/iOS 15, VoiceOver, live signed updates, signed-upgrade durability and store acceptance remain unrun. The next boundary is separately authorized Wiki data/tool implementation or device/release validation.
