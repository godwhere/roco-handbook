# V1 release readiness

## Active native release boundary

ADR-0023 replaces the active Flutter/Android release target with `ios/RocoHandbook.xcodeproj`, App version 1.2.0, build 3, bundle identifier `world.roco.rocoHandbook`, and minimum iOS 15. The earlier candidates and Android evidence below are historical artifacts, not acceptance for this client.

CI retains the offline Python data suite on Ubuntu and replaces the Flutter job with Swift XCTest and a native unsigned simulator build on macOS. The local XCUITest matrix is recorded separately in Phase 9 evidence. The native App declares no protected-resource usage description, background mode, ATS exception, account capability, or third-party runtime package. Settings exposes the version-specific Catalog attribution and frozen visual-source information.

A future iOS release must independently verify a signed upgrade from the preceding Flutter build, physical offline use, personal-data retention, VoiceOver/Dynamic Type, older supported iOS versions, archive/export, signing, current store policy, upload, review, and publication. The Phase 6 waiver is not inherited as native device proof.

## Version identity

The first candidate uses App version `1.0.0`, build number `1`, Catalog schema version `1`, Catalog data version `1`, and User schema version `1`. Settings displays the App version and the installed data versions independently.

The current Phase 7 source uses App version `1.1.0`, build number `2`, Catalog schema version `1`, and the pre-release NRC Catalog data version `2`. This prevents the network-enabled source from producing a different binary under the preserved Phase 6 candidate identity. It is not yet a signed or store-submittable candidate.

## Offline release gate

Run the Catalog release check from the repository root:

```bash
PYTHONDONTWRITEBYTECODE=1 PYTHONPATH=tools python3 tools/release/check_catalog.py \
  --release data/release/2
```

The validator reads only tracked local inputs. It checks package shape, hashes, complete source traceability, schema objects, SQLite integrity and foreign keys, stable probe results, truthful coverage, reviewed removals, and the absence of transaction sidecars or placeholder metadata. It never imports from BWIKI, writes the release database, signs an App, or uploads anything.

The default GitHub Actions workflow runs the Python and Flutter contract suites without upstream access or release credentials. All third-party actions are pinned to immutable commits and workflow permissions are read-only.

## Permissions and licenses

The Android source release manifest declares only `android.permission.INTERNET` for the explicit Phase 7 GitHub Releases Catalog flow and declares no sensitive or user-granted permission. The merged Release manifest also contains AndroidX's application-scoped signature permission `world.roco.roco_handbook.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION`; it is not a network or user-granted permission. Flutter's debug and profile tooling manifests retain Internet access for development. The iOS App has no protected-resource usage-description key and adds no App Transport Security exception.

Settings provides **Open-source licenses**, backed by Flutter's packaged license registry. Catalog data attribution and third-party runtime dependency notices are maintained in `licenses/` and the immutable Catalog attribution asset.

## Candidate and publication boundary

`release/1.0.0+1/` records the Catalog check, candidate identity, exact locally built artifact hashes, release notes, known limitations, and manual-gate status. Generated App binaries stay outside Git.

Phase 6 closed under waiver `PHASE6-PHYSICAL-DEVICE-001` after the user explicitly directed the project to skip physical-device validation. Both device evidence statuses remain `not_run`; the waiver permits project sequencing only and is not a compatibility result.

Phase 7 changes the current source permission and runtime behavior after the recorded Phase 6 candidate was built. That historical candidate and its hashes remain unchanged; it is not evidence for the current network-enabled source. A new store candidate must rerun both platform builds, permission inspection, physical-device checks or a new explicit waiver, signing, and submission review.

An unsigned Android bundle or no-codesign iOS App is a local build candidate, not a store-submittable archive. Physical-device evidence, platform signing, archive/export, upload, store review, and publication each require their own successful run and authority. The project does not infer any of those results from a waiver, unit tests, emulators, simulators, or a successful compilation.
