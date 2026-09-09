# Phase 7 implementation report

- Status: temporarily closed under `PHASE7-LIVE-CATALOG-001`; foreground complete-Catalog runtime implemented, live newer Release evidence deferred
- Date: 2026-09-10
- Workspace: `/Users/ethan/Documents/ChatGPT/roco-handbook`

## Declared boundary

Phase 7 implements optional independent delivery of complete immutable Catalog databases. It includes the signed manifest, public trust store, external signing ceremony, strict ZIP and SQLite validation, existing-installer activation and rollback, exact GitHub Releases transport, Settings-only consent and progress, cancellation before installation, version-specific attribution, and monotonic replay state.

It does not implement App binary self-update, App Store differential delivery, runtime BWIKI access, background work, automatic retry, arbitrary endpoints, logical Catalog patches, accounts, cloud synchronization, or any network path for `user.db`. Private key material remains outside the repository and App. No real Release is created until a validated Catalog data version greater than 1 exists.

## Temporary closure

On 2026-09-10, the repository owner directed Phase 7 to close temporarily because a genuine upstream game update is expected in approximately two days. ADR-0014 records waiver `PHASE7-LIVE-CATALOG-001`. The waiver closes current sequencing without claiming the still-missing real Release, GitHub CDN transfer, production fault, or device evidence.

The future data-change test must start from a real changed source snapshot and use the implemented complete-Catalog replacement protocol. It must not create a duplicate or synthetic data version merely to close the evidence gap. Logical row-level patches remain disabled and require a separate accepted protocol if later requested.

## Completed foundation

- ADR-0010 froze Phase 7's ordered gates and invariants.
- ADR-0011 froze the strict canonical envelope, Ed25519 publisher authentication, public-key sequence ranges, compatibility, host, size, and hash rules.
- The production public key `catalog-prod-2026-01` is bundled. The externally held private key is owner-only and excluded from the repository; the repository owner accepted its confirmed iCloud Desktop synchronization model.
- The publisher builds a reproducible complete ZIP containing only the bundled manifest, database, and attribution, then builds a canonical unsigned payload and signs it with the external tool.
- ADR-0012 and the runtime pipeline strictly validate the ZIP container, decompressed output, inner Catalog identity, SQLite contents, attribution, activation, rollback, retention, and replay high-water state.
- Pointer version 2 binds Catalog and attribution files. Legacy pointers migrate safely, damaged active pairs recover the prior validated pair, and database or attribution symlinks are rejected.

## Runtime transport and UI

- ADR-0013 selects public GitHub Releases. Discovery is fixed to `catalog-channel/catalog-manifest.json`; data version `N` must use immutable package path `catalog-data-vN/catalog-vN.zip` in `godwhere/roco-handbook`.
- The Python publisher now rejects every package URL that does not match the exact GitHub repository, versioned tag, filename, and Catalog data version.
- The pure-Dart transport disables automatic redirect following and decompression. It accepts a direct `200` or one `302` to the exact HTTPS `release-assets.githubusercontent.com/github-production-release-asset/` boundary, then rejects every further redirect.
- Discovery and package bodies are streamed through independent header and actual-byte bounds with finite connection, response, and idle timeouts. Package length and SHA-256 must match the authenticated manifest.
- A missing discovery asset reports no published update. A fully validated signed manifest matching both installed data version and replay sequence reports the Catalog as current; stale cross-version or cross-sequence combinations remain errors.
- Settings is the only trigger. It states that there is no background behavior, authenticates the manifest before presenting an update, shows the data version and complete transfer size, requires **Download**, reports progress, permits cancellation during transfer, removes cancellation during verification and installation, and leaves retry explicit.
- Successful installation refreshes the Catalog session and Catalog-backed page state while retaining the existing personal repository. Recovery is disabled while an update operation is active.
- Android production source adds only Internet access. iOS uses standard HTTPS with no protected-resource usage description or App Transport Security exception. No background-update dependency or platform task was added.
- The current source advances to App version `1.1.0`, build `2`; the immutable Phase 6 candidate remains `1.0.0`, build `1` with its original records and hashes.

## Changed files in this runtime delivery

- Runtime: `app/lib/data/catalog/catalog_update_source.dart`, `app/lib/data/catalog/catalog_update_service.dart`, `app/lib/data/catalog/remote_catalog_manifest.dart`, `app/lib/catalog_app.dart`, `app/lib/features/catalog/catalog_home_page.dart`, `app/lib/features/settings/settings_page.dart`, and `app/lib/main.dart`
- Platform and version identity: `app/android/app/src/main/AndroidManifest.xml`, `app/lib/app_version.dart`, and `app/pubspec.yaml`
- Publisher: `tools/catalog_builder/update_package_writer.py`
- Tests: `app/test/data/catalog_update_source_test.dart`, `app/test/data/catalog_update_service_test.dart`, `app/test/data/remote_catalog_manifest_test.dart`, `app/test/features/catalog_flow_test.dart`, `tests/builder/test_update_package_writer.py`, `tests/release/test_candidate_manifest.py`, and `tests/test_project_structure.py`
- Decisions, evidence, and current-state documentation: ADR-0010 through ADR-0014, the Phase 7 hosting, transport, hosted-CI, and live-update-deferral evidence files, the independent-update, recovery, browser, and release-readiness feature documents, the root and App READMEs, and this report
- Hosted-CI compatibility follow-up: `app/test/tool/catalog_signing_test.dart` now establishes the required owner-only temporary-directory fixture on macOS and Linux without weakening the production signing checks; the root README includes the public workflow badge

The Chinese baseline specification was not edited. ADR-0013 is the required English decision record for the accepted runtime architecture, host, lifecycle, permissions, and validation criteria.

## Verification performed

```text
PYTHONDONTWRITEBYTECODE=1 PYTHONPATH=tools python3 -m unittest discover -s tests -p 'test_*.py'
Result: 78 tests passed.

cd app && dart format --output=none --set-exit-if-changed lib test tool
Result: 33 files checked; no changes required.

cd app && flutter analyze --no-pub
Result: no issues found.

cd app && flutter test --no-pub
Result: 88 tests passed.

PYTHONDONTWRITEBYTECODE=1 PYTHONPATH=tools python3 tools/release/check_catalog.py --release data/release/1
Result: passed; integrity check was `ok`, foreign-key violations were zero, and all required tables and views were present.

Production Catalog source probe against the fixed GitHub discovery URL
Result: `current_or_unpublished`; no token or remote mutation was used.

GitHub Actions run 34384152396 at d88e5e7
Result: passed; both `Catalog and release contracts` and `Flutter contracts` completed successfully on Ubuntu. The preceding failed run and the Linux-only test-fixture correction are recorded in `docs/evidence/phase-7-hosted-ci-2026-09-10.md`.

cd app && flutter build appbundle --release
Result: passed; 59.0 MB AAB; SHA-256 `435179c42a114ffd98efa8f2b3b41c4dbb4f7ea29e72210975cae745e35f9ccb`.

cd app && flutter build apk --release
Result: passed; 60.4 MB unsigned APK; SHA-256 `037945fb7837fd873f5103d8b022ee5f3c3c9f7fbd577017244151bc61496503`.

Android merged-manifest inspection
Result: package `world.roco.roco_handbook`, version `1.1.0` code `2`, Internet permission, and AndroidX application-signature permission only.

cd app && flutter build ios --release --no-codesign
Result: passed; 22.9 MB App; embedded version `1.1.0` build `2`; Dart App framework SHA-256 `0a1abc35b77f1e8c4332e67590400703eced126aca99ec6e705953da2b7e9fee`.

git diff --check
Result: passed.

shasum -a 256 docs/technical-spec-v1.md
Result: `343618b414b7b8d6262dd58f82010bfefb2f3fdb29711a9e86428e042dd81876`; the provenance baseline is unchanged.
```

Generated Android and iOS products remain ignored and untracked. Dependency resolution reported newer incompatible package versions but changed neither declared dependency constraints nor the lockfile.

## Not run

- Creation, signing, upload, or publication of a real Catalog data version greater than 1
- Download, hash, archive validation, and activation of a real package through GitHub's Release CDN
- Production-host interruption, regional availability, metered-network throttling, and low-storage behavior during a real transfer
- Physical Android or iOS installation and update behavior; the Phase 6 waiver remains a sequencing decision, not test evidence
- App signing, store archive/export, upload, review, or publication
- Key rotation, revocation delivery, encrypted offline backup, or loss-recovery drill
- Logical incremental patch generation, application, measurement, or fallback

## Remaining risks and next boundary

The runtime capability is implemented and locally verified at its available boundaries, and the empty production channel fails safely. Phase 7 is temporarily closed under ADR-0014, with the missing live-package matrix deferred rather than passed. Its next meaningful evidence requires a real validated Catalog data version greater than 1. That release must be built outside the repository, signed with the accepted external key, uploaded under the exact immutable package tag, checked through the foreground client, and then exercised for interruption, low storage, rollback, and platform behavior. Logical patch work remains deferred until complete-package evidence demonstrates a material need and a separate protocol is accepted.
