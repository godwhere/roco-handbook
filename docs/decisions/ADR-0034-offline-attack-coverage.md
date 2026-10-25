# ADR-0034: Offline attack coverage

- Status: accepted
- Date: 2026-10-26
- Scope: Phase 15 native Tools

## Context

The user approved the source-linked Wiki additions after the Phase 14 review. The first tool can reuse the complete frozen eighteen-type chart, packaged icons and native asset repository without importing new data or changing personal storage.

## Decision

The native Tools home gains Attack coverage. Users select up to five distinct attacking types. A defending type is covered when any selected type is super effective against it. A defending type is resisted when every selected type is resisted by it. Remaining defending types are neutral. These are single defending types, not dual-type creatures or full damage calculations. Empty selection shows instructions and no computed result.

The existing frozen chart supplies both the domain calculation and ordering. The no-type placeholder is excluded from selectable and result types. Invalid selections and inconsistent chart data fail explicitly through the existing error surface. The existing creature relationship API and its dual-type incoming cap retain their meaning. The source chart revision is presented offline through repository-provided provenance rather than inferred from the current website.

The UI uses original bundled type icons, short labels, visible selection marks, result counts and text explanations. Unselected choices are unavailable at the five-choice limit, while selected choices remain removable. Reset clears transient selection. Source information remains readable offline. Dynamic Type, scrolling and minimum target sizes take precedence over a fixed number of columns. This phase adds no persisted battle plan, favorites, account or runtime request.

## Boundary and acceptance

Allowed changes are the coverage DTO/calculation, native Tools view, necessary localizations, focused Core/UI/packaging tests, and mapped Phase 15 documentation/evidence. Catalog/source/SQL, identities, personal records, immutable media, dependencies, updater/installer behavior, signing and publication remain unchanged.

Verify the Fire four-covered/three-resisted example, union/intersection behavior, empty state, invalid inputs, deterministic order, source provenance and malformed contracts with owned offline tests. Verify native selection, limit/reset, source access, Chinese and accessibility rendering, and the previous seven routes. Run the Swift suite, native packaging, generic simulator build, targeted UI cases, English-prose and scoped whitespace checks. Commit and push through GitHub Desktop before starting the next implementation phase. Results belong in the Phase 15 report and evidence; physical iOS/iOS 15, VoiceOver and release acceptance remain separate.
