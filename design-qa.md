# Phase 8 design QA

- Status: passed for the implemented iOS simulator scope
- Review date: 2026-09-10
- Device: iPhone 17 simulator, iOS 26.5, 1206 x 2622 capture
- Scope: creature catalog density, grouped creature filters, shiny detail switching, creature detail hierarchy, skill cards and filters, detail-owned favorites, the vertical Tools destination, Game descriptions, Event timeline, and Outfit inspiration

## Comparison inputs

The review placed each user-provided visual reference beside the matching rebuilt simulator state before judging the result. The latest pass compared the supplied horizontal filter panel with the App's mobile filter sheet, the supplied single Tool card with the complete vertical Tools destination, the supplied wide activity calendar with a narrow-screen vertical timeline, and the source outfit presentation with a two-column mobile preview grid. The source references use desktop-width layouts, while the App evidence uses the actual 402 x 874 logical iPhone viewport at 3x density, so the review judged preserved hierarchy, grouping, card language, content identity, and control clarity rather than reproducing desktop geometry. It also reviewed the shiny full-body asset, Game descriptions, activity detail, and outfit gender switch in the same simulator run. The earlier subtitle comparison used `/var/folders/d4/vlsfy7fd51vgb9ymqtc_zs8m0000gn/T/codex-clipboard-638bd0a2-d0d7-4ef9-9275-2d02538b6f7d.png` and `docs/evidence/phase-8-detail-redesign/ios-creature-form-subtitle.png` in one focused side-by-side image. Earlier combined comparisons covered the supplied compact-card, base-stat, feature, type-relationship, detail-header, skill-card, and filter references against their corresponding simulator captures.

## Final review

| Area | Result | Evidence |
| --- | --- | --- |
| Creature catalog | Pass. The 100-pixel contained full illustration and 10-pixel padding reduce card height while preserving the full creature. Name, complete muted parenthesized form, and fixed `NO.<dex_no>` remain on one line. The name-and-form group keeps its normal size when space permits and scales down when required, with no wrap or ellipsis. Type icons remain clear, and no favorite control competes with navigation. | `ios-creature-catalog.png`, `ios-creature-form-subtitle.png` |
| Creature filters | Pass. Shiny availability, stages 1 through 3, main/regional/lord forms, owning seasons S1 through S4, and creature types are separated into vertically readable mobile groups with consistent outlined controls. The sheet scrolls instead of compressing or clipping the groups. | `/tmp/roco-phase8-filter-sheet.png`, widget and repository regressions |
| Shiny detail | Pass. A shiny-capable creature exposes one outlined Original/Shiny segmented control inside the header. The selected shiny state uses the frozen full-body image and preserves the surrounding identity, favorite, section-dot, and basic-information layout. | `/tmp/roco-phase8-shiny-detail.png`, widget regression |
| Creature header | Pass. The frozen type icon follows the source name without a chip background. The header shows the derived stage label and exposes the creature favorite at the far right. | `ios-creature-header.png` |
| Basic information | Pass. The layout remains two equal columns. A normal creature displays No for Lord evolution, while a lord record displays Yes. | `ios-creature-header.png`, focused widget regression |
| Detail skill cards | Pass. The skill image is vertically centered; name, element icon, and unlock copy form the heading; Energy, Category, and Power form the metric row; source description remains below. | focused widget regression |
| Skill catalog | Pass. Skill handbook, Skill filters, and Skill query share one row. Cards show image, name with element icon, category, energy, power, description, and navigation without a favorite control. | `ios-skill-catalog.png` |
| Skill detail | Pass. The favorite control is visible in the detail header and the relationship list remains navigable. | `ios-skill-detail.png` |
| Tools destination | Pass. The former third destination uses large vertically stacked cards with overlines, strong titles, circular domain icons, descriptions, and diagonal arrows. The hierarchy follows the supplied Tool-card reference while remaining readable in the narrow App viewport. | `/tmp/roco-phase8-tools.png`, widget regression |
| Game descriptions | Pass. The 54-entry handbook uses a normal search field, horizontally scrollable source categories, compact readable descriptions, and image-backed related feature and skill sections. The delayed capture confirms the pushed page fully covers the prior route without a transition remnant. | `/tmp/roco-phase8-game-descriptions.png`, `/tmp/roco-phase8-game-description-detail.png`, widget and asset regressions |
| Event timeline | Pass. Month controls, the Today action, horizontally scrollable source categories, 74 September-intersecting entries, date rails, state badges, source icons, and preserved detail text remain readable without overflow. A vertical timeline is more legible than the supplied desktop calendar at the 402-point viewport. | `/tmp/roco-phase8-activity-timeline.png`, `/tmp/roco-phase8-activity-detail.png`, widget and asset regressions |
| Outfit inspiration | Pass. Search, female and male preview controls, grade chips, the 110-outfit count, two-column source previews, and the detail acquisition hierarchy remain legible. The selected 256-pixel preview stays contained and does not crop the outfit. | `/tmp/roco-phase8-outfit-catalog.png`, `/tmp/roco-phase8-outfit-detail.png`, widget and asset regressions |
| Section navigation | Pass. Eight right-side dots overlay full-width content without a reserved panel; tap, active state, and rounded outlined long-press labels are covered by the widget regression. | focused widget regression |
| Accessibility and large text | Pass. Domain icons keep semantic labels and the focused 2.0 text-scale dark-theme regression completes without overflow. | focused widget regression |

## Intentional differences

The supplied game screenshots define information hierarchy, labels, icon placement, and density rather than a replacement visual theme. The App retains its existing Material 3 light and dark themes, platform typography, and offline frozen Wiki assets. Exact source values remain authoritative, so Flash displays its stored power of 60 rather than the illustrative value of 80 in the reference.

## Unrun visual layers

The current redesign was not visually re-reviewed on Android or a physical device. Activity posters were intentionally excluded from the App because the 242 referenced originals total about 436 MiB; the timeline uses compact source icons. Store screenshots already tracked for the earlier Phase 8 state were not replaced by these working UI evidence captures.

## Comparison history

- Earlier finding, P2: equal flexible-width allocation truncated the alternate form label `（蜕皮时的样子）` even though the title row still had usable space.
- Fix: the name-and-form group now uses single-line, scale-down fitting inside the width left by the fixed `NO.<dex_no>` label.
- Post-fix evidence: the focused side-by-side comparison shows the complete `板板壳（蜕皮时的样子）` label without wrapping, ellipsis, number movement, asset degradation, color drift, or spacing regression. Typography, layout rhythm, colors, frozen image quality, and source copy all pass for the changed component.
- Latest Phase 8 continuation: the iPhone 17 integration run captured the grouped filter sheet, vertical Tools destination, Game descriptions and detail, Event timeline and detail, Outfit inspiration and detail, and shiny detail state at 1206 x 2622. No clipping, overlap, unreadable text, missing frozen image, transition remnant, or broken navigation was observed.

No actionable P0, P1, or P2 findings remain. No additional focused region was needed because the changed surface is the complete title row shown at readable scale in the focused comparison.

final result: passed
