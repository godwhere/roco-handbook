# Known limitations: native 1.2.0 (build 3)

- This is a source/resource candidate, not a signed distributable. No binary
  digest is invented from a source inventory or an earlier Flutter artifact.
- Physical iPhone/iPad offline launch, recovery, persistence, crash/low-storage
  durability, minimum iOS 15 runtime, VoiceOver and device Dynamic Type acceptance
  remain open. Host tests and simulator observations cannot close these gates.
- Signed upgrade from the preceding Flutter app, including real personal records,
  Catalog pointers, rollback/recovery and newer Catalog preservation, is unrun.
  Matching identifiers, SQL and paths establish intended compatibility only.
- Signing team/provisioning, Release archive/export, TestFlight, privacy/store
  metadata and artwork/font/data rights review, upload, review and publication
  remain unverified. The historical Phase 6 waiver is not inherited.
- Catalog 2 still declares `description_note_definitions`, `skill_stone_topics`,
  and `topic_rewards` coverage false. Data is a frozen source snapshot, not a
  promise of complete or current upstream game content.
- The signed Catalog 2 remote update package has not been published. Live update
  transport and full raw-source reproduction were not exercised in this review.
  There are no incremental patches, accounts, cloud sync or cross-device backup.
- Personal data is local; uninstalling may remove it. Existing tests and prior
  simulator preservation evidence do not guarantee recovery after uninstall.
- CI run 30 proves the exact CI commit only; later documentation-only differences
  are disclosed. Local UI reports are historical, with their original scopes and
  partial reruns preserved. No macOS, Android or Mac Catalyst release is claimed.

Before store submission, record the actual device/OS/build and upgrade source,
commands, logs, personal-record comparisons, signed artifact digest, signing and
export result, and store acceptance receipts. Close gates individually from
observed evidence; never turn a waiver or a compile result into a device pass.
