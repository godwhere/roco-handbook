# Phase 15 offline attack coverage evidence

- Date: 2026-10-26, Asia/Shanghai
- Baseline: `6269aae`
- Validation mirror: `/tmp/roco-phase15-validation`, created from `git archive HEAD`

## Observed source and calculation

The packaged `wiki/type-relations-v1.json` contains eighteen real types and a no-type placeholder. Its source is `Module:TypeRelation`, page 12987, revision 39538, revised 2026-06-08, frozen by the existing import on 2026-09-09. This phase does not claim a new live chart import. The source URL, page/revision identity, SHA-1 format and revision date are validated by the new repository method and remain readable offline.

Fire has four super-effective and three resisted targets in that chart. Combination coverage takes the union of super-effective targets and intersection of resisted targets. The result order follows the chart; the no-type placeholder is excluded. Empty selection produces no classifications. Invalid selection, missing/renamed types, overlapping or unknown relationships and malformed provenance fail explicitly. Legacy creature relationship queries retain their previous contract.

## Validation status

The first Core implementation passed the full 33-test Swift suite (`/tmp/roco-phase15-swift.log`). Exact eighteen-type completeness checks were then added; all six focused coverage tests passed (`/tmp/roco-phase15-coverage-final.log`). Those tests use owned offline malformed fixtures and prove the previous relationship API still accepts its documented inputs.

| Check | Observed result | Local artifact |
| --- | --- | --- |
| Native packaging/localization | Four tests passed | `/tmp/roco-phase15-packaging.log` |
| Initial selected native run | One pass, two failures | `/tmp/roco-phase15-ui.log`, `/tmp/roco-phase15-native.xcresult` |
| Final selected native run | Three cases passed | `/tmp/roco-phase15-final-ui.log`, `/tmp/roco-phase15-final-native.xcresult` |
| Generic simulator build | Passed, unsigned | `/tmp/roco-phase15-build.log` |
| English-prose check | Passed | `/tmp/roco-phase15-prose.log` |
| Current-input equivalence, complete scoped review and whitespace | Passed | [Input receipt](phase-15/native-inputs.json), `git diff --check` |

Native commands use project `ios/RocoHandbook.xcodeproj`, scheme `RocoHandbook`, derived data `/tmp/roco-phase15-xcode`, `CODE_SIGNING_ALLOWED=NO`, and destination `platform=iOS Simulator,id=53209D2A-B509-4FC9-B464-7DB15A446055` for tests or `generic/platform=iOS Simulator` for the build. Test flags include `-parallel-testing-enabled NO`, `-collect-test-diagnostics never`, a unique result bundle and these selectors: `testAllDestinationsAndEightToolRoutes`, `testAttackCoverageSelectionLimitResetAndChineseCapture`, and `testToolsAndSettingsRemainReachableWithAccessibilityText`.

The initial route failure was a test precondition error: the simulator retained an explicit Chinese override, and the App correctly honored it rather than the English launch locale. Only the three selected cases now normalize Follow System through Settings, without erasing personal data or changing system preferences. The initial accessibility failure measured the source toolbar target at 36 points despite a larger SwiftUI label. Source now sits in the body header beside Reset, with its own accessibility-size action row. Final tests retain the 44-point assertions and additionally check header and action non-overlap; no acceptance threshold was weakened.

## Final captures

- [Fire coverage](phase-15/coverage-fire-zh.png)
- [Exact frozen source](phase-15/coverage-source-zh.png)
- [Maximum accessibility text](phase-15/coverage-large-text-zh.png)

The final normal capture shows original type icons, selected feedback and the four covered/three resisted Fire result. The accessibility capture shows growing one-column content; the test also scrolls back to verify the action row and source sheet. Native navigation/tab materials remain system-owned. Visual review found no actionable overlap or unreadable content.

The native target and source-equivalence receipt use copied, byte-verified workspace inputs. No real personal database, credential, downloaded executable, runtime endpoint, new asset or Catalog release is included. Build/test logs and result bundles remain under invocation-owned `/tmp` paths.

## Unrun boundaries

Physical devices, iOS 15 execution, VoiceOver, signed upgrades, live signed updates, store signing/upload/review/publication and later Wiki content imports are separate. Phase 15 delivers only the standalone frozen-chart tool. Source discovery for subsequent approved additions is read-only and does not alter this phase's data or release scope.
