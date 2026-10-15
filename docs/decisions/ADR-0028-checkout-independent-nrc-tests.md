# ADR-0028: Checkout-independent NRC normalization tests

- Status: Accepted
- Date: 2026-10-15
- Phase: 9 validation repair

## Context

Offline validation run 29 for `9425e9c` passed Swift tests and the native iOS
build, but the Python suite failed because the NRC determinism test read ignored
`data/raw/snapshot-dad7cd7d5ce73236/content/core.lua`. Only the source lock is
tracked. Local presence of raw data concealed this checkout dependency.

## Declared boundary

Allowed changes are `tests/builder/test_nrc_pipeline.py`, the owned fixture files
under `tests/builder/fixtures/nrc/`, this decision,
`docs/implementation-reports/phase-9.md`, and
`docs/evidence/phase-9-offline-ci-2026-10-15.md`. The workflow, default commands,
native client, production normalizer, imports, source locks, normalized data,
identities, schemas, immutable releases, dependencies, and personal data remain
outside this repair.

Acceptance uses the focused NRC tests, the complete offline Python suite,
release 2 validation, the same checks in a copy containing only tracked files
plus this declared patch, and `git diff --check`. Stop on a required production
contract change, immutable-data drift, or a need for upstream access. Delivery
uses GitHub Desktop for the scoped English commit and push; observe the new
hosted workflow separately before claiming hosted success.

## Decision and limits

The default suite must exercise the real NRC parser and normalizer using owned,
tracked, data-only fixtures. It must not skip the regression, download upstream
data, commit the ignored full snapshot, or turn missing input into success.
Missing required modules and content remain explicit negative cases.

Retain validation of the complete committed normalized Catalog, its counts,
reference closure, reviewed exceptions, and S4 identity. Deterministic fixture
normalization and complete-Catalog validation are separate evidence; neither
claims byte-for-byte reproduction from the ignored full upstream snapshot.
Maintainer full-snapshot reproduction remains a distinct local check requiring
the original frozen input. This decision clarifies default CI evidence only;
source validation and release acceptance requirements are unchanged.
