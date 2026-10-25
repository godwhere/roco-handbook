# ADR-0035: Offline references and independent checklists

- Status: accepted
- Date: 2026-10-26
- Scope: Phase 16, after the Phase 15 coverage tool

## Context and authorization

The user approved the ranked Wiki additions. Research identified data-only Items and Medals modules, research tasks in the already-frozen Handbooks source, explicit encounter records in generated GrassTracker markup, and nineteen literal compressed WorldMap data pages. These are distinct source contracts beyond Catalog schema version 1. Website renderer projections are not complete data: item details retain variants, research rendering suppresses some recipe rewards, and medals retain four records excluded from public browsing.

## Decision

Add five finite, independently validated auxiliary JSON catalogs: items, research, medals, trials and habitats. They share a small normalized card/section/source contract defined in [offline references](../features/offline-references.md). Source-specific adapters own semantics, raw-field preservation and reviewed identity mapping. Native UI receives DTOs and does not inspect raw API fields or execute upstream code. Existing Catalog SQL, identities, releases and personal schema remain unchanged.

Freeze complete source responses before activating a supplement. Bind every allowed title to canonical page identity, fixed revision, content model and hashes. Use the existing explicit import transport; the observed supported POST form for MediaWiki query requests is acceptable. Parse Lua only through the existing safe data parser. Decode only the exact reviewed two-JSON-argument WorldMap data wrapper, with bounded strict base64/gzip/JSON decoding. Parse GrassTracker's data-only markup through an offline HTML parser. No downloaded script, renderer, account endpoint or `require` is executed.

Track the complete public `references-3ad202f604caf1d1` source snapshot through one exact raw-storage ignore exception. This permits checkout-grounded offline reproduction of the five projections without changing historical snapshot policy. Include only revision response bodies, source content and their lock, with no HTTP headers, cookies, credentials or account data.

Retain explicit item, task-progress, medal, encounter and map-point identities. Do not derive creature or item IDs from filenames, names, suffixes or ordering. Every native link closes against the current frozen Catalog/item identities through a unique exact source mapping. Unmapped references remain explicit noninteractive source text with a review reason. Preserve all task rewards, item variants, medal evidence statuses/conditions and encounter form/hierarchy data. Public medal visibility is an explicit reviewed adapter output; hidden/deprecated records remain in the immutable projection.

Research and trial completion use independent, typed JSON sets in the existing personal settings table. Missing data means no marks. Malformed saved data fails without replacing it; unknown well-formed saved IDs survive data changes. Successful SQLite writes precede UI updates. The existing handbook collection flags, favorites, notes, layouts and interface language retain ownership and meaning. Catalog installation/recovery cannot overwrite these records.

Only explicitly manifested and verified original icons are acquired. Reuse exact approved assets where possible and retain source identity, hashes, dimensions, attribution and unavailable-image evidence. No generated game art or substituted creature is allowed. The habitat deliverable is an offline area/layer index with the source's uncertainty; full map-base/tile media, exact-spawn promises, screenshot recognition, inventory, accounts and synchronization are outside this delivery.

## Acceptance

The Phase 16 report declares the allowlist and commands. Require complete source-set/count/reference/identity/variant evidence, safe-parser negative fixtures, deterministic immutable output, media closure and staging checks, independent checklist persistence/isolation/recovery coverage, native search/detail/filter/link/source/AX captures, affected and default Python tests, Swift tests, unsigned native build, English-prose and scoped review. Commit and push through GitHub Desktop. Local results do not prove physical iOS/iOS 15, VoiceOver, live updates, signed upgrades or store acceptance.
