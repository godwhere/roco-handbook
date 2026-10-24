# Phase 12 Wiki-grounded UI design study

- Date: 2026-10-25
- Status: decorative-art revision complete; improved composition delivered for review

## Decorative-art revision boundary

The user rejected the overly plain original-art composition and explicitly requested attractive backgrounds and frames. Continue Phase 12 as a visual study with original game PNGs preserved, adding generated scenery/paper, a transparent reusable corner frame, and a text-free title plaque. Generation is limited to decorative UI assets and must contain no creatures, people, gameplay claims, or UI text. The original-art revision remains historical evidence.

Allowed paths are this report, the Phase 12 visual-study evidence document, and new files under `docs/evidence/phase-12/decorated-art-study/`, plus a matching task-owned inline preview. Production App, frozen media, Catalog, schemas, models, runtime networking, dependencies, and release settings remain outside scope. Verify source-byte identity, actual asset transparency/placement, preserved labels/controls, local preview interactions, 320/390-pixel visual quality, self-contained resources, English project prose, and `git diff --check`. Deliver the improved visual proposal before any native implementation.

The new preview is `docs/evidence/phase-12/decorated-art-study/roco-decorated-art.html`. It replaces gray wells with castle scenery or map-paper backdrops, adds a reusable blue/gold corner frame, integrates short labels into ivory nameplates, removes the repeated header pet, and uses one outer frame for each Settings group. A navy activity badge improves contrast, and portrait/nameplate clearance preserves the full visible source silhouettes. Titles stay at 20 pixels, Tool/primary Settings labels at 14 pixels, and layout-choice labels at 12 pixels.

Three decorative assets were generated independently with the built-in ImageGen tool, inspected, and saved with their full English prompts and original PNGs. No generated scene contains pets or people. Apple `sips` creates display-size delivery derivatives; the frame and nameplate retain real alpha. The frame center and outer corner measure alpha 0; the nameplate outer corner measures 0. All eight original game PNGs remain byte-identical to the source manifest and prior verified study. The 961,730-byte inline fragment embeds the original game art and all three decorative resources without fragment network calls. JSON/hash/length/closure checks, JavaScript syntax, CSS/inline-copy equality, English-prose/whitespace checks, local tab/radio state behavior, and visual checks at 320/390 CSS-pixel viewports passed. An independent visual review prompted varied scenery, a contrasting activity backing, and extra portrait clearance.

The asset/prompt/source records, editable decoration CSS, and four final browser captures are in the same directory. This remains a visual proposal; native navigation, real preference persistence, update/recovery execution, dark rendering, Dynamic Type, VoiceOver, physical devices, image-rights acceptance, and release checks were not run. No native/data test suite is repeated because production files are unchanged. The README and feature documentation still describe the effective Phase 11 App; this report and design evidence record the proposal. Delivery uses a scoped GitHub Desktop commit/push, with native implementation as the next selected-design boundary.

## Original-art revision boundary

The user rejected the generated creature identities and excessive AI-like decoration after reviewing the three boards. Continue this design-only phase with a deterministic, inspectable Tools/Settings composition using byte-identical existing frozen game artwork. Allow this report, the Phase 12 visual-study evidence document, and new files under `docs/evidence/phase-12/original-art-study/`. A task-owned inline preview may be copied into the thread visualization directory for delivery. No further creature generation, network acquisition, production App edit, immutable media edit, or native behavior change is authorized by this revision.

Acceptance is source-manifest identity/hash verification for every embedded image, direct visual inspection of both revised pages at phone widths, local preview interaction checks, explicit compact typography, complete existing top-level entry points, valid offline preview resources, English project prose, and `git diff --check`. Stop after delivering the revised visual composition for user review. Native implementation remains a separate selected-design boundary.

The revised composition is `docs/evidence/phase-12/original-art-study/roco-original-art.html`, with eight source records in `source-art.json` and four 320/390 CSS-pixel browser captures in the same directory. It embeds the exact existing PNG bytes for three Catalog-identified creatures, one feature, two skills, one activity icon, and one outfit preview. All images passed frozen-manifest hash/length checks and embedded-byte equality checks; no new art was generated or acquired. Chinese UI strings come from the native localization resource. The preview uses 20-pixel headings, 15-pixel Tool labels, and 14-pixel primary Settings text with flat image mats and thin outlines. Existing entry points are represented without repeated Tool subtitles.

Both pages were visually inspected at 320 and 390 CSS pixels. Local Tools/Settings switching and a layout-choice state change passed; the six choices and twelve destination identifiers are present. The 693,406-byte fragment has complete embedded-image closure, no network calls, valid JSON, matching thread/project copies, and clean ASCII/newline/whitespace checks. The local preview is a visual study: Tool routes, update/recovery operations, real saved preferences, native accessibility, dark rendering, and device behavior are not implemented or accepted by it. Native App/data/resource files remain unchanged. The original three generated boards remain historical evidence and are superseded by this revision; no generated creature identity is a selected target.

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
