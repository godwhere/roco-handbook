# ADR-0009: Phase 6 physical-device-test waiver

- Status: accepted
- Date: 2026-09-09
- Scope: Phase 6 project closure and physical-device evidence

## Context

The V1 baseline treats missing physical Android or iOS offline, update, recovery, and personal-data-preservation evidence as a Phase 6 stopping condition. The repository has complete local, emulator, simulator, build, permission, license, Catalog, and hosted-CI evidence, but neither platform has completed the required physical-device sequence.

The user explicitly directed the project to skip physical-device validation, record that omission, close Phase 6, and begin Phase 7. The Chinese baseline remains immutable, so this decision records the authorized deviation without changing or weakening its original requirement.

## Decision

- Close Phase 6 for project sequencing under waiver `PHASE6-PHYSICAL-DEVICE-001`.
- Keep both platform device evidence statuses as `not_run`; a waiver is not a passing test result.
- Do not describe the candidate as physically accepted, signed, store-ready, uploaded, reviewed, or published.
- Keep the unsigned Android and no-codesign iOS artifacts as local candidates only.
- Retain physical-device validation as an explicit release risk that must be completed before any future store-readiness claim.
- Treat signing, archive export, store upload, publication, runtime networking, remote hosting, and Phase 7 protocol choices as separately authorized boundaries.

## Consequences

Phase 6 is complete for repository sequencing, so Phase 7 discovery may begin. The candidate remains unsuitable for store submission and carries unverified platform durability, offline behavior, update, recovery, and personal-data-preservation risk. Later physical-device testing may retire the waiver only when its evidence is recorded; it must not retroactively be reported as having passed on 2026-09-09.
