# Native localized visual handbook

## Active client and language

ADR-0023 makes the Swift/SwiftUI iOS client in `ios/` the active implementation. The preserved Phase 8 decisions and captures document the preceding Flutter presentation; they are not current native screenshots.

The interface uses English `en.lproj` and Simplified Chinese `zh-Hans.lproj` resources, reusing the frozen `zh-CN` terminology contract and Phase 8 translations. Other locales fall back to English. Canonical creature, skill, activity, outfit, condition, and description text retains its source language. The English name is Roco World Handbook; the Simplified Chinese name is the frozen short product name. Localized InfoPlist strings set the corresponding home-screen label.

Native interface and domain error messages have matching English and Simplified Chinese entries. The focused packaging test rejects untranslated literal controls/errors, duplicate keys, unequal locale inventories, and drift from the frozen base-stat, feature, energy, and power terms. Device linguistic and accessibility acceptance remain separate.

## Navigation and presentation

Native `TabView` provides Creatures, Skills, Tools, and Settings. Navigation uses `NavigationStack` from iOS 16 and a `NavigationView` fallback on iOS 15. The system supplies current navigation materials; content panels remain opaque or tonal. There is no Flutter platform-view bridge, custom simulated glass, Android branch, or shared cross-platform blur implementation.

The creature root has a full-width tonal branded hero whose background extends behind the status bar. Content is inset below system status information. Accessible Sort and Filters icon buttons share one row with Search. The default three-column grid sizes complete contained illustrations to each card; two-column phone cards and the compact horizontal list remain Settings choices. Existing saved `grid` and `list` preferences are respected; missing, malformed, or unsupported values select `threeColumn` through the same personal database setting. The older `grid` mode retains three columns on wide views. Accessibility-sized text uses one column. All layouts retain handbook numbers, explicit type icons, names, and non-default form subtitles. Colors use the first explicit type and a distinct shiny-capable name accent. ADR-0024 defines the current presentation and preference contract.

Creature and skill filters use adaptive multi-column options grouped by their existing query fields. Types and skill categories reuse bundled Wiki icons with short names. Selected options have a checkmark, outline, and selected accessibility trait. Common actions use labeled native symbols for reset and completion. Existing multi-selection, query composition, and reset behavior remain intact; accessibility text sizes use wider options. Grouping and icon emphasis reference the public BWIKI gallery without importing new records or filter semantics. ADR-0025 defines this follow-up.

Filter sheets observe the parent type list through a binding. Opening a sheet before the offline metadata read finishes shows progress and then the available icons, rather than retaining an empty captured list.

## Offline resources and typography

`ios/prepare_resources.py` stages only active resources from the unchanged `app/assets/`: Catalog data version 2, Wiki images version 3, Tool/font assets version 1, and the frozen reference JSON files. Earlier image versions are excluded. No runtime image or font request exists. Native path helpers validate keys and Tool subdirectories and show a local fallback when a resource is unavailable.

All 621 concrete forms, 193 shiny references, 824 skill/feature references, and explicit type icons are checked against native domain path helpers. The underlying frozen image manifests retain their source URLs, revisions, filenames, sizes, and hashes. Original/shiny switching uses the same source illustration keys. The image and font source information remains separate from Catalog data attribution; packaging does not establish new artwork or font rights.

Headings use the frozen display font with platform fallback. Descriptions and inputs use the system font; numeric values use system monospaced digits. Both frozen font files are staged without modification. SwiftUI relative text styles support Dynamic Type, but physical large-text and VoiceOver acceptance remain open.

## Detail and skill flows

Creature detail uses the same adaptive surface as the page for its illustration hero, with primary text and a tonal number badge, followed by a rounded content surface with Overview, Skills, Type relationships, and Egg groups tabs. The tab strip stays visible while its content scrolls. Overview contains six colored base-stat bars, a total only when all six values exist, the independent feature card, recorded egg weight ranges/size thresholds, and basic facts. The Catalog repository maps existing egg groups and optional measurements to typed DTOs; the UI does not decode raw fields or infer egg height, absent thresholds, or breeding rules. Recorded measurement units are retained. Stage labels use explicit stage/lord fields. Original/shiny switching remains available only for source-backed shiny records.

Details initially show large contained artwork. Browsing contracts the same image into a compact identity header with the tab strip beneath it; returning to the top expands it again. The scroll-content inset remains constant while the overlaid header contracts, preventing a measurement feedback loop. Short tabs retain enough scroll extent to reach both presentations. Original/shiny selection survives scrolling and tab changes. Reduce Motion switches between endpoint layouts without continuous scaling. Tabs, skill-source choices, and base stats add native symbols or existing bundled icons while preserving names and metric meanings. Detail skill filters use the same icon grid and allow multiple existing elements and classifications; filtering remains local to the loaded DTOs.

The detail toolbar retains the favorite button and a More menu for Evolution, My library, and Source. These destinations use native sheets and navigation; notes, collection marks, source revisions, and concrete-form evolution links remain reachable. The four tabs replace the preceding right-side dot navigator.

Pet skills, Bloodline effects, and Learnable skills have separate selectors and preserve source kinds, levels, stages, raw bloodline values, and requirements, including other acquisition kinds in Learnable skills. Name, element, classification, and description search combines with skill type and element filters over DTOs. Feature ownership remains independent. Evolution links use stored edges and concrete pet IDs. Type relationships separately show outgoing effects for each explicit creature type and grouped incoming multipliers, retaining the frozen dual-type three-times incoming damage cap. Egg groups link to the existing same-group Catalog query; absent group information is stated explicitly.

The learnable-skill and feature catalogs retain native search, type/tag/element filtering, explicit pagination, icons, metrics, descriptions, owners, acquisition conditions, source references, and detail-owned favorites. Defined glossary notes resolve from the separate frozen description contract; undefined identifiers remain noninteractive.

Skill and feature catalogs and creature skill tabs share a saved layout: two compact columns by default, three compact columns, or full-width detailed descriptions. Settings and accessible layout menus expose the same choice. The `skill_catalog_layout` JSON string uses the existing personal settings table; invalid or absent values fall back to `twoColumn`. It is independent of `pet_catalog_layout`, requires no migration, and survives process restart and Catalog recovery. ADR-0026 defines this contract.

Compact skill cards follow the supplied reference with a dark rounded surface. The name occupies a dedicated top row alongside the classification glyph; the contained illustration, type/power pill, energy badge, and recorded creature learning-level badge sit below it. Raw textual metrics and unknown values retain their meaning. Feature cards show their feature role without adding invented combat metrics. Full descriptions remain available by tapping a card or selecting detailed mode. Creature-origin skill details show that exact acquisition record near the top, including source kind, level, source stage, bloodline values, and requirements. Detailed mode retains the previous description and acquisition rows. Individual skill details and glossary reading contexts always use full descriptions. Accessibility text sizes use the full-width detailed presentation without changing the saved density.

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
