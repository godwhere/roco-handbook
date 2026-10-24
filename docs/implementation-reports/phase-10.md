# Phase 10 implementation report

- Date: 2026-10-25
- Status: content integration and local acceptance complete; repository delivery through GitHub Desktop
- Decision: [ADR-0030](../decisions/ADR-0030-verified-content-refresh.md)
- Evidence: [content refresh](../evidence/phase-10-content-refresh-2026-10-25.md)

## Declared boundary

The user requested continued optimization and integration of the latest content, then authorized parallel helpers. This phase refreshes the accepted NRC data and required offline media, fixes mixed-revision importing, and preserves existing local identities after upstream source-key reallocation. ADR-0030 declares the allowed paths, commands, non-goals, and stopping conditions. No SQL, personal database, dependency, network configuration, server, signing, publication, or repository-visibility change is included.

## Changed files and behavior

- Live importer and import tests: freeze all heads, fetch exact revisions, recheck heads, reject failed/missing/changed identities, empty/non-Lua bodies, and empty source configurations; preserve immutable reuse timestamps.
- NRC normalizer/CLI, `nrc_identity.py`, focused builder tests and fixture notes: support later NRC image-alias reuse and the exact reviewed source-to-local ID mapping without changing raw provenance.
- `config/nrc_identity_review_v3.json`, `identity_registry_nrc_v2.json`, and the revision-bound exception: retain all 1,911 previous identities, add 15, preserve 617 source-key histories, and keep exact conflict review.
- New source lock, normalized Catalog 3, release 3, and active bundled Catalog: 633 forms, 468 handbook entries, 825 skills, 312 Learnsets, 279 evolution groups, 508 edges, zero removed entities, valid integrity and foreign keys.
- Tool importer/CLI/configuration/tests and active JSON: 552 activities, 124 outfits/248 variants, explicit new raw fields, verified immutable media reuse, and no inferred source semantics.
- Core image configuration/version 4 and Tool image configuration/version 2: all 1,867 previous image paths/bytes retained, 51 required additions; 1,611 core files plus 307 Tool files packaged offline.
- Native resource paths, preparation script, packaging tests, XCTest and UI tests: activate Catalog 3, core v4, Tool v2; verify legacy pointer upgrade/personal-data protection and a reachable newly added creature. No navigation or visual-layout redesign.
- Offline CI now checks release 3. Root/native READMEs, affected browser/visual features, the new refresh contract, raw-storage notes, this report, decision, and evidence describe the effective composition and validation boundary.

## Verification

Final commands, results, artifacts, interrupted cloud-backed reads, byte-identical local validation receipts, and unrun layers are recorded in the evidence file. Focused source/identity/builder tests passed (24 cases); all five Tool import/media cases passed. The new release checker passed with SQLite integrity `ok`, zero foreign-key violations, and no removals. The full Python suite passed 131 tests; all 25 Swift tests passed. The generic simulator build and four focused iOS 27 UI flows passed, including the new creature, all seven tools, preserved skill conditions, and personal data through restart/recovery. The new-creature screenshot was visually reviewed. Only stale version/count assertions required correction during final regression. The complete scoped diff and `git diff --check` were reviewed before GitHub Desktop delivery.

## Remaining boundary

Physical signed upgrade, iOS 15 execution, VoiceOver and device accessibility, low-storage/crash durability, formal signing/archive, live signed GitHub distribution, Tencent public HTTPS/native fallback, and store upload/review/publication remain unrun. The next content refresh must freeze a new source set and create a new identity review rather than reusing the Catalog 3 mapping against another revision.
