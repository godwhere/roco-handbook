# Phase 1 snapshot inspection

- Snapshot: `snapshot-19235f9b9b34dc4e`
- Status: `passed_with_warnings`
- Concrete creatures: 596
- Handbook entries: 442
- Skills: 788
- Learnsets: 298
- Evolution groups: 242
- Verified handbook display numbers: 442
- Resolved default handbook forms: 442

## Verified invariants

- Three distinct sample IDs: True.
- All three sample forms share handbook_000004: True.
- pet_000007 resolves skill_000003 in both Core and Learnset: True.
- Every required data module was parsed by the restricted table parser.
- Executable review modules were rejected by the data parser.

## Blocking issues

- None.

## Warnings

- `disabled_v1_sources_not_imported`: ['head_overrides', 'skill_stone_topics', 'topic_rewards']

The report preserves unknown or unresolved source semantics instead of fabricating values.
