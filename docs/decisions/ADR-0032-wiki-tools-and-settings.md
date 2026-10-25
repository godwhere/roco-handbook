# ADR-0032: Native Wiki-style Tools and Settings

- Status: Accepted
- Date: 2026-10-25
- Phase: 13
- Supersedes: the visual treatment in ADR-0031; its behavior and personal-data guarantees remain intact

## Context and authorization

The user approved the direction established by fresh inspection of the [NRC Wiki home](https://wiki.biligame.com/nrc/) and [skill codex](https://wiki.biligame.com/nrc/%E6%8A%80%E8%83%BD%E5%9B%BE%E9%89%B4). The observed home uses a cool mist-blue/lavender surface, faint background motifs, asymmetric image entrances, short left-aligned labels, rounded display typography, and soft boundaries. The skill codex combines a charcoal title area, flat ivory content, and small gold accents. Elaborate generated castle scenery and metallic picture frames are not the approved target. The earlier generated creature interpretations are also excluded.

## Decision

Adapt these source patterns directly to the existing native SwiftUI Tools and Settings homes. This is a native visual adaptation of the existing seven Tool destinations and Settings controls, not a pixel-identical website clone or a replacement web runtime. Native navigation, safe areas, platform controls, Dynamic Type, and the existing iOS 15 fallback remain authoritative. Generic prototype templates do not apply to this repository's active SwiftUI client.

Tools uses a tall navy Season archive image tile beside stacked lavender Feature handbook and pale-blue Egg groups tiles. Game descriptions, Activity timeline, Outfit inspiration, and Personal library use compact light rows with original image thumbnails. Use short functional labels, the frozen display font, modest corners, and tonal separation. Decorative images do not imply new records, season coverage, identity rules, or official affiliation.

Settings uses ivory surfaces with a compact charcoal Appearance header and existing skill imagery. Gold is limited to small accents, with subtle neutral dividers. Personal library and Catalog actions share a group, with About separate. The two layout controls retain their existing saved bindings. Update checking, candidate presentation, download/progress, verification, cancellation, errors, recovery confirmation, personal-data notices, App version, and source/license access remain available through their existing implementation.

Only existing frozen game images, UI icons, and fonts are used. No source acquisition, generated image, repainted creature, immutable-media change, dependency, or runtime image/font request is introduced. Scoped palette and background helpers serve these two homes without recoloring the creature, skill, or detail interfaces.

## Accessibility and platform behavior

Provide explicit light/dark colors and whole-card or whole-row targets of at least 44 points. Decorative art is hidden from VoiceOver. Accessibility text sizes replace the asymmetric group with vertical text-first rows that grow naturally, and retain the native menu Picker fallback for both saved layouts. Standard text retains native segmented controls. Every action remains reachable by scrolling; no decorative frame may intercept a control or conceal recovery/source information.

## Allowed scope

Changes are limited to the shared presentation helpers in `ios/App/Components.swift`, the Tools home and private label helpers in `ios/App/ToolsViews.swift`, the Settings home and private panel helper in `ios/App/SettingsViews.swift`, focused native UI/packaging assertions, necessary existing localization resources, the root README, affected feature documents, this decision, the Phase 13 report/evidence, and root `design-qa.md`.

Tool child views, game data, source revisions, Catalog/SQL/IDs, repositories/models, personal storage, update/recovery transport and lifecycle code, immutable assets, dependencies, signing, server settings, and publication are outside scope. If the presentation requires one of those changes, narrow the design rather than crossing the boundary.

## Acceptance and stopping conditions

Verify that representative art resolves to existing frozen resources and preserves its bytes. Run focused native packaging/localization/English-prose checks, a generic iOS simulator build, and the four existing focused UI cases: Chinese Tools/Settings captures, all seven Tool routes, personal-data/layout preservation through restore, and accessibility-text reachability. Add geometry assertions that distinguish the new asymmetric regular-text group from a vertical list. Capture and inspect normal Chinese light/dark and maximum-accessibility states.

Compare the native captures with the approved Wiki visual references in combined evidence. Record intentional platform and content adaptations, and require `design-qa.md` to have no unresolved actionable P0/P1/P2 findings before handoff. Review the complete scoped diff, run `git diff --check`, and deliver through a scoped English GitHub Desktop commit and push.

Physical-device rendering, iOS 15 execution, VoiceOver/device accessibility, signed-upgrade durability, live signed updates, and store acceptance remain distinct unrun layers unless separately evidenced. This decision states acceptance requirements, not test results; observed results belong in the [Phase 13 report](../implementation-reports/phase-13.md) and its evidence.
