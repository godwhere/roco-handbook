# Phase 7 implementation report

- Status: offline signed-manifest foundation complete; transport and installation not started
- Date: 2026-09-09
- Workspace: `/Users/ethan/Documents/ChatGPT/roco-handbook`

## Declared boundary

This implementation slice was limited to the remote-manifest contract, a pure-Dart verifier, offline fixtures and tests, the one required cryptographic dependency, runtime license inventory, and mapped Phase 7 documentation. It did not modify platform manifests, Catalog or User schemas, databases, release artifacts, CI, signing configuration, installer behavior, or network behavior.

## Changes

- Kept ADR-0010 as the Phase 7 authorization boundary and added ADR-0011 for the strict V1 envelope, canonical payload, Ed25519 signature, public-key ranges, compatibility, anti-replay, host, size, and hash rules.
- Added three JSON schemas and three public-only conformance fixtures for the trust store, signed envelope, and payload. The fixture private key was never persisted.
- Added `RemoteCatalogManifestVerifier` with actual Ed25519 verification before semantic parsing and fail-closed validation of every frozen field.
- Added ten focused tests covering the valid fixture, package identity, tampering, unknown keys, extensions, replay, version and host policy, key ranges, canonical encoding, impossible dates, and malformed trust keys.
- Added and locked `cryptography 2.9.0` without adding a platform plugin or upgrading unrelated packages; updated the Apache-2.0 runtime notice inventory.
- Updated README, the independent-update feature contract, Phase 7 evidence, and this report without claiming runtime update capability.

## Verification performed

```text
PYTHONDONTWRITEBYTECODE=1 PYTHONPATH=tools python3 -m unittest discover -s tests -p 'test_*.py'
Result: 71 tests passed.

cd app && dart format --output=none --set-exit-if-changed lib test
Result: passed; no files changed.

cd app && flutter analyze --no-pub
Result: no issues found.

cd app && flutter test --no-pub
Result: 54 tests passed, including 10 focused signed-manifest tests.

PYTHONDONTWRITEBYTECODE=1 PYTHONPATH=tools python3 tools/release/check_catalog.py --release data/release/1
Result: passed; Catalog identity, schema, integrity, foreign keys, coverage, attribution, and stable probes matched.

git diff --check
Result: passed.
```

## Not run

- Network retrieval of a remote manifest or package
- Network checks, downloads, redirects, retries, resumable transfer, or metered-network behavior
- Hosting selection, remote resource creation, upload, or availability validation
- Production signing-key generation, custody, rotation, revocation, or secret configuration
- ZIP parsing, archive safety, Catalog extraction, installer handoff, activation, rollback, retention, or persisted release-sequence storage
- App installation, physical-device testing, store-policy review, submission, or publication
- Logical incremental patch generation, application, measurement, or fallback

## Remaining risks and next boundary

The protocol and offline publisher-authentication boundary are now executable, but network activation remains unsafe until the user approves the concrete host, domain and redirect policy, foreground download behavior, and production key custody. The next allowed boundary is an offline archive-validation and installer-handoff contract, or the pending hosting and key-custody decision before transport work. Neither boundary authorizes network access on its own.

The Chinese baseline specification was not edited. ADR-0010 records the Phase 7 scope, and ADR-0011 records the English protocol and trust decision required by the documentation map.
