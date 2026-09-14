# Phase 8 creature type background evidence

## Scope

This evidence covers the code-native creature-card backgrounds requested for both the compact horizontal list and responsive grid. It does not change Catalog data, type identity, queries, navigation targets, or personal data.

## Visual sources and captures

- Horizontal reference: `docs/evidence/phase-8-creature-type-backgrounds/reference-list.png`
- Grid reference: `docs/evidence/phase-8-creature-type-backgrounds/reference-grid.png`
- iOS list and grid: `docs/evidence/phase-8-creature-type-backgrounds/ios-list.png` and `ios-grid.png`
- Android list and grid: `docs/evidence/phase-8-creature-type-backgrounds/android-list.png` and `android-grid.png`
- Final ordinary iOS installation: `docs/evidence/phase-8-creature-type-backgrounds/ios-installed.png`
- Focused comparisons in reference, iOS, and Android order: `list-reference-ios-android.png` and `grid-reference-ios-android.png`

The implementation preserves the references' low-contrast elemental identity without flattening any App content into screenshots. All creature art and type icons remain the exact bundled Wiki assets. Gradients, curved washes, concentric rings, sparkles, and paw motifs are drawn by Flutter. All 18 combat types have distinct accents; dual-type forms blend their two accents. The reviewed evolved single-light presentation uses a warm gold accent while the default single-light presentation remains blue.

The green or blue crosshair visible over the selected bottom destination in integration screenshots is the integration binding's pointer-location overlay. It is not part of the production App and is absent from the final ordinary simulator installation.

## File identities

```text
reference-list.png  3ad5943956133016d0488ec5537d62a0fa462bf6882d610e354868f6d4596cd1
reference-grid.png  6e214c560bb12435b1072e20fc8cc0341b97ee02ae236805a2b5cf77c0d367d4
ios-list.png  31cf7e645a3fae1c6f493821047d6261870cd1dedfe885d56595ef5f1656ab85
ios-grid.png  0d553aad7648732c7aa20ab18af6af00f01a666faff3d00c2f62e1fcacf5e6f6
android-list.png  d2072111cfeaaedad1d7678ae53eb72a5ba86b0f631e434162536645ef85a010
android-grid.png  9ae5cb319fa467786c136feebd0a0c270dc0c1bb26c16db55b37bd3ca19f9c5c
ios-installed.png  a3acee93e3b82f8b681fefc7ac105b2279053bbda907d3af93833842a42127eb
```

## Validation

```sh
cd app && flutter test --no-pub test/widgets/catalog_asset_image_test.dart test/features/catalog_flow_test.dart test/theme/catalog_theme_test.dart
```

Result: 30 focused tests passed. They include distinct accents for all 18 active type names, a separate warm-light accent, and list/grid background presence.

```sh
cd app && flutter drive --driver=test_driver/integration_test.dart --target=integration_test/phase_8_visual_test.dart -d 22A24FD1-B554-4683-A1A0-E454020C8F08 --no-pub
cd app && flutter drive --driver=test_driver/integration_test.dart --target=integration_test/phase_8_visual_test.dart -d emulator-5554 --no-pub
```

Result: two integration-test results passed on each platform. Each flow explicitly selected and captured the list layout, selected and captured the grid layout, changed all four destinations, and completed the existing filter, Tool, normal-input, detail, and shiny checks.

After those test runs, the iOS simulator App was rebuilt, installed with `simctl install`, launched normally, and resolved through `simctl get_app_container`. No further `flutter drive` command ran after that installation. The final capture confirms the production view without the integration pointer overlay.

## Not proven

- Physical iPhone or Android-device rendering
- Reduce Transparency, Increase Contrast, or dynamic-color appearance
- Store screenshot acceptance, signed archive, upload, review, or publication
