# Roco World Offline Handbook

An independent, non-commercial offline reference application for iOS and Android. Development tools convert validated BWIKI snapshots into a SQLite Catalog; the released App reads only local data distributed in its installation package.

## Current project status

- Phase 0 was completed on 2026-09-09, with the offline baseline test suite passing.
- A local Git repository exists. Phase completion is committed and pushed through GitHub Desktop.
- The supplied technical baseline is preserved at [docs/technical-spec-v1.md](docs/technical-spec-v1.md).
- The Catalog and User V1 SQL files are the current normative schema sources.
- Real API JSON has not been imported, a complete Catalog database has not been generated, and the Flutter App has not been created. None of those outcomes are claimed as complete.
- The Phase 1 entry point is importing existing API JSON snapshots, safely parsing them, and generating structure and reference reports.

## V1 boundary

V1 includes offline creature and skill lookup, favorites, collection marks, notes, and safe whole-Catalog replacement with App updates. It excludes runtime BWIKI access, an application server, independent patch downloads, accounts, cloud synchronization, and bulk game-image acquisition.

`catalog.db` and `user.db` remain physically separate: the Catalog is replaceable, while personal data changes only through an independent migration.

## Repository structure

- `docs/`: baseline specification, decisions, evidence, and implementation reports
- `config/`: source, identity, display, and reviewed-exception configuration
- `schemas/`: normative Catalog, User, and manifest structures
- `tools/`: project configuration for later import and build tools
- `tests/`: offline, repeatable structure and contract tests

## Local verification

Run from the repository root:

```bash
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s tests -p 'test_*.py'
```

The default tests do not use the network, read personal credentials, or change system networking. Flutter, complete-data, device, signing, store, and release verification are recorded separately in their owning phases.
