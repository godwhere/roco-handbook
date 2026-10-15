# Phase 9 neutral artwork and compact skill evidence

## Scope and source of truth

[ADR-0026](../decisions/ADR-0026-neutral-hero-and-compact-skills.md) declares the Phase 9 allowlist, commands, stopping conditions, and acceptance boundary. Work started from clean, synchronized `main` at `78481f09fe156c2896adedecc8730d612420a786`.

The user requested a neutral creature illustration background, compact skill cards inspired by the supplied reference, two or three cards per row, and the existing detailed presentation as an option. The final title placement follows the user's correction: the skill name occupies its own top row instead of sitting beside the illustration. The supplied reference remains outside Git. Catalog version 2, immutable Wiki assets version 3, identities, schemas, source contracts, dependencies, and runtime networking remain unchanged.

## Implementation path

- `UserRepository` reads and writes the JSON string `skill_catalog_layout` through the existing personal settings table. `SkillCatalogLayout` defines two columns, three columns, and detailed descriptions. Missing, malformed, wrong-type, or unsupported values select two columns without a migration or startup write.
- `AppModel` loads the choice on session startup and publishes a change only after persistence succeeds. The preference is separate from the creature layout and shared by Settings, skill/feature catalogs, and creature skill tabs.
- `SkillGrid` selects two or three adaptive columns, or one detailed column. Accessibility text sizes use the existing detailed presentation without altering the stored choice. `CompactSkillCard` puts the name and classification glyph above the illustration and metrics. Type icons, energy, power, and recorded learning levels preserve DTO meanings; features receive no fabricated energy or power.
- Compact cards retain the existing skill-detail route and full descriptions. A creature-origin route also passes its exact `LearnableSkill` record to the existing acquisition renderer near the top of the destination. Detailed mode retains inline descriptions and acquisition rows.
- The creature artwork header uses the existing adaptive surface and primary text. Artwork contraction/restoration, shiny selection, pinned tabs, source access, and personal controls retain their existing behavior.

## Environment and checks

Xcode 27.0 (`27A266a`), iOS 27.0, iPhone 18 Pro. UI tests reuse the task-owned `Roco Catalog Layout 2026-10-15` simulator (`CC001E44-E80A-41FC-BB23-EC55BA1CFB97`). Full logs, result bundles, personal backups, and build products remain under `/tmp`.

| Check | Observed result |
| --- | --- |
| Swift core tests | Passed: 25 tests; `/tmp/roco-compact-swift.log` |
| Offline Python discovery | Passed: 109 tests; `/tmp/roco-compact-python.log` |
| Final native packaging/localization tests | Passed: four tests; `/tmp/roco-compact-native-final.log` |
| Complete iOS UI suite | Passed: 11 cases, zero failures; `/tmp/roco-compact-ui-final.xcresult` and `.log` |
| Final title placement and Chinese captures | Passed: two cases, zero failures; `/tmp/roco-compact-title-reviewed.xcresult` and `.log` |
| Final generic simulator build | Passed; `/tmp/roco-compact-build-final.log` |
| Original simulator destination build and installation | Passed; `/tmp/roco-compact-install-build.log`; installed executable matches the final build |

Core coverage verifies the default, all saved choices across repository reopen, invalid-value fallback, and independence from creature layout and favorites. UI coverage checks real two/three-column geometry, detailed descriptions, process restart, the shared Settings value, creature learning levels and source stages, and feature cards without invented metrics. The retained suite also covers search/filter results, all destinations and Tools, artwork contraction/restoration, shiny selection, and personal records surviving Catalog recovery.

The complete 11-case run preceded the final title-only rearrangement. The final two-case run rechecked both skill-layout behavior and Chinese captures against the rearranged source; it is not represented as another complete-suite run.

## Reviewed captures

Eight original 1206 × 2622 PNGs from the final focused run were visually reviewed and retained under `phase-9-compact-skills/`. Both densities place the full visible sample names above their illustrations; power/energy and learning-level badges do not overlap the title. Detailed captures retain readable descriptions and acquisition rows. Expanded and compact artwork use the neutral page surface. Earlier task evidence remains untouched.

- [Skill catalog, two columns](phase-9-compact-skills/skills-two-columns-zh.png) and [three columns](phase-9-compact-skills/skills-three-columns-zh.png)
- [Skill catalog, detailed descriptions](phase-9-compact-skills/skills-detailed-zh.png)
- [Expanded neutral artwork](phase-9-compact-skills/neutral-hero-expanded-zh.png) and [compact neutral artwork](phase-9-compact-skills/neutral-hero-compact-zh.png)
- [Creature skills, two columns](phase-9-compact-skills/creature-skills-two-columns-zh.png), [three columns](phase-9-compact-skills/creature-skills-three-columns-zh.png), and [detailed descriptions](phase-9-compact-skills/creature-skills-detailed-zh.png)

## Original simulator installation and review

The original simulator is `Roco Swift Migration` (`59C3C5B8-DC7B-418A-84D7-8C0B165A5B8A`), bundle ID `world.roco.rocoHandbook`. Before installation, the App was terminated and its personal database was backed up locally. The read-only audit records normalized table digests/counts, schema version, `integrity_check`, and `foreign_key_check` without printing personal content. The baseline contains one favorite, two notes, zero collection marks, one settings row, and one metadata row. Integrity is `ok` and foreign-key violations are absent.

The final destination-specific build was installed without uninstalling, then launched in Chinese. The installed executable's SHA-256 matches the final build. All personal table digests/counts and the schema version match the pre-install snapshot; integrity remains `ok` and foreign-key violations remain absent. Manual navigation on this original device confirms the neutral expanded header, contraction while browsing, and top-row names above skill artwork and metric/level badges. The local installation capture is `/tmp/roco-compact-installed-original.png`.

The complete scoped diff was reviewed, `git diff --check` passed, and all 24 changed paths match ADR-0026. No personal database, record content, credential, reference screenshot, generated Catalog, or build product is included in Git. GitHub Desktop remains the required commit/push route; the final handoff reports observed synchronization.

## Acceptance limits

These checks do not establish physical iPhone behavior, iOS 15 runtime rendering, VoiceOver, exhaustive Dynamic Type/Reduce Motion acceptance, signed upgrades, distribution signing, live updates, store upload, review, or publication. The next allowed boundary remains physical iOS/accessibility and signed-upgrade validation.
