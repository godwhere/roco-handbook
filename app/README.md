# Historical Flutter client and shared assets

ADR-0023 moves active client development and future releases to the Swift/SwiftUI iOS application in `../ios/`. Android is outside the current delivery scope. This directory retains the preceding Flutter implementation, tests, platform projects, and signing utility as migration evidence; it is not a second supported release target.

The immutable offline assets remain here to avoid moving or duplicating validated content. The native build stages the current Catalog data version 2, active Wiki image version 3, Tool and font version 1 assets, and frozen JSON contracts using `../ios/prepare_resources.py`. Its personal SQL asset must remain identical to `../schemas/user_v1.sql`.

Catalog version 2 contains 621 concrete forms, 466 handbook entries, 824 skills, 311 Learnsets, and 273 evolution groups. Upstream snapshots, identities, schemas, public signing trust, images, and attribution are preserved. The prior Flutter source version remains `1.1.0+2`; it does not describe the native App version.

Use the native project and validation commands in `../ios/README.md`. Physical Flutter-to-Swift upgrade acceptance remains open; the preceding implementation should be retained until that boundary is verified.
