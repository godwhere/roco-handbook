# Phase 8 creature Catalog layout evidence

- Date: 2026-09-14
- Device: iPhone 17 simulator, iOS 26.5
- Logical viewport: 402 x 874
- Capture: `docs/evidence/phase-8-layout/ios-creature-grid.png`
- Capture pixels: 1206 x 2622
- Capture SHA-256: `ee5b886d1992f99a51455d73acd0e6c9a7f3564ea95fa65afc9eea16dbb94593`

## Observed behavior

The integration flow opened Settings, selected the Grid creature Catalog layout, returned to Creatures, and captured the first four Dimo forms. The rendered phone layout used two equal columns, large contained full-body illustrations, localized source names and form labels, bundled type icons, stable `NO.<dex_no>` copy, and one detail affordance per card. The same run opened the grouped creature filter and completed the existing Tools and shiny-detail navigation flow without a Flutter exception.

The focused widget regression selected List, returned to the creature Catalog, verified the horizontal list, recreated `CatalogHomePage`, and confirmed that the preference was retained. The repository regression verified the Grid default and the persisted JSON value in the existing `user.db.settings` table.

## Commands and results

```text
cd app && dart format --output=none --set-exit-if-changed lib test integration_test test_driver tool
Result: 54 files checked; no changes required.

cd app && flutter analyze --no-pub
Result: no issues found.

cd app && flutter test --no-pub
Result: 117 tests passed.

PYTHONDONTWRITEBYTECODE=1 PYTHONPATH=tools python3 -m unittest discover -s tests -p 'test_*.py'
Result: 105 tests passed.

cd app && flutter drive --driver=test_driver/integration_test.dart --target=integration_test/phase_8_visual_test.dart -d 22A24FD1-B554-4683-A1A0-E454020C8F08 --no-pub
Result: two integration-test results passed; the grid screenshot was captured.

git diff --check
Result: passed.
```

## Not run

Android visual validation and physical-device validation were not run. No signed archive, store upload, review, release, Catalog package, or remote state was changed.
