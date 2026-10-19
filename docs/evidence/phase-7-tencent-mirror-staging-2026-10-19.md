# Phase 7 Tencent mirror staging evidence

- Evidence date: 2026-10-19, Asia/Shanghai
- Decision: ADR-0029
- Result: private server deployment accepted; public activation blocked by missing ICP approval and TLS acceptance

## Observed ownership and readiness

The owner identified `time9.site` in the authenticated Tencent domain console and authorized using the existing Tencent server for Catalog downloads. An A record for the root domain was created with TTL 600. Both authoritative servers, `calf.dnspod.net` and `leila.dnspod.net`, returned `124.220.51.72` after the change. Domain registration is valid; this is separate from ICP approval.

Instance metadata identifies the region as `ap-shanghai`. The authenticated Tencent ICP console explicitly displays `time9.site` with status **not filed**. The deployment therefore leaves public HTTP/HTTPS listeners and the existing firewalls unchanged. Public TLS or regional availability is not inferred from DNS or an internal response. Tencent's [mainland blocking policy](https://cloud.tencent.com/document/faq/243/20220) remains a public activation prerequisite.

## Deployed server state

- Ubuntu 22.04.5 LTS; `nginx-light` package `1.18.0-6ubuntu14.21` from the existing Tencent-hosted Ubuntu update/security repository
- Four server packages newly installed; no existing packages upgraded or removed; no application dependencies or lockfiles changed
- Nginx enabled in systemd and listening only at `127.0.0.1:8081`
- Active configuration and shared route restrictions match `deploy/catalog-mirror/`; the public HTTPS template is installed but not enabled
- Public data directory: `/srv/roco-catalog/public`; root-only staging and acceptance records: `/srv/roco-catalog/staging`
- The package-created default-site link was disabled; its source configuration was retained
- Timeline remained active with the same process during deployment, its listener stayed at `127.0.0.1:3000`, and host firewall rules were unchanged
- No private signing key, certificate key, cookie, personal database, application source, or new public upload endpoint was installed

## Real internal artifact

The existing offline `catalog_builder build-complete-update` command validated `data/release/2` and built a new archive outside the checkout. No upstream import, source revision, immutable release directory, or data version changed.

| Field | Value |
| --- | --- |
| Catalog data version | 2 |
| Internal path | `/roco/catalog-data-v2/catalog-v2.zip` |
| Bytes | 889409 |
| SHA-256 | `805210c80c41922a88d87a188a5ee4e0c715570200ffcb624847de0a04b2333a` |
| ZIP contents | Existing bundled manifest, Catalog database, attribution; three entries, valid CRCs |
| Discovery | Absent; `/roco/catalog-manifest.json` returns 404 with `no-store` |

This archive is privately staged for transport checks. It is not a signed release or an App-visible update.

## Acceptance results

The server integration check passed all 12 groups:

1. Readiness JSON.
2. Full real-archive download, exact length and SHA-256, identity encoding, and immutable successful-response cache policy.
3. HEAD with the exact archive length and no body.
4. Correct 32-byte partial response and Content-Range.
5. Unpublished discovery returns 404 without caching.
6. Hidden files, directory paths, unrelated paths, and missing archives return 404; missing archives are not cached as immutable.
7. POST/upload attempt returns 405.
8. An unrelated Host is rejected.
9. A temporary owned symlink is rejected and removed after the check. The initial test expected 403; Nginx's `try_files` returns 404 for this refusal. The final assertion accepts either refusal status and still fails on successful file delivery.
10. The actual three-entry ZIP passes CRC checks.
11. `nginx -t`, service restart, readiness after restart, and boot enablement.
12. Loopback-only deployment and the existing Timeline listener/service.

The deployment's private records are `deployment.log` and `acceptance.json` under `/srv/roco-catalog/staging`. Native-client and source-pipeline behavior were not changed; the App still accepts only its fixed GitHub URLs.

The three installed configuration files were read back and matched the checkout's SHA-256 values. Only invocation-owned temporary uploads and the negative-test symlink were removed. The focused repository command `PYTHONDONTWRITEBYTECODE=1 PYTHONPATH=tools python3 -m unittest discover -s tests -p 'test_project_structure.py'` passed all 12 tests. Tracked/new-file whitespace checks, the exact 10-file allowlist, local Markdown links, and new-artifact English checks passed. The complete new files and tracked diff were reviewed before GitHub Desktop delivery.

## Not run and next boundary

- Public web activation, public certificate issuance/renewal, external TLS or HTTP download, regional bandwidth measurement, and reboot acceptance
- ICP submission, identity verification, or approval
- Signed discovery generation, signing-key use, GitHub Release publication, or two-source publication automation
- Native fallback, public-network interruption/recovery, or physical-iPhone update acceptance
- The full Python suite, Swift XCTest, and iOS UI tests; this slice changes no client or data-pipeline implementation

Complete the owner's ICP process first. Then install a valid certificate and renewal process, validate and enable the public template, review only the required web firewall rules, and verify downloads from an independent network without bypassing TLS verification. The separate native fallback and signed publication workflow follow that hosting acceptance.
