# Phase 8 assets, localization, and visual evidence

- Evidence date: 2026-09-10
- Decisions: ADR-0015 through ADR-0017
- Devices: iPhone 17 and iPhone 17 Pro simulators on iOS 26.5; Roco API 36 Android emulator

## Frozen source contracts

The image importer derived every required business reference from the active Catalog, resolved configured source titles through the MediaWiki API, and accepted only the configured image host and path prefix. The frozen manifest reports:

- 1,340 unique image files;
- 1,419 Catalog references;
- 97,655,049 local bytes; and
- manifest SHA-256 `414ef24f292b70cf4e48f1cddc716d7b7bd47afb7bde735f2feafcb291749756`.

The complete set contains 569 distinct creature illustrations, 736 skill or feature icons, and 35 domain UI icons. Shared illustration keys cover all 596 active forms, and every active skill or feature has a resolvable icon. ADR-0016 removes the 596 previously bundled head files while preserving the upstream `head_key` values in the Catalog.

The App-side packaging regression opened the real bundled Catalog read-only, resolved illustrations for all 596 active forms, all 788 active skill or feature records, and all 18 type records through the production asset helpers, and found every resulting path in Flutter's generated asset manifest. Shared image keys account for the differences between active records and distinct files.

The complete-Catalog stat audit found 595 active forms with all six base-stat values and one source-incomplete form, `pet_000535`, with all six values absent. The domain total returns 582 for the verified Dimo record and null for the incomplete record, preserving the documented no-zero-fill rule. The type audit also resolved the actual one- or two-type combination of all 596 active forms and produced only supported `0.25`, `0.5`, `2`, or capped `3` multipliers.

The type relationship contract freezes `Module:TypeRelation` page ID 12987, revision 39538, timestamp `2026-06-08T19:57:39Z`, and source SHA-1 `f44cdbb07c94454696c9e8560b53dd5cc12890ca`. Its local SHA-256 is `72ceba2bf9d149a6a162a7a4dbca9215e61718f39ff54daee98b2fbf35f1f07b`. It preserves 19 source type records and eight reviewed inverse-list exceptions.

The Flutter localization suite compares the UI's source-grounded domain vocabulary with every applicable entry in `config/ui_terminology_zh_cn.json` and accounts for the source-page-only `creature_handbook` term. It also checks every literal BuildContext `.tr(...)` call for a distinct Chinese mapping and rejects fixed visible copy that bypasses the localization entry point. All three regressions passed as part of the current 102-test Flutter suite.

The Chinese-locale top-level smoke test rendered and navigated the creature search, skill search, personal library, Settings, and Catalog information interfaces. It observed localized labels in every section and passed as part of the current 102-test Flutter suite. A separate widget regression confirms that both an absent asset path and a failed bundled-asset load retain the declared accessible image label while showing the local fallback icon. The ADR-0017 regression renders exact default and named-form card copy, checks the inline form and `NO.<dex_no>` row, locks the 100-logical-pixel illustration and compact padding, confirms list favorites are absent and detail favorites are present, locks both one-to-one-to-two toolbars, exercises the modal filters, and verifies derived stage plus lord-evolution copy.

## Brand asset identity

The formal icon and launch generator reads the frozen Dimo illustration with SHA-256 `485d76e697b8f75d63a4036cf534c146b7d22addde663b831f80900e7018eb77`. Regression checks lock the exact inventory, dimensions, and SHA-256 values of all 24 iOS and Android icon or launch-image slots. Representative reviewed outputs are:

| Platform asset | Pixels | SHA-256 |
| --- | ---: | --- |
| iOS marketing App icon | 1024 × 1024 | `b6d3277e8eba499b6d81a47108f5959b283b01e7755b80051e515f7dace4ab89` |
| iOS 3× launch mark | 600 × 600 | `29750876e644a50ebb4fc830f0eec2251c8340ccde2a70af66f910a6bd51d24a` |
| Android xxxhdpi launcher icon | 192 × 192 | `b6c9d5481836160ed5af1ec73acb8914907b404381bff662aa47b54ddddb4076` |
| Android launch mark | 384 × 384 | `062afaefdc8993ba61a5d30cbf014f947c7fa375da8a6c175c21f031fdd1eafe` |

### Product rename verification on 2026-09-11

The Chinese product name was shortened to **洛克手册** without changing the English name, Android application ID, iOS Bundle ID, App version, Catalog dataset, or personal-data identity. The same Chinese value now owns the Flutter `zh-CN` title, iOS `CFBundleDisplayName`, Android `application-label`, and root project heading.

The complete 101-test Python suite and 115-test Flutter suite passed after the rename, and Flutter analysis reported no issues. The current iOS Simulator debug build succeeded; the focused Runner platform test passed on the iPhone 17 simulator, and the built App's `Info.plist` returned the new value. The current Android debug APK also built successfully, and Android build-tools inspection returned the new `application-label`. Reinstalling and launching the current iOS build showed the new title in the implemented creature Catalog header.

The existing store screenshot set predates both this rename and the ADR-0019 typography revision. It remains historical evidence and must be regenerated before any store submission.

## Placeholder and temporary-content audit

The tracked production Flutter source, iOS Runner resources, and Android main resources contain no Flutter counter-demo copy, Lorem Ipsum, sample-App text, temporary visual asset, or default Flutter logo. The App disables the debug banner. The exact 24-file brand inventory check prevents an unreviewed image or missing platform size from remaining in an icon or launch slot.

The standard Android debug manifest and iOS `Debug.xcconfig` remain development-only build configuration, not production copy or visual assets. Interface Builder's `IBFirstResponder` placeholder nodes remain required storyboard infrastructure. The accessible missing-image fallback remains intentionally present because ADR-0015 requires controlled local degradation; it is not a shipped substitute for any current Catalog image, as the complete packaging regression resolves every active image reference.

## Simulator and emulator observations

The current Phase 8 source was rebuilt and installed on both virtual platforms. The iOS simulator and Android emulator displayed:

- the formal Chinese App name and localized navigation;
- enlarged full creature illustrations in the Catalog list and detail page;
- the compact Search, Sort, and Types row plus matching sort and type bottom sheets;
- the six base stats and calculated `种族资质总和`;
- incoming and outgoing `属性克制` values with domain icons; and
- feature and learnable-skill imagery in the creature detail flow.

The repository owner separately observed the implemented skill imagery in the iOS simulator. No additional skill-image observation is claimed here.

After the iOS Simulator window was closed, the current working source was rebuilt, installed, and launched on the still-booted iPhone 17 simulator. A fresh 1206 × 2622 capture confirmed the localized creature Catalog and bundled creature imagery, distinguishing a successful reinstall from a cached home-screen icon. The ADR-0016 build was then installed again on the same simulator and on the Android API 36 emulator. Fresh capture artifacts record the Sort/Types/Search row, rounded Search field, handbook number below each illustration, and enlarged full illustrations. Final subjective acceptance of this revision remains with the repository owner.

## ADR-0017 handbook and detail review

The current source was rebuilt, installed, and launched on the iPhone 17 simulator after the complete ADR-0017 presentation changes. The final 1206 x 2622 captures confirmed:

- the denser creature catalog with a 100-logical-pixel full illustration, complete adaptive single-line form label, far-right `NO.<dex_no>`, accessible type icons, and no list favorite;
- First, Second, Third, and Lord form detail labels derived from preserved fields, with a normal creature explicitly showing No for Lord evolution;
- creature type icons directly after the detail name without a white chip background;
- creature and skill favorite controls in their respective detail headers;
- skill element icons immediately after skill names;
- the Skill handbook, Skill filters, and Skill query toolbar; and
- skill cards with category, energy, power, source description, element icon, and no list favorite.

The skill filter regression covers the four declared skill types, 20 accepted labels, and 18 combat elements. Type and element values use preserved Catalog fields. The 20 labels are read-only filter projections over preserved source descriptions or description-note identifiers where no first-class tag field exists; no inferred value is written back to the Catalog. Values use OR inside one group and the selected groups combine with AND.

| Capture | SHA-256 |
| --- | --- |
| `phase-8-detail-redesign/ios-creature-catalog.png` | `b1b0e00a7bc08b5743a1a5fbe37a98c5e16519cc904b3039e978fb15ec3c9d17` |
| `phase-8-detail-redesign/ios-creature-form-subtitle.png` | `97532a3fdf0bd30b06609a708c592d9c6db7673b3d562e93ab9fbe73e5fb6e5a` |
| `phase-8-detail-redesign/ios-creature-header.png` | `6b4306901b9dead7f32756e59212065d0284f1909f485c7aa7fbc01fd9693573` |
| `phase-8-detail-redesign/ios-skill-catalog.png` | `fa81a12f638c8908f5e2bb3c36c8b0c8340f2a306554f18ef12ca243989d8153` |
| `phase-8-detail-redesign/ios-skill-detail.png` | `2d81d8e001451225deb820b529231b5edfea7d924c345d2b0bb156b117e35c08` |

`design-qa.md` records the side-by-side reference comparison and final checklist. The current ADR-0017 revision was not re-reviewed on Android or a physical device.

## Store screenshot set

The reviewed captures follow the current official submission constraints recorded on 2026-09-10:

- [Apple screenshot specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/) accept 1206 × 2622 portrait screenshots for the 6.3-inch iPhone display class and require RGB images without transparency.
- [Google Play preview asset requirements](https://support.google.com/googleplay/android-developer/answer/9866151?hl=en) require PNG or JPEG screenshots without alpha, dimensions from 320 through 3840 pixels, and a maximum dimension no greater than twice the minimum dimension. They recommend at least four 1080 × 1920 portrait screenshots for app promotion eligibility.

The iOS captures retain their exact simulator dimensions. The Android captures use a measured 1080 × 2057 emulator viewport whose 137-pixel status bar is removed, producing 1080 × 1920 App-content images without stretching. All eight files are then losslessly normalized to 8-bit sRGB PNGs without alpha. No marketing frame, caption, or content overlay is added.

| Platform | File | Pixels | SHA-256 |
| --- | --- | ---: | --- |
| iOS | `phase-8-store-screenshots/ios/01-creature-catalog.png` | 1206 × 2622 | `cc96331a910aafa413fe0cf60e1a3f1268e0619fb6030bfb35a44f115bf72200` |
| iOS | `phase-8-store-screenshots/ios/02-creature-detail-stats.png` | 1206 × 2622 | `df3e4086acaba4e7902af0b03bd052a03f144e47f67b408aff85dccf17380b20` |
| iOS | `phase-8-store-screenshots/ios/03-type-relationships.png` | 1206 × 2622 | `e3f6599ab17d5b20aa9ddeed67e3e72d995f8c91c1efdc6e8004f4faf3458196` |
| iOS | `phase-8-store-screenshots/ios/04-skill-catalog.png` | 1206 × 2622 | `c1c15da973bdcba0c09e99544f123abc6bb885b70def42a4f8e9338003de2931` |
| Android | `phase-8-store-screenshots/android/01-creature-catalog.png` | 1080 × 1920 | `f79e85dd4627c680264fe0021ff30a44c7cfdee51958b5f5428a41741fe32cb2` |
| Android | `phase-8-store-screenshots/android/02-creature-detail-stats.png` | 1080 × 1920 | `d8987442f5c01d6f3818dc678ec2567b8736f915cdccac13b17d4e3ba19c5fb9` |
| Android | `phase-8-store-screenshots/android/03-type-relationships.png` | 1080 × 1920 | `26cc36d9091e39ce204b1beb30acd1d2b31f0f850b51d560b3c0f1b082c91d89` |
| Android | `phase-8-store-screenshots/android/04-skill-catalog.png` | 1080 × 1920 | `bf9bd07db5b0412e8c3e110091fc2fc20c2774cf06f4766200b83cf5ed6f9ae1` |

The regression gate requires the exact four-file inventory for each platform, the recorded dimensions, 8-bit RGB PNG encoding without alpha, an 8 MB maximum per file, and the Android two-to-one maximum aspect ratio. The Android captures use the Chinese locale and exclude emulator notification artifacts together with the cropped status bar.

## Local builds

The current `1.1.0` build `2` source built successfully with the complete frozen image set:

- Android Release AAB: 158,152,015 bytes reported as 158.2 MB by Flutter; SHA-256 `5ad3b961b314a2f6cbe6999e741554b92e5a5eab758d28d87f4bc8543ff16cd3`.
- iOS no-codesign Release App: 122,644 KiB reported as 122.8 MB by Flutter; the embedded version remains 1.1.0 build 2, and the App framework binary SHA-256 is `6d0e0d6f848063dd9e5ea1397f91066d0378f7e09da28a9957a0a8abbdcd4b50`.
- iOS simulator App and Android debug APK: both built, installed, launched, and supplied the screenshot observations above.

The generated build products remain ignored and untracked. The package sizes are the measured cost of shipping the complete offline image library; ADR-0016 reduces that library by 9,221,952 uncompressed bytes by removing unused heads.

The focused `RunnerTests` iOS suite also passed on the iPhone 17 Pro simulator. It verifies that the built application exposes the published Chinese display name and `world.roco.rocoHandbook` Bundle ID; the generated empty example test is no longer present.

## Hosted validation

GitHub Actions run [34400308182](https://github.com/godwhere/roco-handbook/actions/runs/34400308182) executed the `Offline validation` workflow against commit `94ee692d9fc30ef33f9937116c891773d425a489`. The run started at `2026-09-09T20:19:10Z`, completed at `2026-09-09T20:20:29Z`, and reported `success`.

## Evidence boundary

These observations prove virtual-platform rendering of the rebuilt source. They do not prove physical-device launch, memory pressure, storage behavior, accessibility services, signing, archive export, store upload, review, or publication. The Phase 6 physical-device waiver remains unchanged.
