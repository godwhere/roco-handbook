# Localized visual handbook

## Product identity and locale

The App is named **Roco World Handbook** in English and **洛克手册** in Chinese. The iOS and Android home-screen label uses the Chinese display name. The App follows the device locale, supports `zh-CN` and `en-US`, and falls back to English for every other locale.

The iOS and Android App icons and launch marks are generated from the frozen Dimo illustration with the Phase 8 brand treatment. Regression checks freeze that source identity plus the exact inventory, dimensions, and hashes of all 24 platform output slots, so a default Flutter, missing size, or unrelated same-size image cannot silently replace the reviewed assets.

Chinese game-domain terminology is frozen in `config/ui_terminology_zh_cn.json`. It uses source terms such as `精灵`, `图鉴`, `技能`, `特性`, `系别`, `种族资质`, `种族资质总和`, and `属性克制`. Generic actions and recovery messages use concise native interface copy. Canonical creature names, descriptions, skills, and other Catalog content retain their stored source language.

Focused localization tests compare every source-grounded domain term used by the UI with the frozen terminology contract. They also fail when a literal `context.tr(...)` key lacks a Chinese mapping or fixed visible copy bypasses the localization entry point. Dynamic Catalog names and descriptions remain source data and are not translated by this check.

A Chinese-locale navigation smoke test renders the creature and skill search fields, personal library tabs, Settings sections, and Catalog information sheet. It verifies the actual top-level interface instead of treating dictionary coverage as rendering evidence.

## Platform navigation materials

iOS navigation uses native UIKit views rather than a Flutter blur approximation. The creature root uses its branded Catalog hero instead of an ordinary top bar; other pages register bounded `UINavigationBar` views, and the root registers a `UITabBar` platform view. Their iOS 26 system appearance remains untouched so Liquid Glass comes from the operating system. Earlier supported iOS versions retain the same native navigation and use a system-material blur fallback. Back and destination-selection events return to the existing Flutter navigation state through per-view channels.

Android retains Material 3 navigation. Its four icon-and-label bottom destinations sit inside one safe-area-aware floating stadium with horizontal screen margins, an opaque tonal fill, a light outline, and low shadow elevation. A separate pill selection indicator plus selected-state icon scale retain the M3 Expressive hierarchy. Localized visible labels and stable automation keys identify all four controls. Android does not receive an iOS-style glass imitation.

The shared root scaffold extends the body behind the floating bottom navigation on both platforms. Seven overlapping clipped backdrop layers begin with a near-clear `0.9` sigma across the full navigation region and accumulate toward an effective visual strength of about `8` sigma at the screen edge. A four-stop low-alpha surface gradient masks layer boundaries. This creates a progressive clear-to-blurred transition without making the iOS and Android navigation materials identical. Creature-grid, creature-list, and skill-list results derive their final scroll clearance from the scaffold-provided bottom inset, so more Catalog content remains visible behind the floating surface while the final card can still scroll completely clear of it.

This material split applies only to navigation and transient control hierarchy. Creature and skill cards, filter sheets, reference panels, settings, and descriptions remain opaque or tonal so dense offline information stays readable. The platform branch introduces no runtime asset or network request.

## Typography

The App bundles immutable font asset version 1. `RocoDisplay` follows the Wiki's primary game-facing typeface for Material display, headline, title, and label roles. `RocoNumbers` supplies tabular handbook identifiers and selected creature, skill, and timeline values. Body roles retain the platform face so descriptions, search input, Settings explanations, and accessibility-scaled paragraphs remain clear.

The frozen font contract locks the Wiki stylesheet, two exact source URLs, byte counts, SHA-256 values, and local paths. The development importer accepts only its configured HTTPS host and path, validates the SFNT container and exact payload identity, and never replaces an existing version. Both fonts ship inside the App; ordinary browsing performs no font request.

The reviewed pre-typography store evidence contains four iOS portrait PNGs at 1206 × 2622 and four Android portrait PNGs at 1080 × 1920. Every image is 8-bit RGB without an alpha channel. The screenshots preserve the rendered App content; the Android set removes only the measured emulator status bar before lossless RGB normalization. ADR-0019 changes visible typography, so this historical set must be regenerated before store submission.

## Offline image library

The App bundles active immutable NRC Wiki image version 3 under `app/assets/wiki/v3/` and compact Tool media version 1 under `app/assets/wiki/tools/v1/`. Creature lists, skill-user lists, and original creature details resolve stable local illustration paths from each source filename. Shiny detail art resolves the explicit NRC shiny filename instead of assuming a suffix. Skills and features resolve `icon_key` together with their stored relationship category. Selected type, base-stat, and skill-category controls use 35 exact domain UI icons preserved from immutable image version 2 because the NRC file namespace does not expose them. Activity cards use 53 deduplicated source icons, and Outfit inspiration uses 220 gender-specific previews. The Catalog still preserves its upstream `head_key`, but the App no longer projects, packages, or renders head images.

The manifest contains 1,594 unique files and 1,673 Catalog references:

| Kind | Files | Local bytes |
| --- | ---: | ---: |
| Creature illustrations | 595 | 81,723,106 |
| Shiny creature illustrations | 191 | 24,606,991 |
| Skill and feature icons | 773 | 18,322,479 |
| Domain UI icons | 35 | 114,409 |
| **Total** | **1,594** | **124,766,985** |

The 595 deduplicated original files cover 621 active forms, the 191 deduplicated shiny files cover 193 active form references, and the 773 skill files cover 824 active skill and feature records. The import tool validates exact MediaWiki page identity, allowed image hosts and paths, MIME type, source dimensions, source SHA-1, downloaded length, PNG dimensions, and local SHA-256 before an immutable version is accepted. A missing runtime asset displays a semantic placeholder and never starts a network request.

An App-side packaging regression reads the active records from the real bundled Catalog and resolves every creature illustration, skill or feature icon, and type icon through the production path helpers. It then requires each resolved path to exist in Flutter's generated asset manifest, closing the gap between source-manifest completeness and runtime packaging.

## Creature catalog presentation

The creature catalog always returns concrete forms and no longer exposes a Handbook/All forms mode switch. Its branded hero combines the localized product title and tagline with data-version and Catalog-information actions over one frozen decorative background; every label, control, and interaction remains a live Flutter widget rather than flattened screenshot content. Sort and Types lead the compact control row with one width unit each; Search follows with two units and uses a rounded outline without a floating label. Sort uses the same modal-bottom-sheet pattern as type filtering, with a visible selected chip and explicit Cancel and Apply actions.

The default responsive grid presents two cards per phone row and three cards at widths of at least 720 logical pixels. Settings can switch to the preserved compact horizontal list, whose illustration remains in a 100-logical-pixel contain box and whose name, parenthesized form label, and number share one row. Both layouts use distinct code-owned palettes for all 18 combat types. A dual-type form blends its two accents; an applicable evolved single-light form uses the reviewed warm-light variant. Low-contrast curved washes, rings, sparkles, type-icon watermarks, and paw motifs provide element identity while the center surface stays light enough for source names, form labels, icons, and `NO.<dex_no>` values. Both modes scale long single-line labels down instead of truncating them, omit the form label for default forms, use accessible frozen type icons, and keep each card as one detail-navigation target without a favorite control.

The layout selection is a localized segmented control backed by the existing typed `UserRepository` and `user.db.settings` table. The grid is the missing-value and invalid-value fallback. Catalog replacement does not overwrite the preference.

Sort, Filters, and Search retain the one-to-one-to-two toolbar ratio. Filters open one vertical sheet with Shiny form, Creature stage, Creature form, Owning season, and Creature type sections. S4 remains selectable with an empty current result, while no separate shiny-season control is shown because the Catalog cannot distinguish that value.

## Base-stat total

The detail page presents the exact total in a full-width summary bar, the six stored values as labeled progress rows, and height, weight, review gold, and starlight as supporting fact pills. The progress bars use a bounded 300-point visual scale and never replace the exact numeric copy. `PetDetail.totalBaseStats` calculates the total only when HP, attack, defense, magic attack, magic defense, and speed are all present. Partial source data displays no fabricated total. The Chinese label is `种族资质总和`.

The current NRC Catalog contains 621 active forms with all six values. Every form produces its exact total; the null-safe calculation remains in place so a future incomplete source record cannot fabricate a value from zeros.

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

A complete-Catalog regression resolves the actual one- or two-type combination of every active creature form. All 621 current combinations are recognized by the frozen relationship contract, and every emitted multiplier stays within the supported `¼`, `½`, `×2`, or capped `×3` set.

## Accessibility and offline boundary

Every domain image supplements visible text and has a semantic label; icons are never the only way to identify a creature, skill, type, or stat. Ordinary browsing reads only bundled files and the installed read-only Catalog. The optional foreground GitHub Releases Catalog update remains the production App's only HTTP path and does not acquire images.
