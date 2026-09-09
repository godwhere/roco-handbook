# Raw snapshot storage

The local importer freezes exact MediaWiki response bytes and extracted Lua source under a content-addressed snapshot directory. Raw response and content bodies are intentionally ignored by Git; the source lock remains trackable so a maintainer can verify provenance without silently replacing a published snapshot.

To recreate local raw files, import the original responses again. Never edit a frozen response or content file in place.
