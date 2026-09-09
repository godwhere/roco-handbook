# Roco World Offline Handbook

An independent, non-commercial offline reference application for iOS and Android. Development tools convert validated BWIKI snapshots into a SQLite Catalog; the released App reads only local data distributed in its installation package.

## Current project status

- Phases 0 and 1 were completed on 2026-09-09, with the offline test suite passing.
- A local Git repository exists. Phase completion is committed and pushed through GitHub Desktop.
- The supplied technical baseline is preserved at [docs/technical-spec-v1.md](docs/technical-spec-v1.md).
- The Catalog and User V1 SQL files are the current normative schema sources.
- Phase 1 imported an immutable local snapshot, safely parsed all seven required data modules, and generated a complete structure and reference report for 596 creatures, 442 handbook entries, 788 skills, 298 learnsets, and 242 evolution groups.
- The upstream rendered index verified all 442 display numbers and default handbook forms. Forty-eight ambiguous defaults use evidence-bound explicit overrides; `show_topics`, record order, and ID suffixes are not local default-selection rules.
- A complete Catalog database has not been generated, and the Flutter App has not been created. Neither outcome is claimed as complete.
- The Phase 2 entry point is normalization, identity auditing, full validation, and generation of a versioned SQLite Catalog package.

## V1 boundary

V1 includes offline creature and skill lookup, favorites, collection marks, notes, and safe whole-Catalog replacement with App updates. It excludes runtime BWIKI access, an application server, independent patch downloads, accounts, cloud synchronization, and bulk game-image acquisition.

`catalog.db` and `user.db` remain physically separate: the Catalog is replaceable, while personal data changes only through an independent migration.

## Repository structure

- `docs/`: baseline specification, decisions, evidence, and implementation reports
- `config/`: source, identity, display, and reviewed-exception configuration
- `schemas/`: normative Catalog, User, and manifest structures
- `tools/`: project configuration for later import and build tools
- `tests/`: offline, repeatable structure and contract tests
- `data/raw/`: ignored immutable response bodies plus tracked provenance locks
- `data/reports/`: tracked structure, reference, source-field, and sample-mapping reports

## Phase 1 tools

Import previously downloaded MediaWiki revision responses:

```bash
PYTHONDONTWRITEBYTECODE=1 PYTHONPATH=tools python3 -m bwiki_import import-local \
  --input-dir /path/to/responses \
  --output data/raw \
  --config config/bwiki_sources.json
```

Inspect a frozen source snapshot together with a frozen rendered-index response:

```bash
PYTHONDONTWRITEBYTECODE=1 PYTHONPATH=tools python3 -m catalog_builder inspect \
  --snapshot data/raw/snapshot-19235f9b9b34dc4e \
  --output data/reports \
  --display-overrides config/handbook_display_overrides.json \
  --rendered-index-response \
    data/raw/rendered-index-55e8fc070aec7c28/responses/pet_index.json
```

Raw response and Lua bodies are not committed. Their tracked locks and generated reports preserve revision IDs and hashes; recreating a report requires the matching original responses.

## Local verification

Run from the repository root:

```bash
PYTHONDONTWRITEBYTECODE=1 PYTHONPATH=tools python3 -m unittest discover -s tests -p 'test_*.py'
```

The default tests do not use the network, read personal credentials, or change system networking. Flutter, complete-data, device, signing, store, and release verification are recorded separately in their owning phases.
