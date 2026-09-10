# Phase 8 design QA

- Status: passed for the implemented iOS simulator scope
- Review date: 2026-09-10
- Device: iPhone 17 simulator, iOS 26.5, 1206 x 2622 capture
- Scope: creature catalog density, creature detail hierarchy, skill cards and filters, and detail-owned favorites

## Comparison inputs

The review placed each user-provided visual reference beside the matching rebuilt simulator state before judging the result. The final subtitle comparison used `/var/folders/d4/vlsfy7fd51vgb9ymqtc_zs8m0000gn/T/codex-clipboard-638bd0a2-d0d7-4ef9-9275-2d02538b6f7d.png` and `docs/evidence/phase-8-detail-redesign/ios-creature-form-subtitle.png` in one focused side-by-side image. The 678 x 662 source crop showed the `NO.012` alternate form with an ellipsis; the 1206 x 2622 iPhone capture used the 402 x 874 logical viewport at 3x density and showed the same form after searching for `012`. The comparison normalized both focused card regions to the same 700-pixel width. The surrounding list states differ because the source was scrolled and the implementation used an exact-number search; only the matching `NO.012` alternate-form card was judged in this pass. Earlier combined comparisons covered the supplied compact-card, base-stat, feature, type-relationship, detail-header, skill-card, and filter references against their corresponding simulator captures.

## Final review

| Area | Result | Evidence |
| --- | --- | --- |
| Creature catalog | Pass. The 100-pixel contained full illustration and 10-pixel padding reduce card height while preserving the full creature. Name, complete muted parenthesized form, and fixed `NO.<dex_no>` remain on one line. The name-and-form group keeps its normal size when space permits and scales down when required, with no wrap or ellipsis. Type icons remain clear, and no favorite control competes with navigation. | `ios-creature-catalog.png`, `ios-creature-form-subtitle.png` |
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

## Comparison history

- Earlier finding, P2: equal flexible-width allocation truncated the alternate form label `（蜕皮时的样子）` even though the title row still had usable space.
- Fix: the name-and-form group now uses single-line, scale-down fitting inside the width left by the fixed `NO.<dex_no>` label.
- Post-fix evidence: the focused side-by-side comparison shows the complete `板板壳（蜕皮时的样子）` label without wrapping, ellipsis, number movement, asset degradation, color drift, or spacing regression. Typography, layout rhythm, colors, frozen image quality, and source copy all pass for the changed component.

No actionable P0, P1, or P2 findings remain. No additional focused region was needed because the changed surface is the complete title row shown at readable scale in the focused comparison.

final result: passed
