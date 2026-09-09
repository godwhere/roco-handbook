# Catalog update and recovery

## Normal startup

The App reads Catalog data only from private application-support storage. Startup completes Catalog selection before creating the read-only repository or showing normal navigation. One file lock serializes installer work.

The installer validates the active record and its exact generated file. If that Catalog is compatible and at least as new as the version bundled with the App, it remains active. Installing an App that carries an older Catalog therefore does not silently downgrade a newer compatible local Catalog.

When the bundle has a newer data version, the App copies the complete database to a unique staging file and performs full manifest, hash, metadata, schema-object, integrity, foreign-key, and probe-query validation. It renames the verified file to a hash-qualified versioned filename, records the previous Catalog, atomically replaces the active pointer, and probes the new active file again.

## Failure and rollback

A staging copy or validation failure leaves the old active pointer unchanged. A failure after the new pointer is written restores and opens the separately recorded previous Catalog. A damaged active pointer may use only a valid previous record or the exact bundled package; it does not scan arbitrary files.

Failed operations record a bounded machine-readable code without personal content. A later successful startup removes the failure record and orphaned installer temporary files.

Cleanup is non-recursive and limited to generated direct-child filenames in `catalogs/` and `catalog-state/`. After success, at most the active and one distinct previous Catalog database are retained. Unrelated files, nested directories, and `user/user.db` are outside the cleanup boundary.

## Personal-data isolation

Catalog replacement never opens, migrates, overwrites, or deletes `user.db`. Favorites, handbook collection marks, notes, and settings retain their dataset and stable object identifiers plus name snapshots. A creature or skill that is retired or absent from a new Catalog remains interpretable in My Library.

Automated update, rollback, storage-failure, and recovery tests compare the User V1 logical snapshot across the operation. Android runtime evidence additionally preserved the existing personal database byte-for-byte during Phase 3 pointer migration and explicit bundled recovery.

## Restore bundled Catalog

Settings provides **Restore bundled Catalog**. A confirmation dialog explains that only the offline Catalog is replaced, personal data is kept, and the bundled data version may be older than the current version.

After confirmation, the App closes the current session, runs the same trusted installer state machine in explicit-recovery mode, and creates a new read-only Catalog session. The Settings page reports whether startup reused, installed, recovered, or explicitly restored the Catalog.

This is a local recovery action, not an online update. V1 has no Catalog download button, timer, background updater, incremental patcher, account, or cloud service.
