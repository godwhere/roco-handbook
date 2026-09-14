# ADR-0022: Platform-Native Navigation Materials

- Status: Accepted
- Date: 2026-09-14
- Phase: 8

## Context

The App needs a more polished platform identity without placing translucent material behind dense creature data, long descriptions, filters, or reference tables. iOS 26 provides the native Liquid Glass navigation language, while Android 16 aligns with Material 3 Expressive. Flutter 3.47.2 supports iOS 26 but does not yet provide complete framework-level Liquid Glass parity, so a Flutter blur imitation would not satisfy the native iOS requirement.

## Decision

- The creature root uses a branded Flutter hero instead of an ordinary top bar. Other iOS top navigation and the root bottom navigation use a bounded UIKit platform-view bridge. The bridge owns native `UINavigationBar` and `UITabBar` instances, and Flutter retains page content, repository state, and route ownership.
- On iOS 26 and later, the UIKit navigation components keep their system appearance so the operating system supplies Liquid Glass, contrast adaptation, and accessibility behavior. No custom blur, tint background, or simulated glass shader overrides the system material.
- On iOS 15 through 25, the same native components use a system-material blur fallback. The fallback preserves navigation and legibility without claiming Liquid Glass support.
- Flutter retains bottom-destination hit testing and semantics through transparent labeled regions over the native bar, then sends selected-state updates to UIKit. Back actions cross a per-view method channel; the creature-root Catalog version and information actions remain live Flutter controls inside the branded hero. No domain data or personal data crosses the platform boundary.
- Widget tests running outside iOS use a Cupertino fallback with the same labels and actions. Production iOS always selects the registered UIKit view.
- Android uses Flutter Material 3 `AppBar`, `NavigationBar`, sheets, and existing controls. The four icon-and-label bottom destinations sit inside an opaque safe-area-aware floating stadium surface with 16 logical pixels of horizontal margin, a tonal fill, a light outline, and low shadow elevation. The selected destination retains the Material pill indicator and icon scale. Every destination keeps its localized visible label, semantics, and stable automation key. Android does not copy iOS translucency.
- The shared root `Scaffold` extends its body behind the bottom navigation on both platforms. Child roots do not consume the bottom safe area, while Catalog result scroll views add the scaffold-provided inset to their final padding. Seven overlapping clipped backdrop layers begin nearly clear and accumulate blur toward the screen edge; a low-alpha surface gradient masks their boundaries. This progressive transition replaces the earlier uniform six-sigma blur without copying the iOS system material onto Android. More content remains visible beneath the floating silhouette without trapping the last card behind it.
- Glass remains restricted to iOS navigation. Creature cards, skill cards, reference panels, sheets, and long-form reading surfaces remain opaque or tonal on both platforms.
- The change adds no package dependency, runtime asset, network request, Catalog field, or personal-data migration.

## Consequences

The two platforms share a floating bottom-navigation silhouette but intentionally differ in material while preserving identical destinations, data, and task flow. iOS navigation requires the native Runner registration and an iOS build to validate; Flutter widget tests alone cannot prove the platform view. Android remains entirely inside the existing Flutter rendering and accessibility tree.

Future navigation destinations must update both the Flutter label contract and the UIKit item list. Store screenshots must be regenerated after this visual change.
