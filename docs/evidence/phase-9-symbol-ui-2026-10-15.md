# Phase 9 scroll-linked artwork and filter evidence

## Scope and source of truth

[ADR-0025](../decisions/ADR-0025-scrollable-artwork-and-symbol-filters.md) declares the allowed paths, commands, stopping conditions, and acceptance boundary. The starting revision is `30a649ed74b692605c4a9dbe89a8a9f2b047fcde` on `main`, with a clean worktree and synchronized remote.

The user requested large artwork on detail entry, contraction while browsing, multiple creature/skill filter choices per row, and greater use of existing icons. Public visual research used the [NRC BWIKI creature gallery](https://wiki.biligame.com/nrc/%E7%B2%BE%E7%81%B5%E5%9B%BE%E9%89%B4), observed on 2026-10-15. The reference groups short choices and emphasizes type icons. This is visual research only; its live records, counts, filters, and artwork were not imported. The App continues to read immutable Catalog data version 2 and bundled Wiki images version 3 without a runtime Wiki request.

## Implementation path

- Existing repository queries and DTOs feed `PetCatalogView`, `SkillCatalogView`, and `PetDetailView`; no source, schema, identity, or repository contract changed.
- `MultiSelectSection` renders adaptive grids through shared `FilterChoice` buttons. Type icons resolve through `CatalogAssets.type`; the four frozen skill classifications map to existing bundled category icons. Missing icon mappings retain the text label. Selection remains on the actual button, with a checkmark and outline in addition to color.
- `PetDetailView` measures a constant scroll-content frame. Its artwork/header overlay lives inside the same native scroll view, so vertical drags from artwork, tabs, and content reach the scroll gesture. The image shrinks from up to 250 points to 100 points; returning to the top restores it. Header sizing does not change the scroll inset. Tab changes bring the new content to its start while retaining a compact header if already browsing.
- Original/shiny state, concrete-form routes, feature ownership, acquisition requirements, type multipliers, favorites, notes, and recovery remain on their existing paths. Detail skill filters use local DTO classifications and elements with the shared icon choices.

## Environment and verification

Xcode 27.0 (`27A266a`), iOS 27.0, iPhone 18 Pro simulator. UI tests reuse the task-owned `Roco Catalog Layout 2026-10-15` device (`CC001E44-E80A-41FC-BB23-EC55BA1CFB97`) to isolate test notes and preferences from the user's simulator.

Full logs and build products remain under `/tmp`; no personal database or build product belongs in this evidence directory.

| Check | Observed result |
| --- | --- |
| `swift test --package-path ios --scratch-path /tmp/roco-handbook-spm` | Passed: 24 tests; `/tmp/roco-symbol-swift.log` |
| Offline Python discovery | Passed: 109 tests; `/tmp/roco-symbol-python-final.log` |
| Final native packaging/localization discovery | Passed: four tests; `/tmp/roco-symbol-native-final.log` |
| Complete iOS UI suite | Passed: nine cases, zero failures; `/tmp/roco-symbol-ui-final.xcresult`, `/tmp/roco-symbol-ui-final.log` |
| Final filter hydration and Chinese captures | Passed: two cases, zero failures; `/tmp/roco-symbol-ui-hydration.xcresult`, `/tmp/roco-symbol-ui-hydration.log` |
| Final generic simulator build | Passed; `/tmp/roco-symbol-build-hydration.log` |

The complete UI run includes actual multi-option row geometry and minimum target height, combined creature/skill selections, correct filtered results, reset behavior, detail skill classification/element combinations, 250-to-100-point artwork contraction, top restoration, source-backed shiny state, short-tab navigation, all Tools routes, layout persistence, and personal records surviving Catalog recovery. After that run, final visual review darkened the hero for white metadata and exposed a sheet opened before its type list finished loading. Binding the sheet to the parent list and showing progress corrected hydration. The final two-case run rechecks filter results and explicitly waits for type icons in early-opened Chinese sheets before capturing them. The final native build and packaging checks use that final source.

Early focused failures identified discarded chip accessibility identifiers, scroll-offset propagation, and a viewport overlay intercepting vertical drags. Button-owned accessibility and the content-owned header overlay resolved them before the complete passing run. The first failed test's verbose simulator diagnostic collection stalled after tests ended; only that invocation-owned diagnostic process was stopped. Subsequent runs use `-collect-test-diagnostics never` while retaining test activities, failures, and screenshots in their result bundles. Non-failing App Intents metadata notes and the toolchain's UI-test linkage warnings are not iOS 15 runtime evidence.

## Reviewed captures

Nine original 1206 × 2622 PNGs from the final Chinese run are retained in `phase-9-symbol-ui/`. Earlier task captures remain in their original directory.

- [Catalog](phase-9-symbol-ui/catalog-zh.png)
- [Expanded artwork](phase-9-symbol-ui/detail-overview-zh.png) and [compact artwork](phase-9-symbol-ui/detail-compact-zh.png)
- [Creature filters](phase-9-symbol-ui/creature-filters-zh.png) and [skill filters](phase-9-symbol-ui/skill-filters-zh.png)
- [Skill panel](phase-9-symbol-ui/detail-skills-zh.png) and [detail skill filters](phase-9-symbol-ui/detail-skill-filters-zh.png)
- [Type relationships](phase-9-symbol-ui/detail-types-zh.png) and [egg group](phase-9-symbol-ui/detail-eggs-zh.png)

## Original simulator installation

The final destination-specific build passed (`/tmp/roco-symbol-install-build.log`) and was installed without uninstalling onto `Roco Swift Migration` (`59C3C5B8-DC7B-418A-84D7-8C0B165A5B8A`). Bundle ID remains `world.roco.rocoHandbook`. The installed executable's SHA-256 matches the final build product. A Chinese launch and manual navigation visibly confirm Dimo's expanded artwork and all four detail tabs; the local installation capture is `/tmp/roco-symbol-installed-original.png`.

Before installation, the App was terminated, its personal database was backed up locally under `/tmp`, and every personal table's logical records were hashed without printing content. After installation and startup, all row digests, table counts, and schema version match. Counts remain one favorite, two notes, zero collection marks, one settings row, and one metadata row. `integrity_check` returns `ok`; `foreign_key_check` is empty. This is logical personal-data preservation evidence, not a raw database-file hash claim. No backup, record content, or personal database is included in Git.

The complete scoped diff was reviewed, `git diff --check` passed, and only the 20 allowed source/document/capture paths changed. Shared detail helpers and the skill-detail implementation remain byte-identical to the starting revision. GitHub Desktop is the required commit/push route; remote synchronization is checked in the final handoff.

## Acceptance limits

This evidence does not establish physical iPhone behavior, iOS 15 runtime rendering, VoiceOver, exhaustive Dynamic Type and Reduce Motion acceptance, signed upgrades, distribution signing, live updates, store upload, review, or publication. No archived Flutter or Android build is an active delivery target.
