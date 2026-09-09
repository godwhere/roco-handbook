# Phase 8 assets, localization, and visual evidence

- Evidence date: 2026-09-10
- Decision: ADR-0015
- Devices: iPhone 17 Pro simulator on iOS 26.5; Roco API 36 Android emulator

## Frozen source contracts

The image importer derived every required business reference from the active Catalog, resolved configured source titles through the MediaWiki API, and accepted only the configured image host and path prefix. The frozen manifest reports:

- 1,936 unique image files;
- 2,015 Catalog references;
- 106,877,001 local bytes; and
- manifest SHA-256 `6433b65b637f752d68ec572c16696597db81fe4822e9626f6dfd9ff1d132fd0d`.

The complete set contains 596 creature heads, 569 distinct creature illustrations, 736 skill or feature icons, and 35 domain UI icons. Every active creature has a resolvable head and illustration; every active skill and feature has a resolvable icon. Nine absent source head files are recorded as explicit same-record illustration fallbacks.

The type relationship contract freezes `Module:TypeRelation` page ID 12987, revision 39538, timestamp `2026-06-08T19:57:39Z`, and source SHA-1 `f44cdbb07c94454696c9e8560b53dd5cc12890ca`. Its local SHA-256 is `72ceba2bf9d149a6a162a7a4dbca9215e61718f39ff54daee98b2fbf35f1f07b`. It preserves 19 source type records and eight reviewed inverse-list exceptions.

## Simulator and emulator observations

The current Phase 8 source was rebuilt and installed on both virtual platforms. The iOS simulator and Android emulator displayed:

- the formal Chinese App name and localized navigation;
- creature head images in the Catalog list;
- a full creature illustration on the detail page;
- the six base stats and calculated `种族资质总和`;
- incoming and outgoing `属性克制` values with domain icons; and
- feature and learnable-skill imagery in the creature detail flow.

The repository owner separately observed the implemented skill imagery in the iOS simulator. No additional skill-image observation is claimed here.

## Store screenshot set

The screenshots are raw virtual-device captures with no marketing frame or post-processing:

| Platform | File | Pixels | SHA-256 |
| --- | --- | ---: | --- |
| iOS | `phase-8-store-screenshots/ios/01-creature-catalog.png` | 1206 × 2622 | `09e5a4667ac5387cea4cbd52fcd014438b707ad777fcb2256957c364e8d42808` |
| iOS | `phase-8-store-screenshots/ios/02-creature-detail-stats.png` | 1206 × 2622 | `4b9bc60086ea87d379a9cca1016326cadc2659c8290ab7dd054f97c14bf22ffd` |
| iOS | `phase-8-store-screenshots/ios/03-type-relationships.png` | 1206 × 2622 | `0f32ee2ede7b5011446a1fd61c9d96a91cbd4b35848bf10b828232ac5d6cbce1` |
| iOS | `phase-8-store-screenshots/ios/04-skill-catalog.png` | 1206 × 2622 | `9bda1c5506e4f5da53dc22b86e869374e128f2dbe6a790a9e317bfe78cd95d43` |
| Android | `phase-8-store-screenshots/android/01-creature-catalog.png` | 1080 × 2424 | `cbd389a6e2a32fe46c6758e1a9d76951eadb3c462028698ed2b80f505f5a326e` |
| Android | `phase-8-store-screenshots/android/02-creature-detail-stats.png` | 1080 × 2424 | `3f6b15937ebf928f5d2646d16ec29c6d89795fef2a7f2c6f420243340ec5bec7` |
| Android | `phase-8-store-screenshots/android/03-type-relationships.png` | 1080 × 2424 | `542168e12205c7ffb490d537e894cedbd0649ec515ed65a565b1e665c882e556` |

The Android captures use the Chinese locale and omit the airplane-mode status used by earlier offline test evidence.

## Local builds

The current `1.1.0` build `2` source built successfully with the complete frozen image set:

- Android Release AAB: 167,411,505 bytes reported as 167.4 MB by Flutter; SHA-256 `8087d21c2023200ac2dce65aa8b3c3dadc5c8265601d1aea8bd251ccf007f8a5`.
- iOS no-codesign Release App: 133,024 KiB reported as 132.2 MB by Flutter; the embedded display name is the declared Chinese App name, and the App framework binary SHA-256 is `e8d2d8df1f5639fdc3bf447bd27b1deb9c29bb1db8465bf5a27605617fd62642`.
- iOS simulator App and Android debug APK: both built, installed, launched, and supplied the screenshot observations above.

The generated build products remain ignored and untracked. The larger package sizes are the measured cost of shipping the complete image library for offline use.

## Evidence boundary

These observations prove virtual-platform rendering of the rebuilt source. They do not prove physical-device launch, memory pressure, storage behavior, accessibility services, signing, archive export, store upload, review, or publication. The Phase 6 physical-device waiver remains unchanged.
