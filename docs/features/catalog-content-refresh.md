# Verified offline content refresh

ADR-0030 owns Phase 10. The active native bundle contains Catalog data version 3, frozen NRC snapshot `snapshot-a7dec7b598109dc2`, core image version 4, and Tool image version 2. Catalog and personal SQL remain at schema version 1. Existing releases, image versions, source locks, and the Chinese technical baseline remain immutable.

## Source and identity contract

Live import freezes all eight allowed module heads, requests bodies by revision ID, validates title/page/revision identity and content hashes, and rechecks all heads before freezing or reusing a snapshot. Empty/non-Scribunto content and any failed or changed head block the operation. A stable head set proves only stability across the bounded import. All later parsing, adaptation, validation, and building remain offline.

NRC source skill keys were reallocated between Catalogs 2 and 3. `config/nrc_identity_review_v3.json` binds the exact snapshot and SHA-256 of Catalog 2 to an explicit, injective mapping. The adapter applies it once to typed local references and preserves actual upstream keys in `entity_sources.source_record_key`; raw values are never recursively rewritten. Stale contexts, absent sources, malformed targets, and collisions fail before mutation.

All 824 existing skills preserve local ID, numeric game ID, exact name, and category. The added feature uses the previously unused local `skill_000834`. All 311 existing Learnsets preserve their complete ordered acquisition records after skill mapping. All 273 existing evolution groups preserve their labels and ordered members; 16 chess-condition texts across ten groups now name the opposing piece color explicitly, without changed endpoints, levels, direction, or ordinals. The exact mapping review and regressions distinguish these changes from deleted entities.

The new `config/identity_registry_nrc_v2.json` preserves all 1,911 previous local identities and first-seen revisions, records 617 source-key histories, adds 15 identities, and records ten reviewed form-label fingerprint updates. The original NRC registry remains the Catalog 2 record. The 38 duplicated Evolution/Core type conflicts remain the exact reviewed pair set, bound separately to Core revision 19223 and Evolution revision 19224. No wildcard exception or unreviewed removal is accepted.

## Reproduction commands

From the repository root, use the live importer only for an authorized refresh:

```sh
PYTHONDONTWRITEBYTECODE=1 PYTHONPATH=tools python3 -m bwiki_import import-live \
  --output data/raw --config config/bwiki_sources_nrc_v1.json

PYTHONDONTWRITEBYTECODE=1 PYTHONPATH=tools python3 -m catalog_builder normalize-nrc \
  --snapshot data/raw/snapshot-a7dec7b598109dc2 \
  --type-aliases config/type_aliases.json \
  --previous-catalog data/release/2/assets/catalog/catalog.db \
  --identity-review config/nrc_identity_review_v3.json \
  --data-version 3 --built-at-utc 2026-10-24T17:54:56.246815Z \
  --output /tmp/roco-catalog-v3-rebuilt.json

PYTHONDONTWRITEBYTECODE=1 PYTHONPATH=tools python3 -m catalog_builder build-release \
  --normalized /tmp/roco-catalog-v3-rebuilt.json \
  --schema schemas/catalog_v1.sql \
  --manifest-schema schemas/manifests/bundled_catalog_v1.schema.json \
  --identity-registry config/identity_registry_nrc_v2.json \
  --reviewed-exceptions config/reviewed_exceptions.json \
  --previous-database data/release/2/assets/catalog/catalog.db \
  --output /tmp/roco-catalog-rebuild

PYTHONDONTWRITEBYTECODE=1 PYTHONPATH=tools python3 tools/release/check_catalog.py \
  --release data/release/3
```

The normalization command needs the exact locally retained raw snapshot; a fresh live import may produce another snapshot and cannot reuse this review. Builders refuse existing output versions. Use an unused temporary output for reproduction, and never overwrite a committed release.

## Tool and media contracts

Activities revision 18960 contains 552 entries; fashion revision 18962 contains 124 outfits and 248 gender variants. Previous IDs remain present. Activity `arrivals`, `collection_rewards`, `letters`, `missions`, `paid_bundles`, `clues`, `newspapers`, and `opponents`, fashion `same_name_ids`/`title_suffix`, and variant `pet`/`bonus_ids` are accepted explicit raw fields preserved in `source_record`; they do not create new native interaction or gameplay rules. Unrecognized fields and executable Lua still fail closed. Exact expected counts remain frozen in the source configurations.

Terms revision 7078 and type relationships revision 39538 were checked live and remain unchanged. The installed App never fetches these sources. Source timestamps remain per contract instead of being replaced by a single misleading freshness date.

The core image importer reuses all 1,594 existing images byte-for-byte and adds 17 required images. Tool version 2 reuses all 273 existing images and adds 34 required images. Source hosts, byte limits, PNG dimensions, source SHA-1, and local SHA-256 remain enforced. Only the current Catalog's required art is acquired; unrelated bulk acquisition and runtime image downloads remain outside scope. Native resource staging packages `wiki/v4` and `wiki/tools/v2`; historical versions are excluded.

## Acceptance boundary

The release checker and focused regressions prove source/identity/reference closure, zero removed entities, immutable artifact consistency, and native bundle paths. Swift installer tests exercise an actual owned Catalog 2 pointer followed by Catalog 3 installation and recovery, retaining saved skill identity, favorites, notes, collection marks, and layouts. Simulator UI tests cover offline entry points and the new creature. Physical signed upgrades, iOS 15, device accessibility/durability, live signed update distribution, and store acceptance remain separate gates.
