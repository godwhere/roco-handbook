# Phase 1 implementation report

- Status: complete
- Date: 2026-09-09
- Workspace: `/Users/ethan/Documents/ChatGPT/roco-handbook`

## Declared boundary

Phase 1 was limited to the local importer, restricted Lua parser, metadata key expansion, source adapters, related configuration and tests, immutable raw snapshot storage, reports, and required documentation. It did not create Flutter UI, download images, execute Lua, overwrite the original temporary responses, build a Catalog database, publish an App, or change system networking.

## Changes

- Added strict MediaWiki response validation for page identity, revision metadata, UTF-8 byte size, and SHA-1 content integrity.
- Added content-addressed immutable snapshot storage with mutation detection for revision and rendered-page responses.
- Added a bounded parser for data-only Lua tables with source locations, type and shape preservation, comments and string support, depth and token limits, and explicit executable-syntax rejection.
- Added recursive metadata key expansion with duplicate-key protection.
- Added Core, Index, Handbook, Evolution, SkillCatalog, Learnset, and LearnsetCatalog adapters that inventory every observed field and preserve unknowns as blockers.
- Added reference-closure, feature-conflict, default-form, rendered-number, rendered-main-form, and sample-entity checks.
- Added 48 evidence-bound handbook overrides for entries that cannot be selected by the unique unformed name rule.
- Added a frozen snapshot for the seven required modules and three executable review modules, plus a separate frozen rendered-index response.
- Added generated structure and sample-mapping reports, including the required three-form creature case.
- Added importer, parser, key-expander, adapter, rendered-evidence, schema, and governance regression tests.

## Verified results

- Required data modules parsed offline: 7 of 7.
- Concrete creatures: 596.
- Handbook entries: 442; observed display numbers: 442; resolved defaults: 442.
- Skills: 788.
- Learnsets: 298 with 596 pet assignments.
- Evolution groups: 242.
- Unknown fields: zero across required adapters.
- Missing references and Core/Learnset feature conflicts: zero.
- The three required sample forms retain distinct pet IDs and the shared handbook ID; the base Core and Learnset feature both resolve to the same required skill.
- Executable Pet, Skills, and DexIndex modules are rejected by the restricted parser.

## Verification performed

```text
PYTHONDONTWRITEBYTECODE=1 PYTHONPATH=tools python3 -m unittest discover -s tests -p 'test_*.py'
Result: 46 tests passed.

PYTHONDONTWRITEBYTECODE=1 PYTHONPATH=tools python3 -m bwiki_import import-local --input-dir /private/tmp --output data/raw --config config/bwiki_sources.json
Result: snapshot-19235f9b9b34dc4e created with 10 validated sources.

PYTHONDONTWRITEBYTECODE=1 PYTHONPATH=tools python3 -m bwiki_import import-rendered-index --input /private/tmp/roco-handbook-index-render.json --output data/raw
Result: rendered-index-55e8fc070aec7c28 created and validated.

PYTHONDONTWRITEBYTECODE=1 PYTHONPATH=tools python3 -m catalog_builder inspect --snapshot data/raw/snapshot-19235f9b9b34dc4e --output data/reports --display-overrides config/handbook_display_overrides.json --rendered-index-response data/raw/rendered-index-55e8fc070aec7c28/responses/pet_index.json
Result: passed_with_warnings; zero blocking issues and one scope warning.
```

The first report attempt correctly stopped on 48 ambiguous default forms. No value was inferred from `show_topics`; the entries were resolved only after the rendered upstream main-form markers were frozen and compared. A bare test command without `PYTHONPATH=tools` also failed to import the new tool packages; the documented command now includes the required local module path.

## Not run

- Cross-version identity comparison against a second complete snapshot
- Normalization into the Catalog schema or full SQLite Catalog generation
- Catalog manifest, package, diff, deletion review, or release validation
- Optional disabled HeadOverrides, SkillStoneTopics, or TopicRewards coverage
- Flutter dependency resolution, analysis, build, simulator, or device tests
- Image acquisition, licensing completion, signing, store upload, or App release

## Remaining risks and next boundary

The live rendered index intentionally omits two Core titles, but the raw Core records remain present and auditable. Three optional modules remain disabled for V1, and referenced skill-note definitions are not yet available. The source IDs have not been tested across multiple snapshots, so stable local identity remains a Phase 2 gate.

Phase 2 may add normalization, identity resolution, validators, differ logic, SQLite writers, package writers, related configuration, tests, and generated normalized or release data. It must not publish a package while identity changes, removals, feature conflicts, missing references, or coverage gaps remain unreviewed.
