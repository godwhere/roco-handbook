# Phase 2 Catalog build evidence

- Date: 2026-09-09
- Input snapshot: `snapshot-19235f9b9b34dc4e`
- Rendered evidence: `rendered-index-55e8fc070aec7c28`
- Data version: 1
- Network access during normalization and build: none

## Artifacts

The normalized contract is stored at `data/normalized/snapshot-19235f9b9b34dc4e/catalog-v1.json`. The immutable release directory is `data/release/1/` and contains:

- `assets/catalog/catalog.db`
- `assets/catalog/bundled_catalog.json`
- `assets/catalog/ATTRIBUTION.txt`
- `build-report.json`

The database is 3,424,256 bytes and has SHA-256 `2c27ddc3cd36f543ea6319ea9878b4a3c8b8a9a89afad6bd6eaacfd9592ed8f2`. Both values match the release manifest and build report.

## Database verification

SQLite opened the generated file in read-only mode. `PRAGMA integrity_check` returned `ok`, and `PRAGMA foreign_key_check` returned no rows. The database contains 20 tables and two views. Principal row counts are:

| Contract | Rows |
| --- | ---: |
| Creatures | 596 |
| Handbook entries and display mappings | 442 each |
| Skills | 788 |
| Learnsets | 298 |
| Creature-to-Learnset mappings | 596 |
| Native skill sources | 4,212 |
| Bloodline skill sources | 5,346 |
| Skill-stone sources | 5,198 |
| Legendary skill sources | 6 |
| Evolution groups | 242 |
| Evolution members | 642 |
| Directed evolution edges | 400 |
| Entity source records | 2,366 |

The required sample query resolved `pet_000007` to `handbook_000004`, display number `004`, and feature skill `skill_000003`.

## Validation and review

- The identity audit passed with 1,826 mappings and no missing, reused, or removed identity.
- No previous Catalog exists, so the difference report is an explicit baseline with zero unreviewed removals.
- All normalized references closed, and no feature conflict remained.
- The reviewed Evolution duplicate-type exception covers exactly 31 mismatching records at Core revision 43006 and Evolution revision 42851. Its pair-set SHA-256 is `1456a9b7beee2c79268d301391f933e15b150d3df2a6780bf99892b43e22f07e`.
- Handbook source fields `areas`, `habitat`, `title`, and `topics` are outside the current SQLite contract. They are preserved in normalized `source_extra` and reported as a warning.
- Coverage remains false for topic rewards, skill-stone topics, and description-note definitions. The manifest reports these limitations explicitly.

## Automated evidence

The offline suite passed 56 tests. It includes failure cases for invalid default forms, unreviewed Evolution type differences, identity removal or fingerprint change, foreign-key constraints, manifest hash mismatch prevention, read-only access, and attempted reuse of an existing release version.

A clean temporary rebuild using the same snapshot, configuration, data version, and fixed build timestamp matched the tracked normalized JSON, SQLite database, manifest, and build report byte-for-byte.

Flutter analysis, simulator or device behavior, store signing, upload, and App release were not run because they are outside Phase 2.
