# ADR-0005: Phase 3 offline Flutter client boundaries

- Status: accepted
- Date: 2026-09-09
- Scope: bundled Catalog preparation, read-only queries, and offline browse UI

## Context

Phase 3 must turn the validated data version 1 package into a usable iOS and Android application without introducing a runtime BWIKI client, a second schema source, personal-data writes, or sample production data. Search must preserve concrete form identity and source semantics. The later upgrade and recovery state machine belongs to Phase 5, but first launch still needs a safe, verifiable local database.

The Catalog contains 442 handbook entries, 596 concrete forms, and 788 skills, so a first-page-only UI is not a complete browser. SQLite work, file copying, hashing, and integrity checks must stay out of Widget builds, and public query inputs must never become SQL fragments.

## Decision

- Bundle the exact data version 1 database, manifest, and attribution from `data/release/1/assets/catalog/`. A repository test compares all three App assets byte-for-byte with the validated release.
- Parse the manifest with an exact field and coverage contract. Require dataset `roco-world-zh-cn`, Catalog schema 1, positive data and byte counts, the fixed asset path, a 64-character SHA-256, and true creature, skill, and evolution coverage.
- On first launch, copy only the bundled database to an invocation-owned staging file in the private `catalogs/` directory. Validate its length, hash, metadata, required tables and views, integrity, foreign keys, and sample query before renaming it to a versioned file and atomically writing the active pointer.
- Reuse a valid active file for the same manifest without recopying it. A failed candidate keeps the existing pointer and deletes only the staging file created by that invocation. Full previous-version rollback, retention cleanup, recovery UI, and fault injection remain Phase 5 work.
- Open every production query with SQLite read-only and query-only modes. Execute synchronous SQLite work through a background isolate. Domain DTOs cross the repository boundary; Widgets never receive a database handle or raw upstream JSON.
- Bind every user value. Escape SQLite `LIKE` wildcard characters, normalize only purely numeric handbook input, and select sort SQL through the `PetSort` enum. Type filters match any selected explicit type ID.
- Page creature and skill collections in fixed 60-row requests with a visible `Load more` control. A new search generation supersedes older in-flight results.
- When search text is present, return concrete forms so an exact special-form name opens that pet ID. Default browsing uses the evidence-backed handbook display mapping. Form switching reloads the complete detail, stats, feature, learning sources, and evolution graph.
- Model feature ownership separately from native, bloodline, skill-stone, and legendary learning sources. Preserve every condition. Never turn glossary note references without definitions into active links.
- Use English for App-authored copy. Canonical names, types, descriptions, conditions, and test fixtures may retain their source language. Do not fetch online images; the current UI uses local Material symbols and text.

## Dependencies

The locked Flutter client adds `sqlite3` 3.5.2, `path_provider` 2.1.6, `crypto` 3.0.7, and `path` 1.9.1. `sqlite3` supplies the local read-only database runtime, `path_provider` selects private application support storage, `crypto` verifies SHA-256, and `path` constructs allowlisted paths. No HTTP package or remote-data dependency is present.

## Consequences

The application can start and browse the complete packaged Catalog without a network connection or account. A direct SQLite implementation avoids generated schema drift while tests compare required objects and query behavior against the normative SQL package.

Phase 3 does not create or migrate `user.db`, implement favorites or notes, perform signed device builds, or claim robust multi-version recovery. Those capabilities remain behind their later phase boundaries.
