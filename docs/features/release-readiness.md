# V1 release readiness

## Version identity

The first candidate uses App version `1.0.0`, build number `1`, Catalog schema version `1`, Catalog data version `1`, and User schema version `1`. Settings displays the App version and the installed data versions independently.

## Offline release gate

Run the Catalog release check from the repository root:

```bash
PYTHONDONTWRITEBYTECODE=1 PYTHONPATH=tools python3 tools/release/check_catalog.py \
  --release data/release/1
```

The validator reads only tracked local inputs. It checks package shape, hashes, complete source traceability, schema objects, SQLite integrity and foreign keys, stable probe results, truthful coverage, reviewed removals, and the absence of transaction sidecars or placeholder metadata. It never imports from BWIKI, writes the release database, signs an App, or uploads anything.

The default GitHub Actions workflow runs the Python and Flutter contract suites without upstream access or release credentials. All third-party actions are pinned to immutable commits and workflow permissions are read-only.

## Permissions and licenses

The Android release manifest requests no Internet or sensitive permission. Flutter's debug and profile tooling manifests request Internet access for development only and are not merged into the release candidate. The iOS App has no protected-resource usage-description keys.

Settings provides **Open-source licenses**, backed by Flutter's packaged license registry. Catalog data attribution and third-party runtime dependency notices are maintained in `licenses/` and the immutable Catalog attribution asset.

## Candidate and publication boundary

`release/1.0.0+1/` records the Catalog check, candidate identity, exact locally built artifact hashes, release notes, known limitations, and manual-gate status. Generated App binaries stay outside Git.

An unsigned Android bundle or no-codesign iOS App is a local build candidate, not a store-submittable archive. Physical-device evidence, platform signing, archive/export, upload, store review, and publication each require their own successful run and authority. The project does not infer any of those results from unit tests, emulators, simulators, or a successful compilation.
