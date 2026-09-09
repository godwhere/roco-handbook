# Roco World Offline Handbook: Agent Collaboration Guide

## Core principles

Understand the real data path before changing it. The goal is the smallest complete, readable, and verifiable implementation, not merely the fewest lines.

Choose solutions in this order and stop expanding once one is sufficient:

1. Confirm whether the requirement is already satisfied or needs no new implementation.
2. Reuse an existing schema, domain contract, adapter pattern, test fixture, or adjacent module.
3. Prefer Python, Dart, Flutter, SQLite, and platform capabilities already accepted by the baseline architecture.
4. Make a localized change inside the current phase and ownership boundary.
5. Add a new abstraction or dependency only when the preceding options cannot deliver the required behavior.

Minimal scope must not remove source validation, identity stability, reference closure, personal-data protection, recovery behavior, accessibility, explicit user requirements, or tests that can prove the behavior.

### English-only project language

- All project-authored code, identifiers, comments, documentation, reports, configuration descriptions, test names, CLI messages, UI copy, and commit messages must be written in English.
- New explanatory prose in the repository must not be written in Chinese.
- Canonical upstream game data, such as creature names and descriptions, may retain its source language. Fixtures may contain that data only when the language itself is part of the parsing or mapping case.
- `docs/technical-spec-v1.md` is the sole governance exception: it preserves the user-supplied Chinese baseline specification byte-for-byte for provenance and must not be translated in place.
- User communication may use the user's language; this repository-language rule applies to project artifacts.

## Before modifying

- Read the relevant sections of `docs/technical-spec-v1.md`, `README.md`, mapped documentation, implementation, and tests.
- Trace the actual flow from source response through validation, snapshot, parser, adapter, normalized contract, database, repository, state, and UI before changing a cross-layer behavior.
- Search for every caller, stable identifier, schema field, migration impact, and adjacent test before changing a public contract.
- Inspect `git status` and the relevant diff first. Uncommitted work belongs to the user; never clean, revert, overwrite, or broadly reformat unrelated files.
- Declare the current phase, allowed paths, explicit non-goals, acceptance commands, and stopping conditions before implementation.
- For a complex but clear task, deliver the smallest risk-controlled version. Ask only when a missing choice would materially change the result or authorization boundary.

## Project facts and boundaries

- This is an independent, non-commercial Flutter application for iOS and Android.
- The development pipeline reads explicitly allowed BWIKI MediaWiki modules, freezes immutable source revisions, safely parses data-only Lua tables, normalizes records, validates identities and references, and builds SQLite artifacts.
- The installed App is offline-first. It must not request BWIKI, execute Lua, require an account, or depend on a first-launch download.
- `schemas/catalog_v1.sql` is the sole V1 Catalog schema source. The App opens the installed Catalog read-only and must not auto-create or migrate it.
- `schemas/user_v1.sql` is the sole V1 personal-data schema source. `user.db` is independently migrated and must never be overwritten, deleted, or rebuilt as part of Catalog install or recovery.
- `handbook_id`, `pet_id`, and upstream numeric IDs have different meanings. Do not infer official numbering, default forms, evolution direction, or identity from suffixes, names, or list order.
- Core and Learnset feature references must remain independently traceable. Conflicts require a specific review result and must not be silently overwritten.
- Shared Learnsets and every native, bloodline, and skill-stone acquisition condition must be preserved.
- V1 distributes complete Catalog databases with App releases. Runtime full downloads, incremental patches, servers, accounts, cloud synchronization, and bulk image acquisition are outside scope.
- Do not change system proxy, DNS, TUN, routes, certificates, shell networking configuration, or Shadowrocket.

## Implementation constraints

- Work in one declared phase at a time and modify only that phase's allowlisted paths.
- Reuse existing models and contracts. Avoid single-use abstractions, speculative configuration, unused extension points, parallel sources of truth, and unrelated repository-wide refactors.
- Network access belongs only in the import client and only in an explicitly authorized import task. Parser, normalizer, validator, writer, repository, and ordinary tests must run offline.
- Never execute downloaded Lua, call its `require`, or use whole-file regular-expression replacement as a parser. Unsupported executable syntax must fail with a source location.
- Preserve source revisions, hashes, upstream IDs, null values, unknown fields, raw conditional values, and review-required conflicts.
- A failed API response, empty module, parse failure, or incomplete snapshot must never be converted into an empty successful release or bulk deletion.
- Builders write a new versioned output and must not overwrite an existing release with the same version.
- Installer cleanup is restricted to invocation-owned staging files and validated Catalog versions in its private allowlisted directory. It must never recursively delete the application support directory.
- UI consumes domain DTOs through repositories and controllers. It must not read raw API fields, open databases directly, or decide source semantics.
- Do not add dependencies or upgrade unrelated versions without recording the need, lockfile impact, and focused verification.

## Validation

- Every non-trivial behavior or contract change requires the smallest regression test that would fail under the incorrect implementation.
- The default Phase 0 check is:

  ```sh
  PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s tests -p 'test_*.py'
  ```

- Schema changes must execute both normative SQL files in a fresh database and verify exact objects, `integrity_check`, `foreign_key_check`, constraints, and schema versions.
- Parser and adapter tests use owned offline fixtures. Tests must cover unsupported syntax, unknown fields, empty input, identity conflicts, shared Learnsets, and the documented three-form creature case when those modules exist.
- Flutter behavior changes require focused Dart or Widget tests. Database, file lifecycle, accessibility, platform, and update behavior require their corresponding integration or device checks.
- Automated local tests do not prove live BWIKI access, complete source coverage, iOS or Android device behavior, store signing, upload, or release acceptance. Report every unrun layer explicitly.
- Before phase completion, run `git diff --check`, review the complete phase diff, and confirm that no credentials, cookies, proxy data, personal databases, fake release data, or unrelated files are included.

## Documentation and delivery

- `README.md` describes only the current effective project state, architecture, supported capabilities, and user commands. Do not turn it into a chronological design or change log.
- Each completed phase must update `docs/implementation-reports/phase-<n>.md` with changed files, commands, passed/failed/not-run checks, artifacts, remaining risks, and the next allowed boundary.

The following changes require the mapped English Markdown updates in the same delivery:

| Change type | Required documentation |
| --- | --- |
| Product scope, supported features, local commands, top-level architecture, or current release composition | `README.md` |
| Architecture, source contract, IDs, schema, lifecycle, or phase acceptance criteria | `docs/technical-spec-v1.md` through a new English decision record; preserve the Chinese baseline file unchanged |
| Observed tool, source, device, network, or release evidence | `docs/evidence/` |
| Schema columns, constraints, views, or migrations | The affected schema documentation, decision record, repository contract, and migration evidence |
| Upstream field mapping, parser grammar, adapter behavior, identity mapping, or reviewed exception | The corresponding config contract, fixture notes, and phase report |
| Catalog packaging, install, pointer switch, rollback, or cleanup behavior | The installer decision/evidence document and current README when user-visible |
| UI navigation, search, accessibility, theme, or visible English copy | The feature documentation and README when capabilities or entry points change |
| Build, signing, permissions, validation commands, or release criteria | The corresponding evidence/report and README when the user-facing command changes |

- If a change matches multiple rows, update every mapped document. If no documentation change is needed, state the reason in the final handoff.
- Phase completion requires a scoped English commit made through GitHub Desktop, followed by a push to the configured remote through GitHub Desktop.
- If the remote does not yet exist, create it as a private GitHub repository unless the user explicitly requests public visibility.
- Never force push, rewrite shared history, publish an App, upload to a store, or change repository visibility unless explicitly authorized.
- The final handoff states only what changed, where, how it was verified, what was not run, and any concrete next boundary.
