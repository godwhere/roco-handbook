# Phase 8 creature Catalog layout design QA

- Review date: 2026-09-14
- Source visual truth: `/var/folders/d4/vlsfy7fd51vgb9ymqtc_zs8m0000gn/T/codex-clipboard-178ba5d3-9f1f-431c-b8fa-e5a61a80b622.png`
- Supporting full-screen concept: `/Users/ethan/.codex/generated_images/01a084ad-ac2c-7d23-9db4-d6fa0b1cfbbb/exec-6ed72adb-da77-435d-906c-a20036587ddc.png`
- Implementation screenshot: `docs/evidence/phase-8-layout/ios-creature-grid.png`
- Comparison images: `/tmp/roco-phase8-grid-comparison.png` and `/tmp/roco-phase8-grid-full-comparison.png`
- Device and state: iPhone 17 simulator, iOS 26.5, `zh-CN`, light theme, grid selected, first four Dimo forms visible
- Viewport: 402 x 874 logical pixels at 3x density; implementation capture 1206 x 2622 pixels

## Normalization

The binding card-region source is 772 x 1048 pixels. The matching implementation region was cropped from the 1206 x 2622 simulator capture and resampled to 772 x 1048 before the focused side-by-side comparison. The supporting full-screen concept is 853 x 1844; the complete implementation screenshot was resampled to the same 853 x 1844 dimensions before the full-view comparison. Device chrome is absent from both implementation comparisons.

## Full-view comparison evidence

The implementation preserves the concept's app title and data version hierarchy, single compact control row, two-column illustrated Catalog, stable card information, and four-destination bottom navigation. The user-attached crop makes the two-column card region the binding target. The existing Sort, Filters, Search order, Material 3 page shell, and frozen Wiki display font remain intentional product constraints rather than adopting the concept's generated tagline, castle background, or glass treatment. No unapproved decorative bitmap or fabricated domain asset was introduced.

## Focused comparison evidence

The same four source-backed creatures appear in the same two-column order. Card aspect ratio, large contained full-body art, rounded surface, name hierarchy, muted Lord-form subtitle, circular detail affordance, type icons, and bottom-right `NO.001` placement match the attached target at readable scale. Blue, warm-gold, green, and warm-red surfaces separate the four example cards while preserving contrast. No label wraps, truncates, overlaps, or leaves the card bounds.

## Required fidelity surfaces

- Fonts and typography: the implementation keeps the approved `RocoDisplay` and `RocoNumbers` roles. Names, subtitles, and identifiers remain single-line and legible; using the approved product font instead of the generated concept font is intentional.
- Spacing and layout rhythm: two equal phone columns, 10-pixel grid gaps, consistent 12-pixel outer inset, stable card radii, and aligned card footers match the target hierarchy. The responsive contract changes to three columns at 720 logical pixels.
- Colors and visual tokens: type-aligned low-opacity surfaces preserve Material contrast in light and dark themes. The non-default single-Light example uses the target's warm-gold separation.
- Image quality and asset fidelity: every card uses the exact frozen full-body Wiki illustration and bundled type icon through the production asset resolver. Images remain contained and sharp with no crop or transparency halo.
- Copy and content: source names, form text, type identity, and `NO.<dex_no>` remain data-backed. No concept-only tagline or online feature was added.

## Interaction and accessibility evidence

The iOS integration run opened Settings, selected Grid, returned to Creatures, captured the result, opened the grouped filter sheet, and completed the existing Tools and shiny-detail flow. The focused widget test switches to List, verifies the horizontal layout, recreates the page, and confirms that the saved choice persists. The complete Flutter test suite covers dark theme and a 2.0 text scale. The integration log contains no Flutter exception or failed assertion.

## Comparison history

- First pass, P2: the non-default single-Light card used the same blue surface as the default Dimo card, weakening the target's visual grouping.
- Fix: apply a restrained warm-gold surface to non-default single-Light cards while leaving the exact illustration and type icon unchanged.
- Second pass: the normalized focused comparison confirms the blue, gold, green, and red grouping with unchanged geometry, copy, image scale, and contrast. No actionable P0, P1, or P2 finding remains.

## Follow-up polish

- P3: the generated concept contains decorative star and castle imagery that is not part of the attached binding card crop or the approved offline asset library. A later visual-theme task may add a reviewed source asset without coupling it to the layout preference.

final result: passed
