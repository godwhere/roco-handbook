# ADR-0010: Phase 7 independent-update inception

- Status: accepted
- Date: 2026-09-09
- Scope: post-V1 independent Catalog updates

## Context

The user directed the project to begin optional Phase 7 after closing Phase 6. The baseline permits this work only as a new explicit scope and requires renewed decisions for hosting, authentication, protocol compatibility, download behavior, platform policy, rollback, and fault testing.

The current App is offline-only. It installs complete Catalog databases bundled with App releases, validates them before activation, retains a previous valid version, and keeps `user.db` independent. Phase 7 must reuse that validated staging and pointer lifecycle rather than introduce a second installation authority.

## Decision

Phase 7 proceeds in ordered gates:

1. Freeze the scope, trust model, and protocol contract using offline fixtures only.
2. Implement and test a signed complete-Catalog package path without activating network access.
3. Select an HTTPS host, exact domain and redirect policy, key custody and rotation plan, foreground download behavior, and target-store policy evidence.
4. Enable a user-authorized complete-package check and download only after the preceding gates pass.
5. Measure full-package behavior in production-like conditions before deciding whether logical incremental patches are justified.

The following invariants apply from the first Phase 7 change:

- Remote content may contain static Catalog data and metadata only; it must not contain Dart, Lua, dynamic libraries, arbitrary SQL, or executable instructions.
- SHA-256 validates bytes but does not authenticate their publisher. A trusted App-bundled public key must authenticate the signed manifest before any package can be installed.
- Private signing keys, credentials, cookies, personal data, proxy configuration, and platform signing material must never enter the repository or App.
- URLs must use HTTPS and match an explicit host and redirect allowlist. An arbitrary URL field or user-entered endpoint is not permitted.
- Every candidate installs through the existing staging, validation, pointer-switch, rollback, retention, and `user.db` isolation path.
- Unavailable, invalid, stale, replayed, incompatible, or interrupted updates leave the current Catalog usable.
- Complete Catalog packages come first. Logical patches remain disabled until full-package delivery has stable evidence and an independently accepted protocol.
- No remote service, repository release, DNS record, paid resource, App runtime network permission, background task, or signing key is created by this inception decision.

## Pending authorization and evidence

Implementation may continue with offline protocol fixtures and validators. Network activation stops until the user approves the concrete host, allowed domains, redirect behavior, download UX, and signing-key custody. Store-policy conclusions stop until the intended distribution channels and then-current rules are reviewed. Logical patch work stops until complete-package measurements demonstrate a real need.

## Consequences

Phase 7 is active, but no existing App behavior changes in this inception slice. The repository gains an explicit path for safe progress without treating a transport hash as publisher authentication, exposing a private key, or prematurely committing to hosting and incremental-update complexity.
