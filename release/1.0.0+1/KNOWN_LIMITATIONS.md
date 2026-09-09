# Known limitations for 1.0.0 (build 1)

- V1 packages no bulk game imagery. Creature and skill data are presented as text and native interface elements.
- Topic rewards, skill-stone topic metadata, and description-note definitions are outside the validated V1 coverage. Their manifest flags are `false`, and the App does not claim those features.
- The App has no runtime Catalog download, incremental patching, account, cloud synchronization, cross-device personal-data transfer, or application server.
- Personal data stays only in the App's private device storage and may be removed by uninstalling the App.
- Generated Android and iOS candidates are intentionally unsigned or not code-signed. Signing identities, credentials, store archives, and upload automation are not stored in this repository.
- Automated host tests, Android emulator evidence, and iOS simulator evidence do not prove physical flash durability, store-managed upgrades, or platform review acceptance.
- Physical Android and iOS installation, offline launch, update, recovery, and personal-data preservation were explicitly waived for Phase 6 closure and remain unrun. Waiver `PHASE6-PHYSICAL-DEVICE-001` does not establish device compatibility or store readiness.
- The data attribution review is not legal advice and does not establish rights to game artwork, trademarks, or unrelated third-party material.
