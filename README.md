# Roco World Offline Handbook

An independent, non-commercial offline reference application for iOS and Android. Development tools convert validated BWIKI snapshots into a SQLite Catalog; the released App reads only local data distributed in its installation package.

## Current project status

- Phases 0 through 6 are complete. Phase 6 closed under an explicit physical-device-test waiver; those tests remain unrun and store publication remains a separate unmet gate.
- Phase 7 has an offline end-to-end complete-package path: immutable ZIP and canonical-payload builders, external Ed25519 signing, an App-bundled production public key, strict bounded ZIP validation, inner Catalog validation, version-specific attribution, monotonic replay state, and existing-installer activation and rollback. It is not connected to runtime discovery or transport; the App still has no production host, download UI, or network permission.
- A local Git repository exists. Completed delivery checkpoints use GitHub Desktop for commits and pushes unless the active user instruction explicitly defers that step.
- The supplied technical baseline is preserved at [docs/technical-spec-v1.md](docs/technical-spec-v1.md).
- The Catalog and User V1 SQL files are the current normative schema sources. Catalog V1 currently contains 20 tables and two query views.
- Phase 1 imported an immutable local snapshot, safely parsed all seven required data modules, and generated a complete structure and reference report for 596 creatures, 442 handbook entries, 788 skills, 298 learnsets, and 242 evolution groups.
- The upstream rendered index verified all 442 display numbers and default handbook forms. Forty-eight ambiguous defaults use evidence-bound explicit overrides; `show_topics`, record order, and ID suffixes are not local default-selection rules.
- Phase 2 generated normalized Catalog data and release data version 1 from the validated snapshot. The package contains a verified 3,424,256-byte SQLite database with 596 creatures, 442 handbook entries, 788 skills, 298 Learnsets, and 242 evolution groups.
- The tracked release manifest records database SHA-256 `2c27ddc3cd36f543ea6319ea9878b4a3c8b8a9a89afad6bd6eaacfd9592ed8f2`. The identity registry locks 1,826 creature, handbook, and skill identities.
- The Flutter App now runs on iOS and Android with no runtime network data source. It validates and installs the bundled Catalog, opens it read-only, and provides paginated creature and skill browsing, exact form search, type filtering, whitelisted sorting, full form switching, skill-source separation, evolution evidence, and Catalog attribution.
- The App creates and validates an independent personal database from the normative User V1 schema. Creature and skill favorites, handbook-level collection marks, and device-local notes survive restart; missing Catalog objects retain their saved name and notes.
- Startup now serializes Catalog installation, validates a new immutable whole-database candidate and its attribution before activation, keeps independent active and previous records, rolls back a failed post-activation open, and retains at most the current and previous validated Catalog and attribution files. A newer compatible local Catalog is not silently downgraded by an older bundled version.
- The fixed bottom navigation provides Creatures, Skills, My Library, and Settings. Settings explains local-storage and uninstall risk, shows the effective Catalog, recovery outcome, and personal schema versions, and provides an explicitly confirmed bundled-Catalog recovery action that does not modify `user.db`.
- The first candidate is App version 1.0.0, build 1. Settings exposes that version and Flutter's packaged open-source license registry.
- The offline release validator rejects transaction sidecars, placeholder metadata, false coverage, source-lock or hash divergence, unreviewed removals, schema failures, and probe failures. Read-only CI runs the Python and Flutter gates without BWIKI, signing, or store credentials.
- Android first launch, personal-data persistence, legacy-pointer migration, and explicit bundled recovery passed in an emulator with airplane mode enabled and Wi-Fi disabled. iOS build, first launch, Catalog validation, personal-database creation, restart reuse, and legacy-pointer migration passed in an iPhone simulator. No physical-device, signing, upload, or store-release claim is made.
- Local unsigned Android and no-codesign iOS release candidates have been built and audited. Physical Android and iOS offline/update validation was explicitly waived for Phase 6 sequencing, not passed; no store upload or publication is authorized.

## V1 boundary

V1 includes offline creature and skill lookup, favorites, collection marks, notes, and safe whole-Catalog replacement with App updates. It excludes runtime BWIKI access, an application server, independent patch downloads, accounts, cloud synchronization, and bulk game-image acquisition.

Phase 7 does not alter the shipped V1 boundary. Its production trust root and complete-package path are implemented and tested offline, but transport, runtime consent and progress UI, and device evidence remain absent. Logical patches remain later work.

`catalog.db` and `user.db` remain physically separate: the Catalog is replaceable, while personal data changes only through an independent migration.

## Repository structure

- `docs/`: baseline specification, decisions, evidence, and implementation reports
- `config/`: source, identity, display, and reviewed-exception configuration
- `schemas/`: normative Catalog, User, bundled-manifest, and signed remote-manifest structures
- `tools/`: project configuration for later import and build tools
- `tests/`: offline, repeatable structure and contract tests
- `app/`: Flutter iOS and Android client, bundled Catalog assets, and App tests
- `data/raw/`: ignored immutable response bodies plus tracked provenance locks
- `data/reports/`: tracked structure, reference, source-field, and sample-mapping reports
- `data/normalized/`: deterministic normalized build input with preserved source extras
- `data/release/`: immutable versioned Catalog database, manifest, attribution, and build report
- `licenses/`: Catalog attribution boundary and resolved runtime dependency notices
- `release/`: versioned release-candidate checks, metadata, notes, and known limitations; generated App binaries remain untracked
- `.github/workflows/`: credential-free offline project and Flutter validation

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

## Phase 7 offline update packaging

Build the exact complete-Catalog ZIP from an already validated immutable release:

```bash
PYTHONDONTWRITEBYTECODE=1 PYTHONPATH=tools python3 -m catalog_builder \
  build-complete-update \
  --release data/release/1 \
  --output /path/outside-the-repository/catalog-v1.zip
```

The command reruns the complete release check, includes only the manifest, database, and attribution paths accepted by the App, verifies its own output, prints the archive length and SHA-256, and refuses to overwrite an existing file. It does not sign, publish, upload, or place an update artifact in the repository.

After an HTTPS host and immutable package URL are approved, build the canonical unsigned payload:

```bash
PYTHONDONTWRITEBYTECODE=1 PYTHONPATH=tools python3 -m catalog_builder \
  build-update-payload \
  --release /path/to/release/N \
  --archive /path/outside-the-repository/catalog-vN.zip \
  --package-url https://approved.example/full/catalog-vN.zip \
  --release-sequence N \
  --minimum-app-version 1.0.0 \
  --published-at-utc 2026-09-09T23:45:00Z \
  --output /path/outside-the-repository/catalog-payload-vN.json
```

Sign only a reviewed payload, using a private key outside the repository:

```bash
cd app
dart run tool/catalog_signing.dart sign-payload \
  --private-key /path/outside-the-repository/catalog-signing.private.json \
  --payload /path/outside-the-repository/catalog-payload-vN.json \
  --output /path/outside-the-repository/catalog-manifest-vN.json
```

The signing tool canonicalizes and validates the payload, checks the key range and private/public pair, and runs its output through the production verifier. The current production key already exists under the explicitly authorized Desktop custody path and must not be regenerated casually. The custody evidence records that iCloud Desktop synchronization is enabled; real release signing requires an explicit decision to accept that model or replace the key in an approved non-synchronized location. `generate-key` is reserved for an explicit future rotation ceremony.

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

## Release candidate validation

Validate the immutable Catalog release from the repository root:

```bash
PYTHONDONTWRITEBYTECODE=1 PYTHONPATH=tools python3 tools/release/check_catalog.py \
  --release data/release/1
```

The tracked candidate record, release notes, and known limitations are in `release/1.0.0+1/`. The checked-in workflow runs this gate plus the complete Python and Flutter suites without contacting BWIKI or any application store.

Local Android and iOS candidate build commands are:

```bash
cd app
flutter build appbundle --release
flutter build ios --release --no-codesign
```

These commands intentionally do not produce a signed, exported, or store-ready submission. Signing and publication require separate credentials, platform checks, and explicit authorization.

## Local verification

Run from the repository root:

```bash
PYTHONDONTWRITEBYTECODE=1 PYTHONPATH=tools python3 -m unittest discover -s tests -p 'test_*.py'
```

The default tests do not use the network, read personal credentials, or change system networking. Physical-device, signing, store, and App release verification are recorded separately in their owning phases.
