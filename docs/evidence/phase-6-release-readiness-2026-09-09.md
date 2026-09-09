# Phase 6 release-readiness evidence

- Date: 2026-09-09
- Candidate: App 1.0.0, build 1
- Flutter: 3.47.2 stable
- Dart: 3.13.2
- Xcode: 26.6, build 17F113
- Catalog data version: 1
- Catalog schema: 1
- User schema: 1

## Catalog release gate

`tools/release/check_catalog.py` ran against `data/release/1` using only tracked local inputs. It passed package-shape, manifest, coverage, source-lock, normalized-artifact, attribution, byte-length, SHA-256, schema-object, integrity, foreign-key, table-count, and stable-probe checks.

The result is tracked at `release/1.0.0+1/catalog-check.json` with these primary identities:

- Database: 3,424,256 bytes
- Database SHA-256: `2c27ddc3cd36f543ea6319ea9878b4a3c8b8a9a89afad6bd6eaacfd9592ed8f2`
- Source lock SHA-256: `98707d94b8d47ec3ce1599ee122ed67c75753b4578b8ceacbbf90c9531efb3ff`
- Normalized Catalog SHA-256: `171db314e1c1f922af4cdce57eb8dc27654f9dd62c6d06676e5b8d4887e033a0`
- Attribution SHA-256: `0fe12d26c69f01469724e691927237ce78689f7a800fd0f503c3f0dc189a9ea2`
- Frozen source revisions: 10
- SQLite `integrity_check`: `ok`
- SQLite foreign-key violations: 0

Six focused negative regressions prove that the gate rejects SQLite sidecars, placeholder text, false required coverage, blockers, unreviewed removals, and a database hash mismatch. The checked candidate manifest also rejects divergence between the App version, Catalog inputs, User schema, signing status, device-gate status, and publication boundary.

## Automated project checks

The root Python suite passed 70 tests. The Flutter suite passed 44 tests: 14 Catalog installer lifecycle tests, 10 Catalog repository tests, nine User V1 tests, and 11 Widget flows. The additional Widget flow confirms visible App version 1.0.0 (1) and navigation to Flutter's packaged license page.

`dart format --output=none --set-exit-if-changed lib test` passed, and `flutter analyze --no-pub` completed with no issues.

The CI workflow parsed as YAML and exposes two jobs. Every third-party action reference is pinned to a 40-character commit SHA, workflow permissions grant only `contents: read`, checkout credential persistence is disabled, and no secret or BWIKI access is configured.

The first hosted run completed successfully but reported that the initially pinned checkout and setup-python releases used the deprecated Node 20 action runtime. The pins were upgraded to the official current checkout v7.0.1 and setup-python v7.0.0 releases before final handoff. Follow-up workflow run `34352830184` at commit `d3a5f6a` completed successfully: every step in **Catalog and release contracts** and **Flutter contracts** passed.

## Android candidate

`flutter build appbundle --release` completed successfully after resolving missing Flutter Android engine artifacts into the local Gradle cache. That build-time toolchain download is not a runtime App dependency.

- Local artifact: `app/build/app/outputs/bundle/release/app-release.aab`
- Bytes: 57,492,013
- SHA-256: `f9316e510b7d18849b54599f6a30d8265ba63cc2d5c2d2f32d4401f4c701bebb`
- Version name: 1.0.0
- Version code: 1
- Application ID: `world.roco.roco_handbook`
- Minimum SDK: 24
- Target SDK: 36
- Signing: absent; `jarsigner` reported `jar is unsigned`
- Embedded Catalog SHA-256: `2c27ddc3cd36f543ea6319ea9878b4a3c8b8a9a89afad6bd6eaacfd9592ed8f2`
- Packaged Flutter notices: `base/assets/flutter_assets/NOTICES.Z`

The generated release manifest contains no Internet permission and no sensitive permission. AndroidX adds one application-scoped signature permission named `world.roco.roco_handbook.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION`; it is not a user-granted or network permission. Debug and profile source manifests retain development-only Internet access for Flutter tooling and are not part of the release manifest.

## iOS candidate

`flutter build ios --release --no-codesign` completed successfully and explicitly warned that manual code signing is required before device deployment.

- Local artifact: `app/build/ios/iphoneos/Runner.app`
- Regular files: 58
- Regular-file bytes: 22,331,299
- Content-tree SHA-256: `b6fa812e5e7676cc8fdc80e43c2a1fb7d5a29ed3326ae49b5986431fcfb5996e`
- Content-tree method: SHA-256 over sorted directory, file, and link records containing relative paths, byte lengths, and individual file hashes
- Version: 1.0.0
- Build number: 1
- Bundle ID: `world.roco.rocoHandbook`
- Minimum iOS version: 15.0
- Signing: absent; `codesign --verify --deep --strict` reported `code object is not signed at all`
- Protected-resource usage-description keys: none
- Embedded Catalog SHA-256: `2c27ddc3cd36f543ea6319ea9878b4a3c8b8a9a89afad6bd6eaacfd9592ed8f2`
- Packaged Flutter notices: `Frameworks/App.framework/flutter_assets/NOTICES.Z`

Generated binaries remain ignored local outputs. They are identified in the tracked candidate manifest but are not committed.

## Source and software license review

The Roco World BWIKI Module:Pet page was checked on 2026-09-09 and displayed a CC BY-NC-SA 4.0 data-use notice requesting source attribution. The Creative Commons deed requires appropriate credit, a license link, an indication of changes, non-commercial use, ShareAlike treatment for applicable adaptations, and no implied endorsement.

`licenses/DATA_ATTRIBUTION.md` records the source, license links, frozen-revision evidence, transformation notice, non-official status, and material boundary. `licenses/THIRD_PARTY_NOTICES.md` inventories every resolved runtime package and license identifier from `app/pubspec.lock`. Settings opens Flutter's packaged full license registry.

This review is not legal advice, a rights clearance for artwork or trademarks, or evidence of application-store approval.

## Device and publication gates

The read-only device inventory showed an Android emulator, one physical iPhone, and an iOS simulator. No physical Android device was connected. No App was installed on the physical iPhone because a physical-device mutation was not separately authorized.

A second read-only preflight at 20:54 CST confirmed that the physical iPhone remained paired and available. An exact bundle-ID query returned no installed `world.roco.rocoHandbook` application, so a future first test installation would not replace an existing installation of this App. The host reported one valid code-signing identity, but the tracked Xcode Release configuration does not resolve a development team. No certificate name, team identifier, device identifier, or other signing detail was written to the repository. Preparing a signed device build therefore remains a separately authorized action and must use an explicitly selected team without committing personal signing data.

The following Phase 6 acceptance layers remain **not run**:

- Physical Android first install, offline launch, update, recovery, interruption, and personal-data preservation
- Physical iOS first install, offline launch, update, recovery, interruption, and personal-data preservation
- Actual physical-device storage exhaustion
- Signed Android artifact, signed iOS archive, platform export, or notarization
- Store-managed upgrade, submission, review, upload, or publication

The local candidate is therefore auditable but not store-ready. Missing physical-device evidence is a Phase 6 stopping condition and must not be represented as a pass.
