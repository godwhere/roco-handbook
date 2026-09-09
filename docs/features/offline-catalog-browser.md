# Offline Catalog browser

## Entry and navigation

The App prepares the bundled Catalog before showing normal navigation. Preparation is a local copy and validation step; the screen explicitly states that no download is required. A startup failure shows a retry action and confirms that personal data was not changed.

The bottom navigation has two destinations:

- **Creatures** opens the handbook browser.
- **Skills** opens the skill browser.

The information action shows data version, Catalog schema, snapshot ID, build time, complete source revision time range, coverage flags, and the packaged attribution text.

## Creature browser

The default view shows one evidence-backed default form for each handbook entry. **All forms** shows concrete pet records. Entering search text always returns concrete forms so an exact special-form result opens that exact `petId`.

Search supports canonical name, title, alias, and exact handbook number. Pure numeric input is left-padded for matching, so `4` and `004` both match stored display number `004`; the stored number is not rewritten. `%`, `_`, and backslash are treated as literal search characters.

The type filter matches any selected type. Sorting is limited to the visible enum choices: handbook number, name, attack, magic attack, or speed. Results load 60 at a time through an explicit **Load more** action.

## Creature detail

The detail screen shows the concrete form's number, name, form label, types, source description, basic information, six stats, feature, learnable skills, evidence-backed evolution relations, and source revision.

Forms sharing a handbook entry appear in the form selector. Changing the selector reloads the complete record by `petId`; it does not reuse the previous form's feature, stats, skills, or evolution data.

Feature ownership has its own section. Learnable skills remain separated by native, bloodline, skill-stone, and legendary source. Levels, source stages, bloodline values, and legendary requirements remain visible when provided.

## Skill browser and detail

The skill browser supports name search and relationship filters for all skills, features, or learnable skills. Results are paginated by the same explicit control.

A skill detail preserves category, element, energy, power, target, original description, and source revision. Feature owners and creatures that can learn the skill use separate sections. A skill may appear in both without collapsing the relationships.

Description-note identifiers remain stored in the Catalog. When their definitions are not included, the App shows a coverage notice instead of a broken glossary link.

## Offline and accessibility behavior

The production Dart code has no HTTP client or BWIKI endpoint. All ordinary data comes from the installed read-only SQLite file. Search requests use a generation token so a slow older result cannot replace a newer query.

Controls provide text labels or tooltips, progress states announce local preparation, content is scrollable, and layouts are tested with dark theme and a 2.0 text scale. Canonical upstream text may retain its source language; navigation and explanatory copy are English.
