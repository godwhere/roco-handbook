# Phase 11 Roco Tools and Settings evidence

- Date: 2026-10-25, Asia/Shanghai
- Scope: ADR-0031; user-requested native visual update
- Baseline commit: `8cdff58` (Phase 10, committed and pushed through GitHub Desktop)
- Simulator: iPhone 17 Pro / iOS 27, `Roco Phase 10` (`53209D2A-B509-4FC9-B464-7DB15A446055`)
- Tools: Xcode 27.0, Swift 6.4, Python 3.13

## Baseline and design

The actual native Tools and Settings pages were captured before their presentation changed. `testChineseToolsAndSettingsCaptures` passed against the Phase 10 App, and the exported [Tools baseline](phase-11/tools-before.png) and [Settings baseline](phase-11/settings-before.png) were visually inspected. The plain List/Form used system-gray backgrounds and blue icons; Settings' segmented controls did not visibly show the separate layout labels.

One initial capture dispatch selected the new test before its source had been copied to the local mirror. That owned run was stopped and is not acceptance evidence. The corrected copy was rebuilt and the actual one-case baseline capture passed; logs/result are `/tmp/roco-phase11-before-final.log` and `/tmp/roco-phase11-before-final.xcresult`.

The final treatment reuses the existing Wiki display font and immutable Miaomiao/Shuilanlan illustrations. Warm paper, forest green, and gold distinguish this pair of pages without changing the creature/skill/detail theme. All illustrations and icon badges used decoratively are hidden from accessibility. Card/action targets are at least 44 points, text wraps naturally, and the two layout Pickers use native menus at accessibility sizes.

After the user requested smaller text, the normal hierarchy was reduced to 21-point header titles, 16-point Tool titles, 17-point Settings section titles, 72-point header art, and 64-point Tool card minimums with smaller padding. Tool subtitles use platform footnote text and Settings rows use subheadline text. The final normal Chinese Tools capture shows all seven entries together; maximum accessibility text remains independently scaled and is labeled separately. At accessibility sizes the header omits its decorative brand/subtitle/art, retaining a smaller scalable title so actions appear earlier.

Custom secondary ink has separate light/dark values. Static sRGB calculations for that ink against the paper surface and strongest forest header wash are respectively 6.18:1 / 5.14:1 in light mode and 8.60:1 / 6.59:1 in dark mode. These calculations supplement simulator inspection; they do not establish device accessibility acceptance.

## Checks and logs

- Four native packaging/localization cases passed: `/tmp/roco-phase11-native-contracts.log`.
- Generic iOS simulator build passed: `/tmp/roco-phase11-build.log`; the existing non-failing App Intents metadata note remains.
- Baseline screenshot case: one passed, two images exported and reviewed.
- Independent read-only source review verified all seven routes/IDs, iOS 15 API compatibility, unchanged update/check/install/cancel logic and recovery confirmation, unchanged child screens, existing art paths, and no wider runtime network authority. It identified the intrinsic Download/Cancel targets after leaving Form; both now have explicit 44-point targets.

The ordinary runtime never requests the network for this styling. No fake remote candidate, live update, real personal database, or upstream import was used.

The initial `AppleInterfaceStyle` launch argument did not actually switch UIKit to dark appearance; those light images were rejected as dark-mode evidence. Final mode checks instead boot the invocation-owned simulator, use `xcrun simctl ui 53209D2A-B509-4FC9-B464-7DB15A446055 appearance dark`, confirm the reported value, and run the same generic Chinese capture case. No production test hook or application appearance override was added. The simulator is returned to light appearance after capture.

## Final compact-design verification

| Check | Observed result | Evidence |
| --- | --- | --- |
| Native packaging/localization plus English-prose tests | Five passed | `/tmp/roco-phase11-contracts-final.log` |
| Generic simulator build, `CODE_SIGNING_ALLOWED=NO` | Passed for final App sources | `/tmp/roco-phase11-compact-build.log` |
| Light-mode UI selection | Four passed | `/tmp/roco-phase11-compact-light.log`, `.xcresult` |
| Actual dark-mode Chinese capture | One passed; both images are visibly dark | `/tmp/roco-phase11-compact-dark.log`, `.xcresult` |
| Source-equivalence receipt | Current native source inputs match local mirror bytes | `/tmp/roco-phase11-validation-receipt.json` |
| Complete scoped diff / `git diff --check` | Passed | Final review before GitHub Desktop delivery |

Commands ran from `/tmp/roco-phase10-validation` with byte-matching repository inputs. The generic build used `xcodebuild -project ios/RocoHandbook.xcodeproj -scheme RocoHandbook -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/roco-phase10-xcode CODE_SIGNING_ALLOWED=NO build`. UI runs used the same project/scheme/derived path, destination `platform=iOS Simulator,id=53209D2A-B509-4FC9-B464-7DB15A446055`, disabled parallel testing, and selected the following cases:

- `testChineseToolsAndSettingsCaptures`: normal Chinese text, run once with the simulator reporting `light`, then again with it reporting `dark`.
- `testAllDestinationsAndSevenToolRoutes`: every existing Tool destination and reachable Settings recovery action.
- `testFavoritesNotesLayoutAndRestorePreservePersonalData`: saved layout, favorite, and note preservation through restore and restart.
- `testToolsAndSettingsRemainReachableWithAccessibilityText`: maximum accessibility text, native menu Pickers, natural wrapping, 44-point rows, reachable last Tool/source-license actions, and recovery-confirmation cancellation.

The final UI selection passed after the user's smaller-text clarification. The initial larger-header and ineffective-dark-argument trial captures are not the delivered previews. All seven final captures below were visually inspected; an independent helper checked the three maximum-text images for clipping, overlap, and inaccessible controls and found no blocker.

| Appearance | Tools | Settings |
| --- | --- | --- |
| Normal light | [Tools](phase-11/tools-zh.png) | [Settings](phase-11/settings-zh.png) |
| Normal dark | [Tools](phase-11/tools-dark-zh.png) | [Settings](phase-11/settings-dark-zh.png) |
| Maximum accessibility text | [Tools](phase-11/tools-large-text-zh.png) | [Settings](phase-11/settings-large-text-zh.png), [lower actions](phase-11/settings-large-text-lower-zh.png) |

No new source data, Catalog/Tool JSON, schema, immutable art/font, dependency, release setting, or runtime transport changed. Source comparison proves that Tool child views, Catalog information/license views, and the update check/install implementations remain unchanged. The owned test simulator reports `light` again after final capture.

## Verification limits

Simulator capture/XCUITest accessibility queries do not prove physical-device rendering or VoiceOver usability. iOS 15 execution, device accessibility/contrast settings, physical signed upgrades, crash/low-storage durability, live signed-update publication/install, and store upload/review/publication remain unrun. The complete prior UI suite and data/Swift package suites are not automatically repeated for presentation-only edits; Phase 10 retains their separate evidence.
