# Roco Handbook Flutter App

This directory contains the offline-first iOS and Android client. It installs the bundled, validated Catalog database and matching attribution into private application support storage, opens the Catalog read-only, and exposes creature, skill, personal-library, recovery, and optional complete-Catalog update features through repository-owned domain models. Versioned local assets provide creature, skill, feature, type, stat, and category imagery without runtime image requests.

The production App does not request BWIKI, execute Lua, require an account, or download data on first launch. Settings is the only trigger for its fixed GitHub Releases Catalog source; no startup, automatic, or background update exists. Canonical upstream names and descriptions retain their source language. The interface supports `en-US` and source-grounded `zh-CN`, with English fallback for every other locale.

The current Phase 7 source is App version `1.1.0`, build `2`. The preserved Phase 6 candidate remains `1.0.0`, build `1` with its original artifact hashes.

The creature catalog lists concrete forms with Sort, Types, and Search on one row, opens both selectors as modal bottom sheets, and uses full illustrations instead of head images. Search uses a compact rounded outline without a floating label. Compact cards place a smaller muted non-default form label after the source name, keep `NO.<dex_no>` at the far right, show accessible type icons, and reserve favorite actions for the detail header.

Creature detail follows the Basic information, Feature, Base stats, Skills, and Evolution hierarchy, followed by Type relationships, My library, and Source. The removed form selector is replaced by stage-derived First, Second, Third, or Lord form copy, direct concrete-form catalog entries, and clickable evidence-backed evolution routes. Name rows use unbacked type icons and a detail-owned favorite control. A fixed right-side dot navigator overlays the full-width page without a reserved gutter, tracks the current section, supports tap-to-scroll, and shows an outlined localized label on long press. Skills are separated into Pet skills, Bloodline effects, and Learnable skills, with a combined skill-type and element filter; each skill places its element icon after the name. Exact base-stat values use visual bars and a complete-set-only total. Incoming type relationships come from the frozen `assets/wiki/type-relations-v1.json` contract, including the source three-times cap for a dual-type four-times weakness.

The skill destination is a learnable-skill handbook with a one-row Skill handbook, Skill filters, and Skill query toolbar. Its filter sheet combines four skill types, 20 documented read-only source-text labels, and 18 stored elements. Result cards show the frozen icon, name with element icon, category, energy, power, and source description; feature relations remain accessible from creature details, and skill favorites live in the skill detail header. The frozen image manifest under `assets/wiki/v1/` covers every active creature illustration and every active skill reference.

## Run locally

From this directory:

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

The bundled Catalog release assets under `assets/catalog/` must match `../data/release/1/assets/catalog/`. Phase 7 also bundles a public-only Catalog trust store and connects the signed complete-package pipeline to a bounded `dart:io` GitHub Releases source. Android production requests Internet access; iOS uses standard HTTPS without an App Transport Security exception. Private signing material remains outside the repository and App. A missing `catalog-channel` discovery asset safely reports that no update is published.
