# Phase 12 Wiki-grounded UI design study

- Date: 2026-10-25
- Status: visual study complete; three design proposals delivered for selection

## Declared boundary

The user requested direct observation of the Wiki before further UI design, emphasizing excessive text and missing image/frame treatment. This phase studies the live NRC Wiki and develops three visual alternatives for the existing Tools and Settings homes. Previous feedback requires compact normal typography. All seven Tool destinations and every existing Settings operation remain part of the design contract.

Allowed paths are this report and new reference screenshots, design proposals, prompts, and source/visual observations under `docs/evidence/phase-12/` and `docs/evidence/phase-12-wiki-ui-study-2026-10-25.md`. Existing App code, Catalog/Tool content, immutable runtime media, SQL, repositories, dependencies, runtime networking, signing, server configuration, and store publication are non-goals. Live page browsing is authorized for visual reference; no data import or runtime source access is introduced.

## Acceptance and stopping conditions

Inspect actual rendered source pages, capture the relevant image/card/border patterns, and inspect existing App screenshots and bundled artwork. Produce exactly three independent, source-grounded visual directions with realistic compact Chinese UI copy and complete existing entry points. Keep visible dates source-grounded or omit them. Mark concepts as proposals rather than implemented or validated App behavior. Do not change production UI before a direction is selected. Record the source URLs, visual evidence, image prompts, observed limitations, and next boundary. Review the complete allowed diff, run `git diff --check`, and deliver saved design evidence through GitHub Desktop.

No build or runtime test is required for this design-only phase. Native implementation, simulator comparisons, accessibility behavior, resource packaging, and device acceptance belong to the later selected implementation scope.

## Delivered artifacts

- `docs/evidence/phase-12-wiki-ui-study-2026-10-25.md`: source URLs, observations, prompt/output mapping, visual review, and limitations.
- `docs/evidence/phase-12/wiki-*.jpg`: five direct browser captures of the home, image entrances, tool section, season archive, and skill gallery.
- `docs/evidence/phase-12/design-prompts.json`: complete English prompts, escaped exact UI strings, and reference paths for three independent built-in image generations.
- `docs/evidence/phase-12/concept-*.png`: three paired Tools/Settings proposals, displayed as magic workbench (1), blue gallery (2), and season album (3).

## Validation results

- Passed: actual rendered source inspection and visual inspection of all three boards; all existing top-level destinations and Settings operations represented.
- Passed: generated originals copied byte-for-byte into the phase evidence directory; PNG dimensions and SHA-256 recorded.
- Passed: new Markdown/JSON ASCII, final-newline, trailing-whitespace, and JSON checks; scoped file review and `git diff --check`.
- Not run: App build, Python data suite, native tests, simulator implementation comparisons, Dynamic Type, VoiceOver, physical-device checks, image-rights acceptance, or release validation. This phase changes no implementation, data, or shipped media.

The raster generator did not fully follow the requested compact headings or phone geometry. The first proposal has extra side margins and wider page proportions; generated character art is illustrative rather than identity-verified. These are recorded design limitations, not accepted runtime behavior. The next allowed boundary is a user-selected, scoped native Tools/Settings implementation with compact type, reviewed offline art, preserved controls, and relevant native/accessibility/visual checks.

The root README is unchanged because supported functionality, commands, release composition, and the effective Phase 11 App are unchanged. Source/design evidence and this report supply the documentation required for this visual study. Commit and push use GitHub Desktop; no App or store publication is part of this delivery.
