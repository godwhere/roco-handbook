# ADR-0006: Phase 4 personal-data ownership and migration boundary

- Status: accepted
- Date: 2026-09-09
- Scope: personal database creation, repositories, and local library UI

## Context

Favorites, handbook collection marks, notes, and settings must outlive Catalog replacement without creating a cross-database foreign key or copying Catalog records into a second long-term source of truth. A missing or retired Catalog object must not make personal records unreadable. Personal database failures must not trigger delete-and-recreate recovery, and a note save failure must leave the editor draft intact.

The current App already uses the `sqlite3` package and background-isolate operations for the read-only Catalog. Adding another database abstraction would create a second schema representation and an unnecessary dependency. User V1 has no released predecessor, so its only valid migration path in this phase is creation of schema version 1 or validation and reuse of an existing version 1 database.

## Decision

- Bundle an exact byte-for-byte copy of `schemas/user_v1.sql` as the runtime schema asset. The root suite prevents drift between the normative file and the App asset.
- Store the personal database at `user/user.db` inside private application support storage, physically separate from the versioned Catalog directory and active pointer.
- Create User V1 in an invocation-owned staging file, insert its singleton metadata, validate the version, required tables and indexes, absence of foreign keys, and SQLite integrity, then rename it into place. A failed first creation deletes only that staging file.
- Reuse a valid version 1 database without rewriting it. Reject an unknown version or invalid contract and preserve the existing file. No catch-and-delete recovery path exists.
- Treat future schema versions as explicit migration work. Phase 4 does not claim a V2 migration or an active-database backup implementation because no V2 schema exists.
- Use `datasetId + objectType + objectId` for favorites and notes, and `datasetId + handbookId` for collection marks. Save a current name snapshot with every personal reference, but resolve live details through `CatalogRepository` in the application layer.
- Implement `setFavorite` and `setCollected` as explicit idempotent state changes inside transactions. Repeated enables cannot create duplicate rows, and repeated disables remain successful.
- Keep note IDs bound to their original object. A note may be edited or deleted when its Catalog object is unavailable, but it cannot be reassigned to another object.
- Open, transact, and close each personal database operation in a background isolate. Only primitive paths and operation values cross the isolate boundary; active streams and Widget state must not be captured.
- Publish committed favorite and collection changes through repository streams. Widgets consume domain models and never receive a SQLite connection.
- Keep note editor text until a save succeeds. Show a retryable failure message without logging the note body.
- Provide four fixed navigation destinations: Creatures, Skills, My Library, and Settings. My Library separates favorites from handbook-level collection marks. Settings states that personal data is device-local and may be removed by uninstalling the App.

## Consequences

Catalog installation, replacement, and recovery cannot cascade into personal tables. A saved object can remain explainable through its name snapshot when it is absent from the current Catalog, and its notes remain editable.

The `settings` table is validated as part of User V1, but Phase 4 does not add arbitrary setting writes or claim backup, export, account, or cloud synchronization. Whole-Catalog replacement and bundled recovery remain Phase 5 work.
