# Offline Catalog browser

## Entry and navigation

The App prepares the bundled Catalog before showing normal navigation. Preparation is a local copy and validation step; the screen explicitly states that no download is required. A startup failure shows a retry action and confirms that personal data was not changed.

The bottom navigation has four destinations:

- **Creatures** opens the handbook browser.
- **Skills** opens the skill browser.
- **Tools** opens season, feature, egg-group, game-description, activity-timeline, outfit, and device-local Personal library routes.
- **Settings** shows local data versions and attribution, starts the optional foreground complete-Catalog update flow, and provides the confirmed bundled-Catalog recovery action.

The information action shows data version, Catalog schema, snapshot ID, build time, complete source revision time range, coverage flags, and the attribution text validated and retained with that exact Catalog version.

## Creature browser

The creature browser always shows concrete pet records, so an exact special-form result opens that exact `petId` without a handbook/form mode switch.

Search supports canonical name, title, alias, and exact handbook number. Pure numeric input is left-padded for matching, so `4` and `004` both match stored display number `004`; the stored number is not rewritten. `%`, `_`, and backslash are treated as literal search characters.

The grouped filter sheet combines shiny availability, First/Second/Third stage, Main/Regional/Lord form, S1 through S4 owning season, and creature type. Choices use OR within a group and AND between groups. Main forms use the reviewed `handbook_display.default_pet_id`; regional and lord predicates use preserved source fields rather than suffix or list-order inference. The current Catalog has no independent shiny-season field, so the App does not present a misleading nested shiny-season filter. Sorting is limited to the visible enum choices: handbook number, name, attack, magic attack, or speed. Results load 60 at a time through an explicit **Load more** action.

Shiny-capable creature names use the stored season's Wiki-aligned color family. Records without an owning season use the App primary color. The S4 filter remains visible for forward compatibility even though data version 1 contains no S4 creature records.

## Creature detail

The detail screen shows the concrete form's number, name, derived stage label, type icons, source description, favorite control, basic information, feature, six stats, categorized skills, evidence-backed evolution relations, incoming type relationships, personal data, and source revision. First, Second, Third, and Lord form labels derive from preserved stage and lord-evolution fields. Non-lord records explicitly display No for Lord evolution. A shiny-capable record adds an Original/Shiny control backed by the frozen `_yise` full-body illustration. The five primary sections appear in the order Basic information, Feature, Base stats, Skills, and Evolution.

The detail screen has no form selector. Every concrete form remains directly reachable from the catalog, and tapping an evidence-backed evolution row opens the related concrete `petId` on a new route. Back returns to the previous detail without inferring a form or evolution relation.

Feature ownership has its own image-backed section and displays the stored source description. Pet skills, Bloodline effects, and Learnable skills separate native, bloodline, and skill-stone relations. Preserved legendary relations remain under Learnable skills with their distinct source and requirement. An optional in-memory filter combines physical attack, magic attack, defense, or status with the stored skill element. The element icon follows each skill name; energy, category, and power form the metrics row. Levels, bloodline values, and legendary requirements remain visible when provided.

The fixed right-side dot navigator overlays the full-width content without a separate panel or reserved gutter. Every dot has a full accessible tap target, scrolls to its section, and reveals the localized section name in a rounded outlined tooltip on long press.

## Skill browser and detail

The skill browser is a learnable-skill handbook with a compact Skill handbook, Skill filters, and Skill query toolbar. The filter sheet combines four skill types, 20 accepted labels, and 18 stored elements. Source-backed fields are queried directly; labels without a first-class Catalog field use documented read-only matches over preserved descriptions or note identifiers. Results are paginated by the same explicit control. Feature records remain accessible through creature feature sections.

A skill card shows its image, name with element icon, category, energy, power, and source description. Catalog cards have no favorite control. A skill detail preserves category, element, energy, power, target, original description, source revision, and the favorite control. Feature owners and creatures that can learn the skill use separate sections. A skill may appear in both without collapsing the relationships.

Description-note identifiers remain stored in the Catalog. When their definitions are not included, the App shows a coverage notice instead of a broken glossary link.

## Tools

Tools uses compact vertically stacked cards based on the supplied and captured Wiki navigation references. Each card begins with its functional title at the upper left and omits the earlier numbered category overline. Season archive queries `belong_season_raw`, and Feature handbook queries preserved feature relationships. Egg groups combines normal text-input creature search with a multi-select sheet over the numeric identifiers in `pets.extra_json`; an empty group selection means every stored group, selected groups use OR semantics, and results open the matching concrete creature directly. No second identity or raw-field UI path is introduced.

Personal library remains available as a Tools card. Game descriptions reads a separate bundled 54-term contract and joins each term to distinct Catalog skill or feature relationships. Event timeline reads 547 bundled activity occurrences, filters them by source category and selected month, derives Active, Upcoming, Ended, or Undated against the device clock, and opens preserved summaries and descriptions. Outfit inspiration reads 110 bundled outfits and 220 gender variants, supports text and grade filtering, switches the preview gender, and displays acquisition details.

These three Tool contracts preserve their source revision and complete source records but remain separate from Catalog schema version 1. Their development import commands validate data-only Lua and refuse executable syntax or a changed identity. The App packages compact source activity icons and outfit previews and never opens the Wiki or downloads a missing image at runtime.

## Offline-first and accessibility behavior

All ordinary browsing data comes from the installed read-only SQLite file, and first launch requires no network. Production code has no BWIKI endpoint. Its only HTTP client is the exact-host GitHub Releases Catalog source, and Settings is its only trigger; browsing, search, favorites, notes, startup, and recovery do not request the network. Search requests use a generation token so a slow older result cannot replace a newer query.

Controls provide text labels or tooltips, local preparation and Catalog update states use live semantics, transfer progress is visible, content is scrollable, and layouts are tested with dark theme and a 2.0 text scale. Canonical upstream text may retain its source language; navigation and explanatory copy are English.
