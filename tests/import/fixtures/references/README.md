# Reference supplement fixtures

These small, owned offline fixtures exercise the accepted data grammar and identity boundaries. They are synthetic parser cases, not game data or release records. `items.lua` includes a shared item with conditional variants, empty acquisition lists, null/unknown values and explicit related titles. `trial.lua` includes two distinct encounter IDs and an explicit regional-form Wiki target in one chapter.

Tests build gzip/JSON callback envelopes in memory and use an owned MediaWiki response transport. No fixture executes Lua/JavaScript, contacts BWIKI, reads accounts or changes personal data. Packaged production-data tests separately verify the real immutable Phase 16 counts and reference closure.
