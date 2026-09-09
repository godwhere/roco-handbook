# Phase 5 implementation report

- Status: implementation and local acceptance complete; GitHub Desktop commit and push approved for this checkpoint
- Date: 2026-09-09
- Workspace: `/Users/ethan/Documents/ChatGPT/roco-handbook`

## Declared boundary

Phase 5 was limited to startup-only whole-Catalog selection and replacement, candidate staging and validation, active and previous records, post-activation rollback, bundled recovery, allowlisted retention cleanup, deterministic lifecycle fault tests, the Settings recovery entry, platform runtime evidence, and mapped documentation. It did not add runtime downloads, incremental patches, a remote package source, an account or cloud service, a Catalog schema change, a User schema migration, recursive application-support cleanup, or store publication.

## Changes

- Expanded `CatalogInstaller` with explicit bundled recovery and outcomes for reuse, installation, previous-version recovery, and user-requested restoration.
- Added an operating-system file lock so only one installer operation runs at a time before repositories and navigation are created.
- Replaced the minimal active pointer with complete validated artifact descriptors and an independent previous pointer, while retaining exact Phase 3 pointer compatibility.
- Added hash-qualified immutable Catalog filenames, strict basename derivation, same-version conflict rejection, and prevention of automatic downgrade from a newer compatible active version.
- Added staging validation, atomic active-pointer replacement, post-activation validation, previous-pointer rollback, and a bounded failure record.
- Added direct-child cleanup that recognizes only project-generated staging, pointer-temporary, and Catalog filenames and retains at most the active and one distinct previous database.
- Added a confirmed **Restore bundled Catalog** Settings flow that closes the current session, runs trusted local recovery, reopens the App session, and reports the last Catalog action.
- Made personal repository closure idempotent for safe session replacement.
- Added 10 installer lifecycle regressions beyond the existing four and one recovery Widget flow. The fixture proves added, modified, and retired Catalog records without creating a fake release artifact.
- Added ADR-0007, the Catalog update and recovery feature contract, Android/iOS evidence, two inspected screenshots, this report, README updates, and a correction to the current four-destination browser documentation.

## Verification performed

```text
cd app && flutter analyze
Result: no issues found.

cd app && flutter test
Result: 43 tests passed.

PYTHONDONTWRITEBYTECODE=1 PYTHONPATH=tools python3 -m unittest discover -s tests -p 'test_*.py'
Result: 58 tests passed.

cd app && flutter build apk --debug
Result: debug APK built successfully.

cd app && COPYFILE_DISABLE=1 flutter build ios --simulator --debug
Result: iOS simulator App built successfully.

Android API 36 emulator, airplane mode 1 and Wi-Fi 0
Result: in-place APK install migrated the legacy pointer; explicit confirmed bundled recovery succeeded; the existing User V1 database and its one favorite, one collection mark, and one note remained byte-for-byte unchanged.

iPhone 17 Pro simulator, iOS 26.5
Result: in-place App install migrated the legacy pointer after readiness; the existing User V1 database remained byte-for-byte unchanged and passed integrity_check.
```

```text
Final repository review
Result: tracked and untracked whitespace checks passed; the User V1 schema and all three bundled Catalog assets matched their normative or release copies byte-for-byte; both screenshot hashes matched this evidence report; the technical baseline SHA-256 remained 343618b414b7b8d6262dd58f82010bfefb2f3fdb29711a9e86428e042dd81876; the main Android manifest had no Internet permission; no personal database, private key, signing team, embedded secret, debug print, ignored build output, or unexpected artifact was found; and the complete Phase 5 diff was reviewed before the approved GitHub Desktop delivery.
```

## Not run

- Physical iOS or Android update and recovery
- Actual process kill during file or pointer operations
- Actual device storage exhaustion
- Distinct release Catalog data version 2 on a device
- iOS manual recovery UI flow
- Release signing, archives, uploads, or store publication

## Remaining risks and next boundary

Local fault injection cannot prove physical flash flush and rename durability, store-managed update behavior, or low-storage platform details. The currently bundled release remains Catalog data version 1; the version 2 used by tests is temporary and cannot be distributed.

Phase 6 may lock release metadata, add CI and release artifact gates, audit application permissions and packaged licenses, prepare unsigned release candidates, and collect physical-device offline and upgrade evidence. It must not upload or publish an App, change repository visibility, create paid services, or claim physical-device acceptance without the corresponding runs and authorization.
