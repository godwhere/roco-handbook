# ADR-0004: Phase 2 normalization, identity, and source ownership

- Status: accepted
- Date: 2026-09-09
- Scope: normalized Catalog V1 contract, identity lock, and first release package

## Context

The validated Phase 1 snapshot contains upstream identifiers, duplicated fields across modules, source-specific type labels, and fields that are intentionally outside the V1 SQLite query contract. Phase 2 must produce stable local identities and a complete queryable database without inventing semantics, silently dropping evidence, or treating the first snapshot as proof of cross-version stability.

Thirty-one Evolution membership records repeat a type list that differs from the corresponding Core creature type list. The Evolution module also contains the authoritative group membership, ordering, and directional conditions. No released Catalog or personal database exists yet, so this phase is the only permitted initialization point for the first identity lock.

## Decision

- Normalize every entity and relationship in a deterministic order. Preserve explicit nulls, raw acquisition conditions, source revision identifiers, and unmodeled Handbook fields in `source_extra`.
- Use Core as the canonical owner of creature attributes, including types. Use Evolution only for group membership, ordered chain direction, lord branches, and their raw conditions.
- Bind the 31 known duplicated-type differences to the exact Core and Evolution revisions and to a SHA-256 of the complete mismatching pair set. A different revision, count, or pair hash is an unreviewed blocking conflict.
- Resolve observed short bloodline type labels only through the explicit type-alias configuration. Map the upstream untyped markers to null instead of creating a fabricated ordinary type.
- Initialize stable local IDs from the validated upstream keys once. Lock creature, handbook, and skill mappings with entity kind, source key, first revision, fingerprint, and optional remap history. Later missing mappings, key reuse, or fingerprint changes are review items and cannot be accepted by name similarity.
- Treat data version 1 as the baseline release. With no previous database, the difference report records a baseline and zero removals; later versions must compare against a selected previous Catalog.
- Build into a new versioned directory only. Validate normalized references, identity state, SQL constraints, database integrity, foreign keys, manifest fields, byte length, and SHA-256 before retaining the package. Never overwrite an existing data version.

## Consequences

The same normalized input, schema, registry, and reviewed-exception configuration has a stable logical representation. The release database is queryable without interpreting raw upstream fields, while out-of-schema evidence remains available for later design decisions.

The first registry contains 1,826 mappings. Rename and reuse behavior still requires a second complete snapshot before cross-version identity handling can be considered proven. Optional topic rewards, skill-stone topics, and description-note definitions remain explicitly uncovered rather than being represented as complete.
