# Phase 10 content refresh evidence

- Local date: 2026-10-25 (Asia/Shanghai)
- Scope: ADR-0030; user-authorized latest-content import and parallel helpers
- Source system: `bwiki.nrc`; existing type contract remains the accepted `bwiki.rocom` source
- Source snapshot: `snapshot-a7dec7b598109dc2`
- Import completed: `2026-10-24T17:54:56.246815Z`
- Catalog schema/data version: 1 / 3; personal schema: 1, unchanged

## Live source evidence

The live importer queried every head before body acquisition, fetched every body by frozen revision, validated the response hashes and identity, and rechecked the full head set. The new source lock records `revision_set_verified: true`. Stable revisions over the import interval do not establish an atomic upstream release or complete game coverage.

| Source | Previous revision | Checked revision | Source revision time (UTC) |
| --- | ---: | ---: | --- |
| Core | 13095 | 19223 | 2026-10-24T04:34:11Z |
| Evolutions | 7267 | 19224 | 2026-10-24T04:34:12Z |
| Handbooks | 7268 | 18791 | 2026-10-19T12:28:47Z |
| History | 13096 | 18792 | 2026-10-19T12:28:48Z |
| Index | 12251 | 18793 | 2026-10-19T12:28:51Z |
| Learnsets | 13094 | 18761 | 2026-10-19T12:07:57Z |
| Overview | 12253 | 18794 | 2026-10-19T12:28:53Z |
| Skills | 7273 | 18764 | 2026-10-19T12:08:03Z |
| Activities | 10044 | 18960 | 2026-10-21T02:52:48Z |
| Fashions | 12224 | 18962 | 2026-10-21T02:52:52Z |

Terms revision 7078 and type-relationship revision 39538 were also queried through their existing importers. Both complete normalized contracts and source hashes were unchanged, so their active files and original timestamps were preserved. New raw source bodies remain local and ignored; only provenance locks and validated normalized/release artifacts are tracked.

## Content and compatibility review

| Contract | Catalog 2 / previous Tool contract | Current |
| --- | ---: | ---: |
| Concrete forms | 621 | 633 |
| Handbook entries | 466 | 468 |
| Skills and features | 824 | 825 |
| Learnsets | 311 | 312 |
| Evolution groups | 273 | 279 |
| Evolution edges | 502 | 508 |
| Activities | 547 | 552 |
| Outfits / gender previews | 110 / 220 | 124 / 248 |

All 1,911 prior local creature/handbook/skill identities remain present. The 617 upstream skill-key reallocations preserve all 824 old skill local IDs, numeric identities, exact names, and categories. The added feature is local `skill_000834`, game ID 200326. The registry now has 1,926 mappings; first-seen revisions and remap history remain explicit. All 311 old Learnsets and 15,561 old acquisition rows remain exact subsets, as do existing pet/Learnset assignments. All 273 prior evolution labels/member lists remain; 16 condition strings across ten chess groups clarify the opposing piece color without changed endpoints, levels, kinds, or ordinals. Ten source-provided creature form labels are the only old entity fingerprint updates. There are zero removed entities.

The unreviewed initial normalization correctly failed against Catalog 2's previously unsupported NRC image alias format. The adapter now uses explicit `extra_json.game_id` and retains the accepted legacy fallback solely for old `Head_` records. Invalid explicit IDs cannot fall back to inferred filename identity. The raw source-key output was kept separate from the reviewed normalized artifact; no failed candidate was built or activated.

The same exact 38 Evolution/Core duplicated-type conflicts remain, pair hash `a71114693e32e01b59a6fb7d42b83da4e57a85b23af71e2409bd2383e1408bcd`. A separate exception binds that complete set to revisions 19223/19224. No source types or learning conditions were silently overwritten.

Tool review found no removed IDs. Fourteen previously masked activity records change a null source ID to the explicit numeric identity; no known ID is reassigned. Seventeen source names are revealed/corrected. All 110 previous outfits retain names and source IDs. New explicit raw fields are preserved under the contract documented in the refresh feature; arbitrary unknown fields and executable Lua remain rejected.

## Artifacts

- `data/release/3/assets/catalog/catalog.db`: 4,710,400 bytes; SHA-256 `e5072f8a8776eb0d93cad20623c040381c17391803fd8a9d80fedfedea9889d4`.
- Normalized Catalog SHA-256: `7bf1bebbdddf6303a33c85cb276f55cf88697d1f989bb8f2578cbb7beeba1514`.
- Source-lock SHA-256: `5ce4a581e9b33b2dcbbdbbc7bb85100434101945d0b76aca69a815afb08de084`.
- Core image v4: 1,611 files, 1,690 references, 126,980,986 bytes; 607 original images, 195 shiny images, 774 skill/feature icons, 35 domain icons. All 1,594 previous bytes/paths retained, 17 additions, no changed existing PNG hash.
- Tool image v2: 307 files, 796 references, 13,961,806 bytes; 59 activity icons and 248 outfit previews. All 273 prior bytes/paths retained, 34 additions. Manifest SHA-256 `19fe148353153ad35bb73c4ff0273279f3ca00ec62048dbe3d7c959421f7f123`.
- Detailed scoped identity/edge audit: `data/reports/phase-10/identity-review.json`.
- Detailed Tool identity/media audit: `data/reports/phase-10/tool-review.json` and `tool-media-review.json`.

## Commands and observed checks

The [refresh contract](../features/catalog-content-refresh.md#reproduction-commands) records exact normalization/build parameters. All long output was redirected to `/tmp/roco-phase10-*.log`.

- Live import: passed, all eight required modules, exact frozen-revision/body/head checks.
- Focused live/NRC/identity regressions: 24 passed, `/tmp/roco-phase10-focused-final.log`.
- Tool parser/media suite: five passed, `/tmp/roco-phase10-tools-tests.log`; covers raw-field/null preservation, unknown fields, Lua rejection, immutable reuse, and tampering rejection.
- Release 3 build/check: passed with the existing explicit coverage warnings. SQLite integrity is `ok`, foreign keys have zero violations, and the difference report has zero removals. Logs: `/tmp/roco-phase10-build-release.log`, `/tmp/roco-phase10-check-catalog.log`.

The initial full Python run and first core-image reuse run blocked while reading cloud-backed historical PNG files. The owned processes were stopped; the first image staging directory alone was removed. A local validation mirror was created from the current Git commit with exact changed/new files overlaid and hashed. Reusing the same tracked baseline bytes completed image import with the original hash/dimension/source checks intact. No system networking or cloud configuration was changed.

Final local verification used Xcode 27.0 (`27A266a`), Swift 6.4, Python 3.13, and the iOS 27 simulator named `Roco Phase 10` (`53209D2A-B509-4FC9-B464-7DB15A446055`). The normative CI Python pin remains 3.11; no dependency upgrade was made.

| Command / check | Result | Local evidence |
| --- | --- | --- |
| `PYTHONDONTWRITEBYTECODE=1 PYTHONPATH=tools python3 -m unittest discover -s tests -p 'test_*.py'` | 131 passed | `/tmp/roco-phase10-python-final.log` |
| `swift test --package-path ios --scratch-path /tmp/roco-phase10-spm` | 25 passed | `/tmp/roco-phase10-swift-final.log` |
| `xcodebuild -project ios/RocoHandbook.xcodeproj -scheme RocoHandbook -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/roco-phase10-xcode CODE_SIGNING_ALLOWED=NO build` | Passed | `/tmp/roco-phase10-xcode-build.log` |
| Destination simulator `xcodebuild test`, parallel testing disabled | Four focused flows passed | `/tmp/roco-phase10-ui.log`, `/tmp/roco-phase10-ui.xcresult` |
| Source-equivalence overlay | Every changed code/data/media input matched SHA-256 before testing | `/tmp/roco-phase10-validation-receipt.json` |
| `git diff --check` | Passed | Final scoped review |

The UI cases were `testRefreshedCreatureIsReachableFromBundledCatalog`, `testAllDestinationsAndSevenToolRoutes`, `testCreatureDetailTabsSkillSearchAndEggGroupNavigation`, and `testFavoritesNotesLayoutAndRestorePreservePersonalData`. [The exported new-creature capture](phase-10/new-creature.png) was visually reviewed for actual artwork, identity, type icons, metrics, and navigation. The installer XCTest uses real Catalog 2 bytes and a legacy pointer, then installs Catalog 3 and restores while preserving saved local skill identity, favorites, notes, collection marks, layout, and personal database bytes. This is owned local test evidence, not a physical signed-upgrade claim.

The first complete regressions exposed stale Catalog 2 equality assertions and the old shiny count, plus the new image configuration's canonical upstream Chinese filenames needing the same narrow language exception as prior image configurations. These assertions were updated without weakening data validation. Final full suites passed afterward. Non-failing App Intents build notes remain. The four UI cases are focused coverage; the complete historical UI suite was not rerun.

## Not run

Physical-device installation or signed upgrade, iOS 15 execution, VoiceOver/device accessibility, low-storage and crash durability, formal signing/archive, hosted CI for this commit, live signed update publication/install, Tencent public hosting or native fallback, App Store upload/review/publication, and third-party content rights acceptance were not run. Simulator and owned-database tests do not establish these layers.
