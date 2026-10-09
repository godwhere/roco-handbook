# Roco Handbook native iOS client

This is the active Swift/SwiftUI client for iOS 15 and later. Open `RocoHandbook.xcodeproj` in Xcode and select the shared `RocoHandbook` scheme. Choose an iOS simulator and run. Physical installation requires the user's signing team; no team or private signing key is configured by this migration.

`App/` contains native presentation and application state. `Sources/HandbookCore/` contains the domain DTOs, actor-owned SQLite repositories, independent personal storage, offline asset repositories, Catalog installation/recovery, and explicitly initiated signed updates. `Tests/HandbookCoreTests/` runs offline on the Mac host; `UITests/` exercises actual iOS UI flows.

The local package uses only Apple frameworks and platform SQLite/zlib. There is no remote Swift package, CocoaPods dependency, Flutter engine, or Dart build step.

## Validation

Run from the repository root:

```sh
swift test --package-path ios --scratch-path /tmp/roco-handbook-spm
xcodebuild -project ios/RocoHandbook.xcodeproj -scheme RocoHandbook \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /tmp/roco-handbook-xcode CODE_SIGNING_ALLOWED=NO build
```

For UI tests, replace `SIMULATOR_ID` with an available iOS simulator:

```sh
xcodebuild -project ios/RocoHandbook.xcodeproj -scheme RocoHandbook \
  -destination 'platform=iOS Simulator,id=SIMULATOR_ID' \
  -derivedDataPath /tmp/roco-handbook-ui -parallel-testing-enabled NO test
```

Temporary build roots avoid the resource-fork signing failure observed when building test bundles inside the Documents-backed checkout. Full validation results and unrun physical/release layers are recorded in the Phase 9 report.

## Assets and upgrade compatibility

The build stages active immutable resources from `../app/assets/` using `prepare_resources.py`. It validates the personal SQL against `../schemas/user_v1.sql`; both database schemas and Catalog data version 2 remain unchanged. All browsing, images, reference tools, favorites, and notes work without runtime network access. Only explicit Settings update actions use the fixed Phase 7 GitHub source.

The bundle ID and iOS application support layout remain compatible with the preceding client. The native installer accepts existing Catalog descriptors; `user/user.db` is opened independently without replacement. Unknown personal schemas are preserved and block startup.

`generate_project.py` regenerates the checked-in Xcode project and shared scheme from the owned App sources. Run it after adding or removing App source files. Do not edit the preserved historical client to implement a new native feature.
