# ADR-0014: Phase 7 temporary closure and live-update deferral

- Status: accepted
- Date: 2026-09-10
- Waiver ID: `PHASE7-LIVE-CATALOG-001`
- Scope: Phase 7 sequencing and deferred production evidence

## Context

Phase 7 gates 1 through 4 delivered the authenticated complete-Catalog package, external signing boundary, bounded GitHub Releases transport, and explicit foreground Settings flow. Local validation and hosted Ubuntu CI pass. Gate 5 still requires a genuine newer Catalog and production-like delivery measurements before logical patches can be considered.

No validated Catalog data version greater than 1 exists. Creating a duplicate or synthetic data version 2 would produce false release evidence and would violate the immutable release boundary. On 2026-09-10, the repository owner directed the project to close Phase 7 temporarily because an upstream game update is expected in approximately two days, when a real changed dataset can support the deferred update test.

## Decision

Phase 7 is closed for current project sequencing under waiver `PHASE7-LIVE-CATALOG-001`. The implemented complete-Catalog capability remains enabled and covered by local and hosted tests. Closure does not convert any missing live, device, signing, or store result into a pass.

The deferred test must begin from a genuinely changed, explicitly authorized upstream snapshot. It must inspect and review the source delta, preserve stable identities, build a new immutable Catalog data version, package and sign it outside the repository, publish only validated assets to the approved GitHub Releases paths, and exercise the foreground V1-to-new-version flow without modifying `user.db`.

For this reopening boundary, an "incremental test" means testing a real increment in Catalog data between two versions while delivery still uses the implemented complete-Catalog ZIP. It does not authorize or claim a logical row-level patch protocol. Logical patches remain disabled until complete-package measurements justify them and a separate decision accepts their digest, base-version, field-clear, provenance, fallback, and failure contracts.

The following remain unchanged:

- no synthetic, duplicate, or empty release may stand in for a real upstream change;
- the private signing key remains outside the repository under its accepted custody model;
- no background update, arbitrary endpoint, runtime BWIKI access, account, cloud sync, or `user.db` network path is introduced;
- no physical-device result, App signing, store upload, or publication result is inferred; and
- the Chinese baseline specification remains unchanged.

## Deferred evidence

- A real immutable Catalog data version greater than 1
- A signed package and discovery asset published under the exact approved GitHub Release tags
- Foreground download, hash, archive, SQLite, attribution, replay, activation, and rollback evidence against the real package
- Production-host interruption, low-storage, regional availability, and metered-network observations
- Physical Android and iOS update behavior, unless separately waived at that future boundary
- Any evidence required before deciding whether logical patches are justified

## Consequences

The repository may report Phase 7 as temporarily closed under an explicit evidence deferral, but not as fully live-validated. Reopening must use the real changed dataset and the existing complete-package protocol first. Any later request for logical patch delivery or App Store differential behavior requires its own scope and evidence.
