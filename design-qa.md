# Phase 8 design QA

- Status: passed for the implemented iOS simulator scope
- Review date: 2026-09-10
- Device: iPhone 17 simulator, iOS 26.5, 1206 x 2622 capture
- Scope: creature catalog density, creature detail hierarchy, skill cards and filters, and detail-owned favorites

## Comparison inputs

The review placed each user-provided visual reference beside the matching rebuilt simulator state before judging the result. The final creature-card density comparison used the current compact-card reference and `docs/evidence/phase-8-detail-redesign/ios-creature-catalog.png` in one side-by-side image. Earlier combined comparisons covered the supplied base-stat, feature, type-relationship, detail-header, skill-card, and filter references against their corresponding simulator captures.

## Final review

| Area | Result | Evidence |
| --- | --- | --- |
| Creature catalog | Pass. The 100-pixel contained full illustration and 10-pixel padding reduce card height while preserving the full creature. Name, muted parenthesized form, and `NO.<dex_no>` share the title row. Type icons remain clear, and no favorite control competes with navigation. | `ios-creature-catalog.png` |
| Creature header | Pass. The frozen type icon follows the source name without a chip background. The header shows the derived stage label and exposes the creature favorite at the far right. | `ios-creature-header.png` |
| Basic information | Pass. The layout remains two equal columns. A normal creature displays No for Lord evolution, while a lord record displays Yes. | `ios-creature-header.png`, focused widget regression |
| Detail skill cards | Pass. The skill image is vertically centered; name, element icon, and unlock copy form the heading; Energy, Category, and Power form the metric row; source description remains below. | focused widget regression |
| Skill catalog | Pass. Skill handbook, Skill filters, and Skill query share one row. Cards show image, name with element icon, category, energy, power, description, and navigation without a favorite control. | `ios-skill-catalog.png` |
| Skill detail | Pass. The favorite control is visible in the detail header and the relationship list remains navigable. | `ios-skill-detail.png` |
| Section navigation | Pass. Eight right-side dots overlay full-width content without a reserved panel; tap, active state, and rounded outlined long-press labels are covered by the widget regression. | focused widget regression |
| Accessibility and large text | Pass. Domain icons keep semantic labels and the focused 2.0 text-scale dark-theme regression completes without overflow. | focused widget regression |

## Intentional differences

The supplied game screenshots define information hierarchy, labels, icon placement, and density rather than a replacement visual theme. The App retains its existing Material 3 light and dark themes, platform typography, and offline frozen Wiki assets. Exact source values remain authoritative, so Flash displays its stored power of 60 rather than the illustrative value of 80 in the reference.

## Unrun visual layers

The current redesign was not visually re-reviewed on Android or a physical device. Store screenshots already tracked for the earlier Phase 8 state were not replaced by these working UI evidence captures.
