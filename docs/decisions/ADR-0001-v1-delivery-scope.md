# ADR-0001: V1 delivery scope

- Status: accepted
- Date: 2026-09-09

## Decision

Build the first release as a Flutter application backed by two local SQLite databases:

- a replaceable, read-only `catalog.db` built from frozen and validated BWIKI source revisions;
- an independently migrated `user.db` containing favorites, collection marks, notes, and settings.

The development pipeline may perform controlled upstream reads, but the installed application must support first launch and normal use without network access. Catalog updates are delivered with new App versions for V1.

## Consequences

V1 does not introduce an application server, in-App data downloads, incremental patches, user accounts, cloud synchronization, or runtime Lua parsing. Catalog replacement must never overwrite or recreate the personal database. Image acquisition is outside the current scope; local placeholders remain valid.

This record restates the accepted baseline so implementation tasks do not silently widen it.

