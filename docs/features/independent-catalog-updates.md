# Independent Catalog updates

## Current state

Phase 7 now has a complete-ZIP publisher, signed-manifest generator, production public trust key, strict validator and installer, and an enabled user-triggered GitHub Releases transport. The App still starts entirely from its bundled Catalog and performs no automatic or background network request.

## Supported first capability

The first Phase 7 delivery targets a complete immutable Catalog database package. ADR-0011 freezes its strict envelope, canonical signed payload, Ed25519 authentication, public-key sequence ranges, dataset and compatibility fields, monotonic release sequence, exact-host HTTPS URL, byte length, and SHA-256. Offline conformance fixtures and negative tests now cover that metadata boundary.

The update client fetches only from the approved GitHub Releases URLs and passes the received bytes into the existing offline pipeline. That pipeline authenticates metadata, enforces compatibility and anti-replay rules, validates the exact ZIP and inner Catalog, and hands the candidate to the existing installer. The installer remains the only owner of staging, database validation, activation, rollback, retention, recovery, and personal-database isolation. It also keeps version-specific attribution and a separate monotonic remote release-sequence high-water mark.

The publisher turns a validated immutable Catalog release into the exact three-entry ZIP accepted by the App. It reruns release validation, is reproducible for the same toolchain and input, verifies its own output, reports the bytes and SHA-256 required by the signed payload, and refuses overwrite. The canonical-payload command requires the exact `catalog-data-vN/catalog-vN.zip` URL and binds release metadata to those bytes. The external signing tool uses the Desktop-held production key and self-verifies the public envelope; publication remains separate so this repository never becomes a private-key store. The repository owner explicitly accepted the confirmed iCloud Desktop synchronization model.

## Frozen manifest boundary

- The Ed25519 signature covers the exact canonical UTF-8 payload before semantic parsing.
- The App supplies a public-only trust store and an independently owned validation context; no private key is accepted.
- Both data version and release sequence must advance, and the key must cover the release sequence.
- Package URLs must use HTTPS, match the exact supplied host allowlist, use the standard port, and contain no credentials, query, fragment, or traversal segment.
- The package descriptor supports only a complete ZIP and binds its maximum size, exact byte length, and lowercase SHA-256.
- A complete package contains exactly the existing bundled manifest, database, and attribution asset paths. ZIP structure, actual decompressed output, CRC, inner-to-outer identity, SQLite validity, installation, attribution rollback, and persisted anti-replay state are covered offline.

Production bootstrap exposes the pipeline only to Settings. No update check, archive download, installation, or retry begins without the corresponding user action, and no background task exists.

## Discovery and transfer

The discovery asset is fixed at `https://github.com/godwhere/roco-handbook/releases/download/catalog-channel/catalog-manifest.json`. A complete package for data version `N` must be exactly `https://github.com/godwhere/roco-handbook/releases/download/catalog-data-vN/catalog-vN.zip`.

The client disables automatic redirects and accepts a direct `200` or exactly one `302` to the HTTPS `release-assets.githubusercontent.com` delivery host under `/github-production-release-asset/`. It rejects every other host, additional redirect, downgrade, nonstandard port, credentials, fragment, original-URL query, compressed response body, invalid declared length, excessive streamed bytes, timeout, cancellation, or final hash mismatch.

Settings shows the candidate data version and total complete-package size before asking the user to download over the current connection. During transfer it shows exact byte progress and a cancel action. Once verification and installation begin, cancellation is removed. Failures keep the prior Catalog and expose the same button for an explicit retry.

The current channel has no published manifest because no real Catalog data version greater than 1 exists. A missing discovery asset reports that the Catalog is current; it is not an installation failure.

## Failure behavior

- An unreachable host or interrupted transfer keeps the active Catalog and remains retryable.
- Invalid signatures, hashes, lengths, datasets, schemas, versions, sequences, or redirects fail closed before activation.
- A candidate database must still pass metadata, object, integrity, foreign-key, and probe validation.
- A failed activation restores the previous validated pointer.
- No update path writes, migrates, deletes, uploads, or synchronizes `user.db`.
- A bundled Catalog cannot silently downgrade a newer compatible installed Catalog.

## Accepted network boundary and remaining evidence

- GitHub Releases is the only V1 host; `github.com` is the initial host and `release-assets.githubusercontent.com` is the only redirect host.
- The production public key and accepted synchronized private-key custody are fixed; rotation, revocation delivery, and encrypted backup operations remain future work.
- The foreground check, size confirmation, progress, cancellation, no-automatic-retry, and current-network consent behavior are implemented.
- Platform policy must be reviewed again immediately before submission.
- A real package, production-host interruption, low-storage, rollback, regional availability, and physical-device matrix remain unrun.

No background download, automatic installation, logical patching, arbitrary endpoint configuration, App-binary replacement, or store self-update mechanism is part of this capability. App Store differential delivery, if applied by a store to an App binary, is a separate distribution mechanism and does not replace this Catalog protocol.

## Deferred logical patches

Logical incremental patches remain a later Phase 7 decision. They require complete table and relationship coverage, canonical logical digests, exact base-version matching, field-clear semantics, provenance updates, reference validation, deterministic test vectors, and a full-package fallback. They must not execute downloaded SQL or mutate the active read-only database in place.
