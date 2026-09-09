# ADR-0002: Phase 1 source evidence and handbook mapping

- Status: accepted
- Date: 2026-09-09
- Scope: Phase 1 import, parsing, adapter inspection, and handbook evidence

## Context

The seven required MediaWiki data modules expose data-only Lua tables, while the Pet, Skills, and DexIndex modules contain executable Lua. The baseline specification requires safe offline parsing, complete field inspection, real display numbers, and evidence-backed default handbook forms. It prohibits executing downloaded Lua or deriving product semantics from local ID order, ID suffixes, `show_topics`, or `hide_entry_name` without an independently verified source rule.

## Decision

The importer validates each MediaWiki revision response, verifies the reported byte size and SHA-1 against the UTF-8 source body, and freezes immutable response and content files under a content-addressed snapshot. Git tracks the provenance lock but not the large upstream response bodies.

The restricted parser accepts only a top-level returned Lua table containing supported data literals. It preserves table shape and source locations, rejects executable syntax, and never calls Lua or `require`. Metadata keys are expanded recursively with collision detection before adapter inspection.

The current rendered pet index is separate evidence for presentation semantics:

- Every rendered card title maps to one unique Core title.
- Every card's displayed number is preserved as observed. The local adapter does not calculate a number from a handbook ID suffix.
- The rendered main-form marker covers all 442 handbook entries.
- The 394 unambiguous entries use the unique unformed creature whose name equals the handbook entry name.
- The remaining 48 entries use explicit overrides tied to rendered index revision 41359.
- The complete set of 442 resolved defaults must equal the rendered main-form mapping.
- The observed one-to-one correlation with `show_topics` is diagnostic only and is not a selection rule.

The reviewed DexIndex source at revision 43100 independently confirms how the upstream site currently formats public numbers and emits its main-form marker. The module remains executable review evidence and is rejected by the data parser.

Evolution edges use the explicit ordered `chain` and `lord_branches` source fields. Chain edges connect each member to the following member, and lord branches connect from the terminal chain member while preserving target conditions. No edge is inferred from a shared handbook number or pet ID order.

Learnset `stage` remains `source_stage`. The adapter reports it but does not hide skills according to the current creature stage.

## Consequences

Phase 1 can close required-module parsing, unknown-field inspection, feature references, skill mappings, display-number coverage, and default-form coverage without fabricating values. The two Core creatures absent from the rendered index remain present in source inspection; the upstream index explicitly excludes their titles. Three disabled optional V1 sources remain outside coverage and are reported as a warning.

Any future source revision must regenerate these reports. A missing rendered card, changed display number, duplicate main form, unknown field, unsupported syntax, unresolved reference, or default mismatch becomes a blocking inspection result rather than an automatic remapping.
