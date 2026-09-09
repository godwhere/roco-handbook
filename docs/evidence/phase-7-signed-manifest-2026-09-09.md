# Phase 7 signed-manifest evidence

- Date: 2026-09-09
- Protocol: remote Catalog manifest V1
- Signature algorithm: Ed25519
- Runtime dependency: `cryptography 2.9.0`
- Network behavior: absent

## Implemented proof boundary

`RemoteCatalogManifestVerifier` authenticates the exact payload bytes with an App-supplied public key before parsing their semantic fields. It then enforces canonical JSON, strict fields, protocol and schema compatibility, dataset identity, newer data and release versions, key release ranges, minimum App version, an exact UTC timestamp, coverage, package size, exact HTTPS host policy, and package byte length and SHA-256.

The ten focused tests prove:

- acceptance of the tracked canonical payload and Ed25519 signature;
- exact package byte-length and SHA-256 checks;
- rejection of payload and signature tampering;
- rejection of unknown keys and envelope extensions;
- rejection of replayed releases and non-newer data;
- rejection of incompatible App versions, hosts, and key ranges;
- rejection of validly signed noncanonical JSON;
- rejection of a validly signed HTTP package URL;
- rejection of a validly signed impossible calendar date; and
- rejection of malformed public keys in the trust store.

The tracked trust fixture contains only a 32-byte public Ed25519 key. No private key, production key identifier, selected production host, credential, cookie, personal data, or signing configuration was added. Test-only private keys exist only in memory for the duration of individual test cases.

## Dependency review

`flutter pub get` resolved only the new direct runtime dependency `cryptography 2.9.0`; unrelated package versions were not upgraded. The package's installed license is Apache-2.0. Its public API provides Ed25519 signature verification from message bytes, signature bytes, and an Ed25519 public key. No `cryptography_flutter` platform plugin was added.

## Not proven

- Network availability, DNS, TLS deployment, redirects, retries, interruption, or metered-network behavior
- Production host selection, public-key provisioning, private-key custody, rotation, or revocation operations
- ZIP parsing, extraction limits, path safety, archive contents, or Catalog database validation
- Installer handoff, activation, rollback, retention, or persisted release-sequence ownership
- Simulator or physical-device behavior, platform policy, signing, store upload, or publication

The conformance package bytes are deliberately not represented as an installable Catalog ZIP. They prove only the authenticated transport length and hash boundary owned by this slice.
