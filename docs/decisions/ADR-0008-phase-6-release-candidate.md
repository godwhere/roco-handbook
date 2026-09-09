# ADR-0008: Phase 6 release candidate and publication boundary

- Status: accepted
- Date: 2026-09-09
- Scope: V1 release metadata, offline validation, candidate builds, audit records, and publication authority

## Context

Phases 1 through 5 produced a traceable Catalog, an offline Flutter client, an independent personal database, and a rollback-safe Catalog installer. A release candidate still needs one App version, automated checks that reject incomplete or substituted data, permission and license evidence, platform build artifacts, and an explicit boundary between a locally validated candidate and a store-ready release.

The repository must not contain signing identities, credentials, personal data, or hidden network-based release steps. Physical-device and store-managed update behavior also cannot be inferred from simulator, emulator, or host tests.

## Decision

- Lock the first candidate at App version `1.0.0`, build number `1`, Catalog schema version `1`, Catalog data version `1`, and User schema version `1`.
- Keep `app/pubspec.yaml` as the platform build version source and mirror it in a small compile-time App constant for visible Settings copy. A repository test rejects divergence.
- Validate the immutable Catalog with `tools/release/check_catalog.py`. The command runs offline, returns nonzero on a blocking failure, and rejects SQLite sidecars, placeholder metadata, false required coverage, unreviewed removals, source-lock divergence, hash divergence, schema failure, and probe failure.
- Run default CI without BWIKI, user credentials, signing material, or store access. Pin third-party actions by full commit SHA and grant only read access to repository contents.
- Keep release signing outside the repository. Android release configuration does not fall back to the debug key. iOS candidate construction uses `--no-codesign`. A local unsigned artifact is not store-submittable.
- Audit the release manifests rather than debug tooling manifests. The Android main/release manifest requests no Internet or sensitive permission. The iOS App declares no protected-resource usage-description keys.
- Show the locked App version and Flutter's packaged open-source license registry in Settings. Keep BWIKI data attribution, transformation notice, software licenses, known limitations, and release notes as tracked English release materials.
- Record exact local artifact hashes and inspection results in the versioned candidate manifest. Generated binaries remain local build outputs and are not committed.
- Treat physical iOS and Android installation, offline launch, update, recovery, and personal-data preservation as independent manual gates. Missing either platform's key device evidence prevents a final publication-ready claim.
- Treat signing, archive creation, store upload, review, release, and repository-visibility changes as separate authorized actions. Phase 6 preparation does not grant them.

## Consequences

The repository can reproduce its offline test and Catalog validation gates and can identify the exact local candidate artifacts that were inspected. It cannot be described as signed, store-ready, or physically accepted until the corresponding external gates are performed and recorded.

The candidate is allowed to remain explicitly blocked at a manual gate without weakening validation, inserting sample metadata, enabling debug signing, or silently converting unrun evidence into a pass.
