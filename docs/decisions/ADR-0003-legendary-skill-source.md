# ADR-0003: Preserve legendary skill acquisition separately

- Status: accepted
- Date: 2026-09-09
- Scope: Catalog schema V1 and normalized Learnset contract

## Context

Phase 1 found six real Learnset records with a `legendary` object containing a skill reference and a `requires` condition. The initial V1 SQL represented native, bloodline, and skill-stone acquisition but had no lossless destination for this fourth acquisition source.

Storing the object only in `learnsets.extra_json` would preserve developer evidence but make the relationship unavailable to the App's typed query. Treating it as native, bloodline, or skill-stone acquisition would erase its source semantics.

## Decision

Add `learnset_legendary_skills` to the unreleased Catalog schema V1. Each row preserves the Learnset ID, source ordinal, referenced skill ID, and raw requirement text. Extend `pet_skill_sources` with a `legendary` source kind and a distinct nullable `requirement_text` output column; do not overload the bloodline condition column.

The builder must validate the referenced Learnset and skill through foreign keys and preserve the original condition text without executing or interpreting it. It must not merge this source with another acquisition method.

## Consequences

The Catalog schema now has 20 tables and two views. Schema version 1 remains valid because no Catalog package or App build has been released against the earlier draft. Future changes after release must follow the schema compatibility rules instead of modifying V1 in place.
