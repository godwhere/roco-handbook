# Phase 12 Wiki UI visual study

- Date: 2026-10-25, Asia/Shanghai
- Scope confirmed by user: Tools and Settings only
- Baseline: Phase 11, commit `0c5138b`
- Status: source study and three visual proposals complete; awaiting design selection

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
