# Phase 6 implementation report

- Status: complete with explicit physical-device-test waiver; device evidence remains not run
- Date: 2026-09-09
- Workspace: `/Users/ethan/Documents/ChatGPT/roco-handbook`

## Declared boundary

Phase 6 work was limited to release metadata, an offline Catalog release gate, read-only CI, required platform release configuration, permission and license review, local unsigned platform candidates, versioned audit material, tests, and mapped documentation. It did not install to a physical device, configure a personal signing team, store signing credentials, export a store archive, upload or publish an App, change repository visibility, add runtime networking, create a service, or alter system networking.

## Changes

- Locked App version 1.0.0 and build 1 in Flutter metadata and visible Settings copy, with a repository regression that rejects version divergence.
- Added **Open-source licenses** in Settings through Flutter's packaged license registry and a Widget regression for the version and license route.
- Removed Android's default release fallback to the debug signing key. Release signing is now intentionally external and absent from the repository.
- Added the standard-library-only `tools/release/check_catalog.py` gate and six negative regression cases for release sidecars, placeholders, required coverage, blockers, unreviewed removals, and hash substitution.
- Added a two-job GitHub Actions workflow for offline Python and Flutter validation. Actions are pinned by full commit SHA, permissions are read-only, and no BWIKI, secret, signing, or store step exists.
- Added full Catalog data attribution boundaries and a resolved runtime software-license inventory.
- Built and audited an unsigned Android AAB and a no-codesign iOS App, verified version and permission metadata, confirmed packaged license notices, and matched each embedded Catalog to the immutable Release 1 database hash.
- Added the tracked candidate manifest, deterministic Catalog check report, release notes, known limitations, ADR-0008, release-readiness feature contract, evidence, this report, and current-state README updates.
- Recorded the user-authorized Phase 6 device-test waiver in ADR-0009, README, release readiness, evidence, the candidate manifest, release notes, known limitations, and its regression test. The waiver does not convert unrun device checks into passes.

## Verification performed

```text
PYTHONDONTWRITEBYTECODE=1 PYTHONPATH=tools python3 -m unittest discover -s tests -p 'test_*.py'
Result: 70 tests passed.

PYTHONDONTWRITEBYTECODE=1 PYTHONPATH=tools python3 tools/release/check_catalog.py --release data/release/1
Result: passed; Catalog bytes, SHA-256, 10 source revisions, schema, counts, integrity, foreign keys, coverage, and attribution matched.

cd app && dart format --output=none --set-exit-if-changed lib test
Result: passed.

cd app && flutter analyze --no-pub
Result: no issues found.

cd app && flutter test --no-pub
Result: 44 tests passed.

cd app && flutter build appbundle --release
Result: 57,492,013-byte AAB built; SHA-256 f9316e510b7d18849b54599f6a30d8265ba63cc2d5c2d2f32d4401f4c701bebb; unsigned.

cd app && COPYFILE_DISABLE=1 flutter build ios --release --no-codesign
Result: 22,331,299 regular-file bytes built; content-tree SHA-256 b6fa812e5e7676cc8fdc80e43c2a1fb7d5a29ed3326ae49b5986431fcfb5996e; not code-signed.

Release manifest and package inspection
Result: both platform candidates contain the exact Catalog Release 1 hash and Flutter notices; Android has no Internet or sensitive permission; iOS has no protected-resource usage-description key.

Workflow parse and contract review
Result: valid YAML mapping with two jobs, three current action releases pinned by full SHA, disabled checkout credential persistence, read-only contents permission, no secrets, and no BWIKI step.

GitHub Actions run 34352830184 at d3a5f6a
Result: Catalog and release contracts passed; Flutter contracts passed; every reported step completed successfully.

Read-only physical-device and signing preflight
Result: the paired iPhone was available, the target bundle ID was not installed, one valid host code-signing identity existed, and the tracked Xcode Release configuration had no resolved development team. No device, App, keychain item, or project signing setting was changed.
```

## Not run

- Physical Android or iOS installation, offline launch, update, recovery, interruption, and personal-data preservation
- Actual physical-device storage exhaustion
- Signed release build, Android upload signing, iOS archive/export, or platform credential validation
- Store-managed upgrade, upload, review, or publication

## Closure and next boundary

The local candidate, traceability, permission review, license review, and build materials are complete. Physical Android and iOS validation remains unrun. On 2026-09-09, the user explicitly waived that baseline stopping condition for Phase 6 project sequencing; ADR-0009 and candidate waiver `PHASE6-PHYSICAL-DEVICE-001` preserve the deviation and its risk without claiming a pass.

Phase 7 may begin only under a new explicit scope. Runtime downloads, remote hosting, package signing, platform policy conclusions, store upload, and publication are not authorized by the Phase 6 waiver or by beginning Phase 7. Physical-device acceptance remains a future release boundary if the project later seeks a store-readiness claim.

The Chinese baseline specification was not edited. ADR-0008 records the release-candidate boundary, and ADR-0009 records the later Phase 6 waiver required by the project documentation map.
