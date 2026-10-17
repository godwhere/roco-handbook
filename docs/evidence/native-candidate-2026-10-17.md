# Native source candidate review, 2026-10-17

## Boundary and baseline

This Phase 9 release-metadata follow-up changes only `release/1.2.0+3/`,
`tools/release/check_native_candidate.py`, its focused Python test, the root
README, release-readiness feature document, ADR-0029, this evidence and the
Phase 9 report. Runtime code, immutable data/assets, SQL, dependencies, workflow,
signing, upstream imports and the historical candidate are unchanged. Stop on
unexplained version/resource drift or any need to mutate immutable inputs.

Reviewed source: `bfe145df60b2cf4963ab9b4a1ca22013525a3966`.
GitHub API run/jobs responses were read through the GitHub connector; selected
fields are preserved in `release/1.2.0+3/ci-evidence.json`. Run 38754548059,
number 30, attempt 1 completed successfully on October 15 at
`d29da2f41b7285f5c3795405d2578512f5309e46`. Jobs 116489405817 and
116489406343 and their relevant validation steps succeeded. The workflow
commands establish the test/build scope; job-step success is not device proof.
`git diff d29da2f HEAD --stat` before this patch showed only two Markdown files:
the Phase 9 report and offline CI evidence. No native implementation drift from
that CI baseline was found. CI has not evaluated this new candidate patch yet.

## Observed local validation

- Immutable Catalog 2 validator: passed; report saved with candidate.
  SQLite integrity `ok`, zero foreign-key violations, eight source revisions.
- Native candidate verifier: passed. All 1,882 active resource files match their
  exact lengths and SHA-256 values; no missing, added or linked resource is
  accepted. Bundled/release Catalog and normative/packaged personal SQL match.
- Default offline Python suite: 114 tests passed. New regressions reject stale
  App identity and simulated resource hash drift, and verify the full candidate.
- The first full test attempt had a test-package import collision; corrected
  without relaxing assertions before the passing run.
- `git diff --check`: passed after documentation completion.

Commands are in the candidate release notes. No `swift` or `xcodebuild` is
available in this Linux review environment. Native tests, build and XCUITest
were not rerun here. Historical local UI and simulator-upgrade observations
remain linked at their original scope. No physical device, signed upgrade,
signing/export, live upstream/update, store upload or publication was performed.

The checkout included an untracked temporary file under the historical Catalog 1
folder; it was neither included nor used as release evidence. The historical
candidate and all tracked immutable inputs remain unchanged.
