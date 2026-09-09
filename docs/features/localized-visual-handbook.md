# Localized visual handbook

## Product identity and locale

The App is named **Roco World Handbook** in English and **洛克王国：世界图鉴** in Chinese. The iOS and Android home-screen label uses the Chinese display name. The App follows the device locale, supports `zh-CN` and `en-US`, and falls back to English for every other locale.

Chinese game-domain terminology is frozen in `config/ui_terminology_zh_cn.json`. It uses source terms such as `精灵`, `图鉴`, `技能`, `特性`, `系别`, `种族资质`, `种族资质总和`, and `属性克制`. Generic actions and recovery messages use concise native interface copy. Canonical creature names, descriptions, skills, and other Catalog content retain their stored source language.

## Offline image library

The App bundles immutable Wiki images under `app/assets/wiki/v1/`. Creature lists resolve `head_key`; creature details resolve `illustration_key`; skills and features resolve `icon_key` together with their stored relationship category. Selected type, base-stat, and skill-category controls use fixed source file titles.

The manifest contains 1,936 unique files and 2,015 Catalog references:

| Kind | Files | Local bytes |
| --- | ---: | ---: |
| Creature heads | 596 | 9,221,952 |
| Creature illustrations | 569 | 79,525,000 |
| Skill and feature icons | 736 | 18,015,640 |
| Domain UI icons | 35 | 114,409 |
| **Total** | **1,936** | **106,877,001** |

The import tool validates exact MediaWiki page identity, image host and path, MIME type, source dimensions, source SHA-1, downloaded length, PNG dimensions, and local SHA-256 before an immutable version is accepted. Nine missing head files use the same creature record's frozen illustration as an explicit fallback. A missing runtime asset displays a semantic placeholder and never starts a network request.

## Base-stat total

The detail page displays all six stored base-stat values. `Total base stats` is calculated only when HP, attack, defense, magic attack, magic defense, and speed are all present. Partial source data displays no fabricated total. The Chinese label is `种族资质总和`.

## Type relationships

`app/assets/wiki/type-relations-v1.json` freezes revision 39538 of `Module:TypeRelation`. It contains 19 source types, including the non-combat `无系别` record. The App presents the 18 combat types.

For each creature form, the detail page shows:

- incoming attacker types that increase or reduce damage, with multipliers;
- a maximum `×3` result when both creature types would otherwise produce `×4`; and
- each creature type's outgoing strong-against and resisted-by lists.

The source module contains eight redundant same-type inverse-list differences. The frozen contract preserves those differences as reviewed exceptions. Runtime calculation uses the forward strong-against and resisted-by matrix, matching the module's damage-calculator semantics instead of rewriting source relations.

## Accessibility and offline boundary

Every domain image supplements visible text and has a semantic label; icons are never the only way to identify a creature, skill, type, or stat. Ordinary browsing reads only bundled files and the installed read-only Catalog. The optional foreground GitHub Releases Catalog update remains the production App's only HTTP path and does not acquire images.
