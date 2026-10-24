# ADR-0030: Verified content refresh

- Status: Accepted
- Date: 2026-10-25
- Phase: 10

## Context and authorization

The user requested continued optimization and integration of the latest content. The active native client still bundles Catalog data version 2 from the NRC snapshot frozen on 2026-09-14. The existing live importer validates individual responses but does not freeze the complete revision set before fetching content or recheck it afterward, as required by section 6.2 of the preserved technical specification.

## Decision and allowed paths

This phase reuses the accepted NRC source system and data-only pipeline. Query and validate all configured module heads first, fetch each body by its frozen revision, and recheck every module head before writing or reusing a snapshot. A changed, missing, invalid, or failed source blocks the refresh. Reusing a frozen snapshot does not change its original import time.

Allowed changes are the live importer and focused import/builder tests under `tools/bwiki_import/`, `tools/catalog_builder/`, and `tests/`; necessary source, identity, and reviewed-exception contracts under `config/`; new immutable source locks, normalized inputs, audit reports, and Catalog releases under `data/`; the active shared Catalog resources and, only if required and authorized, a new immutable offline resource version under `app/assets/`; native resource resolution/packaging under `ios/`; the active offline workflow when its Catalog path changes; the root and native READMEs; affected feature/configuration/fixture documentation; this decision; the Phase 10 report; and Phase 10 evidence.

Review the new snapshot against Catalog 2 before activation. Preserve existing NRC local IDs and first-seen provenance; additions and fingerprint changes require specific evidence, and removals or unresolved references block activation. Create a new Catalog data version only for a validated content change. Existing releases and frozen image versions remain immutable. Ordinary browsing remains entirely offline.

SQL schemas, personal databases, source-system migration, unrelated UI redesign, dependency upgrades, bulk image acquisition, signing keys, network configuration, Tencent hosting, native mirror fallback, GitHub Releases publication, App Store operations, and repository visibility changes are outside this phase.

## Acceptance and stopping conditions

Run focused offline regression tests for frozen-revision fetching, changed/invalid heads, unexpected body revisions, failed imports, and immutable reuse. Run the full Python suite with `PYTHONDONTWRITEBYTECODE=1 PYTHONPATH=tools python3 -m unittest discover -s tests -p 'test_*.py'`, the release checker for any new active Catalog, and Swift tests with `swift test --package-path ios --scratch-path /tmp/roco-handbook-spm`. Verify exact source/identity/reference closure and packaged visual paths before switching the active bundle. Build the native simulator target when bundled content or native packaging changes; run focused UI coverage for any native behavior change.

If live access fails, record the failure without treating cached data as current. If there is no validated content change, keep Catalog 2 active and report the checked revisions. Stop activation at unreviewed removals, identity conflicts, incomplete visual coverage, or unsupported source contracts. Do not bypass a source or release gate to manufacture a new version.

Review the complete scoped diff, run `git diff --check`, and commit and push through GitHub Desktop. Local, upstream, simulator, physical-device, signing, online-update, and store evidence remain distinct. The Chinese baseline specification remains unchanged.

## Observed source-key reallocation and accepted review

The verified snapshot contains all 824 previous skill game identities with unchanged exact names and normalized categories, but 617 source keys changed. The snapshot-specific `nrc_identity_review_v3.json` explicitly maps these keys, assigns the added feature an unused local ID, preserves all 311 existing ordered Learnset signatures, and retains all 273 existing evolution groups by their exact labels and ordered members. Typed references are translated once; raw values and actual source record keys remain intact. The review is bound to the previous database SHA-256 and the complete current snapshot. A mapping collision or another context fails closed.

The new NRC registry preserves every previous local ID and first-seen revision and records the changed source-key histories. Ten existing creature form labels are reviewed fingerprint changes. Sixteen chess-condition texts across ten evolution groups now specify the opposing piece color; endpoints, levels, ordinals, and direction do not change. No entity is removed. The same 38 duplicated-type mismatch pairs are reviewed against the new exact Core/Evolution revisions.

Only required source art is extended: immutable core image v4 adds 17 files and Tool image v2 adds 34 files, reusing all 1,867 previous file bytes. Activity/fashion parsers explicitly preserve the observed new out-of-schema fields in `source_record`; native DTO semantics and tool routes are unchanged. New dependencies and lockfile changes are unnecessary. The [refresh contract](../features/catalog-content-refresh.md) records the exact source, configuration, fixture, and reproduction rules.
