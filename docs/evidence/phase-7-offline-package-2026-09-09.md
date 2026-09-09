# Phase 7 offline complete-package evidence

- Date: 2026-09-09
- Package format: strict complete ZIP
- ZIP dependency: `archive 4.2.0`
- Replay state: `catalog_update_state.json` version 1
- Catalog pointer: version 2
- Runtime network behavior: absent

## End-to-end proof

An offline integration test creates a valid data-version-2 SQLite Catalog from the bundled test asset, packages it with its inner manifest and attribution, signs the outer canonical payload with an ephemeral in-memory Ed25519 key, and runs the complete pipeline. The test authenticates the payload, validates the ZIP and its three exact entries, validates the inner contract and database, installs through the existing Catalog installer, opens the changed read-only data, and records release sequence 2.

The private test key is never written to a file. The package is generated only in a temporary test directory and is not a release artifact.

## Publisher-side package proof

The offline publisher command reruns `check_release`, accepts only regular non-link files for the three exact archive paths, applies the same entry-size limits as the App, writes fixed metadata in a fixed order, verifies entry bytes and CRC, requires generated ZIP and payload files to remain outside the resolved repository boundary, and creates the final path without overwriting an existing file. Two independent builds from the same validated release are byte-identical in the regression test.

A local proof build from `data/release/1` produced an untracked temporary archive with these results:

```text
archive_bytes: 729735
archive_sha256: 734105d9c5cee5e59fbc095aa57936d937d106153ba74a4e624d7b8a818911de
entries: assets/catalog/bundled_catalog.json, assets/catalog/catalog.db, assets/catalog/ATTRIBUTION.txt
```

The proof artifact remained outside the repository. It was not signed or published and is not a release candidate.

## Archive and installer regressions

Focused tests cover:

- signed archive byte-length and SHA-256 validation before ZIP decoding;
- missing, unexpected, duplicate, traversal, and trailing entries;
- encrypted entries, unsupported shapes, and declared entry-size limits;
- a forged small ZIP header whose actual decompressed output exceeds its limit;
- CRC mismatch after signed outer bytes are accepted;
- incomplete attribution and signed-to-inner manifest mismatches;
- rejection of remote installation without a valid active base;
- database validation failure before replay-state advancement;
- monotonic replay rejection after explicit bundled recovery;
- fail-closed behavior for malformed replay state;
- conservative sequence burning followed by Catalog rollback when a fault occurs after the replay-state commit;
- pointer version 1 and Phase 3 pointer migration to pointer version 2;
- version-specific attribution reuse and attribution-damage rollback; and
- refusal to follow database or attribution symbolic links, including recovery from dangling canonical database and attribution links.
- reproducible publisher output, exact entry bytes, safe source files, output self-validation, and no-overwrite behavior.

## Dependency and storage review

`flutter pub get` added only direct dependency `archive 4.2.0` and transitive dependency `posix 6.5.2`; unrelated packages were not upgraded. Both installed package licenses are MIT. The decoder uses the in-memory ZIP API with application-owned structural, output-size, and CRC checks. It never uses the convenience function that extracts arbitrary paths to disk.

Generated Catalog databases and attribution files remain direct children of the private `catalogs/` directory. Cleanup remains non-recursive and matches only generated Catalog database, attribution, and invocation-owned staging names. `user/user.db`, unrelated files, nested directories, and external symbolic-link targets remain outside the lifecycle.

## Not proven

- Remote host availability, DNS, TLS deployment, redirects, download progress, retry, interruption, or metered-network behavior
- Production key rotation, revocation, accepted custody for real signing, or a real release signing ceremony
- Runtime update discovery, user consent, Settings integration, background behavior, or platform network permissions
- Simulator or physical-device update installation, low-storage behavior with real archives, store policy, signing, upload, or publication

No production package, remote resource, Release, runtime credential, or platform permission was created by this package slice. The production signing key and public trust store were added later under the separate custody evidence and have not signed a real release.
