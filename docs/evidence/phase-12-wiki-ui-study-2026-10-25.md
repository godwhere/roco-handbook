# Phase 12 Wiki UI visual study

- Date: 2026-10-25, Asia/Shanghai
- Scope confirmed by user: Tools and Settings only
- Baseline: Phase 11, commit `0c5138b`
- Status: original-art revision complete; generated boards superseded after user feedback

## Actual visual sources

The NRC Wiki was inspected in the in-app browser. Its non-binding first-visit information notice was dismissed; no account, form submission, or upstream data import was used. A mobile viewport was requested for the phone-layout comparison. The actual exported browser JPEGs are 375 x 812; no image was stretched or edited.

| Source | Direct page | Saved evidence |
| --- | --- | --- |
| Home, campaign imagery and navigation | [Home](https://wiki.biligame.com/nrc/) | [Top](phase-12/wiki-home-mobile.jpg) |
| Home, creature/skill/feature image gallery | Same home | [Image cards](phase-12/wiki-image-cards-mobile.jpg) |
| Home, Tool entries and collection navigation | Same home | [Tools section](phase-12/wiki-library-tools-mobile.jpg) |
| Season archive | [Season archive](https://wiki.biligame.com/nrc/%E8%B5%9B%E5%AD%A3%E6%A1%A3%E6%A1%88) | [Season images](phase-12/wiki-seasons-mobile.jpg) |
| Skill gallery | [Skill gallery](https://wiki.biligame.com/nrc/%E6%8A%80%E8%83%BD%E5%9B%BE%E9%89%B4) | [Skill framing](phase-12/wiki-skills-mobile.jpg) |

The observed home uses a cool slate/lavender backdrop, asymmetric creature/skill image entrances, short labels, and modest tool rows. The sampled creature image tile has computed background `rgb(52, 71, 109)`, radius `9px`, and no CSS border; its rendered body type is `14px` with `23.1px` line height and a rounded family. Therefore, the more elaborate proposed image frames are an intentional extension of the user's request, not a claim that the home already uses ornate frames.

The season page uses ivory surfaces, inset white picture mats, large paired creature art, muted purple image bands, small season labels, and gold details. The skill gallery uses a charcoal/gold header, framed spell pictures, cream content, and compact selected gold controls. The source supports more than one palette; a generic warm-green text-card treatment does not capture its image hierarchy.

## Design brief and hard constraints

The user described the current presentation as too text-heavy and lacking pictures and frames. Earlier feedback also requires smaller normal text. The next design should let imagery carry the entrances, remove marketing/introductory prose and repetitive Tool subtitles, and retain short functional labels. Each prompt requested two 390 x 844 App-content screens, 780 x 844 total, without device hardware or OS chrome. Actual generated dimensions and deviations are recorded below; the requested geometry is not a measured result.

All seven existing Tool destinations remain present. Settings retains the two saved layout choices and their actual options, personal library, Catalog information, explicit update check, bundled recovery, version, and source/license access. A short recovery/personal-data note and unofficial-project footer remain. No audio, notification, login, profile-statistics, cloud-sync, cache-clearing, or other unsupported controls are introduced.

References 1-3 supplied to every built-in ImageGen call are the actual home image-card, season, and skill JPEGs above. References 4-5 are the final normal-text [Tools](phase-11/tools-zh.png) and [Settings](phase-11/settings-zh.png) App captures. The latter establish functionality rather than requiring their prior plain-row composition. The full English prompts, exact UI copy escaped as JSON, current-date anchor, reference paths, and distinct concept directions are recorded in [design-prompts.json](phase-12/design-prompts.json).

## Proposed directions

The three independent generations explore a cool-blue image gallery, an ivory seasonal postcard album, and a dark/gold magic workbench. They differ in information arrangement and picture hierarchy rather than only recoloring the same seven text rows. All emphasize compact labels, distinct illustrative entrances, meaningful picture mats/borders, and readable Settings controls. Each result is a single visual direction containing the two requested pages.

The built-in image generator produced each concept independently from the five references. Results were displayed once in completion order, not prompt order. The following display numbers are the authoritative mapping for the user's next selection.

| Display order | Saved proposal | Actual PNG dimensions | SHA-256 |
| --- | --- | --- | --- |
| 1 | [Magic workbench](phase-12/concept-magic-workbench.png) | 1704 x 923 | `6b01403075620f3f4fb31bb8d7dde0dffc096e4f7389da83f6320a533b5c676d` |
| 2 | [Blue gallery](phase-12/concept-blue-gallery.png) | 1206 x 1305 | `2f862be2a22ca198e87b9705a4d18f84e4301b492c8eda24cc096e6754fddb5f` |
| 3 | [Season album](phase-12/concept-season-album.png) | 1205 x 1306 | `e94530b3a4efec67c4eb17e5c4ed9238a24066eea001336195b4670433fb34f1` |

All three boards were visually inspected. Each shows the seven Tool destinations, both three-option layout selectors, the five existing Settings destinations/operations, recovery note, unofficial-project footer, version, and bottom navigation. Imagery and visible image framing now carry the Tool entrances, with no repeated explanatory subtitles. No unsupported account or online-service controls appear.

The raster boards are composition proposals with limitations: the generator enlarged page headings beyond the requested compact 18-20 point intent, the first board has extra side margins and wider page proportions, and artwork details are AI interpretations rather than identity-verified canonical media. A chosen implementation must enforce compact native title/body sizes, natural phone geometry, existing domain labels, actual saved choices, sufficient hit targets, and reviewed offline image resources. These deviations are not accepted native typography, layout, or asset provenance.

These are raster design proposals. They do not demonstrate interactive controls, native layout, Dynamic Type, offline image closure, runtime installation, physical-device behavior, or asset rights acceptance. No generated pixels are installed into the App by this phase. Any selected design needs a separate scoped native implementation and appropriate resource/behavior/visual validation.

## Validation and delivery

The five source captures and three generated boards were inspected. The new text artifacts were checked for ASCII English prose, valid JSON with escaped UI strings, final newlines, and whitespace; the complete allowed file list and `git diff --check` were reviewed. Design evidence is delivered through GitHub Desktop. The temporary reference viewport override was reset. App builds and data tests are not repeated because no implementation or content changed. The root README stays unchanged because the effective App is still the committed Phase 11 version.

## Original-art revision after user feedback

The user found the generated boards attractive but too AI-like, and noted that many pictured creatures were not from the game. The generated art is therefore rejected as an identity reference. No direction number from that set authorizes its creature artwork for implementation. This revision uses deterministic UI composition with existing frozen PNGs, avoiding another generative repaint of the creatures.

- [Inspectable paired-page preview](phase-12/original-art-study/roco-original-art.html): one compact composition with local Tools/Settings navigation, selectable layout previews, thin image outlines, inset flat mats, and no long Tool subtitles or decorative fantasy scenery.
- [Source-art records](phase-12/original-art-study/source-art.json): manifest paths, source URLs/timestamps/page IDs, Catalog identities, sizes, and SHA-256 for every unique embedded PNG.
- [Tools at 390 CSS pixels](phase-12/original-art-study/tools-original-light.jpg) and [Settings at 390 CSS pixels](phase-12/original-art-study/settings-original-light.jpg).
- [Tools at 320 CSS pixels](phase-12/original-art-study/tools-original-narrow.jpg) and [Settings at 320 CSS pixels](phase-12/original-art-study/settings-original-narrow.jpg).

The three creature images map through the current Catalog and asset manifest to `pet_000001` / `JL_miaomiao`, `pet_000002` / `JL_shuilanlan`, and `pet_000003` / `JL_huohua`. One feature icon, two skill icons, one activity icon, and one outfit preview come from the same existing immutable resource sets. Every embedded image equals its source PNG byte-for-byte and matches the frozen manifest hash and length. CSS uses `object-fit: contain`; there is no repainting, image filtering, crop, warp, new download, or synthetic pet. Short labels use the current native Chinese localization resource. No new game data or season claims are added.

The preview explicitly defines 20-pixel page titles, 15-pixel Tool labels, 14-pixel primary Settings text, and 12-pixel layout-choice labels. Both page compositions were visually inspected at 320 and 390 CSS pixels, including complete lower actions and navigation. Native accessibility acceptance is not implied by these CSS sizes. Layout diagrams are presentation samples rather than real user collections, saved choices, or previews of the exact native rendering.

Passed checks: eight frozen image hashes/lengths, eight embedded-byte equality checks, all image references resolved, seven Tool plus five Settings identifiers retained, six layout choices, local tab switching, an observed radio selection/state update, valid embedded/source JSON, ASCII project prose and escaped UI strings, final newlines, trailing whitespace, matching inline/project copies, and `git diff --check`. The fragment is 693,406 bytes and has no network calls. The local server was only used for browser inspection; the delivered inline preview is self-contained.

Not run: native App builds/tests, Dynamic Type, VoiceOver, dark preview rendering, physical devices, real navigation/update/recovery operations, image-rights acceptance, or release validation. This is a corrected design proposal only. Production App, Catalog, immutable media, schemas, personal data, dependencies, network behavior, and release composition are unchanged, so feature documentation and README require no effective-state revision. The next boundary is review of this original-art composition followed by a separately scoped native implementation.
