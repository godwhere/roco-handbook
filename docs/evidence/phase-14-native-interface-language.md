# Phase 14 native interface language evidence

- Work dates: 2026-10-25 through 2026-10-26, Asia/Shanghai
- Source baseline: `237b17c`
- Native target: `RocoHandbook`, SwiftUI, iOS 15 deployment target
- Execution: iPhone 17 Pro simulator, iOS 27; unsigned local build

## Method and preservation

A fresh `git archive HEAD` populated `/tmp/roco-phase14-validation`. Edited native inputs were copied from the workspace and verified by SHA-256; [native-inputs.json](phase-14/native-inputs.json) records the final inputs. This avoids the historical cloud-backed-file read issue without altering source files, system settings, or personal data. Tests use owned temporary databases and the existing invocation-owned simulator. No real personal database is included in evidence.

The preference uses the existing personal settings table. Catalog, schemas, immutable assets, source revisions, dependency locks, and update/recovery implementations remain outside the changed paths. Interface translation selects bundled resources and does not write system language preferences. Canonical game text remains unchanged.

## Commands and results

| Check | Observed result | Local artifact |
| --- | --- | --- |
| `swift test --package-path ios --scratch-path /tmp/roco-phase14-spm` | 28 tests passed | `/tmp/roco-phase14-swift.log` |
| Final `swift test` with `--filter InterfaceLanguage` | Two matching tests passed with collection-mark isolation | `/tmp/roco-phase14-swift-isolation-final.log` |
| `PYTHONDONTWRITEBYTECODE=1 PYTHONPATH=tools python3 -m unittest discover -s tests -p 'test_native_ios.py'` | Four tests passed | `/tmp/roco-phase14-packaging.log` |
| Final generic iOS simulator `xcodebuild build`, `CODE_SIGNING_ALLOWED=NO` | Passed | `/tmp/roco-phase14-final-build.log` |
| Initial selected UI run | Three cases passed; later visual review found stale skill-option labels | `/tmp/roco-phase14-ui.log`, `/tmp/roco-phase14-language.xcresult` |
| Seven existing Tool routes | One case passed | `/tmp/roco-phase14-routes.log`, `/tmp/roco-phase14-routes.xcresult` |
| Repaired language lifecycle and maximum-text reachability | Two cases passed | `/tmp/roco-phase14-final-ui.log`, `/tmp/roco-phase14-final-language.xcresult` |
| Final compact English copy: language lifecycle and skill-layout preservation | Two cases passed | `/tmp/roco-phase14-final-copy.log`, `/tmp/roco-phase14-final-copy.xcresult` |
| Final native packaging/localization | Four tests passed | `/tmp/roco-phase14-final-packaging.log` |
| Final English-prose validation | Passed | `/tmp/roco-phase14-prose-final.log` |
| Final input equivalence, scoped review, and whitespace | Passed | SHA-256 receipt and `git diff --check` |

UI commands use `ios/RocoHandbook.xcodeproj`, scheme `RocoHandbook`, destination `platform=iOS Simulator,id=53209D2A-B509-4FC9-B464-7DB15A446055`, derived data `/tmp/roco-phase14-xcode`, a unique result bundle, `-parallel-testing-enabled NO`, and `-collect-test-diagnostics never`. The initial command also named a nonexistent route selector; Xcode executed only the three real selected cases. The real `testAllDestinationsAndSevenToolRoutes` was then run separately and passed. Counts above reflect executed cases.

The language lifecycle case explicitly chooses English, switches to Chinese while remaining on Settings, relaunches under unchanged English launch preferences, restores the bundled Catalog, verifies the saved Chinese preference, and returns to Follow System. The strengthened final case additionally checks immediately refreshed skill-layout options and the Chinese Follow System menu item before restart. The accessibility case checks reachability and the 44-point target at the maximum text category and retains restore cancellation and lower-page action checks.

## Captures and visual inspection

- [English Settings](phase-14/language-english.png)
- [Native language menu](phase-14/language-menu.png)
- [Chinese Settings after immediate switch](phase-14/language-chinese.png)
- [Maximum accessibility text](phase-14/settings-large-text-zh.png)
- [Retained pre-repair Chinese capture](phase-14/language-chinese-before-refresh-fix.png)

The retained pre-repair image shows the real defect: the skill-layout segmented options retained English after the rest of Settings changed to Chinese. Refreshing only language and skill-layout controls fixes that cached content while preserving Settings operation state. No whole-Settings identity reset is used. The English option is shortened to Detailed under the existing key to fit all three native segments. Final visual and independent review confirm translated labels, selected language, native menu choices and checkmark, wrapping, and nonoverlapping accessibility content. The three normal language captures come from the final compact-copy run; the maximum-text Chinese capture comes from the repaired accessibility run, whose Chinese copy and layout are unchanged.

## Limits

The full unrelated Python and UI suites were not repeated. Physical-device rendering, iOS 15 execution, VoiceOver, live signed Catalog update work, signed upgrade durability, signing, store upload/review/publication, and Wiki import/media acceptance remain unrun. Home-screen naming and iOS-owned strings are not controlled by this menu. Read-only Wiki observations and proposed additions are documented separately in [Wiki content review](phase-14-wiki-content-review.md).
