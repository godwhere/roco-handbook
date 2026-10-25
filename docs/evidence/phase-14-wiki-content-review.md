# Phase 14 Wiki content review

## Evidence and authorization

The original live browser review occurred on **2026-10-25**, as recorded in the task-owned `wiki-content-review/notes.json`. It inspected the [Wiki home page](https://wiki.biligame.com/nrc/) and the five destinations below. Screenshots and notes remain outside the repository. A targeted primary-page text review on **2026-10-26** additionally checked navigation and item/egg catalogs; no browser connection was available for that follow-up.

This is the read-only research permitted by the [Phase 14 boundary](../implementation-reports/phase-14.md). No import, module acquisition, login, account mutation, upload, code, schema, Catalog, media, or personal-data change was performed. Page counts describe the observed website, not verified import completeness. Recommendations and offline feasibility are engineering proposals, not implemented capabilities.

## Current Handbook overlap

The current [README](../../README.md) and [browser feature contract](../features/offline-catalog-browser.md) describe 633 concrete forms, 468 handbook entries and 825 skills. Existing features include per-creature incoming/outgoing type relations, egg groups, seasons, 54 game-description entries, 552 activities, 124 outfits with 248 previews, favorites, handbook collection marks and local notes.

Season/activity/egg-group/outfit catalogs are already present. A standalone multi-attack coverage tool would extend the existing type calculations. Research tasks, medals, trial encounters and map content require new data contracts. Targeted searches of native routes, feature documentation, configuration and schemas found no Nature or item/fruit/egg catalog feature; existing egg groups and recorded egg-weight fields do not constitute an egg-item catalog.

## Recommended order

### 1. Standalone attack coverage tool

**Observed:** The [move coverage calculator](https://wiki.biligame.com/nrc/%E6%8A%80%E8%83%BD%E6%89%93%E5%87%BB%E9%9D%A2%E8%AE%A1%E7%AE%97%E5%99%A8) accepts up to five distinct attacking types out of eighteen. Coverage means at least one choice is super effective; weak coverage means all choices are resisted. Selecting Fire displayed four covered types and three weak types, without login.

**Proposed:** Add a Tools entry using the existing frozen relation matrix and type identifiers, with focused checks for combination semantics. Reuse packaged icons; no new upstream data or personal progress is expected if the existing matrix is sufficient. This remains elemental coverage, not a damage or battle simulator.

### 2. Read-only item, fruit and egg reference

**Observed on 2026-10-26:** The [item index](https://wiki.biligame.com/nrc/%E7%89%A9%E5%93%81%E5%9B%BE%E9%89%B4) displays 1,534 item kinds: 207 common items, 178 fruits, 194 eggs, 477 skill stones and 478 recipes. Common-item cards include images, categories and descriptions. The [egg catalog](https://wiki.biligame.com/nrc/%E7%B2%BE%E7%81%B5%E8%9B%8B%E4%B8%80%E8%A7%88) independently displays 194 items, type filters, artwork and hatch/source descriptions. The [fruit destination](https://wiki.biligame.com/nrc/%E7%B2%BE%E7%81%B5%E6%9E%9C%E5%AE%9E%E4%B8%80%E8%A7%88) was identified, but its body timed out; only the index's fruit count is confirmed.

**Proposed:** Start with the common-item reference, then explicitly mapped fruit/egg links to creatures. This is a smaller read-only addition than map or trial tracking and can later support reward links. Gate it on a frozen item source, stable upstream item IDs, explicit item-to-creature/skill references, preserved acquisition conditions and a reviewed image manifest. Do not derive hatch identity from names, or treat skill-stone learnsets as a complete item/recipe catalog. No inventory or owned-item persistence is proposed initially.

### 3. Research tasks and rewards

**Observed:** [Research tasks](https://wiki.biligame.com/nrc/%E5%9B%BE%E9%89%B4%E8%AF%BE%E9%A2%98) display 468 creatures and 2,351 tasks, reward/type/task filters, and shared progress across forms. Public task/reward details are readable; completion marking and synchronization require login.

**Proposed:** A local task checklist would make the handbook useful during play. Require a frozen task/reward source, stable task IDs, explicit handbook-level membership and closed reward references. Reuse approved images where possible; acquire missing reward icons only under a scoped manifest. Design independent local task progress without duplicating it per `pet_id`, overwriting collection marks, or adding website account synchronization.

### 4. Medal reference and acquisition conditions

**Observed:** The [medal catalog](https://wiki.biligame.com/nrc/%E5%A5%96%E7%89%8C%E5%9B%BE%E9%89%B4) displays 56 medals, icons, acquisition conditions, population/individual/bond types and ordinary/precious/legendary qualities. Identical display names can lead to different detail pages.

**Proposed:** Add searchable image cards, then link research requirements. Require frozen medal records and stable IDs rather than name matching; preserve each medal's ownership scope and conditional text. Validate icon provenance and packaging. Any owned-medal tracking requires a separately defined local model for population, individual and bond scope; current handbook collection flags are insufficient.

### 5. Manual grass-badge trial checklist

**Observed:** The [trial record book](https://wiki.biligame.com/nrc/%E8%8D%89%E7%B3%BB%E5%BE%BD%E7%AB%A0%E6%A0%87%E8%AE%B0) shows regional counts of 210, 317 and 199, with a total label of 726. It distinguishes ordinary creatures, bosses and regional forms, exposes floor-source information and a seventh-floor lineup link, and offers screenshot recognition with user verification. Recording/synchronization requires login. The total is not evidence of 726 unique global identities.

**Proposed:** Begin with manual region/floor encounter records. Require frozen trial entries, stable region/floor/entry keys and explicit mapping to concrete forms. Reuse approved creature images. Keep local encounter progress distinct from owned/collected handbook progress. Screenshot recognition remains a later feature requiring its own on-device accuracy, correction and privacy acceptance; no screenshot was uploaded during this review.

### 6. Area habitats before a full offline map

**Observed:** The [map](https://wiki.biligame.com/nrc/%E5%9C%B0%E5%9B%BE) offers continent/academy maps, surface plus three underground floors, cross-floor search, and creature/resource/boss/NPC categories. Its guide states that habitat pins indicate areas rather than exact spawn locations. High-resolution imagery needs more initial traffic. Collection marking requires login; filter preferences are local.

**Proposed:** Start with a small area/habitat index. Gate it on stable area/point IDs, explicit floor/coordinate conventions and creature references. A full map additionally requires reviewed bottom-map/marker rights, immutable assets, installation-size limits and accessible search/navigation. Local point completion requires separate progress keys. Preserve the area's uncertainty and avoid exact-spawn promises or runtime tile/network dependencies.

## Additional candidate and stopping boundary

The [Nature destination](https://wiki.biligame.com/nrc/%E6%80%A7%E6%A0%BC) is present in the Wiki navigation. Its body could not be read during bounded follow-up checks, so no Nature count, modifier table or mechanics were verified. A compact offline reference may rank ahead of trial/map work after its actual data and source contract are checked; do not infer values from another game.

Public pages do not prove that approved data-only modules, stable numeric IDs or reusable image rights exist. Exact source revisions, parser coverage, reference closure, media permissions, release size and device behavior remain unverified. Any implementation needs its own authorized phase, frozen-source review and appropriate offline/personal-data tests. This review stops at recommendations; no new content has been imported or shipped.
