# Localized visual handbook

## Product identity and locale

The App is named **Roco World Handbook** in English and **洛克手册** in Chinese. The iOS and Android home-screen label uses the Chinese display name. The App follows the device locale, supports `zh-CN` and `en-US`, and falls back to English for every other locale.

The iOS and Android App icons and launch marks are generated from the frozen Dimo illustration with the Phase 8 brand treatment. Regression checks freeze that source identity plus the exact inventory, dimensions, and hashes of all 24 platform output slots, so a default Flutter, missing size, or unrelated same-size image cannot silently replace the reviewed assets.

Chinese game-domain terminology is frozen in `config/ui_terminology_zh_cn.json`. It uses source terms such as `精灵`, `图鉴`, `技能`, `特性`, `系别`, `种族资质`, `种族资质总和`, and `属性克制`. Generic actions and recovery messages use concise native interface copy. Canonical creature names, descriptions, skills, and other Catalog content retain their stored source language.

Focused localization tests compare every source-grounded domain term used by the UI with the frozen terminology contract. They also fail when a literal `context.tr(...)` key lacks a Chinese mapping or fixed visible copy bypasses the localization entry point. Dynamic Catalog names and descriptions remain source data and are not translated by this check.

A Chinese-locale navigation smoke test renders the creature and skill search fields, personal library tabs, Settings sections, and Catalog information sheet. It verifies the actual top-level interface instead of treating dictionary coverage as rendering evidence.

## Typography

The App bundles immutable font asset version 1. `RocoDisplay` follows the Wiki's primary game-facing typeface for Material display, headline, title, and label roles. `RocoNumbers` supplies tabular handbook identifiers and selected creature, skill, and timeline values. Body roles retain the platform face so descriptions, search input, Settings explanations, and accessibility-scaled paragraphs remain clear.

The frozen font contract locks the Wiki stylesheet, two exact source URLs, byte counts, SHA-256 values, and local paths. The development importer accepts only its configured HTTPS host and path, validates the SFNT container and exact payload identity, and never replaces an existing version. Both fonts ship inside the App; ordinary browsing performs no font request.

The reviewed pre-typography store evidence contains four iOS portrait PNGs at 1206 × 2622 and four Android portrait PNGs at 1080 × 1920. Every image is 8-bit RGB without an alpha channel. The screenshots preserve the rendered App content; the Android set removes only the measured emulator status bar before lossless RGB normalization. ADR-0019 changes visible typography, so this historical set must be regenerated before store submission.

## Offline image library

The App bundles active immutable Wiki image version 2 under `app/assets/wiki/v2/` and compact Tool media version 1 under `app/assets/wiki/tools/v1/`. Creature lists, skill-user lists, and original creature details resolve `illustration_key`; shiny detail art resolves the same key with the source `_yise` suffix. Skills and features resolve `icon_key` together with their stored relationship category. Selected type, base-stat, and skill-category controls use fixed source file titles. Activity cards use 53 deduplicated source icons, and Outfit inspiration uses 220 gender-specific previews. The Catalog still preserves its upstream `head_key`, but the App no longer projects, packages, or renders head images.

The manifest contains 1,484 unique files and 1,565 Catalog references:

| Kind | Files | Local bytes |
| --- | ---: | ---: |
| Creature illustrations | 569 | 79,525,000 |
| Shiny creature illustrations | 144 | 19,631,958 |
| Skill and feature icons | 736 | 18,015,640 |
| Domain UI icons | 35 | 114,409 |
| **Total** | **1,484** | **117,287,007** |

The 144 deduplicated shiny files cover 146 active form references. The import tool validates exact MediaWiki page identity, image host and path, MIME type, source dimensions, source SHA-1, downloaded length, PNG dimensions, and local SHA-256 before an immutable version is accepted. A missing runtime asset displays a semantic placeholder and never starts a network request.

An App-side packaging regression reads the active records from the real bundled Catalog and resolves every creature illustration, skill or feature icon, and type icon through the production path helpers. It then requires each resolved path to exist in Flutter's generated asset manifest, closing the gap between source-manifest completeness and runtime packaging.

## Creature catalog presentation

The creature catalog always returns concrete forms and no longer exposes a Handbook/All forms mode switch. Sort and Types lead the compact control row with one width unit each; Search follows with two units and uses a rounded outline without a floating label. Sort uses the same modal-bottom-sheet pattern as type filtering, with a visible selected chip and explicit Cancel and Apply actions.

Cards render the frozen 512-pixel-source illustration inside a compact 100-logical-pixel contain box. The source name, a smaller muted parenthesized form label when present, and `NO.<dex_no>` share one title row. The name-and-form group scales down only when necessary to keep the complete form label on that single line; it does not wrap or truncate. Default forms omit the form label. Accessible frozen type icons appear below the name without repeating a text-only type row. Shiny-capable names use the stored season color family observed in the Wiki Season archive: purple-blue for S1, pink for S2, green for S3, and lavender for S4. The catalog card is a single navigation target and no longer contains a favorite control.

Sort, Filters, and Search retain the one-to-one-to-two toolbar ratio. Filters open one vertical sheet with Shiny form, Creature stage, Creature form, Owning season, and Creature type sections. S4 remains selectable with an empty current result, while no separate shiny-season control is shown because the Catalog cannot distinguish that value.

## Base-stat total

The detail page presents the exact total in a full-width summary bar, the six stored values as labeled progress rows, and height, weight, review gold, and starlight as supporting fact pills. The progress bars use a bounded 300-point visual scale and never replace the exact numeric copy. `PetDetail.totalBaseStats` calculates the total only when HP, attack, defense, magic attack, magic defense, and speed are all present. Partial source data displays no fabricated total. The Chinese label is `种族资质总和`.

The current Catalog contains 595 active forms with all six values and one source-incomplete form, `pet_000535`, with all six values absent. The complete forms produce their exact totals; the incomplete form reports an unknown total rather than treating nulls as zero.

## Type relationships

`app/assets/wiki/type-relations-v1.json` freezes revision 39538 of `Module:TypeRelation`. It contains 19 source types, including the non-combat `无系别` record. The App presents the 18 combat types.

For each creature form, the detail page shows:

- incoming attacker types that increase or reduce damage, with multipliers;
- a maximum `×3` result when both creature types would otherwise produce `×4`; and
- the concrete form's own type chips above paired increased and reduced panels.

The domain contract continues to preserve each creature type's outgoing strong-against and resisted-by lists, but ADR-0017 removes that duplicate matrix from the compact detail presentation.

## Creature detail navigation and skills

The current form selector is absent. The primary hierarchy is Basic information, Feature, Base stats, Skills, and Evolution; Type relationships, My library, and Source follow. The detail header shows First, Second, Third, or Lord form from the preserved stage and lord-evolution fields. A shiny-capable record places an Original/Shiny segmented control below its full-body art and swaps only between two verified bundled files. Type icons follow the source name without a chip background, and the creature favorite control is placed at the far end of that header row. Non-lord records show No for the Lord evolution fact. Feature cards use the frozen icon, source name, and stored description.

The Skills section uses three equal source controls plus one icon-only filter control. Pet skills, Bloodline effects, and Learnable skills map to native, bloodline, and skill-stone relations. Legendary relations remain preserved under Learnable skills. The filter combines source-backed physical attack, magic attack, defense, or status classification with any element available to the creature. Each result places its element icon immediately after the name, then shows Energy, Category, and Power with the source description below.

Evolution rows display the related creature illustration and open the stored destination identity on a new detail route. A fixed eight-dot navigator overlays the full-width content without a reserved gutter, highlights the section nearest the reading anchor, jumps on tap, and exposes the localized active skill category or section name in a rounded outlined long-press tooltip.

## Skill catalog presentation

The Skills destination is a learnable-skill handbook. Its compact toolbar contains Skill handbook, Skill filters, and Skill query at a one-to-one-to-two width ratio. Feature records are reached through creature feature relationships rather than mixed into this handbook. Each result displays the frozen skill icon, name followed by the stored element icon, category, energy, power, description, and a detail affordance. Favorite controls are confined to the skill detail header.

The filter sheet contains four skill types, the 20 accepted labels, and all 18 combat elements. Skill type and element predicates use stored columns. Labels that are not stored as first-class fields use frozen read-only matches over preserved source descriptions or description-note identifiers. Selections use OR within one group and AND between the selected type, label, and element groups; no inferred tag is persisted into the Catalog.

The source module contains eight redundant same-type inverse-list differences. The frozen contract preserves those differences as reviewed exceptions. Runtime calculation uses the forward strong-against and resisted-by matrix, matching the module's damage-calculator semantics instead of rewriting source relations.

## Tools presentation

The third bottom destination is Tools rather than a single-purpose library tab. Its shorter cards place the functional title in the former upper-left overline position, omit numbered category labels, and retain a real Material icon inside a smaller circular field, an arrow affordance, and muted source-aligned color surfaces. Season archive uses the captured Wiki season names and color families. Feature handbook opens a source-backed list. Egg groups provides normal creature-name input plus a multi-select group sheet, with OR semantics between selected numeric source groups. Personal library preserves favorites, collection marks, and notes.

Game descriptions presents 54 source-defined terms, six category filters, normal text search, and distinct related feature and skill links. Event timeline presents month navigation, five category filters, current-state badges, compact source icons, local UTC+8 windows, and activity details for 547 source occurrences. Outfit inspiration presents normal text search, grade filters, female and male previews, source descriptions, and acquisition details for 110 outfits. All three are bundled offline; the App does not fabricate entries or open an online fallback.

A complete-Catalog regression resolves the actual one- or two-type combination of every active creature form. All 596 current combinations are recognized by the frozen relationship contract, and every emitted multiplier stays within the supported `¼`, `½`, `×2`, or capped `×3` set.

## Accessibility and offline boundary

Every domain image supplements visible text and has a semantic label; icons are never the only way to identify a creature, skill, type, or stat. Ordinary browsing reads only bundled files and the installed read-only Catalog. The optional foreground GitHub Releases Catalog update remains the production App's only HTTP path and does not acquire images.
