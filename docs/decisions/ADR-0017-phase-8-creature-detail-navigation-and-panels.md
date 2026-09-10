# ADR-0017: Phase 8 creature and skill handbook presentation

- Status: accepted
- Date: 2026-09-10
- Scope: creature and skill catalog cards, creature detail hierarchy, skill filtering, favorites, evolution links, and section navigation
- Supersedes: the catalog and detail presentation portions of the V1 baseline

## Context

The first creature detail page exposed a form selector before the content and presented facts, stats, feature ownership, learnable skills, evolution evidence, and type relationships as similarly weighted cards. The earlier catalog cards also mixed list navigation with favorite controls, and the skill browser used relationship tabs rather than a handbook-oriented filter. The Catalog already exposes every concrete form, preserves three primary Learnset sources, stores skill category, description, and element data, and returns evidence-backed evolution edges with stable creature identifiers. The redesign can therefore use existing contracts without changing either normative schema.

## Decision

- The primary detail order is Basic information, Feature, Base stats, Skills, and Evolution. Type relationships, My library, and Source remain available after the five primary sections.
- Creature cards use a 100-logical-pixel contained full illustration with compact 10-pixel padding. The source name, a smaller muted parenthesized form label, and `NO.<dex_no>` share the title row. Type names are represented by their accessible frozen icons below it. Catalog cards no longer contain favorite controls.
- The Displayed form selector is removed. Each concrete form remains directly reachable from the creature catalog, and selecting an evolution relation opens a new detail route for the related concrete `pet_id` so Back returns to the previous form.
- The detail header derives its visible stage label from the preserved stage value: First, Second, Third, or Lord form. A true lord-evolution flag or source stage 4 displays Lord form. Non-lord records explicitly display No for the Lord evolution fact. Creature type icons follow the name directly without a chip background.
- Creature and skill favorite controls are placed in their detail headers. My Library continues to own the resulting device-local list, while catalog result cards remain dedicated navigation targets.
- Feature presentation uses the frozen feature icon, source name, and stored source description. Opening the row continues to show the complete skill detail.
- Base stats use the exact stored total and six exact stored values. Each value also receives a bounded visual bar on a 300-point presentation scale; the bar never changes or infers the stored number. Height, weight, review gold, and starlight move into compact supporting fact pills below the six values.
- The Skills section provides Pet skills, Bloodline effects, and Learnable skills controls. They map to `native`, `blood`, and `stone` relations. The 14 preserved `legendary` relations remain visible under Learnable skills with their Legendary source label and requirement text rather than being discarded.
- The skill filter is a compact icon control. It filters the currently selected source list in memory by the source `damage_class` values for physical or magic attack, the stored defensive or status category, and the stored skill element. Empty filter selections mean no restriction. Skill cards place the stored element icon immediately after the name, then show Energy, Category, and Power below it.
- The skill browser is a learnable-skill handbook rather than a feature relationship switcher. Its single toolbar provides Skill handbook, Skill filters, and Skill query in a one-to-one-to-two width ratio. Results show the skill icon, name with element icon, category, energy, power, description, and a navigation affordance without a favorite control.
- Skill filters expose the four supported skill types, the 18 combat elements, and the 20 accepted screenshot labels. Element and type predicates use preserved Catalog columns. Labels that are not first-class upstream fields are deterministic read-only projections over preserved description text or description-note identifiers; they never write inferred tags back into the Catalog. Within one filter group values use OR, while selected groups combine with AND.
- Type relationships show the concrete form's accessible type icons and compact incoming-damage panels for increased and reduced damage. Exact multipliers and source type icons remain visible. The domain contract continues to retain outgoing relationships even though this detail panel no longer renders them.
- Every evolution edge and every direction-unknown group member is interactive when it resolves to a different concrete creature. No edge or direction is inferred.
- A fixed right-side navigator overlays the full-width page without reserving a gutter or drawing a separate background panel. It tracks Basic information, Feature, Base stats, the selected skill category, Evolution, Type relationships, My library, and Source. Tapping a dot scrolls to the section. Long pressing a dot shows its localized name in a rounded outlined tooltip.

## Phase boundary

Allowed paths are the existing creature detail presentation, optional skill-summary projections from existing Catalog columns, localized strings, focused tests, current READMEs, Phase 8 feature and evidence documents, and the Phase 8 implementation report.

Catalog and User schemas, source import, identity rules, Learnset preservation, evolution inference, personal-data behavior, Phase 7 transport, signing, store upload, and publication do not change.

## Acceptance

- No Displayed form selector is rendered on creature detail.
- The five primary sections render in the declared order, followed by the three preserved utility sections.
- Feature description and skill damage class come from existing Catalog fields.
- Creature cards keep the form label, `NO.<dex_no>`, type icons, and navigation affordance on a compact layout without a favorite control.
- Detail headers show the derived stage label, unbacked type icons, and the only detail-level favorite control. Non-lord creatures display No for Lord evolution.
- The three skill-source controls show the correct relations, and category plus element filters can be combined, cleared, cancelled, and applied. Skill element icons follow their names.
- The skill browser excludes features, renders the three-part toolbar and source-backed result fields, offers all 42 declared filter chips, combines filter groups deterministically, and keeps favorites on detail only.
- Evolution rows navigate by stored `pet_id` and preserve Back navigation.
- All eight right-side dots overlay full-width content with no dedicated gutter, have a large tap target, track scroll position, jump to their section, and expose a long-press rounded outlined label.
- Base stats, feature, and incoming type relationships match the accepted reference hierarchy on the iOS simulator without overflow.
- Focused repository and widget tests, the full Python and Flutter suites, static analysis, formatting, and diff checks pass.

## Consequences

The detail page no longer provides a same-page shortcut between forms sharing a handbook entry; the concrete-form catalog and evidence-backed evolution links are now the navigation paths. All three main Learnset sources remain distinct while a single optional filter layer reduces long lists without issuing another database query. The catalog surfaces more results per screen, and accidental favorite changes during browsing are removed. Incoming type relationships become easier to scan, while the still-preserved outgoing matrix is no longer duplicated on this screen.
