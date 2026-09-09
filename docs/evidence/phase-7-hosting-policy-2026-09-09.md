# Phase 7 hosting and distribution policy evidence

- Evidence date: 2026-09-09
- Scope: public static hosting feasibility, redirect boundary, and store-policy risk
- Decision status: initial feasibility evidence. GitHub Releases, the redirect boundary, the foreground UX, and synchronized key custody were accepted on 2026-09-10 in ADR-0013. No Release was created.

## GitHub Releases feasibility

GitHub documents Releases as a mechanism for packaging deployable software with downloadable binary assets. A release may have up to 1,000 assets, every asset must be smaller than 2 GiB, and the documented release quota has no total-size or bandwidth limit. The current Catalog is far below the per-asset limit.

GitHub's release-asset API documentation says a public asset can be fetched without authentication. A binary request can return either `200 OK` or `302 Found`, so any client must treat a redirect as an explicit protocol event rather than enabling unrestricted redirect following. GitHub's network reference lists `release-assets.githubusercontent.com` as the domain needed to download release assets and states that listed domains remain constant even when their underlying CNAME records change.

These facts made GitHub Releases a viable candidate for the first public complete-package trial. It was subsequently selected in ADR-0013; selection is not an availability guarantee. The accepted transport boundary is:

- fetch a fixed discovery URL on `github.com` over HTTPS;
- allow at most one HTTPS redirect to the exact host `release-assets.githubusercontent.com` on the default port;
- reject credentials, query injection, fragments, downgrade, additional redirects, and every other host;
- require an immutable versioned release URL inside the signed payload rather than treating a mutable `latest` URL as package identity; and
- retain signed length and SHA-256 validation over the final received bytes.

The public repository does not require an App-embedded GitHub token. No GitHub REST dependency is used for the direct asset URL. Availability, regional reachability, status behavior, caching, and redirect observations against a real owned Release still require a controlled trial when a real newer Catalog exists.

## Apple distribution risk

Apple App Review Guideline 2.5.2 prohibits downloading code that introduces or changes App functionality. The current protocol is intentionally limited to a SQLite database, a data-only JSON manifest, and plain-text attribution; it rejects Dart, Lua, executable code, dynamic libraries, arbitrary SQL, and additional archive entries. This is consistent with a data-only design, but only App Review can determine acceptance.

Guideline 4.2 is a separate, material release risk: Apple says an App must provide adequate utility and an app-like experience, and specifically warns that an App that is simply a book or game guide belongs in Apple Books. The existing offline search, structured filters, relationship navigation, favorites, collection tracking, personal notes, validation, and recovery flows should be presented as interactive utility beyond a static guide. This is an implementation and submission-positioning inference, not evidence of approval.

Guideline 5.2 also requires rights to third-party content and authorization for third-party services. Existing attribution and non-commercial status do not replace a release-time rights review.

## Google Play distribution risk

Google Play's Device and Network Abuse policy prohibits self-updating outside Google Play and downloading executable code such as DEX, JAR, or native libraries from another source. The current exact-entry, data-only package boundary and the prohibition on executable Lua or SQL are designed to avoid that behavior. This is a policy-oriented design inference, not a store acceptance result.

The first transport should remain a user-initiated foreground data transfer with visible size, progress, cancellation, and retry behavior. Background update work, executable content, arbitrary endpoints, and App-binary replacement remain outside the approved scope.

## Sources

- GitHub Docs, [About releases](https://docs.github.com/en/repositories/releasing-projects-on-github/about-releases)
- GitHub Docs, [REST API endpoints for release assets](https://docs.github.com/en/rest/releases/assets)
- GitHub Docs, [Self-hosted runners reference: accessible domains](https://docs.github.com/en/actions/reference/runners/self-hosted-runners#accessible-domains-by-function)
- Apple Developer, [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- Google Play Console Help, [Device and Network Abuse](https://support.google.com/googleplay/android-developer/answer/16559646?hl=en)

## Decision follow-up

The repository owner approved GitHub Releases, the exact one-redirect policy, the user-triggered foreground UX, and current iCloud-synchronized key custody on 2026-09-10. ADR-0013 and `phase-7-github-release-transport-2026-09-10.md` record the implemented boundary and current probe. Store policy must still be checked again immediately before submission because the cited policies can change.
