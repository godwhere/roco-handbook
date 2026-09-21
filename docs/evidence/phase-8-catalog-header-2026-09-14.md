# Phase 8 branded Catalog header evidence

## Scope

This evidence covers the creature-root branded header. It replaces only the ordinary root top bar and toolbar composition. Other page navigation, Catalog queries, domain models, personal data, and offline behavior remain unchanged.

## Source, generated asset, and captures

- User-supplied visual source: `docs/evidence/phase-8-catalog-header/source.png`
- Generated decorative background: `app/assets/brand/v1/catalog-header-background.png`
- iOS capture: `docs/evidence/phase-8-catalog-header/ios-home.png`
- Android capture: `docs/evidence/phase-8-catalog-header/android-home.png`
- Focused source, iOS, and Android comparison: `docs/evidence/phase-8-catalog-header/source-ios-android-comparison.png`
- Immersive iOS capture: `docs/evidence/phase-8-catalog-header/ios-immersive-header.png`
- Previous and immersive iOS top-region comparison, left to right: `docs/evidence/phase-8-catalog-header/ios-immersive-header-before-after.png`

The built-in ImageGen pipeline produced only the pale decorative bitmap. The final edit prompt was: "Keep the pale white and ice-blue star background and open content area; add one tiny warm-yellow four-point sparkle plus a short thin curved golden swoosh near the upper-left title zone; preserve ample blank space; no text, letters, buttons, interface icons, characters, logos, borders, or watermark." All visible title, tagline, data-version, information, sort, type, and search content remains live, localized Flutter UI.

## File identities

```text
catalog-header-background.png  f11e64f2a1eeb5331de9450fd0a67ec010e272301b210ac69bbe8e24f8d49aef
source.png  240765f5e1a278075dd4dcbdb967be617306b9b0dc5849a091c0015569932bbf
ios-home.png  5d3ed3a3e3fcce3f45ed6ae666423110d72f6ef8a27968eef9917ba1cc2627c3
android-home.png  790c4b3229f5a3506fea82847ac2826e0014d25df438331a257b508d9dcac03a
source-ios-android-comparison.png  7420ffe981cc06c4b69980d906b76972dec041ebe7bea2f55cc6a1843c13d4a5
ios-immersive-header.png  a76d4261488c80aaa815572bc45fd038f714227b4052e518ce8e4c5195f4972b
ios-immersive-header-before-after.png  91223b14508a1816cc88c8d5fa910a378d301b6b61d4a9d1f79db73fb7824d50
```

## Immersive status-bar refinement

The 2026-09-15 refinement removes the independent blank top band, top margin, and top corner rounding from the creature-root hero. The same frozen background now begins at the screen edge and paints behind a transparent status bar. Inset-aware internal padding keeps the title, data action, information action, and toolbar below the system boundary. Dark status-bar foreground content is requested for the reviewed light state; the App requests light foreground content when the hero is darkened by the active theme.

The focused before-and-after comparison uses two ordinary iPhone 17 simulator captures at the same 1206 x 2622 pixel viewport. Each source was cropped to the same top 1206 x 820 pixel region and placed side by side without changing App content. The implementation removes the previous white separation while preserving the system clock, Dynamic Island, connectivity indicators, title hierarchy, and control geometry.

## Verification boundary

Focused widget checks verify that the branded hero, localized tagline, data-version action, information action, and one-row controls render at the creature root. The status-bar regression additionally verifies an edge-to-edge hero origin, exact top-inset padding, bottom-only rounding, transparent system background, and matching light-theme icon brightness. The current immersive capture was built, ordinarily installed, launched, and captured on the iPhone 17 simulator. Earlier iOS and Android integration captures show the shared hierarchy at phone dimensions. The screenshots are working evidence, not store-submission assets.

The current Android top treatment was compiled into the debug APK but was not recaptured on an emulator. Physical-device rendering, accessibility display settings, signed archives, store upload, review, and publication were not validated.
