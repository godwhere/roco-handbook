# Roco World Offline Handbook

An independent, non-commercial offline reference application for iOS and Android. Development tools convert validated BWIKI snapshots into a SQLite Catalog; the released App reads only local data distributed in its installation package.

## Current project status

- Phases 0 through 5 were completed on 2026-09-09, with the Python and Flutter test suites passing.
- A local Git repository exists. Completed delivery checkpoints use GitHub Desktop for commits and pushes unless the active user instruction explicitly defers that step.
- The supplied technical baseline is preserved at [docs/technical-spec-v1.md](docs/technical-spec-v1.md).
- The Catalog and User V1 SQL files are the current normative schema sources. Catalog V1 currently contains 20 tables and two query views.
- Phase 1 imported an immutable local snapshot, safely parsed all seven required data modules, and generated a complete structure and reference report for 596 creatures, 442 handbook entries, 788 skills, 298 learnsets, and 242 evolution groups.
- The upstream rendered index verified all 442 display numbers and default handbook forms. Forty-eight ambiguous defaults use evidence-bound explicit overrides; `show_topics`, record order, and ID suffixes are not local default-selection rules.
- Phase 2 generated normalized Catalog data and release data version 1 from the validated snapshot. The package contains a verified 3,424,256-byte SQLite database with 596 creatures, 442 handbook entries, 788 skills, 298 Learnsets, and 242 evolution groups.
- The tracked release manifest records database SHA-256 `2c27ddc3cd36f543ea6319ea9878b4a3c8b8a9a89afad6bd6eaacfd9592ed8f2`. The identity registry locks 1,826 creature, handbook, and skill identities.
- The Flutter App now runs on iOS and Android with no runtime network data source. It validates and installs the bundled Catalog, opens it read-only, and provides paginated creature and skill browsing, exact form search, type filtering, whitelisted sorting, full form switching, skill-source separation, evolution evidence, and Catalog attribution.
- The App creates and validates an independent personal database from the normative User V1 schema. Creature and skill favorites, handbook-level collection marks, and device-local notes survive restart; missing Catalog objects retain their saved name and notes.
- Startup now serializes Catalog installation, validates a new immutable whole-database candidate before activation, keeps independent active and previous records, rolls back a failed post-activation open, and retains at most the current and previous validated Catalog files. A newer compatible local Catalog is not silently downgraded by an older bundled version.
- The fixed bottom navigation provides Creatures, Skills, My Library, and Settings. Settings explains local-storage and uninstall risk, shows the effective Catalog, recovery outcome, and personal schema versions, and provides an explicitly confirmed bundled-Catalog recovery action that does not modify `user.db`.
- Android first launch, personal-data persistence, legacy-pointer migration, and explicit bundled recovery passed in an emulator with airplane mode enabled and Wi-Fi disabled. iOS build, first launch, Catalog validation, personal-database creation, restart reuse, and legacy-pointer migration passed in an iPhone simulator. No physical-device, signing, upload, or store-release claim is made.
- Phase 6 is the next implementation boundary: release metadata, permissions and license audit, CI and release checks, and physical-device update acceptance before any separately authorized store submission.

## V1 boundary

V1 includes offline creature and skill lookup, favorites, collection marks, notes, and safe whole-Catalog replacement with App updates. It excludes runtime BWIKI access, an application server, independent patch downloads, accounts, cloud synchronization, and bulk game-image acquisition.

`catalog.db` and `user.db` remain physically separate: the Catalog is replaceable, while personal data changes only through an independent migration.

## Repository structure

- `docs/`: baseline specification, decisions, evidence, and implementation reports
- `config/`: source, identity, display, and reviewed-exception configuration
- `schemas/`: normative Catalog, User, and manifest structures
- `tools/`: project configuration for later import and build tools
- `tests/`: offline, repeatable structure and contract tests
- `app/`: Flutter iOS and Android client, bundled Catalog assets, and App tests
- `data/raw/`: ignored immutable response bodies plus tracked provenance locks
- `data/reports/`: tracked structure, reference, source-field, and sample-mapping reports
- `data/normalized/`: deterministic normalized build input with preserved source extras
- `data/release/`: immutable versioned Catalog database, manifest, attribution, and build report

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

## Phase 2 tools

Normalize the validated snapshot into the Catalog V1 contract:

```bash
PYTHONDONTWRITEBYTECODE=1 PYTHONPATH=tools python3 -m catalog_builder normalize \
  --snapshot data/raw/snapshot-19235f9b9b34dc4e \
  --rendered-index-response \
    data/raw/rendered-index-55e8fc070aec7c28/responses/pet_index.json \
  --display-overrides config/handbook_display_overrides.json \
  --type-aliases config/type_aliases.json \
  --data-version 1 \
  --built-at-utc 2026-09-09T08:11:51Z \
  --output \
    data/normalized/snapshot-19235f9b9b34dc4e/catalog-v1.json
```

The checked-in identity registry is already initialized. `initialize-identity` exists only for an explicit first registry lock and refuses to replace an initialized registry.

Build and verify a new immutable release version:

```bash
PYTHONDONTWRITEBYTECODE=1 PYTHONPATH=tools python3 -m catalog_builder build-release \
  --normalized \
    data/normalized/snapshot-19235f9b9b34dc4e/catalog-v1.json \
  --schema schemas/catalog_v1.sql \
  --manifest-schema schemas/manifests/bundled_catalog_v1.schema.json \
  --identity-registry config/identity_registry.json \
  --reviewed-exceptions config/reviewed_exceptions.json \
  --output data/release
```

The builder refuses to overwrite an existing data version. A later release must use a new positive data version and compare against the previous Catalog database.

## Flutter App

Run the current offline client checks:

```bash
cd app
flutter pub get
flutter analyze
flutter test
```

Launch on an available iOS or Android simulator with `flutter run`. The production client has no BWIKI or HTTP dependency; canonical source names and descriptions may retain their upstream language while all App-authored copy remains English.

Favorites and notes are stored only in the private `user.db` on the device. They are not included in the replaceable Catalog database and are not synchronized to an account or cloud service.

Catalog replacement runs only during startup or an explicit Settings recovery. The App does not download Catalog data. A candidate must pass manifest, hash, metadata, schema-object, integrity, foreign-key, and probe-query checks before its pointer is activated; failed updates retain the previous validated Catalog and personal database.

## Local verification

Run from the repository root:

```bash
PYTHONDONTWRITEBYTECODE=1 PYTHONPATH=tools python3 -m unittest discover -s tests -p 'test_*.py'
```

The default tests do not use the network, read personal credentials, or change system networking. Physical-device, signing, store, and App release verification are recorded separately in their owning phases.
