# ADR-0016: Phase 8 creature catalog illustration layout

- Status: accepted
- Date: 2026-09-10
- Scope: creature catalog controls, form presentation, and bundled creature imagery
- Supersedes: the creature-head packaging and list-rendering portions of ADR-0015

## Context

ADR-0015 introduced bundled creature heads and illustrations. The first creature catalog placed search, handbook/form mode, sort, and type controls on separate rows and used head images in compact cards. The resulting hierarchy spent too much vertical space on controls, separated related filters, and made the available full creature art unnecessarily small.

The Catalog already preserves stable concrete-form identity, default-form selection, `head_key`, and `illustration_key`. All 596 active forms have a resolvable illustration, with 569 distinct illustration files after shared keys are deduplicated. The requested presentation change therefore does not require a schema, identity, or source-data change.

## Decision

- The creature catalog always lists concrete forms. The Handbook/All forms mode control is removed, and the page uses the existing `searchPets` repository query for both empty and non-empty searches.
- Search, Sort, and Types share one responsive row. Search receives two flexible width units; Sort and Types receive one unit each, with fixed gaps between controls.
- Sort opens a modal bottom sheet with selectable chips and explicit Cancel and Apply actions. Its structure and surface treatment match the existing type-filter bottom sheet.
- Creature cards use the frozen full illustration at 112 logical pixels with contain fitting. Head images are no longer used by App presentation or included in the bundled image library.
- A default-form card displays `<name> <dex number>` followed by its type names. A non-default form displays `<name>（<form>） <dex number>` followed by its type names. The default-form label is intentionally omitted.
- The existing Catalog `head_key` field remains preserved as upstream data. This decision changes only the derived image-import scope, App DTO projection, runtime path helpers, and packaged files; it does not remove or reinterpret the source field.
- Skill user lists use the same frozen illustration helper, so removal of packaged heads leaves no runtime head dependency.

## Phase boundary

Allowed paths are the creature catalog and skill-user presentation, existing Catalog DTO and repository projections, the image import configuration and tool, bundled Phase 8 image assets, focused tests, current READMEs, Phase 8 feature and evidence documents, and the Phase 8 implementation report.

Catalog and User schemas, source identity, default-form rules, detail-page semantics, Phase 7 transport, personal data, runtime networking, signing, store upload, and publication do not change.

## Acceptance

- The Handbook/All forms control is absent and an empty query returns concrete forms.
- Search, Sort, and Types render on the same row with the intended two-to-one-to-one width relationship.
- Sort and type selection use modal bottom sheets, and applying a selection reloads through the existing repository query contract.
- Default and non-default card copy follows the declared exact structure without a default-form label.
- Every active form resolves to a bundled illustration through the production helper.
- No App code or declared Flutter asset path refers to the removed head bundle.
- The immutable image manifest exactly matches the remaining bundled PNG files and records their hashes and byte lengths.
- Focused widget, repository, import, packaging, complete Python, and complete Flutter checks pass.
- The simulator or emulator visual review confirms the final list layout and full-illustration scale before the evidence screenshot is accepted.

## Consequences

The catalog initially contains more rows because each concrete form is visible without a mode switch, while pagination remains bounded. Cards become taller to make full art legible. Removing 596 head files reduces the immutable image bundle by 9,221,952 bytes without reducing active creature coverage. Future image imports derive only creature illustrations, skill or feature icons, and selected domain UI icons.
