# Phase 9 centered detail and illustrated skill-user evidence

## Boundary

[ADR-0027](../decisions/ADR-0027-centered-detail-and-visual-skill-users.md) declares the allowed paths, exclusions, commands, stopping conditions, and acceptance boundary. Work started from clean, synchronized `main` at `3ab21d6620dba0fc7bb0a099859e0c7a14d20efb`. The user requested centered creature names/types, removal of scrolled content bleeding behind the navigation title, and illustrated skill-user links.

`ios/App/DetailViews.swift` changes application behavior. The identity stack centers its name, form subtitle, and type row in expanded/compact states. The content presentation clips to its safe viewport and places the adaptive surface behind the native navigation area. Native controls/material and the constant scroll inset remain. Changed skill-result identities restore the compact browsing start, and opening filters dismisses the search keyboard. Stable accessibility identifiers allow direct geometry checks. Both native localization resources translate the previously dynamic learning-source and feature-user headings.

`SkillDetailView.users` continues to receive the repository's independent feature and learning DTOs. Each existing `SkillUser` retains its `pet.id:relationship:ordinal` key, reuses compact `PetCard` artwork/name/number/form/type presentation, displays the existing full acquisition renderer, and links to its concrete pet ID. A lazy stack handles long lists. No repository, model, query, setting, schema, Catalog, source import, asset, dependency, or runtime network change is included.

## Verification

Xcode 27.0 (`27A266a`), iPhone 18 Pro, iOS 27.0. UI tests reuse the task-owned `Roco Catalog Layout 2026-10-15` simulator (`CC001E44-E80A-41FC-BB23-EC55BA1CFB97`). Full logs, result bundles, build products, and personal backups remain under `/tmp`.

| Check | Result |
| --- | --- |
| Two new and four retained affected UI cases | Passed: six tests, zero failures; `/tmp/roco-detail-polish-verified.xcresult`, `/tmp/roco-detail-polish-verified.log` |
| Native packaging/localization tests | Passed: four tests; `/tmp/roco-detail-polish-local-native.log` |
| Generic simulator build | Passed; `/tmp/roco-detail-polish-local-build-final.log` |
| Original simulator build, install, and personal-data comparison | Passed; `/tmp/roco-detail-polish-local-install-build.log`; installed executable/debug-library hashes match |
| Complete allowed diff and `git diff --check` | Passed; exactly 14 allowed paths, including five captures |

New coverage checks centered dual-type identity before/after scrolling, the artwork remaining below the native navigation bar, source-card number/level/stage text, and navigation to the correct concrete creature. Chinese captures cover expanded identity, two compact scroll positions with dark skill cards, learning-source cards, and independent feature-user cards. Retained cases cover original/shiny state and top restoration, detail tabs/search/filters/egg groups, shared skill layouts and exact acquisition conditions, and personal records surviving Catalog recovery.

Core/pipeline suites and unrelated UI cases are not rerun for this view-only change. Prior results remain historical evidence and are not represented as current runs. Pixel-level toolbar appearance requires visual review; geometry and navigation assertions alone do not establish absence of background bleed.

The first build was interrupted during staging because cloud placeholders blocked local resource reads. Existing installed assets were checked against the baseline's Git blob identities before restoring 1,882 active resources with identical bytes. A temporary shallow bare clone of the same synchronized revision supplied a verified local Git pack; evicted loose entries were preserved in private Git-cache backup directories, and refs/history/index semantics were not changed. Index-matching unchanged workspace inputs were materialized from that exact baseline with edited paths excluded. Cache receipts and backups stay outside the phase diff; this is local cache recovery, not a BWIKI import or a new Catalog/asset version. A runner launch attempt also reported a simulator IPC failure before case execution; the same owned simulator was reused without erasing data.

The first completed six-case run passed four cases and exposed two review issues. The feature capture tapped a partially covered creature-detail control; it now opens a known Core-owned feature through Tools. The retained search/filter case exposed an unreachable first result after the safe-viewport change; result-position restoration and explicit keyboard dismissal address it, and the retained test additionally checks keyboard absence and actual first-card hit testing. Its assertions were strengthened rather than removed. The final six-case run passed every affected case.

The final packaging checks and builds use `/tmp/roco-detail-polish-local-build` to avoid repeated File Provider delays. This build-only mirror contains the same baseline project/native inputs, the final workspace source/localization/test overrides, and 1,882 active assets verified against their committed Git blob IDs. All 33 native project/source/localization/test inputs match the workspace byte-for-byte; receipts remain in `/tmp/roco-detail-polish-build-source-equivalence.json`. The existing immutable AppIcon asset catalog is included from the same baseline after the first mirror build exposed that missing input. No project or release configuration change was needed. The six UI cases ran against the same final application source in the original checkout; the local mirror is not a separate delivery branch or source of truth.

## Captures and original installation

Five original 1206 × 2622 Chinese PNGs from the passing run were visually reviewed and retained under `phase-9-detail-polish/`. The expanded and compact identity is centered; both compact scroll positions have an opaque, clean background behind the native creature title. Learning-source and feature-user cards show stored illustrations, numbers, types, forms, and conditions. Existing capture directories and the supplied reference remain untouched.

- [Expanded identity](phase-9-detail-polish/detail-centered-expanded-zh.png)
- [Compact navigation](phase-9-detail-polish/detail-pinned-navigation-zh.png) and [deep scroll](phase-9-detail-polish/detail-pinned-deep-scroll-zh.png)
- [Learning-source cards](phase-9-detail-polish/skill-learning-cards-zh.png) and [feature-user cards](phase-9-detail-polish/skill-feature-cards-zh.png)

The final destination build was installed onto `Roco Swift Migration` (`59C3C5B8-DC7B-418A-84D7-8C0B165A5B8A`) without uninstalling and launched in Chinese. SHA-256 checks for both `RocoHandbook` and `RocoHandbook.debug.dylib` match the final build. A fresh pre-install personal snapshot was taken after terminating the App, preserving the earlier backup separately. Every table's logical row digest/count and the schema version match after startup. Counts remain one favorite, two notes, zero collection marks, two settings rows, and one metadata row. Integrity is `ok`; foreign-key violations are absent. Personal databases, record content, references, credentials, build products, and cache-recovery receipts remain outside Git.

The complete 14-path diff was reviewed, including all five original captures, and `git diff --check` passed. Immutable assets, native core/repository/schema files, and the Chinese provenance baseline have no content changes. Repository synchronization is verified in the final handoff through GitHub Desktop.

## Acceptance limits

Physical iPhone behavior, iOS 15 runtime rendering, exhaustive Dynamic Type/VoiceOver/Reduce Motion, signed upgrades, distribution signing, live updates, and store delivery are not established. The next allowed boundary remains physical iOS/accessibility and signed-upgrade validation. The scoped English commit and push must use GitHub Desktop, with synchronization checked before final handoff.
