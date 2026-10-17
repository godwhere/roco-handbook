# Native iOS 1.2.0 (build 3) source candidate

Status: source candidate, pending release acceptance. No signed binary, archive,
TestFlight upload, App Store submission, or publication is represented here.

- Active client: Swift/SwiftUI, `ios/RocoHandbook.xcodeproj`, shared scheme
  `RocoHandbook`, bundle ID `world.roco.rocoHandbook`, iPhone/iPad deployment
  target iOS 15.0. Deployment configuration is not proof of iOS 15 execution.
- Bundled Catalog: schema 1, data 2, dataset `roco-world-zh-cn`, snapshot
  `snapshot-dad7cd7d5ce73236`. The 4,657,152-byte database has SHA-256
  `dce0d3376611adc151f8e2abe1f74185d19c94f61a3d0d2fade98a188dae9d61`.
  `catalog-check.json` records integrity, references, source locks and coverage.
- Native catalogs, source-backed original/shiny artwork, reference Tools,
  favorites, collection marks, notes, bilingual interface, and saved layouts
  use bundled resources. Explicit Settings actions may check/download signed
  complete Catalog updates; ordinary use requires no first-launch download.
- `resource-inventory.json` records every active packaging input, including
  fonts, imagery, reference JSON, Catalog and personal SQL. Shared assets remain
  under `app/assets`; this does not make Flutter a native build dependency.
- Personal schema remains version 1. The bundle identity and independent
  `Library/Application Support/user/user.db` path are retained. Actual signed
  Flutter-to-native upgrades remain unverified.

## Reproduction and evidence

Run from the repository root:

```sh
PYTHONDONTWRITEBYTECODE=1 PYTHONPATH=tools python3 tools/release/check_native_candidate.py
PYTHONDONTWRITEBYTECODE=1 PYTHONPATH=tools python3 -m unittest discover -s tests -p 'test_*.py'
swift test --package-path ios --scratch-path /tmp/roco-handbook-spm
xcodebuild -project ios/RocoHandbook.xcodeproj -scheme RocoHandbook \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /tmp/roco-handbook-xcode CODE_SIGNING_ALLOWED=NO build
```

The first command verifies the live Catalog, bundled/release equality, exact
resource closure and hashes, packaged personal SQL, project/generator identity,
and conservative acceptance status. It neither builds nor signs an App.

[CI run 30](https://github.com/godwhere/roco-handbook/actions/runs/38754548059)
passed both jobs at `d29da2f41b7285f5c3795405d2578512f5309e46` on October 15.
It ran host Swift tests and an unsigned simulator build, not XCUITest or a
signed device build. The source baseline in the manifest is
`bfe145df60b2cf4963ab9b4a1ca22013525a3966`; only two evidence/report Markdown
files changed between that CI commit and the baseline. This review adds release
metadata and a validator; it does not claim CI ran on the new delivery commit.
Prior local UI evidence is linked separately in the manifest and is not rerun
or relabeled as CI evidence.

See [known limitations](KNOWN_LIMITATIONS.md) and
[review evidence](../../docs/evidence/native-candidate-2026-10-17.md).
The unchanged `../1.0.0+1/` directory is historical Flutter/Android evidence;
neither its binaries nor its Phase 6 device waiver qualify this native candidate.
