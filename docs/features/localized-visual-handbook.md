# Native localized visual handbook

## Active client and language

ADR-0023 makes the Swift/SwiftUI iOS client in `ios/` the active implementation. The preserved Phase 8 decisions and captures document the preceding Flutter presentation; they are not current native screenshots.

The interface uses English `en.lproj` and Simplified Chinese `zh-Hans.lproj` resources, reusing the frozen `zh-CN` terminology contract and Phase 8 translations. Other locales fall back to English. Canonical creature, skill, activity, outfit, condition, and description text retains its source language. The English name is Roco World Handbook; the Simplified Chinese name is the frozen short product name. Localized InfoPlist strings set the corresponding home-screen label.

Native interface and domain error messages have matching English and Simplified Chinese entries. The focused packaging test rejects untranslated literal controls/errors, duplicate keys, unequal locale inventories, and drift from the frozen base-stat, feature, energy, and power terms. Device linguistic and accessibility acceptance remain separate.

## Navigation and presentation

Native `TabView` provides Creatures, Skills, Tools, and Settings. Navigation uses `NavigationStack` from iOS 16 and a `NavigationView` fallback on iOS 15. The system supplies current navigation materials; content panels remain opaque or tonal. There is no Flutter platform-view bridge, custom simulated glass, Android branch, or shared cross-platform blur implementation.

The creature root has a tonal branded hero with live title, tagline, data version, information link, Sort, Filters, and Search. A two-column phone grid and three-column wide grid display complete contained illustrations, handbook numbers, explicit type icons, names, and non-default form subtitles. Accessibility-sized text uses one column. Settings can switch to the compact horizontal list; the existing personal setting persists independently of Catalog recovery. Colors use the first explicit type and a distinct shiny-capable name accent. Exact prior decorative backgrounds and season palettes are not native migration acceptance requirements.

## Offline resources and typography

`ios/prepare_resources.py` stages only active resources from the unchanged `app/assets/`: Catalog data version 2, Wiki images version 3, Tool/font assets version 1, and the frozen reference JSON files. Earlier image versions are excluded. No runtime image or font request exists. Native path helpers validate keys and Tool subdirectories and show a local fallback when a resource is unavailable.

All 621 concrete forms, 193 shiny references, 824 skill/feature references, and explicit type icons are checked against native domain path helpers. The underlying frozen image manifests retain their source URLs, revisions, filenames, sizes, and hashes. Original/shiny switching uses the same source illustration keys. The image and font source information remains separate from Catalog data attribution; packaging does not establish new artwork or font rights.

Headings use the frozen display font with platform fallback. Descriptions and inputs use the system font; numeric values use system monospaced digits. Both frozen font files are staged without modification. SwiftUI relative text styles support Dynamic Type, but physical large-text and VoiceOver acceptance remain open.

## Detail and skill flows

Creature detail retains Basic information, Feature, Base stats, Skills, Evolution, Type relationships, My library, and Source. Stage labels use explicit stage/lord fields. Original/shiny switching is available only for source-backed shiny records. Base-stat totals require all six values. A right-side accessible dot navigator scrolls to sections, follows scroll positions, and exposes the localized section title on long press.

Pet skills, Bloodline effects, and Learnable skills preserve source kinds, levels, stages, raw bloodline values, and requirements. Skill type and element filters operate over DTOs. Feature ownership remains independent. Evolution links use stored edges and concrete pet IDs. Frozen type relationships retain the dual-type three-times incoming damage cap.

The learnable-skill and feature catalogs retain native search, type/tag/element filtering, explicit pagination, icons, metrics, descriptions, owners, acquisition conditions, source references, and detail-owned favorites. Defined glossary notes resolve from the separate frozen description contract; undefined identifiers remain noninteractive.

## Seven offline Tools

- Season archive filters explicit owning seasons.
- Feature handbook queries independent feature ownership.
- Egg groups combine normal creature search with one or more stored group IDs.
- Game descriptions browse 54 definitions and associated Catalog skills.
- Activity timeline browses 547 entries with text, month, category, and date-derived status filters; missing dates remain unknown.
- Outfit inspiration browses 110 outfits and 220 gender variants with search, grade filters, original previews, and acquisition text.
- My library resolves stable saved objects and retains unavailable name snapshots and notes.

## Evidence boundary

Phase 9 simulator captures and UI results document the native client. Source assets, language mapping, all-image reference closure, database isolation, and core update validation have offline coverage. Older iOS rendering, physical signed upgrades, VoiceOver, Reduce Transparency, Increase Contrast, store screenshots, signing, upload, review, and publication are not inferred from those tests.
