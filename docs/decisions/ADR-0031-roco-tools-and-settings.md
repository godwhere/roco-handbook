# ADR-0031: Roco-themed Tools and Settings

- Status: Accepted
- Date: 2026-10-25
- Phase: 11

## Context and authorization

After the Phase 10 content refresh, the user requested that Tools and Settings better fit Roco Kingdom. Their current native List/Form presentation preserves the features but does not share the illustrated handbook identity of the creature browser. Phase 10 was completed and delivered separately before this visual continuation.

## Decision and allowed paths

Use existing frozen Roco creature illustrations and the accepted display font with warm paper surfaces, forest-green accents, restrained gold outlines, illustrated page headers, and full-width readable cards. Keep native navigation and platform controls. Settings groups remain Appearance, My library, Catalog, and About; all seven Tools destinations retain their routes and accessibility identifiers. No official affiliation or new account behavior is implied by the artwork.

The user's density clarification reduces the standard-text hierarchy to 21-point header titles, 16-point Tool titles, 17-point Settings section titles, and platform subheadline/footnote explanatory text. Header illustrations are 72 points and Tool cards have a 64-point minimum rather than oversized presentation. These are Dynamic Type baselines, not fixed accessibility caps; maximum-text QA images must be identified separately from normal previews.

Allowed changes are `ios/App/Components.swift`, the Tools home inside `ios/App/ToolsViews.swift`, the Settings home inside `ios/App/SettingsViews.swift`, both native `Localizable.strings` files, focused native packaging/localization assertions if required, `ios/UITests/RocoHandbookUITests.swift`, the root README, the affected localized/browser feature documents, this decision, the Phase 11 report, and Phase 11 screenshot/evidence files. Supporting shared appearance helpers must serve these two pages and must not change the creature/skill/detail theme globally.

Source imports, Catalog/Tool records, immutable media, repositories, models, SQL, personal-data semantics, update/recovery implementation, dependencies, signing, release settings, server/network configuration, and unrelated screens are outside this phase. No new image acquisition or generated artwork is needed.

## Accessibility and behavior

Cards have whole-row tap targets of at least 44 points, natural wrapping, and text labels. Decorative art is hidden from VoiceOver. Use explicit dark-mode surface/accent variants, retain platform body fonts for explanatory text, and allow large Dynamic Type to increase card height or hide nonessential decoration. Standard text retains segmented layout controls; accessibility text uses native menu Pickers bound to the same saved preferences. Update cancellation/progress/error behavior, recovery confirmation, and personal-data protection remain unchanged. Download and cancellation actions also retain at least 44-point targets. Every action remains reachable by scrolling, including with accessibility text sizes.

## Acceptance and stopping conditions

Capture the current Tools/Settings before changing their presentation. Verify the resulting Chinese light/dark and accessibility-text layouts visually, all seven Tools routes, persisted layout selection, and the recovery confirmation/personal-data flow. Run focused localization/native packaging tests, a generic simulator build, and the corresponding XCUITest cases. No source/schema/network test expansion is necessary unless implementation unexpectedly crosses those boundaries; stop and narrow the change if it does.

Run `git diff --check`, review the complete scoped diff, and commit/push through GitHub Desktop. Physical-device rendering, iOS 15 execution, VoiceOver/device accessibility acceptance, signed upgrades, and store distribution remain separate evidence layers.
