# Independent Catalog updates

## Current state

Phase 7 now has an offline complete-ZIP publisher, signed-manifest generator, production public trust key, validator, and strict installation pipeline, but independent updates are not enabled. The installed App still performs no runtime network request and has no production host, discovery trigger, or download UI.

## Planned first capability

The first Phase 7 delivery targets a complete immutable Catalog database package. ADR-0011 freezes its strict envelope, canonical signed payload, Ed25519 authentication, public-key sequence ranges, dataset and compatibility fields, monotonic release sequence, exact-host HTTPS URL, byte length, and SHA-256. Offline conformance fixtures and negative tests now cover that metadata boundary.

A future update client will fetch only from an approved HTTPS host and pass the received bytes into the existing offline pipeline. That pipeline already authenticates metadata, enforces compatibility and anti-replay rules, validates the exact ZIP and inner Catalog, and hands the candidate to the existing installer. The installer remains the only owner of staging, database validation, activation, rollback, retention, recovery, and personal-database isolation. It now also keeps version-specific attribution and a separate monotonic remote release-sequence high-water mark.

The publisher can already turn a validated immutable Catalog release into the exact three-entry ZIP accepted by the App. It reruns release validation, is reproducible for the same toolchain and input, verifies its own output, reports the bytes and SHA-256 required by the signed payload, and refuses overwrite. A separate canonical-payload command binds an approved future URL and release metadata to those bytes. The external signing tool uses the Desktop-held production key and self-verifies the public envelope; publication remains separate so this repository never becomes a private-key store. The custody evidence records that this Desktop is currently synchronized to iCloud, which requires an explicit acceptance or replacement decision before real release signing.

## Frozen offline manifest boundary

- The Ed25519 signature covers the exact canonical UTF-8 payload before semantic parsing.
- The App supplies a public-only trust store and an independently owned validation context; no private key is accepted.
- Both data version and release sequence must advance, and the key must cover the release sequence.
- Package URLs must use HTTPS, match the exact supplied host allowlist, use the standard port, and contain no credentials, query, fragment, or traversal segment.
- The package descriptor supports only a complete ZIP and binds its maximum size, exact byte length, and lowercase SHA-256.
- A complete package contains exactly the existing bundled manifest, database, and attribution asset paths. ZIP structure, actual decompressed output, CRC, inner-to-outer identity, SQLite validity, installation, attribution rollback, and persisted anti-replay state are covered offline.

The pipeline is not called by production bootstrap or Settings. No update check, network request, archive download, automatic installation, or background task exists.

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
- Production public-key set, private-key custody, rotation, and revocation operations
- Foreground check/download UX, user consent, retry limits, and metered-network behavior
- Intended distribution channels and current iOS and Android policy evidence
- Production-like interruption, corruption, low-storage, rollback, and device test matrix

GitHub Releases is a possible public static-hosting option for this public repository, but it is not selected and no Release will be created without explicit authorization. No background download, automatic installation, logical patching, or arbitrary endpoint configuration is currently planned for the first implementation slice.

## Deferred logical patches

Logical incremental patches remain a later Phase 7 decision. They require complete table and relationship coverage, canonical logical digests, exact base-version matching, field-clear semantics, provenance updates, reference validation, deterministic test vectors, and a full-package fallback. They must not execute downloaded SQL or mutate the active read-only database in place.
