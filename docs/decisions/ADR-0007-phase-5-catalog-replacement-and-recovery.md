# ADR-0007: Phase 5 Catalog replacement and recovery state machine

- Status: accepted
- Date: 2026-09-09
- Scope: startup Catalog selection, activation, rollback, recovery, and cleanup

## Context

The Phase 3 installer could validate and copy the bundled Catalog, but its pointer held only four fields and had no independent previous record. It could not recover from a damaged active pointer, roll back a failure after pointer activation, distinguish an explicit bundled recovery from normal startup, or prove that cleanup stayed inside the Catalog-owned directory. App updates must replace the complete read-only Catalog without rewriting or deleting `user.db`.

V1 distributes Catalog data only with the App. A safe replacement design must not introduce a remote package source, runtime patching, an account, or a cross-file claim of atomicity. It must also accept the pointer and file layout already installed by Phase 3.

## Decision

- Serialize every installer operation with an operating-system file lock in `catalog-state/`. Replacement finishes before repositories and normal navigation are created.
- Store complete validated artifact descriptors in independent `active_catalog.json` and `previous_catalog.json` records. Each record contains the manifest identity, schema and data versions, snapshot, byte length, SHA-256, coverage, and a generated Catalog basename.
- Accept the Phase 3 four-field active pointer only when it exactly matches the bundled manifest and its derived legacy filename passes full validation. Rewrite that pointer into the current descriptor format without recopying the database.
- Derive all candidate and retained file paths inside `catalogs/`. A pointer basename must equal the descriptor's canonical hash-qualified filename or the exact legacy filename. Absolute paths, `..`, arbitrary basenames, symlinks, and directory scans are not recovery inputs.
- On normal startup, keep a valid compatible active Catalog when its data version is newer than the bundled version. Reject a different artifact that reuses the same dataset, schema, and data version.
- Copy a new bundled artifact to an invocation-owned staging file, flush it, and run the full package validator before rename. The validator checks byte length, SHA-256, metadata, required tables and views, SQLite integrity, foreign keys, and the stable probe query.
- Write the previous descriptor before atomically replacing the active pointer. Reopen and validate the activated Catalog. If that post-activation step fails, restore the previous pointer and open the previous validated Catalog.
- Persist only a bounded failure code and attempted data version in `last_catalog_failure.json`. Do not include local paths, personal content, or source credentials.
- After a successful startup, retain only the active and distinct previous validated Catalog files. Delete only direct-child filenames matching the project's staging, pointer-temporary, or versioned-Catalog patterns. Never recurse through application support or operate on `user/`.
- Expose **Restore bundled Catalog** in Settings behind explicit confirmation. This operation may intentionally return to an older compatible bundled data version, but it runs the same copy, validation, pointer, post-open, rollback, and cleanup sequence.
- Keep deterministic fault points limited to installer tests for abandoned staging, storage-write failure, and post-pointer open failure. Production does not select a fault point.

## Consequences

A normal App update can activate a complete newer Catalog while preserving one proven rollback target. An interrupted or rejected candidate does not become active, a damaged active pointer can recover only its separately recorded previous artifact or the trusted bundled artifact, and an explicit recovery cannot modify the personal database.

The active pointer and database rename are separately durable filesystem operations, not a cross-file transaction. Automated fault injection proves state-machine behavior on the local host, while actual crash durability, low-storage behavior, and file flush/rename semantics still require physical iOS and Android update testing in Phase 6.
