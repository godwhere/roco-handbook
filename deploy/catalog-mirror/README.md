# Tencent Catalog mirror operations

This Phase 7 hosting slice prepares an independent static Catalog download service on the existing Shanghai Tencent server for `time9.site`. ADR-0029 defines its boundary. The App continues to use the fixed GitHub Releases transport.

## Current deployment boundary

The active site listens only on `127.0.0.1:8081`. The public HTTPS configuration is an inactive template. Tencent's console reports the domain as **not filed** for ICP; public activation must wait for approval, certificate installation, and external acceptance. Installing a server package or configuring DNS does not establish public readiness.

The server uses the Ubuntu-maintained `nginx-light` package, its existing `www-data` worker identity, and systemd. No App dependency or lockfile changes are required. The web root is `/srv/roco-catalog/public`; `/srv/roco-catalog/staging` is root-only. Signing keys, credentials, personal databases, and application source never belong in either published path. The existing Timeline service is independent and is not reverse-proxied by this site.

## Installed configuration

| Repository file | Server destination |
| --- | --- |
| `nginx-locations.conf` | `/etc/nginx/snippets/roco-catalog-locations.conf` |
| `nginx-staging.conf` | `/etc/nginx/sites-available/roco-catalog-staging.conf`, linked from `sites-enabled` |
| `nginx-production.conf.example` | `/etc/nginx/sites-available/roco-catalog-production.conf.example`, inactive |

Only GET and HEAD are accepted. Routes expose the readiness response, root notice, exact discovery filename, and versioned ZIP filenames. Directory listing, symlinks, unrelated paths, uploads, reverse proxying, dynamic code, and response compression are disabled. Access logging is disabled; ordinary Nginx error diagnostics remain on the server.

## Package preparation and publication

Use the existing offline builder against a validated immutable release:

```sh
PYTHONDONTWRITEBYTECODE=1 PYTHONPATH=tools python3 -m catalog_builder build-complete-update \
  --release data/release/2 --output /tmp/roco-catalog-v2.zip
```

The output must be new: the builder refuses overwrite. Transfer the archive to the private staging directory, compare its SHA-256 with the builder report, then install it as a regular root-owned file at `/srv/roco-catalog/public/roco/catalog-data-v2/catalog-v2.zip`. Never overwrite a versioned archive. An existing matching hash is an idempotent no-op; a differing hash stops publication.

The initial deployment stages the real Catalog v2 ZIP for internal transport checks. It publishes no signed discovery manifest and creates no GitHub Release. A discovery request therefore returns 404. Do not create placeholder manifests or synthetic Catalog versions.

Future publication must use the existing signing tools and the App's accepted protocol. Upload and verify every immutable archive before atomically replacing discovery with the identical authenticated envelope used by the primary source. Keep older published archives available. The future client must map a signed canonical package identity to a fixed mirror path while retaining signature, version, length, hash, archive, and database validation; editing a signed URL invalidates the envelope.

## Internal acceptance

Run these commands on the server:

```sh
sudo nginx -t
curl --noproxy '*' --fail -H 'Host: time9.site' http://127.0.0.1:8081/healthz
curl --noproxy '*' --fail -H 'Host: time9.site' \
  http://127.0.0.1:8081/roco/catalog-data-v2/catalog-v2.zip -o /tmp/roco-catalog-download.zip
sha256sum /tmp/roco-catalog-download.zip
```

Also check exact HEAD length, a bounded byte-range response, discovery 404, missing-file 404 without immutable caching, rejection of POST, hidden files, directory listing, unrelated hosts, and symbolic links. Confirm the service is enabled after a restart, that its listener remains loopback-only, and that Timeline and its loopback listener remain active. Internal HTTP tests are deployment diagnostics; they do not alter the App's HTTPS-only policy or prove public TLS or iPhone acceptance.

## Public activation after ICP approval

1. Verify `time9.site` ICP approval and Tencent access status in the console, together with current authoritative DNS.
2. Obtain a trusted public certificate covering `time9.site` and establish a renewal procedure. Install the chain at `/etc/ssl/roco-catalog/fullchain.pem` and the root-only private key at `/etc/ssl/roco-catalog/privkey.pem`; keep their directory root-only. Never commit or expose these files.
3. Review and enable the production template, retaining the private staging listener for diagnostics. Run `sudo nginx -t` before reloading. Permit only the required HTTP/HTTPS ports in the host and Tencent firewalls; preserve existing administration rules.
4. Verify hostname and certificate chain without bypassing TLS verification, HTTP-to-HTTPS redirection, exact response bytes and SHA-256 from an independent network, renewal, and missing/invalid-package behavior.
5. Deliver the separately requested native-client fallback and signed publication workflow before advertising an available App update source.

Rollback is a validated Nginx configuration reload that disables only this site's public listener. Preserve versioned packages, private certificate material, existing services, and all personal data. Do not sweep the web root or server directories.
