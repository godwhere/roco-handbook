# ADR-0021: Creature Catalog Layout Preference

- Status: Accepted
- Date: 2026-09-14
- Phase: 8

## Context

The creature Catalog needs a more visual two-column browsing mode while retaining the existing compact horizontal list for users who prefer denser scanning. The choice must survive App restarts and Catalog replacement without introducing a second preferences store or coupling personal state to the read-only Catalog.

## Decision

- The creature Catalog supports `grid` and `list` layouts over the same query, filter, pagination, and detail-navigation state.
- `grid` is the default when no saved preference exists. It uses two columns on phone widths and three columns when at least 720 logical pixels are available.
- `list` preserves the existing horizontal full-illustration card presentation.
- Settings exposes one localized segmented control for the two layouts.
- The typed preference is stored as JSON in the existing `user.db.settings` row with key `pet_catalog_layout` through `UserRepository`.
- Missing, malformed, or unsupported values fall back to `grid`. The preference does not block Catalog startup.
- Catalog install, update, restore, and rollback do not read, replace, or delete the preference.
- Both layouts use the same bundled illustration and type-icon paths. Neither layout adds a runtime image or data request.

## Consequences

No Catalog or personal schema migration is required. The setting remains device-local and may be removed when the App is uninstalled. Widget and repository tests cover the default, persistence, layout switch, two-column phone geometry, and retained list mode.
