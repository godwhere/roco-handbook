# Phase 8 platform navigation design QA

- Review date: 2026-09-14
- Source visual truth: `/Users/ethan/.codex/generated_images/01a084ad-ac2c-7d23-9db4-d6fa0b1cfbbb/exec-6ed72adb-da77-435d-906c-a20036587ddc.png`
- iOS implementation: `docs/evidence/phase-8-platform-navigation/ios-liquid-glass-home.png`
- Android implementation: `docs/evidence/phase-8-platform-navigation/android-m3-expressive-home.png`
- Full-view comparisons: `docs/evidence/phase-8-platform-navigation/ios-source-comparison.png` and `docs/evidence/phase-8-platform-navigation/android-source-comparison.png`
- Focused comparison: `docs/evidence/phase-8-platform-navigation/platform-navigation-focused-comparison.png`
- States: `zh-CN`, light theme, creature grid, first four Dimo forms, first destination selected

## Normalization

The source is 853 x 1844 pixels. The iOS capture is 1206 x 2622 pixels at a 402 x 874 logical viewport and 3x density. Both were center-fitted to 603 x 1311 before horizontal composition. The Android capture is 1080 x 2057 pixels and was center-fitted with the source to a common comparison frame. The focused comparison independently places the source beside each implementation's top and bottom navigation regions.

## Full-view comparison evidence

Both implementations preserve the selected direction's title/version hierarchy, compact Sort/Filters/Search control group, two-column illustrated Catalog, type-aligned card colors, and four equal primary destinations. The source's castle, cloud, star, and glass-card decoration is intentionally absent from production: the user limited glass to preserve reading clarity, the decorative bitmap is not an approved offline source asset, and Catalog content remains an opaque information layer.

The iOS capture preserves the source's floating translucent navigation hierarchy through native UIKit. System Liquid Glass appears on the version, information, and tab-bar navigation layer without adding a custom Flutter blur to cards or text. The Android capture intentionally translates the same hierarchy into M3 Expressive with a tonal app bar, circular tonal information action, rounded sheet contract, pill selection indicator, and stronger selected label instead of copying iOS translucency.

## Focused comparison evidence

The focused top and bottom regions confirm that title, version, information, and four destination labels remain fully visible on both platforms. iOS uses the system's optical material, native SF symbols, and floating bar proportions. Android uses opaque tonal surfaces, Material icons, a larger selected indicator, and platform system-bar spacing. No persistent navigation control overlaps the safe areas or loses its selected state.

## Required fidelity surfaces

- Fonts and typography: Catalog display text retains the approved `RocoDisplay` role and identifiers retain `RocoNumbers`. Native iOS navigation uses the system face and SF Symbols, while Android navigation uses the display label role; this is an intentional platform distinction. Titles and labels remain single-line and legible.
- Spacing and layout rhythm: the two-column grid and control-row geometry remain unchanged. Both navigation bars respect platform safe areas. The iOS bar floats above content; Android reserves an opaque Material navigation surface.
- Colors and visual tokens: iOS lets the system adapt Liquid Glass contrast. Android derives tonal surfaces and selection colors from the App `ColorScheme`. Content-card colors match the accepted blue, gold, green, and red grouping.
- Image quality and asset fidelity: every Catalog card uses the exact frozen Wiki illustration and type icon. No screenshot raster, custom SVG, emoji, placeholder, or generated navigation icon replaces a source asset or platform symbol.
- Copy and content: source names, form labels, `NO.<dex_no>`, data version, and destination labels remain data-backed or localized. No concept-only tagline was added.

## Interaction and accessibility evidence

Focused widget coverage selects the iOS and Android shells, changes destination through the Cupertino test fallback, and checks the M3 theme geometry. The iOS integration flow changes all four destinations through the labeled Flutter hit regions over the native platform view and opens Flutter-owned child routes. Both platform builds launched successfully. Native iOS top-bar buttons carry accessibility labels, the bottom bar uses Flutter-owned destination semantics without duplicating the hidden native item semantics, and Material destinations retain Flutter semantics. The complete Flutter suite covers dark theme and a 2.0 text scale.

## Findings

No actionable P0, P1, or P2 mismatch remains. The platform differences are intentional translations of one shared hierarchy, not drift.

## Comparison history

- First pass, P1: Flutter 3.47.2 does not provide complete Liquid Glass support, so a Cupertino blur would have presented a visual approximation as native behavior.
- Fix: add a bounded UIKit platform-view bridge and keep iOS 26 `UINavigationBar` and `UITabBar` system appearances unmodified.
- First pass, P2: applying the same translucent treatment to Android would weaken platform identity and repeat glass in a dense information surface.
- Fix: keep Android on Material 3 and express hierarchy through tonal elevation, shape, selection scale, and label weight.
- Post-fix evidence: the normalized full and focused comparisons show distinct native platform treatments, complete labels, stable safe areas, and unchanged opaque Catalog content.

## Follow-up polish

- P3: validate Reduce Transparency and Increase Contrast on a physical iPhone before the store candidate.
- P3: evaluate Android dynamic color as a separately approved enhancement; it is not required for the current M3 Expressive treatment.

final result: passed
