# ADR-0012: Phase 7 offline package validation and installation

- Status: accepted
- Date: 2026-09-09
- Scope: complete ZIP validation, installer handoff, attribution ownership, and persisted replay state

## Context

ADR-0011 authenticates complete-package metadata but deliberately stops before ZIP decoding or installation. Passing an authenticated archive to a generic extractor would still permit path traversal, duplicate-name ambiguity, links, encryption, unsupported compression, unbounded expansion, trailing content, inner-manifest substitution, or loss of version-specific attribution.

The Phase 5 installer already owns Catalog staging, database validation, activation, rollback, retention, and personal-data isolation. The complete-package path must enter that state machine rather than create a second file lifecycle. It must also persist the highest accepted remote release sequence independently of the active Catalog so an explicit rollback cannot re-enable a signed replay.

## Decision

The Phase 7 complete package has exactly three regular-file entries and no directory entries:

```text
assets/catalog/bundled_catalog.json
assets/catalog/catalog.db
assets/catalog/ATTRIBUTION.txt
```

The decoder first checks the signed outer archive length and SHA-256. It then enforces one-disk ZIP structure, an exact central-directory boundary, no archive or file comments, no trailing bytes, exactly one occurrence of every allowed path, matching local and central names and flags, no extra fields, no encryption, no symbolic links, no unsupported entry type, and only stored or Deflate compression.

Declared uncompressed limits are 64 KiB for the Catalog manifest, 256 KiB for attribution, and 128 MiB for the database. Decompression writes through an independently bounded output stream, so a false small size in the ZIP header cannot bypass the actual-output limit. Every entry must match its declared length and CRC after decompression.

The inner Catalog manifest retains the existing bundled-manifest contract. Its dataset, schema, data version, snapshot, and coverage must exactly match the signed outer payload. Its database length and SHA-256 then drive the existing SQLite metadata, required-object, integrity, foreign-key, and stable-probe validation. No generic archive path is ever written to disk.

The offline package pipeline performs Ed25519 authentication, archive validation, and installer handoff in that order. Remote installation requires an already validated active Catalog and a strictly newer data version. Runtime startup, Settings, and platform manifests do not invoke this pipeline in this phase.

Catalog attribution now belongs to each installed Catalog artifact. Pointer version 2 adds attribution byte length and SHA-256, stores a hash-qualified sibling attribution file, validates it with the database during reuse and recovery, and returns the active attribution to the App. Pointer version 1 and the Phase 3 four-field pointer migrate using the trusted bundled attribution available during startup. This compatibility path predates remote installation; all newly installed artifacts carry their own validated attribution.

`catalog_update_state.json` stores the highest accepted remote release sequence independently of active and previous pointers. It is strict, atomic, monotonic, and never reduced by bundled recovery. The installer commits this high-water mark only after the candidate database and attribution pass validation, but before pointer activation. A failure or interruption after that safe-state commit burns the sequence and rolls back the Catalog; availability may require a later release sequence, while replay protection cannot regress.

The implementation uses `archive 4.2.0` for ZIP parsing and Deflate decoding. The dependency and its `posix 6.5.2` transitive dependency are locked and recorded under MIT. Application-owned checks do not rely on the package's convenience disk extractor.

The publisher-side builder first reruns the complete immutable release check, then writes the same three entries in a fixed order with fixed ZIP metadata and Deflate compression. It validates the resulting archive and creates the final output with a no-overwrite operation. Its JSON result reports archive length and SHA-256 for the later signed payload. Resolved-path checks require the ZIP and canonical unsigned payload to remain outside the repository, including through symbolic-link aliases. The builder does not accept a private key, create an envelope, select a URL, or publish a Release.

## Consequences

An eligible Catalog release can now be converted into the exact complete-package shape, and an authenticated complete package can be exercised end to end without networking and without touching `user.db`. Corrupt, ambiguous, oversized, encrypted, linked, mismatched, replayed, or SQLite-invalid candidates retain the prior validated Catalog. Attribution follows activation and rollback rather than whichever App bundle happened to launch.

Phase 7 is still not a runtime online-update feature. The later production-key addendum in ADR-0011 resolves the initial trust key and local custody boundary, but production hosting, redirects, foreground consent and progress UX, download interruption, final platform policy, and device evidence remain pending authorization and implementation.
