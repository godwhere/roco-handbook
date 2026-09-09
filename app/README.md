# Roco Handbook Flutter App

This directory contains the offline iOS and Android client. It installs the bundled, validated Catalog database into private application support storage, opens it read-only, and exposes creature and skill browsing through repository-owned domain models.

The production App does not request BWIKI, execute Lua, require an account, or download data on first launch. Canonical upstream names and descriptions retain their source language; all App-authored copy is English.

## Run locally

From this directory:

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

The bundled assets under `assets/catalog/` must match `../data/release/1/assets/catalog/`. Personal-data features are not part of the current phase.
