# Phase 13 native Wiki-style Tools and Settings evidence

- Date: 2026-10-25, Asia/Shanghai
- Baseline: `145ef4a`; previous effective App presentation was Phase 11
- Decision: [ADR-0032](../decisions/ADR-0032-wiki-tools-and-settings.md)
- Simulator: invocation-owned Roco Phase 10, iPhone 17 Pro / iOS 27, `53209D2A-B509-4FC9-B464-7DB15A446055`
- Implementation and staging use existing SwiftUI/Apple frameworks, frozen media, and source contracts.

## Approved reference and source preservation

The user approved the actual Wiki style observations rather than the earlier generated fantasy frame studies. Sources are the [home library/tools](https://wiki.biligame.com/nrc/%E9%A6%96%E9%A1%B5#library) and [skill codex](https://wiki.biligame.com/nrc/%E6%8A%80%E8%83%BD%E5%9B%BE%E9%89%B4). The selected reference files and computed tokens are saved as [home](phase-13/wiki-home.jpg), [library/tools](phase-13/wiki-library-tools.jpg), [skills](phase-13/wiki-skills.jpg), and [observations](phase-13/wiki-observations.json). Source counts and future promotional dates are not an App content import.

[Source-art records](phase-13/source-art.json) verify all eight representative image paths against existing frozen manifest identities, SHA-256, and lengths. The large tile uses the same already-bundled creature seen in the Wiki reference. Existing feature, skill, creature, activity, outfit, and starlight resources remain immutable. Full game images are contained and decorative/VoiceOver-hidden; only the small background motif uses template rendering. No generated creature, source download, or new dependency is introduced.

The four native source/test inputs match the owned validation archive byte-for-byte; hashes are in [native-inputs.json](phase-13/native-inputs.json). Direct source comparison confirms all Tool child views, update check/install/cancel routines, and Catalog information/license views are unchanged. Recovery confirmation and personal-data protection remain in the existing flow.

## Verification commands and observed results

Commands ran in `/tmp/roco-phase13-validation`, a fresh archive with verified current inputs, avoiding the checkout's known cloud-backed historical-file reads. Full command output remains in `/tmp/roco-phase13-*.log`.

| Check | Observed result | Log/result |
| --- | --- | --- |
| `PYTHONDONTWRITEBYTECODE=1 PYTHONPATH=tools python3 -m unittest discover -s tests -p 'test_native_ios.py'` | Four passed | `/tmp/roco-phase13-contracts-final.log` |
| `python3 -m unittest tests.test_project_structure.ProjectStructureTests.test_project_authored_text_is_english` with the same offline environment | Passed against synchronized documents | `/tmp/roco-phase13-prose-final.log` |
| Generic simulator build | Passed after the icon-column repair | `/tmp/roco-phase13-final-build.log` |
| Seven-route and personal-data/restore UI cases | Both passed; initial source has the same route/update/storage implementations | `/tmp/roco-phase13-light.log`, `.xcresult` |
| Final Chinese normal and maximum-text cases | Both passed after repair | `/tmp/roco-phase13-final-light.log`, `.xcresult` |
| Final actual-dark Chinese capture case | Passed after repair | `/tmp/roco-phase13-final-dark.log`, `.xcresult` |
| Frozen artwork, source equivalence, scoped diff and whitespace | Passed | Image/input records, final review |
| Source/native and before/after visual QA | Passed, no remaining P0/P1/P2 finding | [design-qa.md](../../design-qa.md) |

The generic command was `xcodebuild -project ios/RocoHandbook.xcodeproj -scheme RocoHandbook -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/roco-phase13-xcode CODE_SIGNING_ALLOWED=NO build`.

UI commands used the same project/scheme/derived path, destination `platform=iOS Simulator,id=53209D2A-B509-4FC9-B464-7DB15A446055`, `-parallel-testing-enabled NO`, a fresh `-resultBundlePath` per run, and these focused selectors:

- `testAllDestinationsAndSevenToolRoutes`
- `testFavoritesNotesLayoutAndRestorePreservePersonalData`
- `testChineseToolsAndSettingsCaptures`
- `testToolsAndSettingsRemainReachableWithAccessibilityText`

The initial four-case selection recorded three passes and one capture assertion failure: a nominal 44-point frame was represented as `43.99999999999994`. The test now permits 0.001-point conversion rounding without lowering the target contract. Xcode then stalled in its own `simctl diagnose` collector; only that invocation-owned diagnostic process was stopped, retaining the result and attachments. Corrected/final runs use the supported per-run `-collect-test-diagnostics never` flag; no system security, network, or logging setting changed.

Independent visual comparison found a separate real P2 issue at maximum text: Settings symbols exceeded their fixed-width leading column. The column now scales with the body metric. The final generic build, normal/accessibility light cases, and actual-dark case passed on the repaired source; updated images were independently reinspected. This is a visual repair, not a change to actions or data.

Actual dark appearance was set and confirmed with `xcrun simctl ui <owned-id> appearance dark`; launch arguments were not treated as proof. The final collector reports dark, both exported pages are visibly dark, and the simulator was restored to light afterward.

## Final captures and comparison

| State | Tools | Settings |
| --- | --- | --- |
| Normal Chinese light | [Top](phase-13/tools-zh.png), [lower](phase-13/tools-lower-zh.png) | [Top](phase-13/settings-zh.png), [lower](phase-13/settings-lower-zh.png) |
| Normal Chinese dark | [Top](phase-13/tools-dark-zh.png), [lower](phase-13/tools-lower-dark-zh.png) | [Top](phase-13/settings-dark-zh.png), [lower](phase-13/settings-lower-dark-zh.png) |
| Maximum accessibility text, light | [Tools](phase-13/tools-large-text-zh.png) | [Appearance](phase-13/settings-large-text-zh.png), [lower actions](phase-13/settings-large-text-lower-zh.png) |

The [native preview](phase-13/native-preview.png) contains two real simulator captures. [Tools comparison](phase-13/tools-comparison.png), [focused image layout](phase-13/tools-focused-comparison.png), and [Settings comparison](phase-13/settings-comparison.png) place source and native views together. Browser captures are 375 x 812 pixels; native captures are 1206 x 2622 pixels, representing 402 x 874 points at 3x. Comparison copies normalize width to 375 pixels while preserving aspect. They explicitly compare a native adaptation: seven existing destinations, contained art, compact titles, and native navigation/controls replace website chrome and different content. They do not assert a pixel-identical site clone.

[Before/after accessibility comparison](phase-13/accessibility-repair-comparison.png) and the retained [pre-repair top](phase-13/settings-large-text-zh-before-fix.png) / [lower](phase-13/settings-large-text-lower-zh-before-fix.png) document the actual P2 repair. Maximum-text captures are intentionally separate from ordinary-size previews.

## Limits and next boundary

No full unrelated UI, data, or Swift package suite was repeated. Physical-device rendering, iOS 15 execution, VoiceOver, device contrast settings, signed upgrades/crash/low-storage durability, live signed Catalog updates, signing, store upload/review/publication, and user visual acceptance remain separate unrun layers. No credentials, real personal database, proxy settings, source import, fake release artifact, or publication is included. The next boundary is a separately scoped device/release check or user-requested visual refinement.
