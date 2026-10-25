# Phase 15 offline attack coverage tool

- Date: 2026-10-26, Asia/Shanghai
- Status: native implementation and local validation complete; scoped GitHub Desktop delivery
- Baseline: `6269aae`

## Authorization and boundary

The user approved adding the ranked Wiki candidates. Work proceeds one declared phase at a time. This phase delivers the first tool: choose up to five distinct attacking types and view covered, resisted, and neutral defending types using the existing frozen relation chart. It also permits read-only source discovery for the later item/research/medal/trial/habitat phases, with findings restricted to invocation-owned temporary files until a later phase declares its import contract.

Allowed paths: coverage DTO/calculation in `ios/Sources/HandbookCore/AssetRepository.swift`, focused Core tests, the Tools home and new coverage view in `ios/App/ToolsViews.swift`, both native localization resources, focused native UI/packaging tests, README and affected feature documents, ADR-0034, this report, and Phase 15 evidence. Temporary validation mirrors, logs and source-discovery notes are invocation-owned.

Non-goals: Catalog/source/SQL/identity changes, personal preference or progress changes, new assets or dependencies, damage simulation, runtime network access, updater/installer behavior, system settings, signing, and publication. Existing eight-module import and other feature contracts remain unchanged.

## Acceptance and stopping condition

Trace the existing frozen chart through asset validation and repository DTOs; preserve existing single/dual-type semantics. Define coverage as any selected type being super effective and resisted targets as every selected type being resisted; remaining targets are neutral. Exclude the no-type placeholder from attacking choices and results. Empty selection produces an instruction state. Reject unknown, duplicate, placeholder and over-limit selections. Test known Fire results, combined union/intersection, deterministic order and malformed contract handling offline. Verify native selection, the five-type limit, reset, source access, Chinese copy, Dynamic Type, and existing Tool routes. Run the Swift suite, native packaging and focused UI tests, generic simulator build, English-prose and scoped diff checks. Capture the native result, update mapped documentation, then commit/push through GitHub Desktop before declaring the next implementation phase.

## Changes and results

- Core asset repository: validated coverage DTO, complete eighteen-type/icon set, source-ordered union/intersection results and exact frozen-chart provenance; six owned offline regression cases. Existing creature relationship behavior is preserved.
- Native Tools: an eighth compact original-icon entrance, native multi-select chips, limit/reset, counts and descriptions, source sheet, cancellation-safe result refresh, and accessible growing layout. No personal store or schema writes were added.
- UI coverage: all eight destinations, Fire results, selection feedback, five-choice limit and removal, reset, exact source access, Chinese captures, maximum-text geometry and the existing Settings/recovery actions.
- README, affected feature documents, ADR-0034 and Phase 15 evidence describe the effective tool. New Wiki datasets remain outside this implementation; their discovery notes are temporary input for the next declared phase.

The initial full Swift suite passed 33 tests, followed by all six final coverage cases after complete-type validation was tightened. Four packaging/localization tests passed. The first native selection passed coverage but failed the route case because a saved Chinese override correctly took precedence over English launch arguments, and failed the source target measurement at 36 points in the system toolbar. The selected tests now choose Follow System through the real Settings UI; the source action is a 44-point body control with a separate accessibility-size action row. The final three native cases passed. The generic simulator build, English-prose, native-input equivalence, scoped review and whitespace checks passed. Actual captures and logs are in [Phase 15 evidence](../evidence/phase-15-offline-attack-coverage.md).

Physical iOS/iOS 15, VoiceOver, signed upgrades, live updates, store acceptance and unrelated full Python/UI suites were not run. No Catalog/source/SQL/identity, personal data, immutable asset, dependency, network configuration, credential or release setting changed. The next boundary is the approved offline item/research/medal/trial/habitat expansion under a new import and presentation phase.
