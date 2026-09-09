# ADR-0011: Phase 7 signed complete-package manifest contract

- Status: accepted
- Date: 2026-09-09
- Scope: offline authentication and validation of complete-Catalog package metadata

## Context

Phase 7 needs publisher authentication before any remote transport can be considered. A package SHA-256 proves byte identity only; it does not prove who published the bytes. The contract must also reject ambiguous encodings, incompatible data, replayed releases, unapproved hosts, and metadata that could bypass the existing Catalog installer.

This decision intentionally precedes network activation. There is no selected production host, production public key, private signing key, downloader, redirect path, or installer integration in this slice.

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

The App trust store contains one to eight public Ed25519 keys with unique identifiers and inclusive release-sequence ranges. It contains no private material. Key rotation is represented by non-overlapping operational ranges selected during the later custody decision; the verifier itself fails closed on an unknown key or an out-of-range release.

The implementation uses the pure-Dart `cryptography 2.9.0` package for Ed25519 verification. The dependency is locked, adds no platform plugin, and is recorded under Apache-2.0 in the runtime notice inventory. The existing `crypto` package remains the SHA-256 implementation.

## Conformance fixtures

Tracked fixtures contain one canonical payload, its signed envelope, and the corresponding public-only test trust store. The fixture key pair was generated ephemerally; only the public key and signature were retained. Tests also generate ephemeral in-memory keys to prove that authenticated but noncanonical, insecure, or calendar-invalid payloads still fail semantic validation.

The fixture package bytes exercise authenticated length and SHA-256 comparison only. They are not an installable Catalog archive and do not claim to test ZIP parsing, extraction, database validation, activation, or rollback.

## Consequences

The repository now has a real offline publisher-authentication boundary and executable negative conformance tests. It still cannot check for, download, extract, or install a remote update. A later slice must select production hosting and key custody, implement a bounded foreground transport, validate archive shape without executable content or unsafe paths, and hand a verified Catalog to the existing installer. That work requires the pending authorization and evidence in ADR-0010.
