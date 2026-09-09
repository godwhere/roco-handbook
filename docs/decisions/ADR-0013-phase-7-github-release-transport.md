# ADR-0013: Phase 7 GitHub Release transport and foreground update flow

- Status: accepted
- Date: 2026-09-10
- Scope: complete-Catalog discovery, download, consent, cancellation, and runtime activation

## Context

ADR-0010 requires an approved host and foreground user experience before runtime network access. ADR-0011 and ADR-0012 already provide publisher authentication, strict complete-ZIP validation, replay protection, and the sole Catalog installation state machine. The repository owner explicitly accepted the current iCloud-synchronized signing-key custody model, approved GitHub Releases, and directed the project to retain the original complete-package plan instead of changing to App Store differential App delivery.

The first runtime capability must retrieve data only. It must not update the App binary, execute downloaded code, contact BWIKI, introduce accounts or cloud synchronization, or mutate `user.db`. A real data version 2 does not yet exist, so runtime enablement must not fabricate or publish an update merely to populate the channel.

## Decision

GitHub Releases in the public `godwhere/roco-handbook` repository is the only V1 Catalog update host. The App embeds no GitHub token and does not call the GitHub REST API.

Discovery uses this fixed asset URL:

```text
https://github.com/godwhere/roco-handbook/releases/download/catalog-channel/catalog-manifest.json
```

Every signed complete package for data version `N` must use exactly:

```text
https://github.com/godwhere/roco-handbook/releases/download/catalog-data-vN/catalog-vN.zip
```

The publisher rejects any other host, repository, tag, filename, query, fragment, credential, nonstandard port, traversal segment, or version mismatch. `catalog-channel` is the mutable discovery release; `catalog-data-vN` is the immutable package release. A missing discovery asset means no update is currently published.

The client uses `dart:io` directly and adds no third-party HTTP dependency. It disables automatic redirects and response decompression. An initial request may return `200`, or exactly one `302` to `https://release-assets.githubusercontent.com:443/github-production-release-asset/...`. The redirect may carry GitHub delivery query parameters, but it may not contain credentials or a fragment. Every other host, path prefix, status, downgrade, or additional redirect is rejected. The original GitHub URL itself never accepts a query, fragment, or credentials.

Response headers and streamed bytes are independently bounded. The discovery envelope is limited to 128 KiB. The complete package is limited by the authenticated manifest, with a protocol maximum of 128 MiB. Non-identity content encoding, a conflicting declared length, excessive streamed bytes, truncated content, or a SHA-256 mismatch fails before archive decoding. Connection, response, and stream-idle timeouts are finite.

Settings is the only trigger. The App performs no startup check, timer, background fetch, automatic download, or automatic retry. A check first authenticates and validates the manifest. A signed manifest matching the installed data version and accepted release sequence reports that the Catalog is current. A newer candidate displays its data version and complete download size and requires a separate **Download** confirmation using the current network connection.

The transfer exposes byte progress and **Cancel**. Cancellation aborts the active response and discards partial in-memory bytes. Once all bytes have arrived, the UI changes to **Verifying and installing...** and cancellation is removed because ADR-0012's validation, replay-state, and pointer transaction has begun. A failure remains explicitly retryable and does not trigger an automatic retry.

After successful installation, the App creates a new read-only Catalog repository, updates the visible session, and retains the existing personal repository. Catalog-backed page state is recreated for the new data version. The installer remains the only owner of staging, validation, activation, rollback, retention, attribution, and replay state.

Android production adds only `android.permission.INTERNET`. iOS uses standard HTTPS and adds no protected-resource usage description or App Transport Security exception. Neither platform schedules background update work.

The runtime-enabled source advances from the preserved Phase 6 candidate identity `1.0.0 (1)` to `1.1.0 (2)`. Existing candidate records and artifact hashes remain immutable.

This is an in-App Catalog data download. It is not App self-update behavior and is independent of any App Store optimization or differential delivery that a store may apply to App binaries. Logical Catalog patches remain deferred until complete-package production-like evidence demonstrates a need and a separate protocol is accepted.

## Publication boundary

No GitHub Release or production Catalog payload is created by this decision. The first real publication requires a validated immutable data version greater than 1, its complete ZIP, the exact versioned package URL, a reviewed canonical payload, external production signing, upload of the immutable package release, and then publication of the signed discovery envelope. A failed or partial publication must leave discovery absent or pointing to the prior valid envelope.

## Consequences

The production App can now perform a bounded, user-authorized foreground Catalog check and complete-package update while preserving offline first launch and personal-data isolation. The fixed discovery URL currently returns no published update, which is the expected safe state before data version 2 exists. Real package transfer, interruption, low-storage behavior, physical-device behavior, regional availability, signing, upload, and store acceptance remain unproven until their respective evidence gates run.
