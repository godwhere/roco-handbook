# Phase 8 Catalog presentation and platform navigation design QA

- Review date: 2026-09-14
- Navigation source visual truth: `/Users/ethan/.codex/generated_images/01a084ad-ac2c-7d23-9db4-d6fa0b1cfbbb/exec-6ed72adb-da77-435d-906c-a20036587ddc.png`
- Header source: `docs/evidence/phase-8-catalog-header/source.png`
- Creature-card sources: `docs/evidence/phase-8-creature-type-backgrounds/reference-list.png` and `reference-grid.png`
- iOS implementation: `docs/evidence/phase-8-platform-navigation/ios-liquid-glass-home.png`
- Android implementation: `docs/evidence/phase-8-platform-navigation/android-m3-expressive-home.png`
- Full-view comparisons: `docs/evidence/phase-8-platform-navigation/ios-source-comparison.png` and `docs/evidence/phase-8-platform-navigation/android-source-comparison.png`
- Focused comparison: `docs/evidence/phase-8-platform-navigation/platform-navigation-focused-comparison.png`
- Android before and after: `docs/evidence/phase-8-platform-navigation/android-floating-navigation-before-after.png`
- Progressive bottom-blur captures: `docs/evidence/phase-8-platform-navigation/ios-progressive-blur.png` and `android-progressive-blur.png`
- Header comparison: `docs/evidence/phase-8-catalog-header/source-ios-android-comparison.png`
- Type-background comparisons: `docs/evidence/phase-8-creature-type-backgrounds/list-reference-ios-android.png` and `grid-reference-ios-android.png`
- States: `zh-CN`, light theme, creature list and grid, first four Dimo forms, first destination selected

## Normalization

The navigation source is 853 x 1844 pixels. The header source is 820 x 420 pixels. The horizontal and grid card sources are 636 x 208 and 602 x 400 pixels. The iOS capture is 1206 x 2622 pixels at a 402 x 874 logical viewport and 3x density. The Android Flutter-surface capture is 1080 x 2057 pixels from the API 36 emulator. Full-view and focused comparisons normalize aspect or crop only; they do not alter the captured App content.

## Full-view comparison evidence

Both implementations preserve the selected direction's title/version hierarchy, compact Sort/Filters/Search control group, two-column illustrated Catalog, type-aligned card colors, and four equal primary destinations. The accepted creature root adds a generated pale star-and-sparkle background behind live Flutter title, data, information, sort, type, and search controls. The list and grid cards translate the supplied elemental references through code-native gradients and restrained motifs while preserving exact Wiki illustrations and type icons.

The iOS capture preserves the source's floating translucent navigation hierarchy through native UIKit. System Liquid Glass appears on the version, information, and tab-bar navigation layer without adding a custom Flutter blur to cards or text. The Android capture translates the same complete floating bottom silhouette into M3 Expressive with an opaque tonal stadium, safe-area spacing, a light outline, low shadow, a circular tonal information action, and a separate pill selection indicator instead of copying iOS translucency. On both platforms, the third card row now visibly continues behind the floating navigation layer.

## Focused comparison evidence

The focused bottom region confirms that all three views use one complete floating capsule silhouette with four equal labeled destinations. iOS uses the system's optical material and native SF symbols. Android uses Material symbols inside an opaque M3 tonal surface, a larger selected indicator, 16-logical-pixel horizontal margins, and platform safe-area spacing. The Android before/after evidence shows that the earlier full-width edge-to-edge navigation surface has been replaced rather than merely reshaping the selected destination. Catalog content paints beneath each floating bar, and no persistent control overlaps the safe area or loses its selected state.

## Required fidelity surfaces

- Fonts and typography: Catalog display text retains the approved `RocoDisplay` role and identifiers retain `RocoNumbers`. Native iOS navigation uses the system face and SF Symbols. Android displays each localized destination label with the existing Material typography. Other titles and labels remain single-line and legible.
- Spacing and layout rhythm: the two-column grid and compact list retain their established geometry. Both navigation bars respect platform safe areas and visibly separate from the horizontal screen edges. Android uses a 72-logical-pixel inner bar and retains four equal destinations without clipping. The extended body exposes more of the next card row, while navigation-derived final padding preserves complete end-of-list access.
- Colors and visual tokens: iOS lets the system adapt Liquid Glass contrast. Android derives tonal surfaces and selection colors from the App `ColorScheme`. Creature cards define 18 distinct element accents, blend dual-type accents, and retain a light center wash for legible copy. Default light and reviewed evolved light examples match the blue and gold source direction.
- Image quality and asset fidelity: every Catalog card uses the exact frozen Wiki illustration and type icon. Image generation supplied only the decorative Catalog-header background; all text and controls remain code-native. Card backgrounds are drawn by Flutter, and no screenshot raster, custom SVG, emoji, placeholder, or generated navigation icon replaces a source asset or platform symbol.
- Copy and content: source names, form labels, `NO.<dex_no>`, data version, and visible destination labels remain data-backed or localized. No concept-only tagline was added.

## Interaction and accessibility evidence

Focused widget coverage selects the iOS and Android shells, verifies root body extension on both branches, changes destination through the Cupertino test fallback, and checks the Android safe-area margin, stadium surface, clipping, elevation, transparent inner navigation, visible labels, stable keys, and M3 theme geometry. Current integration flows change all four destinations and open the Phase 8 child routes on both simulators. Native iOS top-bar buttons carry accessibility labels, the bottom bar uses Flutter-owned destination semantics without duplicating the hidden native item semantics, and Android destinations retain matching visible copy and localized Flutter semantics. The complete Flutter suite covers dark theme and a 2.0 text scale.

## Findings

No actionable P0, P1, or P2 mismatch remains. The platform differences are intentional translations of one shared hierarchy, and the element treatments remain decorative rather than becoming a competing reading layer.

## Comparison history

- First pass, P1: Flutter 3.47.2 does not provide complete Liquid Glass support, so a Cupertino blur would have presented a visual approximation as native behavior.
- Fix: add a bounded UIKit platform-view bridge and keep iOS 26 `UINavigationBar` and `UITabBar` system appearances unmodified.
- First pass, P2: applying the same translucent treatment to Android would weaken platform identity and repeat glass in a dense information surface.
- Fix: keep Android on Material 3 and express hierarchy through tonal elevation, shape, selection scale, and label weight.
- Second pass, P1: the Android implementation applied the capsule only to the selected destination while the complete navigation surface remained edge-to-edge, so it did not meet the shared floating silhouette.
- Fix: wrap the complete Android `NavigationBar` in a clipped `StadiumBorder` Material surface, add 16-logical-pixel horizontal margins, respect the bottom safe area, and keep the inner navigation transparent so only the outer capsule defines the silhouette.
- Third pass, user refinement: an icon-only Android variation was evaluated, then the labeled navigation was selected as the clearer visual result.
- Fix: restore `alwaysShow` at 72 logical pixels, retain the cleaner Material pet symbol in place of the text-bearing creature bitmap, and keep stable automation keys for every destination.
- Fourth pass, user refinement: let the bottom navigation float over the Catalog instead of reserving an opaque layout band beneath the content.
- Fix: enable root body extension for both platform branches and derive creature-grid, creature-list, and skill-list final padding from the resulting navigation inset.
- Fifth pass, P1: child page safe areas consumed the extended scaffold's bottom inset, so only Settings visibly painted behind the floating navigation.
- Fix: stop the creature, skill, and Tools roots from reserving the bottom safe area, derive their final scroll clearance dynamically, and add a shared safe-area backdrop with a subtle surface gradient.
- Sixth pass, user refinement: replace the ordinary creature-root top bar with the supplied branded hierarchy.
- Fix: render the title, tagline, data version, information action, and toolbar as live widgets over one generated decorative background; retain native iOS top navigation on non-root pages.
- Seventh pass, user refinement: give each creature element a corresponding card background in both preserved layouts.
- Fix: add 18 distinct type accents, dual-type blending, the reviewed warm-light variant, and low-alpha code-native rings, washes, sparkles, type watermarks, and paw motifs. Focused list/grid comparisons on iOS and Android retain readable names, form labels, identifiers, and controls.
- Eighth pass, user refinement: make the safe-area blur increase toward the bottom instead of applying one uniform strength.
- Fix: replace the uniform six-sigma filter with seven overlapping clipped layers that begin nearly clear and accumulate toward the screen edge, then use a four-stop low-alpha surface gradient to conceal layer transitions. Ordinary-install iOS and Android captures show no hard band or blurred reading surface.
- Post-fix evidence: the normalized header, list, grid, full-navigation, focused-navigation, and Android before/after comparisons show the accepted hierarchy, clear element identity, complete labeled floating capsules, distinct platform materials, content continuing behind the bars, and readable Catalog cards.

## Follow-up polish

- P3: validate Reduce Transparency and Increase Contrast on a physical iPhone before the store candidate.
- P3: evaluate Android dynamic color as a separately approved enhancement; it is not required for the current M3 Expressive treatment.

final result: passed
