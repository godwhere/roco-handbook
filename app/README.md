# Roco Handbook Flutter App

This directory contains the offline-first iOS and Android client. It installs the bundled, validated Catalog database and matching attribution into private application support storage, opens the Catalog read-only, and exposes creature, skill, personal-library, recovery, and optional complete-Catalog update features through repository-owned domain models.

The production App does not request BWIKI, execute Lua, require an account, or download data on first launch. Settings is the only trigger for its fixed GitHub Releases Catalog source; no startup, automatic, or background update exists. Canonical upstream names and descriptions retain their source language; all App-authored copy is English.

The current Phase 7 source is App version `1.1.0`, build `2`. The preserved Phase 6 candidate remains `1.0.0`, build `1` with its original artifact hashes.

## Run locally

From this directory:

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

The bundled Catalog release assets under `assets/catalog/` must match `../data/release/1/assets/catalog/`. Phase 7 also bundles a public-only Catalog trust store and connects the signed complete-package pipeline to a bounded `dart:io` GitHub Releases source. Android production requests Internet access; iOS uses standard HTTPS without an App Transport Security exception. Private signing material remains outside the repository and App. A missing `catalog-channel` discovery asset safely reports that no update is published.
