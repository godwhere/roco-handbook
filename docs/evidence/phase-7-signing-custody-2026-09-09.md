# Phase 7 production Catalog signing custody evidence

- Date: 2026-09-09
- Custody follow-up: 2026-09-10
- Authorization: the repository owner explicitly allowed the Catalog signing key to be kept on the Mac Desktop
- Key identifier: `catalog-prod-2026-01`
- Algorithm: Ed25519
- Accepted release-sequence range: 1 through unbounded
- Public-key SHA-256 fingerprint: `2c8d08ab11ce334d9aef54bf119b15156442d26209ab9f121aae1b828bce2eed`

## Custody boundary

The private key is outside the repository in `~/Desktop/RocoWorld-Catalog-Signing/`. The directory was verified as owner-only mode `0700`; `catalog-prod-2026-01.private.json` was verified as a regular non-link file with owner-only mode `0600`. A custody README records handling, backup, loss, compromise, and rotation rules.

A read-only follow-up check found Finder's `FXICloudDriveDesktop` preference set to `1`. The same custody directory and private-key filename are visible under `~/Library/Mobile Documents/com~apple~CloudDocs/Desktop/`; the visible cloud file is a regular non-link file with mode `0600` and is byte-identical to the Desktop file. The current key must therefore be treated as synchronized to iCloud, not as machine-local-only. No synchronization setting, key file, or cloud copy was changed by this check.

The repository contains only the corresponding public key in `app/assets/catalog/catalog_trust_store.json`. A root ignore rule rejects the generated `*.private.json` filename class. Repository tests parse the production trust store and assert that it contains no private-key field.

The signing tool resolves the custody path and refuses direct or link-based repository placement, refuses a private-key directory that is missing, directly linked, or accessible to group or other users, refuses linked or over-permissive private-key files, validates exact key fields and lengths, checks the private/public pair, enforces the key's release range, canonicalizes the payload, signs it, and runs the generated envelope through the production verifier before writing a no-overwrite public envelope.

## Proof performed

The production key signed the offline data-version-2 conformance payload. The signing tool then passed the resulting envelope through `RemoteCatalogManifestVerifier` using the matching production public key. The proof envelope was written only under `/tmp`; no production Catalog release, remote URL, or repository artifact was signed or published.

Separate automated tests generate ephemeral keys under an owned temporary directory, verify an accepted signature through the production verifier, and cover repository-path rejection, private-key link rejection, release-range rejection, overlapping Trust Store range rejection, public-only trust configuration, and output no-overwrite behavior.

## Residual custody risks

- The unencrypted private key is synchronized to iCloud Desktop. Before real release signing, the repository owner must explicitly accept that custody model or authorize replacement with a new key held in an approved non-synchronized location; merely moving the current file would not prove removal of cloud copies.
- No encrypted offline backup was created or verified.
- No compromise drill, key-rotation release, revocation delivery, or recovery from key loss was performed.
- The current trust range has no upper bound. Before rotation, an App release must cap this key and add a non-overlapping successor public key before the successor signs a Catalog release.
- The private key is an unencrypted local JSON secret protected by directory and file permissions. A stronger hardware-backed or encrypted custody process remains an optional later hardening decision.

No private key bytes, private-key hash, credential, token, cookie, or signing secret is recorded in this evidence.
