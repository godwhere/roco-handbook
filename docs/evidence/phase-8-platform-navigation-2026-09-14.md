# Phase 8 platform navigation evidence

- Date: 2026-09-14
- Flutter: 3.47.2
- Xcode: 26.6
- iOS SDK: 26.5
- iOS device: iPhone 17 simulator, iOS 26.5, 402 x 874 logical pixels at 3x density
- Android device: Roco API 36 emulator, Android 16, 1080 x 2057 captured pixels

## Captures

- iOS native navigation: `docs/evidence/phase-8-platform-navigation/ios-liquid-glass-home.png`
- Android M3 Expressive navigation: `docs/evidence/phase-8-platform-navigation/android-m3-expressive-home.png`
- Normalized iOS comparison: `docs/evidence/phase-8-platform-navigation/ios-source-comparison.png`
- Normalized Android comparison: `docs/evidence/phase-8-platform-navigation/android-source-comparison.png`
- Focused top and bottom navigation comparison: `docs/evidence/phase-8-platform-navigation/platform-navigation-focused-comparison.png`

The capture SHA-256 values are `1cc462e4629ec6bd1199d1b3291e91eab86337898e4530dc70d24d4968771da0` for iOS and `8c5c319b558aef96f9fa90104700c526d1e16eedc67bb0f2a09d70e44a605497` for Android.

## Observed behavior

The iOS 26.5 build rendered the App title, Catalog version, information action, and four primary destinations through native UIKit navigation. The system supplied the floating Liquid Glass tab presentation and glass-backed bar actions. Scrolling content and Catalog cards remained opaque, with no custom Flutter blur applied to reading surfaces.

The Android 16 build rendered the same four destinations through Material 3. The top app bar used a low tonal surface and rounded lower edge; the information action used a tonal circular container; and the bottom navigation used a pill indicator, stronger selected label, and size change. No translucent glass surface was introduced on Android.

Both captures preserve the selected light visual direction, exact frozen creature illustrations, source-backed copy, Wiki typography roles, and two-column Catalog geometry. Platform-specific navigation changes do not alter Catalog queries, user data, or offline behavior.

## Verification boundary

The UIKit bridge compiled with Xcode 26.6 and launched on the iOS 26.5 simulator. The Android debug APK built, installed, and launched on the API 36 emulator. Focused widget coverage selects both platform shells and exercises iOS fallback destination switching. The complete iOS and Android integration flow changed all four destinations, opened each Tool family and the shiny detail state, and completed without a failed assertion. Full Flutter, Python, formatting, analysis, Xcode platform tests, and diff checks are recorded in the Phase 8 implementation report.

Physical-device behavior, Reduce Transparency, Increase Contrast, Android dynamic color, signed archives, store upload, review, and publication were not validated.
