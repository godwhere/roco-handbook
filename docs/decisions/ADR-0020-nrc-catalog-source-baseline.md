# ADR-0020: NRC Catalog source baseline

- Status: Accepted
- Date: 2026-09-14
- Phase: 8

## Context

The maintained BWIKI dataset moved from the legacy `rocom` modules to the newer `nrc` module family. The NRC modules expose explicit handbook numbers, handbook order, season metadata, complete source references, additional creatures and skills, and a different source-ID allocation. Reusing the legacy identity registry would therefore either reject the current source or incorrectly associate records whose source IDs were reassigned.

The App has not been published. There is no production user population or released personal database that requires cross-source favorite migration.

## Decision

Catalog data version 2 uses `https://wiki.biligame.com/nrc/api.php` and freezes eight required modules: Catalog, Handbooks, Evolutions, Learnsets, Skills, Index, Overview, and History. Development import remains explicit; the installed App does not access BWIKI.

The NRC adapter treats source numeric IDs as source-system-local identities and initializes `config/identity_registry_nrc_v1.json` as the new pre-release identity baseline. It does not translate legacy `bwiki.rocom` favorite IDs. The existing `user.db` isolation and lifecycle remain unchanged, but no compatibility promise is made between unpublished Catalog data version 1 identifiers and the NRC baseline.

The adapter uses the source's explicit handbook number and default handbook order. `Overview.season` supplies the stored owning season. Catalog type membership remains authoritative when an Evolution record duplicates a conflicting type list; the reviewed conflicts are frozen in `config/reviewed_exceptions.json`. A creature may belong to more than one explicit evolution graph, so normalization preserves every group membership instead of selecting one graph.

Image asset version 3 resolves NRC creature, shiny, skill, and feature source filenames while retaining stable local paths for unchanged game IDs where possible. NRC does not expose the 35 existing domain UI icons, so those exact frozen files remain preserved from image asset version 2. No runtime image acquisition is introduced.

## Consequences

- Catalog data version 2 contains 621 concrete creature forms, 466 handbook entries, 824 skills, 311 Learnsets, and 273 evolution groups.
- The S4 sample with game ID `3542` resolves to `pet_000598`, handbook number `454`, complete base stats, two types, one feature, and original plus shiny illustrations.
- All 621 active forms have complete six-value base stats in the NRC snapshot.
- Image asset version 3 contains 1,594 unique files and 1,673 Catalog references.
- The old data version 1 release and registry remain historical build evidence; they are not the active App baseline.
- A future public release must preserve NRC identities or define a separately reviewed migration before changing source systems again.

## Acceptance

- Live import validates response identity, canonical title, revision, hashes, content model, and non-empty source content before freezing an immutable snapshot.
- The data-only Lua parser rejects executable syntax and never executes upstream code.
- NRC normalization proves source-reference closure, deterministic output, explicit identity uniqueness, and the required S4 sample.
- The release builder verifies schema objects, constraints, integrity, foreign keys, manifest identity, database hashes, and reviewed exceptions.
- The image importer verifies MediaWiki identity, allowed hosts and paths, source SHA-1, byte limits, PNG dimensions, local hashes, preserved assets, and immutable reuse.
- Python and Flutter regressions resolve every active Catalog image and query the bundled NRC database without runtime Wiki access.
