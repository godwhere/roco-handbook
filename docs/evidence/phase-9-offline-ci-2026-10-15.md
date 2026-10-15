# Phase 9 offline CI repair evidence

- Evidence date: 2026-10-15 (Asia/Shanghai)
- Failed revision: `9425e9ce81c925ed289fbb82d82207dbfea24374`
- Failed workflow: [Offline validation run 29](https://github.com/godwhere/roco-handbook/actions/runs/38751322820)
- Decision: [ADR-0028](../decisions/ADR-0028-checkout-independent-nrc-tests.md)

## Observed failure

The user supplied `logs_105013596652.zip`. Its Catalog job ran 109 Python tests
and reported one error in
`test_current_snapshot_normalizes_deterministically`: the checkout did not contain
`data/raw/snapshot-dad7cd7d5ce73236/content/core.lua`. The error is an input-file
dependency, not a Git transport or native UI build failure. The same logs show
25 passing Swift XCTest cases and `BUILD SUCCEEDED` for the simulator App.
The Catalog release-check step was not reached after the Python failure.

`git ls-files data/raw` confirms only locks and storage documentation are tracked;
`data/raw/.gitignore` deliberately excludes source content and API response bodies.
The original two NRC tests passed with local raw data present. A `git archive
HEAD` copy in a temporary directory reproduced the missing-core error without
changing or deleting the original snapshot. Baseline logs are
`/tmp/roco-ci29-baseline-local.log` and `/tmp/roco-ci29-baseline-clean.log`.

## Repair

The NRC normalization regression now uses eight small owned, tracked data-only
Lua modules. It creates a temporary snapshot and fixed synthetic revision
metadata, calls the real parser/normalizer twice with reversed source-lock order,
and checks explicit default identity, shared Learnsets, native stage/level
conditions, blood/stone/legendary acquisition, evolution conditions, and validated
reference closure. Two negative tests require missing metadata or content to
raise `AdapterError`. The complete committed normalized Catalog still receives
its existing reference, count, reviewed-exception, and S4 identity checks.

Production code, the offline workflow, immutable data, and dependencies are
unchanged. No live BWIKI import or remote Catalog update was requested.

## Verification

| Check | Result |
| --- | --- |
| `PYTHONDONTWRITEBYTECODE=1 PYTHONPATH=tools python3 -m unittest tests.builder.test_nrc_pipeline` | Passed: 4 tests |
| Full offline Python suite in the working checkout | Interrupted during slow frozen-PNG reads; not counted as a pass |
| `PYTHONDONTWRITEBYTECODE=1 PYTHONPATH=tools python3 tools/release/check_catalog.py --release data/release/2` | Passed: release identity, hashes, schema, integrity, references |
| Full offline Python suite and release check in a tracked-files-plus-patch copy without raw content | Passed: 111 tests, zero skips, release check passed |
| Complete scoped diff review and `git diff --check` | Passed: all 13 changed paths match ADR-0028 |
| New hosted workflow after GitHub Desktop delivery | Pending |

Full local logs use `/tmp/roco-ci29-{nrc,python,catalog}.log`. Clean-copy checks
use `/tmp/roco-ci29-clean-{python,catalog}.log` with a receipt at
`/tmp/roco-ci29-clean-receipt.json`. Temporary files are validation artifacts and
are not included in the repository.

The working-copy run was interrupted inside the frozen-image byte/hash check;
no asset was altered. The clean copy was extracted from Git and overlaid with
the declared patch, verified to have no raw Lua content, and ran all 111 tests in
2.021 seconds on Python 3.13. Its first patched run caught one unescaped Chinese
test literal; that literal was corrected without relaxing the English-text
guard. The final clean run passed every test. Fixture Lua totals 2,352 bytes.
The immutable specification retains SHA-256
`343618b414b7b8d6262dd58f82010bfefb2f3fdb29711a9e86428e042dd81876`.
No production code, immutable data, personal database, credential, or build
product is included. The hosted Python 3.11 result remains a separate check.

## Limits and next boundary

This repair changes tests and documentation only. Native Swift, simulator build,
and UI tests are not rerun locally for this patch; the new hosted workflow must
be observed independently. Physical iOS behavior, signed upgrades, VoiceOver,
live source access, full raw-snapshot reproduction, remote Catalog publication,
and store delivery remain unrun. The baseline native job's success does not prove
any of those layers.

The README is unchanged because product capabilities, architecture, commands,
and release composition are unchanged. The fixture notes, ADR, this evidence,
and Phase 9 report document the revised default-test evidence boundary.
