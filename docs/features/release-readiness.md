# Native iOS release readiness

The active source candidate is [1.2.0 build 3](../../release/1.2.0+3/RELEASE_NOTES.md).
Its [manifest](../../release/1.2.0+3/release-candidate.json) binds the native
Swift/SwiftUI project to Catalog schema 1/data 2, personal schema 1, exact active
resource hashes, source baseline and separately scoped native CI evidence.
The bundle ID is `world.roco.rocoHandbook`; deployment is iOS 15.0 for iPhone
and iPad. This is not a signed or store-ready release.

## Offline verification

```sh
PYTHONDONTWRITEBYTECODE=1 PYTHONPATH=tools python3 tools/release/check_native_candidate.py
PYTHONDONTWRITEBYTECODE=1 PYTHONPATH=tools python3 -m unittest discover -s tests -p 'test_*.py'
PYTHONDONTWRITEBYTECODE=1 PYTHONPATH=tools python3 tools/release/check_catalog.py --release data/release/2
```

Native Swift test, simulator build and UI commands are maintained in
[the native README](../../ios/README.md). CI uses pinned actions, read-only
permissions, Python data/release tests, Mac-host Swift tests and an unsigned
simulator build. It does not run UI, signing or physical-device acceptance.
The verifier is exercised by the default Python suite.

The native client declares no protected-resource usage description, background
mode or ATS exception, and no third-party runtime package. Settings exposes
Catalog attribution and frozen visual-source information. Explicit signed
Catalog update transport is separate from ordinary offline use. These source
facts do not replace signed-binary permissions or store privacy review.

## Open acceptance gates

See the candidate's [known limitations](../../release/1.2.0+3/KNOWN_LIMITATIONS.md)
for physical devices, iOS 15 execution, accessibility, low-storage/crash durability,
signed Flutter-to-native upgrades, signing, archive/export, TestFlight, licensing,
privacy metadata and store acceptance. Each needs its own evidence. No native
device waiver has been applied; store readiness and upload remain false.

## Preserved history

`release/1.0.0+1/` retains the original Flutter iOS/Android candidate, Catalog 1,
artifact hashes and Phase 6 sequencing waiver unchanged. Phase 7's Flutter
1.1.0 build 2 was a later source boundary. Neither qualifies Swift 1.2.0 build 3.
Android and Flutter builds are outside current acceptance. Historical runtime
license UI and permission statements must not be carried into native release
claims without verification.
