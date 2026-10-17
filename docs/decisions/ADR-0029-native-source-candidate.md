# ADR-0029: Native source candidate and evidence separation

- Status: accepted for this release-metadata follow-up
- Date: 2026-10-17

## Decision

Preserve `release/1.0.0+1/` unchanged and add `release/1.2.0+3/` for the active
Swift/SwiftUI source candidate. Record Catalog 2, personal schema 1, active
packaging-input hashes, exact source/CI commits, and explicit unrun gates.
Do not reuse Flutter/Android binary hashes or the Phase 6 device waiver.

A source inventory is not an executable artifact. Until a signed archive and
its validation exist, artifact path/digest remain null and store readiness is
false. Host tests, simulator builds, local UI reports, physical upgrades and
store acceptance are separate evidence classes. The offline candidate checker
must reject version, Catalog, schema and resource drift; its regressions run in
the existing Python CI suite. No runtime or immutable-data contract changes.

## Consequences

The candidate is reviewable and reproducible from tracked inputs without
credentials, network access or Apple tooling. New native runtime changes or
packaging changes require refreshed evidence and candidate review. A future
signed artifact must be bound to its actual commit and build settings, inspected
and hashed independently before release gates can be closed. The Chinese
baseline specification and all historical release evidence remain intact.
