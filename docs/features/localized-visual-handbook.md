# Localized visual handbook

## Product identity and locale

The App is named **Roco World Handbook** in English and **洛克王国：世界图鉴** in Chinese. The iOS and Android home-screen label uses the Chinese display name. The App follows the device locale, supports `zh-CN` and `en-US`, and falls back to English for every other locale.

The iOS and Android App icons and launch marks are generated from the frozen Dimo illustration with the Phase 8 brand treatment. Regression checks freeze that source identity plus the exact inventory, dimensions, and hashes of all 24 platform output slots, so a default Flutter, missing size, or unrelated same-size image cannot silently replace the reviewed assets.

Chinese game-domain terminology is frozen in `config/ui_terminology_zh_cn.json`. It uses source terms such as `精灵`, `图鉴`, `技能`, `特性`, `系别`, `种族资质`, `种族资质总和`, and `属性克制`. Generic actions and recovery messages use concise native interface copy. Canonical creature names, descriptions, skills, and other Catalog content retain their stored source language.

Focused localization tests compare every source-grounded domain term used by the UI with the frozen terminology contract. They also fail when a literal `context.tr(...)` key lacks a Chinese mapping or fixed visible copy bypasses the localization entry point. Dynamic Catalog names and descriptions remain source data and are not translated by this check.

A Chinese-locale navigation smoke test renders the creature and skill search fields, personal library tabs, Settings sections, and Catalog information sheet. It verifies the actual top-level interface instead of treating dictionary coverage as rendering evidence.

The reviewed store evidence contains four iOS portrait PNGs at 1206 × 2622 and four Android portrait PNGs at 1080 × 1920. Every image is 8-bit RGB without an alpha channel. The screenshots preserve the rendered App content; the Android set removes only the measured emulator status bar before lossless RGB normalization.

## Offline image library

The App bundles immutable Wiki images under `app/assets/wiki/v1/`. Creature lists, form selectors, skill-user lists, and creature details resolve `illustration_key`; skills and features resolve `icon_key` together with their stored relationship category. Selected type, base-stat, and skill-category controls use fixed source file titles. The Catalog still preserves its upstream `head_key`, but the App no longer projects, packages, or renders head images.

The manifest contains 1,340 unique files and 1,419 Catalog references:

| Kind | Files | Local bytes |
| --- | ---: | ---: |
| Creature illustrations | 569 | 79,525,000 |
| Skill and feature icons | 736 | 18,015,640 |
| Domain UI icons | 35 | 114,409 |
| **Total** | **1,340** | **97,655,049** |

The import tool validates exact MediaWiki page identity, image host and path, MIME type, source dimensions, source SHA-1, downloaded length, PNG dimensions, and local SHA-256 before an immutable version is accepted. A missing runtime asset displays a semantic placeholder and never starts a network request.

An App-side packaging regression reads the active records from the real bundled Catalog and resolves every creature illustration, skill or feature icon, and type icon through the production path helpers. It then requires each resolved path to exist in Flutter's generated asset manifest, closing the gap between source-manifest completeness and runtime packaging.

## Creature catalog presentation

The creature catalog always returns concrete forms and no longer exposes a Handbook/All forms mode switch. Search occupies half of the compact control row; Sort and Types divide the remaining width with fixed spacing. Sort uses the same modal-bottom-sheet pattern as type filtering, with a visible selected chip and explicit Cancel and Apply actions.

Cards render the frozen 512-pixel-source illustration inside a 112-logical-pixel contain box. Default forms display `<name> <dex number>` and omit a form label. Named non-default forms display `<name>（<form>） <dex number>`. Type names appear as a separate text line, preserving exact Catalog terminology while leaving more space for the full creature art.

## Base-stat total

The detail page displays all six stored base-stat values. `PetDetail.totalBaseStats` calculates the total only when HP, attack, defense, magic attack, magic defense, and speed are all present. Partial source data displays no fabricated total. The Chinese label is `种族资质总和`.

The current Catalog contains 595 active forms with all six values and one source-incomplete form, `pet_000535`, with all six values absent. The complete forms produce their exact totals; the incomplete form reports an unknown total rather than treating nulls as zero.

## Type relationships

`app/assets/wiki/type-relations-v1.json` freezes revision 39538 of `Module:TypeRelation`. It contains 19 source types, including the non-combat `无系别` record. The App presents the 18 combat types.

For each creature form, the detail page shows:

- incoming attacker types that increase or reduce damage, with multipliers;
- a maximum `×3` result when both creature types would otherwise produce `×4`; and
- each creature type's outgoing strong-against and resisted-by lists.

The source module contains eight redundant same-type inverse-list differences. The frozen contract preserves those differences as reviewed exceptions. Runtime calculation uses the forward strong-against and resisted-by matrix, matching the module's damage-calculator semantics instead of rewriting source relations.

A complete-Catalog regression resolves the actual one- or two-type combination of every active creature form. All 596 current combinations are recognized by the frozen relationship contract, and every emitted multiplier stays within the supported `¼`, `½`, `×2`, or capped `×3` set.

## Accessibility and offline boundary

Every domain image supplements visible text and has a semantic label; icons are never the only way to identify a creature, skill, type, or stat. Ordinary browsing reads only bundled files and the installed read-only Catalog. The optional foreground GitHub Releases Catalog update remains the production App's only HTTP path and does not acquire images.
