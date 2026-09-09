# Independent Catalog updates

## Current state

Phase 7 inception is complete, but independent updates are not implemented or enabled. The installed App still uses only a Catalog bundled with an App release and performs no runtime network request.

## Planned first capability

The first Phase 7 delivery will support a complete immutable Catalog database package. Its signed manifest must identify the dataset, protocol, Catalog schema, target data version, monotonic release sequence, minimum compatible App, package URL, byte length, SHA-256, signing key, and signature. Exact field names and signed-byte encoding will be frozen with offline conformance fixtures before any transport is added.

The App will authenticate metadata, enforce compatibility and anti-replay rules, download only from an approved HTTPS host, verify the package, and pass it to the existing Catalog installer. The installer remains the only owner of staging, database validation, activation, rollback, retention, recovery, and personal-database isolation.

## Failure behavior

- An unreachable host or interrupted transfer keeps the active Catalog and remains retryable.
- Invalid signatures, hashes, lengths, datasets, schemas, versions, sequences, or redirects fail closed before activation.
- A candidate database must still pass metadata, object, integrity, foreign-key, and probe validation.
- A failed activation restores the previous validated pointer.
- No update path writes, migrates, deletes, uploads, or synchronizes `user.db`.
- A bundled Catalog cannot silently downgrade a newer compatible installed Catalog.

## Decisions required before network activation

- Static hosting provider and exact allowed hostnames
- Redirect policy and availability expectations
- Manifest signature algorithm, public-key set, private-key custody, rotation, revocation, and replay policy
- Foreground check/download UX, user consent, retry limits, and metered-network behavior
- Intended distribution channels and current iOS and Android policy evidence
- Production-like interruption, corruption, low-storage, rollback, and device test matrix

GitHub Releases is a possible public static-hosting option for this public repository, but it is not selected and no Release will be created without explicit authorization. No background download, automatic installation, logical patching, or arbitrary endpoint configuration is currently planned for the first implementation slice.

## Deferred logical patches

Logical incremental patches remain a later Phase 7 decision. They require complete table and relationship coverage, canonical logical digests, exact base-version matching, field-clear semantics, provenance updates, reference validation, deterministic test vectors, and a full-package fallback. They must not execute downloaded SQL or mutate the active read-only database in place.
