# ADR-0033: Native interface language selection

- Status: accepted
- Date: 2026-10-26
- Scope: Phase 14 native Settings and existing localization resources
- Related: ADR-0023, ADR-0032

## Context and authorization

The user requested a language-switching control in Settings. The native App already bundles English and Simplified Chinese interface resources. A local preference can reuse those resources and the existing personal settings table without changing the Catalog, source terminology, or system configuration.

## Decision

`InterfaceLanguage` defines `system`, `zh-Hans`, and `en`. `UserRepository` stores the raw value as a JSON string under the existing `interface_language` key. Missing, malformed, or unsupported values resolve to `system`. This needs no SQL change or personal schema migration and is independent of both saved layouts and all personal records.

`HandbookLocalization` selects a specific bundled localization and supplies the existing `tr` entry point. Follow System uses Foundation's preferred-localization matching against `en` and `zh-Hans`, with English as the default. A missing translated key falls back to English and then to the key. The App supplies the selected locale to SwiftUI. It never rewrites `AppleLanguages`, swizzles bundles, contacts a service, or changes system settings. Canonical game text and personal notes remain verbatim. Home-screen naming and system-owned controls follow iOS behavior.

The App saves the preference before publishing it. A failed write retains the preceding interface and uses the existing error surface. Settings exposes a native menu in Appearance, with recognizable language names, an accessible value, a minimum 44-point target, and a vertically growing layout at accessibility text sizes. The menu is unavailable during update work, Catalog work, or an in-progress language save.

The selected Settings tab and its operation state survive language changes. The other three tabs rebuild their navigation roots so cached App-owned labels refresh. Existing session-generation changes still reset navigation after Catalog replacement. The language choice is read from the independent personal database at startup and survives Catalog recovery.

## Acceptance and allowed boundary

Changes are limited to the language contract and repository methods, translation helper, App state/root, Settings control, both localization resources, focused Core/UI tests, mapped documentation, and Phase 14 evidence. No new dependencies, data imports, Catalog records, SQL changes, immutable assets, network paths, or release settings are authorized.

Core tests cover preference matching, explicit overrides, invalid stored values, restart persistence and personal-data isolation, real localization resources, English/key fallback, and unchanged system language preferences. Native tests cover immediate Settings/tab translation, staying on Settings, persistence under an opposing launch locale, Catalog recovery, return to Follow System, and accessibility-text reachability. Build, packaging, scoped review, visual captures, and documentation checks precede GitHub Desktop delivery. Results and unrun device/release layers belong in the Phase 14 report and evidence.
