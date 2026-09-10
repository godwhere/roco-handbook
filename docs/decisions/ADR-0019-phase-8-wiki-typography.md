# ADR-0019: Frozen Wiki typography roles

- Status: Accepted
- Date: 2026-09-11
- Phase: 8

## Context

The Flutter App used only the platform-default Material typography. The current Wiki stylesheet defines several font families and applies `MIANFEIZITI` to its primary game-facing headings and controls while exposing `MIANFEIZITI-NUM` as a dedicated numeric face. Applying the display face to every App string would reduce readability for descriptions, search input, Settings explanations, and accessibility-scaled paragraphs.

The installed App must remain offline-first. A font used at runtime therefore needs the same immutable, validated packaging boundary as the existing image library rather than a stylesheet or CDN dependency.

## Decision

Font asset version 1 freezes two exact TrueType files declared by the current Wiki stylesheet:

- `RocoDisplay` maps the Wiki `MIANFEIZITI` face to display, headline, title, and label roles.
- `RocoNumbers` maps the Wiki `MIANFEIZITI-NUM` face to selected handbook numbers, base-stat values, skill metrics, and timeline dates with tabular figures.

Body roles retain the platform text face. Search input, creature and skill descriptions, Settings explanations, and other long-form content therefore keep native readability. Missing glyphs in either frozen face fall back through the platform Chinese and Latin families.

`config/wiki_fonts_v1.json` freezes the source stylesheet, exact HTTPS asset boundary, byte counts, and SHA-256 values. The development-only font importer rejects another host, an unsafe path, a changed payload, an oversized file, or an invalid SFNT header. It writes an immutable versioned directory and verifies an existing version instead of replacing it. Flutter packages both files directly; the App performs no runtime font request.

The same role mapping applies on iOS and Android. Platform text scaling remains active because the change replaces typefaces without fixing text scale factors or paragraph dimensions.

## Consequences

- The App gains source-matched game typography without changing Catalog data, identities, navigation, or localization copy.
- Long-form text remains visually distinct from headings and controls.
- Font asset version 1 adds 4,568,108 verified bytes before platform packaging.
- Updating either typeface requires a new immutable font asset version and a reviewed contract change.

## Acceptance

- Offline import tests prove URL confinement, SFNT validation, exact byte and hash matching, immutable reuse, and tamper rejection.
- Flutter tests prove the display/body/number role split and load both font files from the packaged asset bundle.
- Existing creature, skill, Tool, dark-theme, enlarged-text, localization, and navigation widget tests remain green.
- Simulator review confirms that headings and labels use the game face without clipping or obscuring core controls.
