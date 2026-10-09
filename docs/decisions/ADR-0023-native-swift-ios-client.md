# ADR-0023: Native Swift iOS client

- Status: Accepted for implementation; physical upgrade and release acceptance remain open
- Date: 2026-10-09
- Phase: 9

## Context

The user requested Swift instead of Flutter and delivery only on iOS. The previous client already contains a complete offline Catalog, personal storage, frozen visual assets, and a manually initiated signed complete-package update flow. A language migration must preserve those contracts rather than produce a second data model or regenerate personal data.

This decision supersedes the client-language and platform assumptions in sections 1, 4, 13, 17, 19, 20, and 22 of the preserved Chinese specification, ADR-0005, and the Flutter bridge implementation in ADR-0022. The baseline specification and historical evidence remain unchanged.

## Declared boundary

Allowed changes are `ios/`, `AGENTS.md`, both existing READMEs, `.github/workflows/offline-validation.yml`, focused native packaging and CI assertions under `tests/`, this decision, the current feature documents, `docs/implementation-reports/phase-9.md`, and Phase 9 evidence.

The phase does not change upstream imports, source revisions, identities, normalized records, immutable releases, either normative SQL schema, signing keys, network configuration, App Store accounts, or repository visibility. It does not remove the historical Flutter checkout or personal data. Android is excluded from active implementation, CI, and release acceptance.

Acceptance commands are the offline Python suite, release 2 validation, `swift test --package-path ios --scratch-path /tmp/roco-handbook-spm`, an unsigned iOS simulator build, focused XCUITest flows, and `git diff --check`. Stop if an existing personal schema cannot be validated, an immutable asset differs, native packaging needs an unapproved dependency, or installer behavior cannot preserve the independent personal database.

## Decision

- `ios/RocoHandbook.xcodeproj` is the active client. SwiftUI owns presentation, native navigation, Dynamic Type, and accessibility. iOS 15 remains the minimum; `NavigationStack` is used from iOS 16 with a `NavigationView` fallback on iOS 15. System controls adopt the current Apple navigation appearance without a Flutter bridge.
- `ios/Package.swift` supplies `HandbookCore`, tested on the Mac host. SQLite and zlib come from the platform; Foundation and CryptoKit supply files, concurrency, networking, hashing, and Ed25519 verification. There is no third-party Swift package or new dependency lockfile.
- Actor-owned repositories preserve the existing DTO semantics, concrete-form identities, explicit default mappings, source references, shared Learnsets, conditional acquisition values, and evolution edges. Views consume DTOs and application state. SQLite values are bound; sorting uses enums; search wildcards are escaped. Query generations prevent obsolete results replacing a newer search.
- Reuse the immutable assets in `app/assets/`, packaged by `ios/prepare_resources.py`. Only active version 3 creature images, version 1 Tool/font assets, Catalog assets, and frozen JSON contracts are staged. Older image versions are excluded. The personal SQL asset must match `schemas/user_v1.sql` byte-for-byte.
- Preserve bundle identifier `world.roco.rocoHandbook`, `Library/Application Support/user/user.db`, both Catalog pointer basenames, versioned Catalog filenames, attribution filenames, and the release replay-state path. The prior `path_provider_foundation` 2.6.0 implementation uses the same iOS application support path without a bundle-ID suffix.
- `user.db` is independently opened and validated. Unknown or damaged schemas fail visibly and remain intact. Catalog recovery and updates cannot write that database. Favorites, collection marks, notes, their stable IDs, and the `pet_catalog_layout` setting remain compatible.
- The native installer serializes work with the existing OS file-lock basename, validates regular files and private directories, checks manifest identity, SHA-256, exact database objects, metadata, integrity, foreign keys, and the established probe, then writes the previous descriptor and atomically renames the active pointer. It accepts current pointer version 2 and matching older bundled pointers. Recovery retains a separately validated previous Catalog.
- Cleanup is conservative: remove only staging files created by the current native invocation. Earlier validated or abandoned files are not swept during migration. This uses additional disk space but avoids expanding deletion authority before physical upgrade validation.
- Settings retains explicit recovery confirmation and manually initiated signed complete-Catalog updates. Native transport is confined to one file, permits the established GitHub repository and one validated release-asset redirect, disables persistent cookies/cache/credentials, and bounds response bytes. Signed canonical JSON, trust-key sequence ranges, compatibility, replay floors, ZIP paths, entry count, compression, expanded size, CRC, and database validation remain enforced.
- Interface resources reuse the frozen Phase 8 English and Simplified Chinese terminology. Native strings use `en.lproj` and `zh-Hans.lproj`. The source language of canonical game data remains intact.
- Native App version is `1.2.0`, build `3`. The previous `1.1.0+2` Flutter source and `1.0.0+1` release candidate remain historical references. Only iOS is a future release target.

## Consequences and verification limits

The active client can be built and tested without Flutter, Dart, CocoaPods, or an Android toolchain. Python remains the development-time import and Catalog-build language. Retaining the earlier client provides migration evidence; it is not a second supported release target.

Mac unit tests, iOS simulator UI tests, and captures do not prove a signed Flutter-to-Swift upgrade on physical hardware, iOS 15 rendering, VoiceOver, crash durability, low-storage behavior, a live signed update, or App Store acceptance. Those checks remain explicit next boundaries. Scoped completion still requires GitHub Desktop commit and push.

## Primary platform references

- [Apple: Adopting Liquid Glass](https://developer.apple.com/documentation/TechnologyOverviews/adopting-liquid-glass)
- [Apple: Build a SwiftUI app with the new design](https://developer.apple.com/videos/play/wwdc2025/323/)
- [Apple: Curve25519 signing public key](https://developer.apple.com/documentation/cryptokit/curve25519/signing/publickey)
