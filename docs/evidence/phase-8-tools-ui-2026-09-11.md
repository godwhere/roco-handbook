# Phase 8 compact Tools and Egg groups simulator evidence

- Date: 2026-09-11
- Platform: iOS Simulator, iPhone 17
- Simulator ID: `22A24FD1-B554-4683-A1A0-E454020C8F08`
- Scope: compact unnumbered Tool cards and the searchable, filterable Egg groups route

## Command

```text
cd app
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/phase_8_visual_test.dart -d 22A24FD1-B554-4683-A1A0-E454020C8F08 --no-pub
```

## Result

The integration run passed both results and captured the Tools destination, Egg groups browser, and Egg-group filters at 1206 x 2622.

The Tools destination displayed each functional title in the former upper-left category-label position. No numbered Catalog-tool or Personal-tool overline remained. The reduced card height preserved one complete title, one complete description, the circular icon, and the navigation affordance without overlap.

The Egg groups browser displayed a same-row Filters button and normal text-input Search field above concrete creature results. The filter sheet displayed all 15 stored group choices and their member counts, plus unobstructed Clear and Apply actions. No clipping or overflow was observed at the tested text scale.

## Limits

This is simulator and automated interaction evidence. Physical iOS touch, hardware keyboard behavior, Android visual parity, accessibility-reader navigation, store packaging, and publication were not run by this check.
