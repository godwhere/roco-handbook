# Phase 13 native design QA

## Result

final result: passed

No actionable P0/P1/P2 findings remain. The maximum-text Settings icon-column issue was repaired with a body-relative `ScaledMetric`, recaptured, and independently rechecked. No source images or action semantics changed for this repair.

## Source truth and implementation

- Approved visual targets: `docs/evidence/phase-13/wiki-library-tools.jpg` and `wiki-skills.jpg`, captured from the actual NRC Wiki and explicitly approved by the user. `wiki-observations.json` records URLs and computed colors, 9-pixel corners, and the display font.
- Implementation: native `ToolsView` and `SettingsView`; `tools-zh.png`, `settings-zh.png`, their lower-page and actual-dark variants, and the three `*-large-text-*.png` captures in the same evidence directory.
- Browser sources are 375 x 812 pixels. Native captures are 1206 x 2622 pixels for a 402 x 874 point simulator at 3x density. Combined boards resample both views to 375 pixels wide while preserving aspect, with no content stretching. The source and native heights differ naturally; native navigation/status/tab bars and the actual seven Tool destinations replace website chrome/content by explicit product scope.
- Full-view comparisons: `tools-comparison.png` and `settings-comparison.png`. Focused image-layout comparison: `tools-focused-comparison.png`. Both source and implementation were opened together in each board, supplemented by full-resolution native inspection.

## Required fidelity surfaces

- Typography: reuse the frozen display font for compact 16-point functional Tool titles and 15/17-point Settings section titles. Platform body/subheadline/caption styles remain readable and scalable. The user's earlier smaller-text feedback intentionally takes precedence over copying the website's larger headings.
- Layout: one tall left tile and two stacked right tiles, 9-point corners, short left-aligned titles, four image rows, and lightly separated Settings panels. Shorter native tiles preserve room for all seven destinations. The fixed web float buttons and website navigation are intentionally omitted.
- Colors: the regular-text home cards use the observed navy `#34476D`, lavender `#E4E0F1`, and pale blue `#DCEAF3`; Settings follows the charcoal/ivory pattern with restrained gold. Native dark-mode colors have separate values and were actually captured with the simulator reporting dark.
- Images: eight existing frozen resources have source identity/hash/length evidence in `source-art.json`; game art is contained, not generated, repainted, warped, or relabeled as a source record. Only the decorative starlight watermark uses template rendering. No new image/font request or dependency is introduced.
- Content: all seven original Tool IDs, both saved layout choices, personal library, Catalog information, update/recovery/cancel/error states, recovery notice, version, and licenses are retained. Marketing headers and repeated Tool descriptions are removed. The Settings grouping is an intentional native adaptation.

## Comparison history

1. Normal light and actual-dark combined/full-resolution review: no actionable P0/P1/P2 mismatch for the approved native-adaptation scope. Image identities, palette, compact labels, hierarchy, and lower-action reachability checked. A focused-board crop initially clipped a few pixels below the right tile; only the QA board crop was corrected, not App content.
2. Maximum-accessibility inspection: P2, Settings leading symbols crowd labels because their rendered Dynamic Type size exceeds a fixed column. Before evidence: `settings-large-text-zh-before-fix.png` and `settings-large-text-lower-zh-before-fix.png`. Repair: scale the column with the body metric. The final generic build, normal/maximum-text light cases, and actual-dark capture case passed. Updated `settings-large-text-zh.png` and `settings-large-text-lower-zh.png` show clear symbol/label separation and natural wrapping. `accessibility-repair-comparison.png` places the matching before/after state together. Independent reinspection confirmed the repair and no remaining P0/P1/P2 issue.

## Interaction and evidence limits

The seven-route and favorites/notes/layout-through-recovery cases passed. Final normal and maximum-text light cases passed after the icon-column repair, followed by a final actual-dark capture pass. The first normal capture run hit a 43.99999999999994 versus 44-point assertion precision edge; a 0.001-point numerical tolerance preserves the 44-point target contract. Xcode's automatic failure-diagnostic collector stalled after the initial completed tests; its invocation-owned diagnostic process was stopped, preserving the result/attachments. Later runs use the supported per-invocation `-collect-test-diagnostics never` option. The simulator was restored to light appearance after final capture.

This is an iOS native App, so no web-template runtime, browser console, or Sites deployment claim applies. Physical devices, iOS 15 execution, VoiceOver, device contrast settings, live signed updates, signing, and store acceptance remain unrun. Simulator screenshots and tests do not establish those layers.

## Follow-up polish

None required beyond the recorded P2 repair. User visual acceptance remains separate from this implementation check.
