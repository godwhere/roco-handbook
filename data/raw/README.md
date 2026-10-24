# Raw snapshot storage

The local importer freezes exact MediaWiki response bytes and extracted Lua source under a content-addressed snapshot directory. Raw response and content bodies are intentionally ignored by Git; the source lock remains trackable so a maintainer can verify provenance without silently replacing a published snapshot.

To recreate local raw files, import the original responses again. Never edit a frozen response or content file in place.

Live import queries all configured module heads first, downloads each body by its frozen revision ID, and rechecks the complete head set before writing or reusing a snapshot. A changed head, failed query, unexpected body identity, empty body, or non-Scribunto model fails closed. New live locks record `revision_set_verified: true`; this describes stability during that import, not an atomic upstream release or complete game coverage. Reusing an existing snapshot leaves its original import time unchanged. The [content refresh contract](../../docs/features/catalog-content-refresh.md) documents the separate identity and release gates.
