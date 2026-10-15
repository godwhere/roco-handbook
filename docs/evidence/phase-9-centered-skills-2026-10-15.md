# Phase 9 centered skill card evidence

## Boundary and implementation

The user clarified the supplied card reference: the illustration belongs on the left, with the name above the type/power pill on the right; those two modules align at their vertical centers. [ADR-0026](../decisions/ADR-0026-neutral-hero-and-compact-skills.md#centered-card-clarification-2026-10-15) declares the follow-up allowlist, exclusions, acceptance commands, and stopping conditions. The starting revision was clean, synchronized `main` at `57e34273ac7fb87e539dcbc7e552bda84ed3fb9a`.

Only `CompactSkillCard` in `ios/App/Components.swift` changes application rendering. Its centered horizontal stack holds a 60-point illustration for two columns or a 40-point illustration for three columns, each 25% larger than before. The right-hand stack contains the name and type/power pill. It uses its natural height so the complete stack centers against the image. The classification symbol and recorded learning level occupy separate upper/lower-right corners, with lower space reserved for the level. Energy remains on the illustration. Existing accessible summaries, routes, metrics, settings, detailed cards, and acquisition rendering are reused unchanged.

The README, feature document, ADR, and Phase 9 report describe the clarified presentation. No repository/model/settings, Catalog/schema, source, immutable asset, dependency, network, or release contract changed. No new implementation-mirroring test is added for this reversible layout adjustment; existing skill-layout and Chinese-capture UI regressions exercise its actual navigation and density choices.

## Verification

Xcode 27.0 (`27A266a`), iPhone 18 Pro simulator, iOS 27.0. Tests reuse the task-owned `Roco Catalog Layout 2026-10-15` (`CC001E44-E80A-41FC-BB23-EC55BA1CFB97`). Full logs and artifacts remain under `/tmp`.

| Check | Result |
| --- | --- |
| Existing skill-layout and Chinese-capture UI tests | Passed: two tests, zero failures; `/tmp/roco-centered-skills.xcresult`, `/tmp/roco-centered-skills-ui.log` |
| Generic simulator build | Passed; `/tmp/roco-centered-skills-build.log` |
| Original simulator build/install and personal-record comparison | Passed; `/tmp/roco-centered-skills-install-build.log`; installed executable/debug-library hashes match the build |
| Full scoped diff and `git diff --check` | Passed; exactly ten allowlisted paths |

The focused behavior case covers actual two/three-column geometry, shared setting persistence, detailed descriptions, exact creature learning conditions, and feature cards without invented combat metrics. Core/pipeline tests and the complete UI suite are not rerun for this view-only change; their earlier results remain historical evidence rather than new acceptance claims.

## Captures and installation

Four original 1206 × 2622 Chinese captures from the passing run were visually reviewed and retained under `phase-9-centered-skills/`. Both densities put the larger image to the left of the centered name/metric stack. Long names wrap within the right module, and recorded level badges remain separate. Previous capture directories remain untouched. The user-supplied reference stays outside Git.

- [Skill catalog: two columns](phase-9-centered-skills/skills-two-columns-zh.png) and [three columns](phase-9-centered-skills/skills-three-columns-zh.png)
- [Creature skills: two columns](phase-9-centered-skills/creature-skills-two-columns-zh.png) and [three columns](phase-9-centered-skills/creature-skills-three-columns-zh.png)

The destination-specific build passed and was installed onto the original `Roco Swift Migration` simulator (`59C3C5B8-DC7B-418A-84D7-8C0B165A5B8A`) without uninstalling, then launched in Chinese. SHA-256 checks of both `RocoHandbook` and `RocoHandbook.debug.dylib` match the final build. The startup capture is `/tmp/roco-centered-installed-original.png`. The shared device window changed to another device during review, so no further manual navigation was performed there; the retained layout captures come from the focused UI run, and installed-code identity is established separately.

Before/after logical personal-table digests/counts and the schema version match exactly. Counts remain one favorite, two notes, zero collection marks, one settings row, and one metadata row. Integrity is `ok`; foreign-key violations are absent. Audits and backups remain local under `/tmp`; no personal database, record content, reference input, credential, or build product enters Git. The complete ten-path diff was reviewed, including the four original captures, and `git diff --check` passed.

## Acceptance limits

Physical iPhone rendering, iOS 15 runtime behavior, exhaustive Dynamic Type, VoiceOver, Reduce Motion, signed upgrades, distribution signing, live updates, and store delivery are not tested. The next boundary remains physical iOS/accessibility and signed-upgrade validation. Repository delivery uses GitHub Desktop for the scoped English commit and push, followed by local synchronization verification.
