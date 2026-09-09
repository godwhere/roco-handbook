# Phase 3 implementation report

- Status: implementation and local acceptance complete; GitHub Desktop commit and push not run under the user's latest instruction
- Date: 2026-09-09
- Workspace: `/Users/ethan/Documents/ChatGPT/roco-handbook`

## Declared boundary

Phase 3 was limited to Flutter iOS and Android initialization, the exact bundled Catalog assets, first-install validation, read-only Catalog access, domain DTOs and repository interfaces, creature and skill browsing, search, filters, pagination, detail views, form switching, evolution evidence, accessibility behavior, tests, and mapped documentation. It did not create or write `user.db`, add favorites, collection marks, notes, accounts, cloud services, runtime BWIKI access, online images, signed releases, uploads, or store publication.

The Phase 2 worktree was preserved while work continued without a GitHub Desktop push at the user's direction. No CLI commit or push was used as a substitute.

## Changes

- Created the Flutter project for iOS and Android with English package metadata and no checked-in personal signing team.
- Added the exact validated data version 1 database, manifest, and attribution as App assets.
- Added strict manifest parsing, SHA-256 and byte validation, required object checks, metadata comparison, SQLite integrity and foreign-key checks, and the stable sample query.
- Added an invocation-owned staging copy, versioned private Catalog file, atomic active pointer, same-version reuse, and scoped cleanup. Broader recovery remains Phase 5.
- Added a read-only SQLite repository running queries in background isolates and returning domain models instead of rows or connections.
- Added safe name, title, alias, and handbook-number search with bound parameters and escaped wildcard input.
- Added explicit type filtering, enum-whitelisted sorting, 60-row paging, and stale-query suppression.
- Added creature and skill navigation, details, complete three-form switching, distinct feature and learning-source presentation, evolution relations, source references, data coverage, and attribution.
- Added dark and light Material themes, labeled controls, retry and empty states, large-text handling, and local-only startup messaging.
- Added 19 Flutter data, installer, repository, and Widget tests plus root asset parity and English-production-source checks.
- Added the Phase 3 architecture decision, feature contract, durable simulator screenshots, evidence, implementation report, and current-state README updates.

## Verification performed

```text
cd app && flutter analyze
Result: no issues found.

cd app && flutter test
Result: 19 tests passed.

cd app && flutter build apk --debug
Result: debug APK built successfully.

cd app && flutter build ios --simulator --debug
Initial result: failed because file-provider extended attributes were copied into Flutter.framework.
Scoped retry: ignored build output redirected to /tmp; project source and global SDK unchanged.
Final result: iOS simulator App built successfully.

flutter run on iPhone 17 Pro simulator
Result: installed and launched; Catalog hash, metadata, integrity, row count, and restart reuse verified.

flutter run on Android API 36 emulator after airplane mode enabled and Wi-Fi disabled
Result: APK installed and launched; Catalog hash and restart reuse verified while offline.
```

```text
PYTHONDONTWRITEBYTECODE=1 PYTHONPATH=tools python3 -m unittest discover -s tests -p 'test_*.py'
Result: 57 tests passed.

git diff --check
Result: passed for tracked changes.

Repository artifact review
Result: all untracked files were enumerated; ignored build output was absent; the bundled App assets matched the validated release byte-for-byte; the technical baseline SHA-256 remained 343618b414b7b8d6262dd58f82010bfefb2f3fdb29711a9e86428e042dd81876; and no credential, signing-key, personal-database, or unexpected personal-path artifact was found.
```

The final simulator screenshots were visually inspected after the latest filter and sorting controls were installed. Both platforms showed the creature browser without clipping or overflow.

## Not run

- Physical iOS or Android device installation
- iOS simulator flight-mode isolation
- Release-mode signing, archive, or performance profiling
- Store upload or publication
- Image acquisition or image-license review beyond the packaged data attribution
- `user.db`, personal-data migration, favorites, collection marks, or notes
- Phase 5 update rollback, previous-pointer recovery, disk-full and forced-exit fault injection, or retention cleanup

## Remaining risks and next boundary

Android cold debug launch logged skipped frames on the emulator; this is not release-mode performance evidence. Physical touch behavior and platform file durability still require later device checks. The first-install path validates before pointer commit, but complete multi-version rollback remains intentionally unimplemented.

Phase 4 may add the independent personal database, versioned migration chain, `UserRepository`, idempotent favorites, handbook collection marks, notes with retained drafts on failure, orphan-compatible name snapshots, and focused tests. It must not add cross-database foreign keys, rebuild or delete `user.db` on migration failure, modify the Catalog package, or start Phase 5 update recovery work.
