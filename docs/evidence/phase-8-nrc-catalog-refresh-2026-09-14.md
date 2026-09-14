# Phase 8 NRC Catalog refresh evidence

- Date: 2026-09-14
- Source system: `bwiki.nrc`
- Snapshot: `snapshot-dad7cd7d5ce73236`
- Catalog data version: 2
- Image asset version: 3

## Frozen source revisions

| Source key | Requested module | Revision |
| --- | --- | ---: |
| `core` | `Module:Pets/data/Catalog` | 13095 |
| `handbook` | `Module:Pets/data/Handbooks` | 7268 |
| `evolution` | `Module:Pets/data/Evolutions` | 7267 |
| `learnset_catalog` | `Module:Pets/data/Learnsets` | 13094 |
| `skill_catalog` | `Module:Pets/data/Skills` | 7273 |
| `index` | `Module:Pets/data/Index` | 12251 |
| `overview` | `Module:Pets/data/Overview` | 12253 |
| `history` | `Module:Pets/data/History` | 13096 |

The source lock records each canonical title, page ID, revision timestamp, API SHA-1, response SHA-256, source-content SHA-256, and exact local response and content path.

## Import and normalization

```text
PYTHONDONTWRITEBYTECODE=1 PYTHONPATH=tools python3 -m bwiki_import import-live --output data/raw --config config/bwiki_sources_nrc_v1.json
Result: passed; eight required modules were frozen as snapshot-dad7cd7d5ce73236.

PYTHONDONTWRITEBYTECODE=1 PYTHONPATH=tools python3 -m catalog_builder normalize-nrc --snapshot data/raw/snapshot-dad7cd7d5ce73236 --type-aliases config/type_aliases.json --previous-catalog data/release/1/assets/catalog/catalog.db --data-version 2 --built-at-utc 2026-09-14T00:00:00Z --output data/normalized/snapshot-dad7cd7d5ce73236/catalog-v2.json
Result: passed; a deterministic normalized Catalog was produced with closed creature, handbook, skill, Learnset, feature, type, and evolution references.

PYTHONDONTWRITEBYTECODE=1 PYTHONPATH=tools python3 -m catalog_builder initialize-identity --normalized data/normalized/snapshot-dad7cd7d5ce73236/catalog-v2.json --registry config/identity_registry_nrc_v1.json
Result: passed; 1,911 NRC identity mappings were frozen as the pre-release baseline.

PYTHONDONTWRITEBYTECODE=1 PYTHONPATH=tools python3 -m catalog_builder build-release --normalized data/normalized/snapshot-dad7cd7d5ce73236/catalog-v2.json --schema schemas/catalog_v1.sql --manifest-schema schemas/manifests/bundled_catalog_v1.schema.json --identity-registry config/identity_registry_nrc_v1.json --reviewed-exceptions config/reviewed_exceptions.json --output data/release
Result: passed with declared coverage warnings; Catalog data version 2 was written without overwriting data version 1.
```

The database contains 621 active creature forms, 466 handbook entries, 824 active skills, 311 Learnsets, 273 evolution groups, 502 evolution edges, and 18 types. `integrity_check` returned `ok`, `foreign_key_check` returned no row, and the database SHA-256 is `dce0d3376611adc151f8e2abe1f74185d19c94f61a3d0d2fade98a188dae9d61`.

The S4 source sample with game ID `3542` resolves to `pet_000598`, handbook `handbook_000454`, handbook number `454`, season `4`, stage `1`, two types, total base stats `567`, a feature relation, and original plus shiny source filenames. All 621 active forms have all six base-stat values.

## Image assets

```text
PYTHONDONTWRITEBYTECODE=1 PYTHONPATH=tools python3 -m bwiki_import preflight-image-assets --catalog data/normalized/snapshot-dad7cd7d5ce73236/catalog-v2.json --config config/wiki_assets_v3.json
Result: passed; 1,559 NRC source files and 35 preserved domain UI icons were accepted.

PYTHONDONTWRITEBYTECODE=1 PYTHONPATH=tools python3 -m bwiki_import import-image-assets --catalog data/normalized/snapshot-dad7cd7d5ce73236/catalog-v2.json --config config/wiki_assets_v3.json --output app/assets/wiki --reuse-assets app/assets/wiki/v2
Result: passed and passed again as an immutable reuse check.
```

| Kind | Files |
| --- | ---: |
| Original creature illustrations | 595 |
| Shiny creature illustrations | 191 |
| Skill and feature icons | 773 |
| Preserved domain UI icons | 35 |
| **Total** | **1,594** |

The manifest contains 1,673 Catalog references and 124,766,985 local bytes. Its SHA-256 is `0a38eea8a313ce72f910b6f5c914d82d3250d2db816f16e109cd2120d06f9373`. Flutter packages only image asset version 3 for the active creature and skill paths.

## Validation boundary

The focused NRC pipeline, live snapshot, image importer, release checker, Catalog repository, installer, remote archive, asset-resolution, and Catalog-flow tests passed during implementation. Complete suite results are recorded in the Phase 8 implementation report after the final run.

No Xcode build, simulator run, physical-device run, signed remote update package, GitHub Release upload, store upload, review, or publication was performed for this refresh.
