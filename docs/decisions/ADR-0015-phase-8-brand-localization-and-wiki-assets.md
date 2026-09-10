# ADR-0015: Phase 8 brand, localization, and Wiki assets

- Status: accepted
- Date: 2026-09-10
- Scope: Phase 8 visual identity, Chinese UI, offline Wiki imagery, and store screenshots

## Context

Phases 0 through 7 established the validated data pipeline, offline Flutter App, personal-data boundary, Catalog replacement, release gates, and optional complete-Catalog transport. The App still uses Flutter placeholder icons, a blank launch image, English-only interface copy, and generic Material symbols where the Catalog already preserves upstream image keys.

The repository owner directed Phase 8 to deliver a formal App identity, launch experience, iOS and Android store screenshots, source-grounded Chinese UI terminology, and offline images for creatures, skills, features, and selected domain controls. All other Phase 8 release work is deferred.

## Decision

Phase 8 uses the following bounded product contract:

- The display name is **Roco World Handbook** in English and **洛克手册** in Chinese. Platform home-screen labels use the Chinese display name.
- English remains available. `zh-CN` is selected for Chinese device locales, while every other locale falls back to `en-US`.
- Chinese game-domain terms come from a frozen BWIKI terminology file. Generic actions and platform messages use concise native Chinese copy but do not redefine game semantics.
- Creature heads and illustrations are resolved from the existing Catalog `head_key` and `illustration_key` values. Skill and feature icons are resolved from `icon_key` plus the preserved category.
- Creature details calculate and display the total only when all six stored base-stat values are present. The Chinese label is source-grounded as `种族资质总和`; it is not a separately stored or inferred gameplay stat.
- Type relationships are frozen from `Module:TypeRelation`. The App builds incoming single- and dual-type damage multipliers from the module's `strong_against` and `resisted_by` source relations, including its three-times cap for a dual-type four-times weakness, and presents outgoing relationships per creature type.
- The module's redundant inverse lists omit eight same-type relationships. Those exact reciprocity differences are preserved as reviewed exceptions; the App does not overwrite either source list and uses the same forward matrix inputs as the module's damage calculator.
- Selected type, stat, and skill-category icons use exact BWIKI file titles. They supplement semantic text and never become the only accessible label.
- A dedicated import client queries only the configured MediaWiki API, accepts only validated bitmap metadata, downloads only from the exact image host and path prefix returned by that API, verifies size, MIME type, dimensions, and hashes, and freezes an immutable asset manifest.
- Images ship inside the App. Ordinary App browsing never requests the Wiki or an image CDN, and a missing local image fails to an accessible in-App placeholder.
- The formal icon and launch mark use the frozen Dimo illustration over a project-authored background. The upstream character pixels are not redrawn.
- Store screenshots are captured from the implemented Chinese App on iOS and Android simulators or emulators and stored as release evidence. They are not uploaded to a store by this phase.

## Phase boundary

Allowed paths are `AGENTS.md`, root and App READMEs, `config/`, `tools/bwiki_import/`, focused Python tests, `app/assets/`, App localization and UI files, platform icon and launch resources, focused Flutter tests, `docs/decisions/`, `docs/evidence/`, `docs/features/`, and `docs/implementation-reports/phase-8.md`.

The phase does not change Catalog or User schemas, stable identities, source semantics, runtime Catalog transport, `user.db`, App signing, store account configuration, store upload, store publication, logical patches, a real Catalog V2, or system networking.

## Acceptance

- Every active creature has a frozen local head and illustration.
- Every active skill and feature has a frozen local icon.
- Every stored asset has exact source metadata and a verified local SHA-256 in the immutable manifest.
- The App renders those assets in list and detail flows without runtime image networking.
- Chinese navigation and domain labels use the frozen terminology contract, including `精灵`, `图鉴`, `技能`, `特性`, `系别`, and `种族资质`.
- Creature details show `种族资质总和` and source-backed `属性克制` with focused tests for single- and dual-type multipliers.
- The App has non-placeholder iOS and Android icons, a branded launch image, and the declared display name.
- Focused localization, repository, asset-contract, and widget tests pass together with the complete Python and Flutter gates.
- iOS and Android store screenshots exist and are visually reviewed.
- The phase report lists exact asset counts, bytes, hashes, checks, unrun layers, and deferred work.

## Consequences

The App package becomes larger because complete visual assets are bundled for offline use. The asset manifest makes that cost measurable and reproducible. A later data release may reference new keys, but it cannot silently acquire images at runtime; adding or updating bundled imagery remains an explicit import and App-release action unless a separately accepted image-update protocol is introduced.
