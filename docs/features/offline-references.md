# Offline reference supplements and checklists

## Phase 16 contract

Five separately frozen JSON catalogs share a small presentation contract: `items`, `research`, `medals`, `trials`, and `habitats`. Each file is staged at `wiki/references/v1/<kind>.json`. This supplements the existing read-only Catalog without changing either normative SQL file. A shared card/section DTO is reused across these five finite kinds; source adapters retain ownership of every semantic mapping.

The active supplement freezes 48 sources under `references-3ad202f604caf1d1`: 46 live NRC revision bodies and the two accepted V3 Handbooks/Index sources. Its complete public source response/content set is tracked through one exact storage exception. It contains 1,534 items and 1,835 variants, 2,351 research tasks and 4,976 rewards, 60 medals with 56 publicly visible, 726 trial encounters in six normal/boss groups, and 109 habitat areas with 1,545 creature-condition rows. Trial detail retains the source's shared floor pool context rather than creating independent per-floor ownership records.

Each document has `contract_version: 1`, `dataset_id: roco-world-zh-cn`, a nonempty `snapshot_id`, `kind`, `sources`, `groups` and `entries`. Sources retain `title`, positive `page_id`/`revision_id`, `revised_at_utc`, `sha1`, `sha256` and a fixed-revision HTTPS `url`. Groups contain `id`, `title` and optional `image_path`. Entries contain:

- Required: `id`, `name`, `group_id`, `visible`, `sections`, `links`.
- Optional: `subtitle`, `description`, `image_path`, `handbook_id`, `progress_id`.
- `sections`: ordered `{title, lines}` objects. Titles are English localization keys when authored by this project; canonical source labels and conditional text retain their language. Lines are prepared by the adapter, never parsed from raw fields by the UI.
- `links`: ordered `{kind, id, name}` objects where kind is `pet` or `item`. Every native link must close against the frozen V3 Catalog or complete item catalog. Unmapped source references remain explicit text and a reviewed mapping result; they must not become guessed links.
- `raw`: complete source record/attributes and conditional values retained in the immutable projection or its recorded raw sidecar. Unknown fields remain preserved even when not presented by the current UI.

Entries are ordered by their explicit source order. IDs retain explicit source identities. Items preserve detail variants as labeled sections rather than merging their acquisition conditions. Research entries use the unique explicit `progress_id` as the entry ID, retain the separate topic ID in raw data, and group by the stable handbook ID. The five group lists provide item categories, handbook names, medal categories, trial regions/chapters, and habitat areas respectively. Only reviewed public medal statuses have `visible: true`; all source medal records remain preserved.

The Core API is `AssetRepository.referenceCatalog(_ kind: ReferenceCatalogKind) -> ReferenceCatalog`; `ReferenceCatalogKind` has the five raw values above. DTO names are `ReferenceCatalog`, `ReferenceSource`, `ReferenceGroup`, `ReferenceEntry`, `ReferenceSection`, and `ReferenceLink`. DTO properties follow Swift camel case. Core validates shape, source identity/URLs/hashes, unique IDs, group and native-link syntax, safe image paths, and kind-specific checklist membership before returning a catalog. The UI receives normalized DTOs, displays source icons/images, supports text/group filtering and full detail/source access, and opens exact linked creature/item records.

## Local progress

Research and trial completion are independent typed sets in the existing personal `settings` table, under `reference_progress.research` and `reference_progress.trials`. `UserRepository.referenceProgress(_ kind:)` returns `Set<String>`; `setReferenceProgress(_ kind:, id:, completed:)` changes one explicit ID. Only research/trials kinds are valid for this API. Missing data means an empty set; malformed existing JSON or invalid IDs throw without overwriting the stored value. Unknown well-formed saved IDs remain preserved across source changes. JSON arrays are sorted for deterministic writes. No Catalog update/recovery operation owns these settings or existing collection marks.

Research completion is shared across all forms through the explicit handbook/progress membership. Trial completion records encounters and does not claim creature ownership. UI marks change only after successful writes and refresh through the existing user revision mechanism. There are no item/medal inventories, accounts or synchronization.

## Media and habitat boundary

Media uses exact upstream filenames, a deduplicated source manifest, verified immutable bytes and attribution. Reused creature images must come from an exact reviewed creature mapping. Missing/unavailable source media is explicit and uses the existing local placeholder; no generated creature or guessed substitute is allowed. Full map base imagery and tiles are excluded. Habitat records describe the source area/layer and preserve estimated-region notes; coordinates do not represent user location or promise an exact spawn.

The declared item/public-medal set has 1,590 references and 1,589 available PNG files totaling 33,091,988 bytes. `File:Item_20000027.png` is absent upstream; `item_a73c5a669658` has no image path and uses the existing local placeholder. Original-file downloads and cached originals must match upstream SHA-1 and byte size; thumbnails retain separate local SHA-256, size and dimension proof. All 1,159 original-file records in the active set were independently rechecked. Existing frozen creature/type artwork is reused without changing its bytes. New icon provenance joins Settings > Source and licenses.

Unresolved or ambiguous references remain canonical noninteractive text and are counted in the identity report. In particular, `_Map` avatar filenames are never stripped to guess a creature identity. Some exact source filename/title/name/form/description mappings are available; others remain unlinked. Habitat areas remain readable regardless. Medal targets are displayed explicitly, so a target of 1 cannot be suppressed by a description containing 10. The auxiliary supplement is bundled with App builds; signed Catalog database updates do not silently replace it.

## Development commands

Only the explicit source/media import commands contact BWIKI. Fresh source import also requires the accepted V3 frozen baselines named in configuration; ordinary tests use owned fixtures. The complete tracked reference snapshot supports offline projection without a live import. Output paths must be new or byte-identical immutable candidates.

```sh
PYTHONPATH=tools python3 -m bwiki_import import-reference-sources --help
PYTHONPATH=tools python3 -m bwiki_import import-reference-media --help
PYTHONPATH=tools python3 -m bwiki_import build-reference-catalogs \
  --snapshot data/raw/references-3ad202f604caf1d1 \
  --config config/reference_sources_v1.json \
  --identity-config config/reference_identities_v1.json \
  --output /tmp/roco-reference-replay-app \
  --normalized-output data/normalized/references-v1 \
  --reports-output /tmp/roco-reference-replay-reports \
  --media app/assets/wiki/references/v1 \
  --media-report data/reports/references-v1/media-report.json
```

Observed source, media, mapping and native validation results belong in Phase 16 evidence and the implementation report. This contract is not evidence of a completed import, device check or release.
