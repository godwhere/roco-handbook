# Phase 1 upstream evidence

- Date: 2026-09-09
- Access mode: read-only HTTPS requests to the configured MediaWiki Action API
- System networking changes: none

## Frozen data snapshot

The local importer validated ten available revision responses: seven required data modules and three executable adapter-review modules. It recomputed the UTF-8 content byte sizes and SHA-1 values before freezing snapshot `snapshot-19235f9b9b34dc4e`.

The required data revisions are:

| Source | Revision | Content bytes |
| --- | ---: | ---: |
| Core | 43006 | 394098 |
| Index | 42853 | 63246 |
| Handbook | 42852 | 198733 |
| Evolution | 42851 | 114329 |
| SkillCatalog | 43008 | 185997 |
| Learnsets | 42855 | 17335 |
| LearnsetCatalog | 42854 | 412526 |

The adapter-review modules are Pet, Skills, and DexIndex. DexIndex revision 43100 contains 39674 source bytes and has computed SHA-1 `6665973f092b2b0fe5c9f207128362fdb6f0af3d`. All three executable modules were rejected by the restricted data parser.

## Rendered index evidence

The MediaWiki parse response for the current pet-index page was frozen as `rendered-index-55e8fc070aec7c28`. The response records page revision 41359, contains 1771138 bytes, and has SHA-256 `55e8fc070aec7c2832666230bc69cfac6d4fe7e3649550740f881e0559e392f0`.

Offline inspection found:

- 594 rendered pet cards, each mapped to a unique Core title.
- 442 displayed handbook numbers with no inconsistent value inside a shared handbook entry.
- 442 main-form markers, covering every handbook entry exactly once.
- 442 matches between the resolved default mapping and rendered main-form evidence.
- 442 correlations between the rendered main form and `show_topics`, recorded only as a diagnostic.
- Two Core records not rendered by the current page because their titles are in the upstream DexIndex block list.

The rendered response is canonical upstream data and remains in ignored raw storage. Its lock and the generated inspection report are tracked.

## Result

`data/reports/snapshot-19235f9b9b34dc4e/structure-report.json` reports no blocking issue. The only warning is that the three optional V1 sources disabled by scope were not imported.

## Transport confirmation

A second unauthenticated request for each live evidence source completed with HTTP 200 and `application/json; charset=utf-8` on 2026-09-09. The DexIndex response was 42463 bytes and byte-identical to the imported response; the server returned request ID `376136a929cf86ac1fa0b1fb`.

The rendered-index response was again 1771138 bytes and retained page revision 41359, all 442 number mappings, and all 442 main-form mappings. Its raw SHA-256 changed to `94a1c655bda3a06edd84e4c6b53d24eb9d0090579d52688f525142a5bb76ffd9` because MediaWiki regenerated dynamic parser-diagnostic comments, including cache and timing values; the semantic card evidence was unchanged. The server returned request ID `ff7e3e5dd681403ca7238917`. The original frozen response remains the report input.
