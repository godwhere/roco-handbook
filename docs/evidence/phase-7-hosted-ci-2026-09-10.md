# Phase 7 hosted CI evidence

- Evidence date: 2026-09-10
- Workflow: `Offline validation`
- Scope: public GitHub Actions validation after the Phase 7 runtime delivery

## Initial hosted result

GitHub Actions run [34382697133](https://github.com/godwhere/roco-handbook/actions/runs/34382697133) evaluated commit `df5c1b99f99f3f22223a789f1427c3fba0442a41`. The `Catalog and release contracts` job passed, but the `Flutter contracts` job failed with 86 tests passed and 2 failed.

The downloaded job log identified both failures in `app/test/tool/catalog_signing_test.dart`. On the Ubuntu runner, `Directory.systemTemp.createTempSync` produced a test directory that granted group or other permissions. The signing tool correctly rejected that directory with `The private key directory must not grant group or other permissions.` before the two positive fixture paths could create their test keys.

This was a test-environment mismatch. The production signing guard remained correct and was not relaxed.

## Correction

Commit `d88e5e7cfb4bd2e19893f25ac73596f6e91c8521` makes the temporary signing-test directory owner-only on macOS and Linux before using it. The existing production checks still require the private-key directory and file to grant no group or other permissions. The same commit adds the public workflow status badge to the root README.

Local validation before the push produced:

```text
dart format --output=none --set-exit-if-changed test/tool/catalog_signing_test.dart
Result: 1 file checked; no changes required.

flutter test --no-pub test/tool/catalog_signing_test.dart
Result: 3 tests passed.

flutter test --no-pub
Result: 88 tests passed.

flutter analyze --no-pub
Result: no issues found.

PYTHONDONTWRITEBYTECODE=1 PYTHONPATH=tools python3 -m unittest discover -s tests -p 'test_*.py'
Result: 78 tests passed.

git diff --check
Result: passed.
```

## Successful hosted result

GitHub Actions run [34384152396](https://github.com/godwhere/roco-handbook/actions/runs/34384152396) evaluated commit `d88e5e7cfb4bd2e19893f25ac73596f6e91c8521` and completed successfully:

- `Catalog and release contracts`: passed
- `Flutter contracts`: passed

The run used the committed workflow on an Ubuntu runner. It did not access BWIKI, use repository credentials after checkout, sign an App or Catalog, publish a Release, install on a device, upload to a store, or validate a real remote Catalog package.
