# ADR-0029: Tencent Catalog mirror staging

- Status: accepted for server preparation; public activation deferred
- Date: 2026-10-19
- Phase: 7, hosting preparation follow-up

## Context and authorization

The owner requested a domestic fallback when GitHub downloads cannot connect, authorized use of the existing Tencent server and `time9.site`, and then requested server deployment first. DNS now points to the owned server. The server is in Shanghai and the Tencent ICP console explicitly reports `time9.site` as not filed. There is no existing public HTTP/TLS service or certificate to reuse.

## Decision and allowed paths

Prepare a static Nginx service using the existing Ubuntu package source. Reuse the complete-Catalog archive builder; do not add a backend or a second installer. The active listener is loopback-only at port 8081. Keep the domain's public HTTPS configuration inactive until ICP approval, trusted certificate installation, firewall review, and external verification.

Repository changes are limited to `deploy/catalog-mirror/`, `AGENTS.md`, `README.md`, this decision, the independent-update feature document, the corresponding Phase 7 evidence, and `docs/implementation-reports/phase-7.md`. Server changes are limited to the Nginx package and its configuration, `/srv/roco-catalog/`, and invocation-owned staging/log files. Preserve Timeline, its databases and secrets, existing firewall rules, and host networking configuration.

The real existing Catalog v2 may be packaged and staged privately for transport checks without a new import or data version. No signed discovery envelope, GitHub Release, new signing key, or public package release is created. The App's existing GitHub-only allowlist remains unchanged. This decision does not enable App fallback, weaken HTTPS or publisher authentication, expose personal data, or extend the update package to images or executable code.

## Acceptance and stopping conditions

Validate the existing Catalog and generated archive, compare the installed and downloaded SHA-256 values, execute `nginx -t`, test HTTP methods and allowed paths, verify missing/hidden/symlink rejection and HEAD/range behavior, and confirm systemd enablement and the loopback listener. Confirm Timeline remains active. Run `git diff --check` and review the complete allowed diff; deliver the scoped record through GitHub Desktop.

Stop before public activation while ICP approval or a trusted certificate is absent. Record internal service acceptance separately from public TLS, a real signed update, App fallback, regional performance, and physical-iPhone acceptance. No credentials or certificate keys enter the repository.

## Consequences

The static serving boundary can be prepared and tested now. Public hosting and native fallback remain explicit later acceptance gates. Nginx is a server-only dependency from the existing Ubuntu repository; application dependency declarations and lockfiles are unaffected. The immutable Chinese specification remains unchanged.

Tencent's current [blocking policy](https://cloud.tencent.com/document/faq/243/20220) requires the appropriate ICP filing or access approval for mainland hosting. The observed console result, configuration versions, artifact hashes, and actual checks belong in the deployment evidence.
