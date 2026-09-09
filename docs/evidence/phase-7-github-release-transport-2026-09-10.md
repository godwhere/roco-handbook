# Phase 7 GitHub Release transport evidence

- Evidence date: 2026-09-10
- Scope: approved public host, observed redirect shape, runtime discovery probe, and local transport/UI validation
- Decision: ADR-0013

## Approval and selected layout

The repository owner approved GitHub Releases and accepted the existing iCloud-synchronized Desktop custody of the production Catalog signing key. The selected public repository is `godwhere/roco-handbook`.

The fixed discovery asset is `catalog-manifest.json` under release tag `catalog-channel`. A complete package for data version `N` is `catalog-vN.zip` under immutable release tag `catalog-data-vN`. The publisher and App independently require the exact repository, tag, filename, and data-version relationship.

No Release was created during this delivery because the only real immutable Catalog is bundled data version 1 and a remote payload must advance it. Publishing a duplicate or fake version 2 would violate the release and identity evidence boundary.

## Read-only host observations

A read-only request to GitHub's generic `releases/latest/download/...` form required more than one redirect before reaching asset delivery, so that form was not selected. A direct versioned `releases/download/<tag>/<asset>` URL returned a single `302` to `release-assets.githubusercontent.com`; its delivery URL used the `/github-production-release-asset/` path prefix and GitHub-owned query parameters.

The runtime therefore disables automatic redirect following. It accepts a direct `200`, or one explicit `302` from the exact initial GitHub URL to the exact release-asset host and path prefix. A second redirect and every other host are rejected. This matches GitHub's documented release-asset behavior while keeping the redirect trust boundary observable in application code.

## Runtime discovery probe

The production `GitHubReleaseCatalogSource`, production public trust store, current Phase 7 App version `1.1.0`, current data version `1`, and the fixed discovery URL were exercised together from the local checkout. The command completed successfully and returned:

```text
current_or_unpublished
```

This is the expected current state: no production discovery asset exists. The probe was read-only, used no token, created no remote resource, and changed no networking configuration.

## Local automated evidence

Focused Dart tests cover:

- a signed discovery envelope delivered through one allowed redirect;
- a missing discovery asset and an already installed signed manifest;
- exact package download, byte progress, authenticated length, and SHA-256;
- unapproved and repeated redirects;
- declared-length and streamed-body limits;
- cancellation without returning partial bytes; and
- rejection of a signed package outside the exact versioned GitHub Release path, including when its version is already installed.

Service tests confirm that every check incorporates the installer's persisted replay high-water state before contacting the host and that malformed replay state fails locally.

Widget tests prove there is no implicit check, confirmation includes data version and total size, download progress is visible, cancellation keeps the current Catalog, restore is disabled during an update, verification cannot be cancelled, failure is manually retryable, and successful activation updates the visible Catalog session.

Python structure tests prove the production Android source manifest requests only Internet access, no background-update dependency was added, `dart:io` networking remains isolated to the Catalog update source, and the existing validated package pipeline is the activation path.

## Local release builds

The network-enabled source built successfully as App version `1.1.0`, build `2`:

- Android Release AAB: 59.0 MB reported by Flutter; SHA-256 `435179c42a114ffd98efa8f2b3b41c4dbb4f7ea29e72210975cae745e35f9ccb`.
- Android Release APK: 60.4 MB reported by Flutter; SHA-256 `037945fb7837fd873f5103d8b022ee5f3c3c9f7fbd577017244151bc61496503`.
- iOS no-codesign Release App: 22.9 MB reported by Flutter; the embedded Info.plist reports `1.1.0` and build `2`; the Dart App framework binary SHA-256 is `0a1abc35b77f1e8c4332e67590400703eced126aca99ec6e705953da2b7e9fee`.

The merged Android APK manifest reports package `world.roco.roco_handbook`, version code `2`, version name `1.1.0`, `android.permission.INTERNET`, and AndroidX's application-scoped signature permission `world.roco.roco_handbook.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION`. No additional user-granted or sensitive permission appeared. The APK is unsigned, and the iOS build explicitly disabled code signing. These are local build proofs, not store-ready artifacts.

## Evidence boundary

The local tests and missing-channel probe do not prove transfer of a real package, production signing or publication, interruption against GitHub's CDN, low-storage recovery, physical-device behavior, regional availability, store review, or release acceptance. Physical-device tests remain waived rather than passed. Those items require a real data version greater than 1 and their own authorized evidence runs.

## Sources

- GitHub Docs, [Linking to releases](https://docs.github.com/en/repositories/releasing-projects-on-github/linking-to-releases)
- GitHub Docs, [REST API endpoints for release assets](https://docs.github.com/en/rest/releases/assets)
