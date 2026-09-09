# Phase 7 implementation report

- Status: offline complete-package and production signing foundation complete; runtime transport not started
- Date: 2026-09-10
- Workspace: `/Users/ethan/Documents/ChatGPT/roco-handbook`

## Declared boundary

Phase 7 work is limited to the remote-manifest contract, validated publisher-side complete-ZIP and canonical-payload construction, external signing-key custody, public App trust configuration, strict in-memory ZIP validation, existing-installer handoff, Catalog-owned attribution and replay state, offline fixtures and tests, required dependencies, runtime license inventory, the formatting gate for the new signing tool, and mapped documentation. It does not modify platform manifests, Catalog or User schemas, tracked release artifacts, `user.db`, or network behavior. Private key material remains outside the repository and App.

## Changes

- Kept ADR-0010 as the Phase 7 authorization boundary and added ADR-0011 for the strict V1 envelope, canonical payload, Ed25519 signature, public-key ranges, compatibility, anti-replay, host, size, and hash rules.
- Added three JSON schemas and three public-only conformance fixtures for the trust store, signed envelope, and payload. The fixture private key was never persisted.
- Added `RemoteCatalogManifestVerifier` with actual Ed25519 verification before semantic parsing and fail-closed validation of every frozen field.
- Added focused tests covering the valid fixture, package identity, tampering, unknown keys, extensions, replay, version and host policy, key ranges including overlap rejection, canonical encoding, impossible dates, and malformed trust keys.
- Added and locked `cryptography 2.9.0` without adding a platform plugin or upgrading unrelated packages; updated the Apache-2.0 runtime notice inventory.
- Updated README, the independent-update feature contract, Phase 7 evidence, and this report without claiming runtime update capability.
- Added ADR-0012 and a strict complete-ZIP decoder that accepts only the three existing Catalog asset paths, rejects ambiguous or unsafe ZIP structures, bounds actual decompression output, verifies CRC, and matches the inner Catalog contract to the signed payload.
- Added an offline pipeline that performs signature verification, ZIP validation, SQLite validation, and installation in order without a runtime network source.
- Extended the existing installer instead of adding another activation authority. Remote candidates require a valid base and newer data version, then reuse staging, full database validation, pointer activation, rollback, retention, and `user.db` isolation.
- Added pointer version 2 with per-Catalog attribution length and hash. The App now returns attribution from the active Catalog artifact, migrates older pointers, rolls back damaged attribution, and refuses database or attribution symlinks.
- Added independent monotonic replay state. It advances only after candidate validation, remains advanced across rollback or bundled recovery, and fails closed if malformed.
- Added and locked `archive 4.2.0` plus transitive `posix 6.5.2`; both are recorded under MIT and no unrelated dependency was upgraded.
- Added focused archive, end-to-end pipeline, replay, attribution, migration, and symlink regressions, including safe repair of dangling canonical database and attribution links.
- Recorded current official GitHub Release constraints, the proposed exact redirect boundary, and Apple and Google store-policy risks without selecting a host or enabling runtime networking.
- Added an offline `build-complete-update` publisher command. It reruns the complete release gate, writes only the three accepted entries with fixed metadata, validates its output, reports signed-payload length and hash inputs, rejects direct or linked repository output paths, refuses overwrite, and performs no signing or publication.
- Added `build-update-payload` to validate the archive against its release and produce canonical unsigned metadata for an explicitly supplied future HTTPS URL, release sequence, App version, and UTC publication time.
- Added a fail-closed signing tool and generated `catalog-prod-2026-01` after explicit Desktop-custody authorization. The private key is an owner-only file outside the repository; resolved-path checks also prevent link-based re-entry into the repository, and only the public trust store is bundled. A production-key proof envelope passed the production verifier without signing or publishing a real release.
- Verified read-only that macOS iCloud Desktop synchronization is enabled and that the cloud-visible private key is byte-identical with mode `0600`. The documentation now treats custody as synchronized and leaves acceptance or replacement for explicit authorization; no sync setting or key file was changed.
- Extended the existing CI formatting gate to include the new `app/tool/` source; CI remains credential-free and offline.

## Changed files in this delivery

- Runtime and contracts: `app/lib/data/catalog/remote_catalog_archive.dart`, `app/lib/data/catalog/remote_catalog_manifest.dart`, `app/lib/data/catalog/catalog_installer.dart`, `app/lib/catalog_app.dart`, `app/lib/features/settings/settings_page.dart`, and `app/assets/catalog/catalog_trust_store.json`
- Dependencies and notices: `app/pubspec.yaml`, `app/pubspec.lock`, and `licenses/THIRD_PARTY_NOTICES.md`
- Publisher tooling and regression coverage: `tools/catalog_builder/update_package_writer.py`, `tools/catalog_builder/cli.py`, `app/tool/catalog_signing.dart`, `tests/builder/test_update_package_writer.py`, `app/test/tool/catalog_signing_test.dart`, `app/test/data/remote_catalog_archive_test.dart`, `app/test/data/catalog_installer_test.dart`, `tests/test_project_structure.py`, `.github/workflows/offline-validation.yml`, and `.gitignore`
- Decisions, evidence, and current-state documentation: `docs/decisions/ADR-0010-phase-7-inception.md`, `docs/decisions/ADR-0011-phase-7-signed-manifest-contract.md`, `docs/decisions/ADR-0012-phase-7-offline-package-installation.md`, `docs/evidence/phase-7-offline-package-2026-09-09.md`, `docs/evidence/phase-7-hosting-policy-2026-09-09.md`, `docs/evidence/phase-7-signing-custody-2026-09-09.md`, `docs/features/independent-catalog-updates.md`, `docs/features/catalog-update-and-recovery.md`, `docs/features/offline-catalog-browser.md`, `docs/implementation-reports/phase-7.md`, `README.md`, and `app/README.md`

## Verification performed

```text
PYTHONDONTWRITEBYTECODE=1 PYTHONPATH=tools python3 -m unittest discover -s tests -p 'test_*.py'
Result: 77 tests passed.

cd app && dart format --output=none --set-exit-if-changed lib test tool
Result: 29 files checked; no changes required.

cd app && flutter analyze --no-pub
Result: no issues found.

cd app && flutter test --no-pub
Result: 73 tests passed.

PYTHONDONTWRITEBYTECODE=1 PYTHONPATH=tools python3 tools/release/check_catalog.py --release data/release/1
Result: passed; integrity check was `ok`, foreign-key violations were zero, and all required tables and views were present.

git diff --check
Result: passed.

shasum -a 256 docs/technical-spec-v1.md
Result: `343618b414b7b8d6262dd58f82010bfefb2f3fdb29711a9e86428e042dd81876`; the provenance baseline is unchanged.
```

## Not run

- Network retrieval of a remote manifest or package
- Network checks, downloads, redirects, retries, resumable transfer, or metered-network behavior
- Hosting selection, remote resource creation, upload, or availability validation
- Acceptance of the confirmed iCloud-synchronized Desktop custody model, an encrypted private-key backup, hardware-backed custody, key-rotation drill, revocation delivery, or loss recovery
- Signing or publishing a real production Catalog payload
- App installation, physical-device testing, store-policy review, submission, or publication
- Logical incremental patch generation, application, measurement, or fallback

## Remaining risks and next boundary

The complete-package protocol, publisher authentication, archive safety, installer handoff, attribution lifecycle, replay state, production public trust root, and external signing ceremony are now executable offline. Network activation remains unsafe until the user approves the concrete host, domain and redirect policy, and foreground download behavior. The next boundary is that hosting and UX decision, followed by a bounded foreground transport and current platform-policy evidence. No current decision authorizes network access.

The Chinese baseline specification was not edited. ADR-0010 records the Phase 7 scope, ADR-0011 records the manifest and trust contract, and ADR-0012 records the English archive, attribution, installer, and replay-state decisions required by the documentation map.
