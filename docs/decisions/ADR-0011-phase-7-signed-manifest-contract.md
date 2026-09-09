# ADR-0011: Phase 7 signed complete-package manifest contract

- Status: accepted
- Date: 2026-09-09
- Custody follow-up: 2026-09-10
- Scope: offline authentication and validation of complete-Catalog package metadata

## Context

Phase 7 needs publisher authentication before any remote transport can be considered. A package SHA-256 proves byte identity only; it does not prove who published the bytes. The contract must also reject ambiguous encodings, incompatible data, replayed releases, unapproved hosts, and metadata that could bypass the existing Catalog installer.

This decision intentionally precedes network activation. The original offline fixture slice had no production host, key, downloader, or redirect path. The repository owner subsequently authorized Desktop key custody; the production public-key and signing-tool addendum below does not select a host or activate networking.

## Decision

The V1 remote manifest consists of a strict JSON envelope and a signed payload:

- The envelope contains exactly `envelope_version`, `payload_encoding`, `signature_algorithm`, `key_id`, `payload`, and `signature`.
- `envelope_version` is `1`, the payload is unpadded canonical Base64url, and the only supported signature algorithm is Ed25519.
- The signature authenticates the exact UTF-8 payload bytes before the payload is parsed or trusted.
- The payload is canonical JSON: object keys are recursively sorted, whitespace is absent, and JSON numbers must be integers. A signed but noncanonical representation is rejected.
- The payload contains exactly the protocol range, dataset, Catalog schema, target data version, monotonic release sequence, minimum App version, UTC publication time, source snapshot, complete coverage map, and complete ZIP package descriptor.
- The package descriptor contains only its fixed kind and format, HTTPS URL, byte length, and lowercase SHA-256. Runtime validation requires an exact caller-provided host allowlist, standard HTTPS port, no credentials, query, fragment, or traversal segment, and a `.zip` path.
- A caller-provided validation context must prove that the target data version and release sequence are both newer, the App and protocol are compatible, the Catalog schema matches, the signing key covers that release sequence, and the package is within the configured size limit.
- Package bytes must match both the authenticated length and SHA-256 before they can advance to archive or Catalog validation.

The App trust store contains one to eight public Ed25519 keys with unique identifiers and inclusive release-sequence ranges. It contains no private material. Key rotation is represented by non-overlapping operational ranges; the verifier itself fails closed on an unknown key or an out-of-range release.

Following explicit custody authorization, `catalog-prod-2026-01` is the first production Catalog key. Its public key is the sole entry in `app/assets/catalog/catalog_trust_store.json`, beginning at release sequence 1 with no current upper bound. The unencrypted private JSON is outside the repository under `~/Desktop/RocoWorld-Catalog-Signing/`, inside an owner-only directory with an owner-only file. A later read-only check confirmed that macOS iCloud Desktop synchronization is enabled and that this file is visible through the iCloud Desktop path. Before real release signing, the repository owner must either explicitly accept that synchronized custody model or authorize a replacement key in an approved non-synchronized location, and must separately decide whether to create an encrypted offline backup.

`app/tool/catalog_signing.dart` owns key generation and envelope signing. It refuses repository-local private keys, linked or over-permissive key files, invalid or out-of-range payloads, and existing outputs. It verifies the private/public pair and passes every generated envelope through the production verifier before writing it. Private bytes are cleared from the tool's owned mutable buffers after use. The root ignore rule is defense in depth; it is not permission to place a private key in the repository.

The implementation uses the pure-Dart `cryptography 2.9.0` package for Ed25519 verification. The dependency is locked, adds no platform plugin, and is recorded under Apache-2.0 in the runtime notice inventory. The existing `crypto` package remains the SHA-256 implementation.

## Conformance fixtures

Tracked fixtures contain one canonical payload, its signed envelope, and the corresponding public-only test trust store. The fixture key pair was generated ephemerally; only the public key and signature were retained. Tests also generate ephemeral in-memory keys to prove that authenticated but noncanonical, insecure, or calendar-invalid payloads still fail semantic validation.

The fixture package bytes exercise authenticated length and SHA-256 comparison only. They are not an installable Catalog archive and do not claim to test ZIP parsing, extraction, database validation, activation, or rollback.

## Consequences

The repository now has a real offline publisher-authentication boundary, a public production trust root, an external private-key custody location, and executable negative conformance tests. The complete package can be built, signed, verified, decoded, and installed offline, but the production App still cannot discover or download an update. A later slice must select production hosting and implement a bounded foreground transport. That work still requires the pending host, redirect, and UX authorization in ADR-0010.
