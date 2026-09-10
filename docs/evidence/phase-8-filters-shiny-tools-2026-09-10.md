# Phase 8 creature-filter, shiny-art, and Tools evidence

- Date: 2026-09-10
- Catalog: data version 1, snapshot `snapshot-19235f9b9b34dc4e`
- App asset version: 2

## Source observations

The Wiki creature index exposes shiny availability, stage, main/regional/lord form groups, and owning-season filters. Its source uses the `_yise` illustration suffix for shiny full-body art. `Module:PetInfo` maps egg-group identifiers 1 through 15 to the displayed group names.

The new Wiki home exposes Season archive, Feature handbook, Egg groups, Game descriptions, Event timeline, and Outfit inspiration. The captured Season archive shows S1 `暗夜拾光`, S2 `狂欢怪谈`, S3 `铅字幻梦`, and S4 `月涌狂想` with distinct purple, pink, green, and lavender color families.

Current Catalog measurements:

- 596 active creature forms;
- 146 shiny-capable form references and 450 non-shiny records;
- stage counts of 210, 203, 122, and 61 for stages 1 through 4;
- owning-season counts of 49 for S1, 41 for S2, 57 for S3, and 0 for S4; and
- 231 source-backed feature records and 15 stored egg-group identifiers.

The nine shiny-capable records without `belong_season_raw` confirm that owning season is not a complete shiny-season classification. No nested shiny-season filter was added.

## Frozen image evidence

The image preflight accepted 1,484 unique source files and 1,565 Catalog references. The imported manifest records:

| Kind | Files | Local bytes |
| --- | ---: | ---: |
| Creature illustrations | 569 | 79,525,000 |
| Shiny creature illustrations | 144 | 19,631,958 |
| Skill and feature icons | 736 | 18,015,640 |
| Domain UI icons | 35 | 114,409 |
| **Total** | **1,484** | **117,287,007** |

Manifest SHA-256: `8e942ab4fa1c1c4f7b803454984009823bad4e20b240cc458c3e93bb0973a278`.

The 144 shiny files cover 146 active form references after shared illustration keys are deduplicated. The importer retained the MediaWiki page identity, source revision metadata, exact image host allowlist, PNG checks, local byte count, and SHA-256 checks used by asset version 1.

## Frozen Tool evidence

The development-only import path validated and froze three data-only Lua sources:

| Contract | Source revision | Records | Source SHA-1 |
| --- | ---: | ---: | --- |
| Game descriptions | `Module:Pets/data/Terms` 7078 | 54 descriptions in six reviewed categories | `ff74e9874fb3b2de64c2d87d8cfe462d3494330b` |
| Event timeline | `Module:Activities/data/Catalog` 10044 | 547 occurrences in five categories | `1df328820658bf6904cb517376c1a81e2c06c43a` |
| Outfit inspiration | `Module:Fashions/data/Catalog` 12224 | 110 outfits and 220 gender variants | `1e215c2d19e7b1d8bb914ef338408eb9cfc2197f` |

The activity contract retains 541 dated or partly dated records, six undated records, 14 source-masked records, normalized UTC+8 windows, and the complete source record for every occurrence. The description contract closes every distinct `skill_description_notes.note_id` currently referenced by the Catalog. The outfit contract retains both gender variants, acquisition text, quality, grade, item count, source image title, and the complete source record.

Tool media version 1 contains 53 deduplicated activity icons and 220 gender-specific outfit previews. Its manifest records 273 files, 749 source references, and 12,379,751 local bytes. Manifest SHA-256: `0c313dd46d84d7da93fb330b2f8e0df42752abe8cfc1f594c44e80e7eea6d8df`. Three source card titles that do not exist use explicit pose-image fallbacks. Large activity posters remain outside the App because their source originals total about 436 MiB; the timeline uses the compact source icons instead.

## App boundary

Creature filters, all seven Tools routes, shiny switching, and Personal library read only the installed Catalog, bundled source contracts, bundled image assets, or device-local user database. The Game descriptions, Event timeline, and Outfit inspiration import commands are development-only and are never invoked by the App. No runtime Wiki request or fallback image download was introduced.

Simulator and automated validation results are recorded in `design-qa.md` and the Phase 8 implementation report.

## Simulator evidence

The iPhone 17 simulator integration flow built and launched the current App, opened the grouped creature-filter sheet, navigated to Tools, opened Game descriptions and a related-term detail, opened the September 2026 Event timeline and a source-backed activity detail, opened Outfit inspiration and a gender-switchable outfit detail, searched for creature 030, and switched its detail header to Shiny. Every capture is 1206 x 2622. The filter sheet preserved every requested group without clipping, the Tools cards retained the supplied vertical hierarchy, the description transition had no residual frame, the timeline displayed 74 September-intersecting records, the outfit grid displayed 110 local previews, and the shiny view displayed its frozen full-body asset.

The skill query remains a normal text field and accepted programmatic text entry in the same App build. The iOS Simulator hardware-keyboard preference was disabled so the software keyboard can be used instead of the Simulator's Scan Text affordance on later interactive launches.
