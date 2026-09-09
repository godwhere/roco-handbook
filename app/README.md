# Roco Handbook Flutter App

This directory contains the offline iOS and Android client. It installs the bundled, validated Catalog database and matching attribution into private application support storage, opens the Catalog read-only, and exposes creature, skill, and personal-library features through repository-owned domain models.

The production App does not request BWIKI, execute Lua, require an account, or download data on first launch. Canonical upstream names and descriptions retain their source language; all App-authored copy is English.

## Run locally

From this directory:

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

The bundled Catalog release assets under `assets/catalog/` must match `../data/release/1/assets/catalog/`. Phase 7 also bundles a public-only Catalog trust store and has an offline-only signed complete-package validation and installer pipeline. Private signing material remains outside the repository and App; production bootstrap does not invoke the pipeline and no runtime network source is configured.
