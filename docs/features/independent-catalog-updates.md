# Independent Catalog updates

## Current state

Phase 7 now has an offline signed-manifest validator, but independent updates are not enabled. The installed App still uses only a Catalog bundled with an App release, performs no runtime network request, and has no production host or trust key.

## Planned first capability

The first Phase 7 delivery targets a complete immutable Catalog database package. ADR-0011 freezes its strict envelope, canonical signed payload, Ed25519 authentication, public-key sequence ranges, dataset and compatibility fields, monotonic release sequence, exact-host HTTPS URL, byte length, and SHA-256. Offline conformance fixtures and negative tests now cover that metadata boundary.

A future update client will authenticate metadata, enforce compatibility and anti-replay rules, download only from an approved HTTPS host, verify the archive, and pass its validated Catalog to the existing installer. The installer remains the only owner of staging, database validation, activation, rollback, retention, recovery, and personal-database isolation. The current validator is not connected to startup, Settings, transport, archive extraction, or the installer.

## Frozen offline manifest boundary

- The Ed25519 signature covers the exact canonical UTF-8 payload before semantic parsing.
- The App supplies a public-only trust store and an independently owned validation context; no private key is accepted.
- Both data version and release sequence must advance, and the key must cover the release sequence.
- Package URLs must use HTTPS, match the exact supplied host allowlist, use the standard port, and contain no credentials, query, fragment, or traversal segment.
- The package descriptor supports only a complete ZIP and binds its maximum size, exact byte length, and lowercase SHA-256.
- The fixture package proves only byte identity. ZIP safety, Catalog contents, installation, and persisted anti-replay state remain later ownership boundaries.

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
- Production public-key set, private-key custody, rotation, revocation, and persisted replay-state ownership
- Foreground check/download UX, user consent, retry limits, and metered-network behavior
- Intended distribution channels and current iOS and Android policy evidence
- Production-like interruption, corruption, low-storage, rollback, and device test matrix

GitHub Releases is a possible public static-hosting option for this public repository, but it is not selected and no Release will be created without explicit authorization. No background download, automatic installation, logical patching, or arbitrary endpoint configuration is currently planned for the first implementation slice.

## Deferred logical patches

Logical incremental patches remain a later Phase 7 decision. They require complete table and relationship coverage, canonical logical digests, exact base-version matching, field-clear semantics, provenance updates, reference validation, deterministic test vectors, and a full-package fallback. They must not execute downloaded SQL or mutate the active read-only database in place.
