# Phase 13 native Wiki-style Tools and Settings

- Date: 2026-10-25, Asia/Shanghai
- Status: native implementation and local validation complete; scoped GitHub Desktop delivery
- Baseline: `145ef4a`; effective native UI remains Phase 11 before this change

## Authorization and boundary

The user approved the freshly inspected Wiki direction: cool mist-blue/lavender surfaces, asymmetric image entrances, real game artwork, compact rounded display titles, gentle boundaries, and restrained gold accents on ivory Settings content. The earlier generated castle/metal-frame studies are not implementation targets. This phase implements the approved direction directly in the existing native SwiftUI App, rather than creating a replacement web runtime. Existing Apple UI/image capabilities and frozen resources take precedence over generic prototype-template instructions.

Allowed paths: `ios/App/Components.swift`, the Tools home and its private label helpers in `ios/App/ToolsViews.swift`, the Settings home and private panel helper in `ios/App/SettingsViews.swift`, focused `ios/UITests/RocoHandbookUITests.swift` assertions/captures, focused native packaging assertions if needed, root `README.md`, affected localized/browser feature documents, a new ADR-0032, this report, root `design-qa.md`, and Phase 13 evidence/screenshots. Existing localization resources may be updated only for necessary visible UI copy.

Non-goals: Tool child screens, creature/skill/detail UI, source imports, game records, immutable art/font files, Catalog/schema/IDs, personal-data semantics, repository/model contracts, update/check/install/cancellation logic, runtime networking, dependencies, signing, server settings, and publication. No generated or repainted creature enters the App.

## Acceptance and stopping conditions

Reuse the existing seven routes/identifiers and saved layout bindings. Preserve every Settings action, recovery confirmation, personal-data note, progress/cancel/error state, version, and source/license route. Keep ordinary targets at least 44 points, natural wrapping, accessibility-text fallback, explicit light/dark values, and decorative art hidden from VoiceOver. Verify source artwork against frozen manifests.

Run focused native packaging/localization/English-prose checks, a generic simulator build, and the existing four focused Tools/Settings UI cases. Capture and visually review Chinese normal light/dark and maximum-accessibility text states. Compare the new native captures with the approved Wiki source images in combined comparison evidence, recording native-platform/content adaptations rather than claiming a pixel-identical website clone. Complete `design-qa.md`, `git diff --check`, a full scoped review, and GitHub Desktop commit/push. Local validation uses an invocation-owned `/tmp/roco-phase13-validation` archive with byte-matching edited inputs to avoid cloud-backed historical file reads. Stop after verified native delivery; physical-device/iOS 15/VoiceOver/live-update/store acceptance remains separate.

## Changes and artifacts

- `Components.swift`: scoped Wiki palette with explicit light/dark variants, a faint existing starlight watermark, and optional template rendering whose default preserves all other image consumers. The obsolete notebook-header helper/palette is removed; the rest of the App theme is unchanged.
- Tools home: navy tall Season archive tile beside lavender Feature and pale-blue Egg groups; four compact original-image rows; short 16-point display titles; 9-point corners; image-free growing rows at accessibility sizes. All seven routes/IDs and every child Tool view are preserved.
- Settings home: charcoal Appearance heading with frozen skill icons, ivory content, native saved layout controls, compact Catalog/personal-library grouping and About. Action icons now reserve a body-scaled column at large text sizes. Check/install/cancel/restore logic, alerts, notices, version, and license/information screens remain unchanged.
- UI tests: asymmetric geometry, no overlapping cards, both pickers, all existing action targets, and lower-page captures. A 0.001-point tolerance handles UIKit/SwiftUI frame rounding while preserving the 44-point threshold.
- Root README, localized/browser feature docs, and ADR-0032 describe the effective native appearance. `design-qa.md` records comparison history and `final result: passed`.
- `docs/evidence/phase-13/`: approved Wiki captures/observations, eight frozen-art identity/hash records, source-equivalence receipt, final light/dark/accessibility captures, the retained pre-repair accessibility evidence, combined comparisons, and `native-preview.png`.

## Verification results

- Passed: four native packaging/localization/project/staging tests and the English-prose check.
- Passed: final generic simulator build, `CODE_SIGNING_ALLOWED=NO`.
- Passed: all seven routes; saved layout, favorite, and note preservation through restore/restart; final normal Chinese geometry/captures; final maximum-text reachability/cancellation; final actual-dark normal captures. These are four distinct focused UI cases across the recorded runs, not a claim that the initial selection had zero failures.
- Passed: eight existing art files match frozen hashes/lengths, current App/test source inputs match the validation mirror, Tool child views and update/install/information/license implementations are byte-identical to baseline, complete scoped review, and `git diff --check`.
- Passed: combined source/native visual comparison and independent post-repair accessibility review, with no remaining actionable P0/P1/P2 finding.

The first capture run failed only on a floating-point 44-point measurement boundary. The corrected numerical assertion passed. Independent visual review then found a real maximum-text icon/label crowding issue; the icon column was scaled, and final light/accessibility/dark captures passed. Xcode's per-failure diagnostic collector stalled after the initial completed tests; only its invocation-owned collector was stopped. Its test result and screenshots remain available, and subsequent runs disable verbose per-failure diagnostics for that invocation.

Commands, log/result paths, image links, state/density normalization, and remaining evidence limits are recorded in [Phase 13 evidence](../evidence/phase-13-native-wiki-tools-settings-2026-10-25.md). No source, Catalog, SQL, personal-store, immutable-art, dependency, network, signing, or release setting changed. The full unrelated UI/data/Swift package suites were not repeated for this scoped presentation change. Physical iOS/iOS 15, VoiceOver/device accessibility, signed-upgrade durability, live signed updates, and store acceptance remain unrun. The next boundary is those separately scoped device/release checks or further user visual iteration.
