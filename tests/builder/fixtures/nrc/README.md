# Owned NRC normalization fixture

These eight small data-only Lua modules are synthetic offline test inputs. They
are not a BWIKI snapshot or release data. The S4 sample name, NRC field names,
Chinese type aliases, and skill categories exercise the accepted source grammar;
the alternate form, stats, images, skills, conditions, and evolution are invented.

`NrcNormalizationTests` copies these files into an invocation-owned temporary
snapshot and creates fixed test revision metadata with hashes of the exact bytes.
The reserved `wiki.example.test` endpoint is metadata only. No network is used.

Coverage includes deterministic normalization despite source-lock ordering,
explicit default-form identity, a shared Learnset, distinct native stage/level
conditions, blood and skill-stone acquisition, a legendary requirement, evolution
conditions, source-reference closure, and rejection of absent modules or content.
The separate current-Catalog test still validates the complete committed
normalized baseline and its real S4 identity. This compact fixture does not prove
that the ignored full raw snapshot can reproduce the published Catalog.
