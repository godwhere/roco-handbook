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
- Focused bottom-navigation comparison in source, iOS, and Android order: `docs/evidence/phase-8-platform-navigation/platform-navigation-focused-comparison.png`
- Android bottom-navigation before and after comparison: `docs/evidence/phase-8-platform-navigation/android-floating-navigation-before-after.png`
- iOS progressive bottom blur: `docs/evidence/phase-8-platform-navigation/ios-progressive-blur.png`
- Android progressive bottom blur: `docs/evidence/phase-8-platform-navigation/android-progressive-blur.png`

The current capture SHA-256 values are `b2585a7f1f93470a0ad825883a9d662a147951792daf408ccdfeac55a4990247` for iOS and `e6fe85c74a57cb5308db4410d16b3a86863160e5e381d9bf884a1d30fe747134` for Android.

The progressive-blur capture SHA-256 values are `b3a43b8b96a2dac3d5c599efa318fc34fb2f8f1cd1996d507039b2e2102dfb22` for iOS and `9fda1ee2125f8a4557af307d6271f398fddc90db59185e5969ec917ecf406c94` for Android.

## Observed behavior

The iOS 26.5 build rendered the creature-root branded hero through Flutter and the four primary destinations through native UIKit navigation. The system supplied the floating Liquid Glass tab presentation. Non-root top navigation continues to use the native UIKit bridge. Opaque Catalog cards now continue behind the floating tab bar, while a shared low-intensity backdrop softens only the former safe-area boundary without applying glass to a reading surface.

The Android 16 build rendered the same branded creature hero and four destinations through Material 3. The complete bottom navigation floated inside a stadium surface with 16 logical pixels of horizontal margin, a gesture-safe bottom inset, a tonal fill, a light outline, and low shadow. All four localized labels remain visible, the first destination uses the standard Material pet symbol instead of the earlier text-bearing Wiki image, and the inner bar is 72 logical pixels high. The selected destination keeps its separate pill indicator and size change. Catalog cards continue behind the opaque navigation surface; only the shared low-intensity boundary backdrop samples content, and Android does not imitate the iOS system glass material.

Both captures preserve the selected light visual direction, exact frozen creature illustrations, source-backed copy, Wiki typography roles, and two-column Catalog geometry. The shared body-extension contract increases the bottom content range, while result lists add the navigation inset to their trailing padding so the final card remains reachable. Platform-specific navigation changes do not alter Catalog queries, user data, or offline behavior.

The current ordinary-install captures verify the later progressive treatment. Content entering the upper edge of the navigation region remains nearly clear, while the card imagery below each bar becomes increasingly diffused toward the system gesture edge. No hard horizontal band, clipped navigation item, or blurred reading surface was observed. Android exposes the progression more directly; iOS combines the shared transition with the operating system's own Liquid Glass sampling.

## Verification boundary

The UIKit bridge compiled with Xcode 26.6 and launched on the iOS 26.5 simulator. The Android debug APK built, installed, and launched on the API 36 emulator. Focused widget coverage verifies body extension for both platform branches plus the Android floating safe-area margin, stadium surface, clipping, elevation, transparent inner navigation, visible-label behavior, stable destination keys, and 72-logical-pixel height. The complete iOS and Android integration flows changed all four destinations, opened each Tool family and the shiny detail state, and completed without a failed assertion. Full Flutter, Python, formatting, analysis, Xcode platform tests, and diff checks are recorded in the Phase 8 implementation report.

Physical-device behavior, Reduce Transparency, Increase Contrast, Android dynamic color, signed archives, store upload, review, and publication were not validated.
