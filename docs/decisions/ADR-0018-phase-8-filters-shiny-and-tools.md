# ADR-0018: Source-backed creature filters, shiny art, and offline tools

- Status: Accepted
- Date: 2026-09-10
- Phase: 8

## Context

The current Catalog already preserves the fields needed for the requested creature filters: `has_shiny`, `stage`, `form`, `is_lord_evolution`, `belong_season_raw`, the reviewed `handbook_display.default_pet_id`, and numeric egg-group identifiers inside `pets.extra_json`. The Wiki creature index and `Module:PetInfo` define the corresponding form and egg-group semantics. The Wiki image convention appends `_yise` to an illustration key for a shiny full-body image.

The Catalog does not preserve a separate shiny-season field. `belong_season_raw` describes the creature record's owning season and must not be relabeled as the season in which its shiny form was available. The current snapshot contains S1 through S3 values and no S4 creature records.

The current Catalog can drive a season archive, feature handbook, and egg-group browser. Its `skill_description_notes` rows provide relationships but not term definitions. The Wiki supplies separate data-only modules for 54 game descriptions, 547 activity occurrences, and 110 outfit groups. Those modules require independently frozen contracts because they are not part of Catalog schema version 1.

## Decision

The creature browser adds one vertically grouped modal filter sheet. Shiny availability is single-select; stages, forms, owning seasons, and types are multi-select. Values use OR within a group and AND between groups.

Form predicates remain explicit:

- Main form means the concrete `pet_id` selected by `handbook_display.default_pet_id`.
- Regional form means a non-empty, non-default source form that is not a lord record; the source-defined default labels are excluded explicitly.
- Lord form means `is_lord_evolution = 1` or source form `首领形态`.

No suffix, list-order, or name-only inference is introduced. S4 remains a valid filter choice so a later complete Catalog can populate it without an App UI change.

Shiny-capable records receive an Original/Shiny control in the creature detail header. Image asset version 2 adds one deduplicated full-body shiny file for each source illustration key whose active record has `has_shiny = 1`. The App resolves those files only from its bundled assets. Catalog creature names with a shiny form use the season color family observed in the Wiki season archive; records without a stored season use the App primary color.

The third bottom destination becomes Tools. Its vertical card layout exposes Season archive, Feature handbook, Egg groups, Game descriptions, Event timeline, Outfit inspiration, and the existing Personal library. All seven routes are functional without a runtime Wiki request.

Game descriptions freeze `Module:Pets/data/Terms` revision 7078, retain the reviewed six-category mapping, and resolve related skills and features through distinct Catalog note relationships. Activity timeline freezes all 547 records from `Module:Activities/data/Catalog` revision 10044, preserves each complete source record, normalizes its UTC+8 window, and provides month, category, current-status, and detail views. Outfit inspiration freezes all 110 groups and 220 gender variants from `Module:Fashions/data/Catalog` revision 12224, preserves each complete source record, and provides search, grade, gender, acquisition, and detail views.

Tool media version 1 contains only the 53 deduplicated activity icons and 220 gender-specific outfit previews needed by the App. Three absent outfit card files use reviewed source pose-image fallbacks. Large activity posters are not packaged; including all source originals would add about 436 MiB before platform packaging. Every downloaded tool image retains source identity and local integrity metadata.

The skill search field explicitly requests normal text input and disables autocorrection. The iOS Simulator software-keyboard preference remains a device setting rather than an App data or navigation contract.

## Consequences

- Catalog schema version 1 and stored identities remain unchanged.
- The App still performs no runtime Wiki or image request.
- Image asset version 2 contains 1,484 files, including 144 deduplicated shiny illustrations covering 146 active creature references.
- The active frozen image payload grows by 19,631,958 bytes for shiny art.
- Tool media version 1 contains 273 files, covers 749 activity or outfit references, and adds 12,379,751 verified bytes.
- S4 remains empty until a later complete Catalog provides S4 creature records; the Tools contracts do not alter Catalog schema version 1.
- The immutable version 1 asset set remains in repository history and version 2 is the active Flutter bundle.

## Acceptance

- Repository tests prove combined shiny, stage, form, season, type, and egg-group predicates against the real bundled Catalog.
- Import tests prove the complete 54-description, 547-activity, 110-outfit, and 220-variant source contracts, executable-Lua rejection, exact source identities, and tool-media reference closure.
- Widget tests prove the grouped filter controls, shiny-art switch, all seven Tools routes, game-description relationships, activity filtering, outfit variants, and normal skill text-input contract.
- Image tests prove complete source derivation, frozen-manifest integrity, and Flutter packaging for original, shiny, activity, and outfit images.
- Simulator review compares the implemented filter, shiny detail, Game descriptions, Event timeline, Outfit inspiration, and Tools screens with the supplied references and captured Wiki pages.
