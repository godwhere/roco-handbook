# Raw snapshot storage

The local importer freezes exact MediaWiki response bytes and extracted source under a content-addressed snapshot directory. Historical raw response and content bodies are ignored by Git; their source locks remain trackable. Phase 16 makes one exact exception for `references-3ad202f604caf1d1`: its complete public revision responses and source bodies are tracked so the five reference projections can be reproduced offline from a checkout. The exception does not expose headers, cookies, credentials, account state, or other snapshot directories.

To recreate local raw files, import the original responses again. Never edit a frozen response or content file in place.

Live import queries all configured module heads first, downloads each body by its frozen revision ID, and rechecks the complete head set before writing or reusing a snapshot. A changed head, failed query, unexpected body identity, empty body, or non-Scribunto model fails closed. New live locks record `revision_set_verified: true`; this describes stability during that import, not an atomic upstream release or complete game coverage. Reusing an existing snapshot leaves its original import time unchanged. The [content refresh contract](../../docs/features/catalog-content-refresh.md) documents the separate identity and release gates.

The Phase 16 supplement additionally accepts explicitly allowlisted JavaScript data-page models through its own fixed-revision contract. Their source is stored verbatim and only the reviewed literal/compressed JSON wrapper is decoded; no script is executed. See ADR-0035 and the reference feature contract for its separate source boundaries.
