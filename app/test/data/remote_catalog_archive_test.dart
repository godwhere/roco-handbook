import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roco_handbook/data/catalog/catalog_installer.dart';
import 'package:roco_handbook/data/catalog/remote_catalog_archive.dart';
import 'package:roco_handbook/data/catalog/remote_catalog_manifest.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  late Directory temporary;
  late Uint8List databaseBytes;
  late String catalogManifestText;
  late String attributionText;
  late Uint8List validArchiveBytes;

  setUp(() {
    temporary = Directory.systemTemp.createTempSync('roco-remote-archive-');
    final databaseFile = File('${temporary.path}/catalog-v2.db')
      ..writeAsBytesSync(
        File('assets/catalog/catalog.db').readAsBytesSync(),
        flush: true,
      );
    final database = sqlite3.open(databaseFile.path, mode: OpenMode.readWrite);
    database.execute(
      'UPDATE catalog_meta SET data_version = 2, snapshot_id = ? '
      'WHERE singleton = 1',
      <Object?>['snapshot-phase7-archive-v2'],
    );
    database.execute(
      "UPDATE pets SET name = 'Remote archive creature' "
      "WHERE pet_id = 'pet_000001'",
    );
    database.close();
    databaseBytes = databaseFile.readAsBytesSync();

    final manifest = jsonDecode(
      File('assets/catalog/bundled_catalog.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    manifest['data_version'] = 2;
    manifest['snapshot_id'] = 'snapshot-phase7-archive-v2';
    manifest['database_bytes'] = databaseBytes.length;
    manifest['database_sha256'] = sha256.convert(databaseBytes).toString();
    catalogManifestText = jsonEncode(manifest);
    attributionText = File('assets/catalog/ATTRIBUTION.txt').readAsStringSync();
    validArchiveBytes = _encode(
      _entries(
        manifestText: catalogManifestText,
        databaseBytes: databaseBytes,
        attributionText: attributionText,
      ),
    );
  });

  tearDown(() {
    temporary.deleteSync(recursive: true);
  });

  test(
    'decodes an exact package and hands it to the existing installer',
    () async {
      final decoded = const RemoteCatalogArchiveDecoder().decode(
        manifest: _remoteManifest(validArchiveBytes),
        archiveBytes: validArchiveBytes,
      );

      expect(decoded.bundle.manifestText, catalogManifestText);
      expect(decoded.bundle.databaseBytes, databaseBytes);
      expect(decoded.bundle.attributionText, attributionText);

      final installer = LocalCatalogInstaller(
        '${temporary.path}/support',
        backgroundWork: false,
      );
      await installer.prepareBundledCatalog(
        BundledCatalogBundle(
          manifestText: File('assets/catalog/bundled_catalog.json')
              .readAsStringSync(),
          databaseBytes: File('assets/catalog/catalog.db').readAsBytesSync(),
          attributionText: attributionText,
        ),
      );
      final installed = await decoded.installWith(installer);
      expect(installed.manifest.dataVersion, 2);
      expect(installed.outcome, CatalogOpenOutcome.installedRemote);
      expect(await installer.readHighestAcceptedRemoteReleaseSequence(), 2);
      final database = sqlite3.open(
        installed.databasePath,
        mode: OpenMode.readOnly,
      );
      addTearDown(database.close);
      expect(
        database
            .select("SELECT name FROM pets WHERE pet_id = 'pet_000001'")
            .single['name'],
        'Remote archive creature',
      );
    },
  );

  test(
    'authenticates, decodes, and installs through the offline pipeline',
    () async {
      final installer = LocalCatalogInstaller(
        '${temporary.path}/support',
        backgroundWork: false,
      );
      await installer.prepareBundledCatalog(
        BundledCatalogBundle(
          manifestText: File('assets/catalog/bundled_catalog.json')
              .readAsStringSync(),
          databaseBytes: File('assets/catalog/catalog.db').readAsBytesSync(),
          attributionText: attributionText,
        ),
      );
      final signed = await _signArchiveManifest(validArchiveBytes);

      final installed = await const RemoteCatalogPackagePipeline()
          .verifyAndInstall(
            envelopeText: signed.envelopeText,
            archiveBytes: validArchiveBytes,
            context: RemoteCatalogValidationContext(
              currentAppVersion: '1.0.0',
              currentDataVersion: 1,
              highestAcceptedReleaseSequence: 99,
              allowedHosts: const {'updates.example.test'},
            ),
            verifier: signed.verifier,
            installer: installer,
          );

      expect(installed.outcome, CatalogOpenOutcome.installedRemote);
      expect(installed.manifest.dataVersion, 2);
      expect(await installer.readHighestAcceptedRemoteReleaseSequence(), 2);
    },
  );

  test(
    'requires a base Catalog and rejects an accepted release replay',
    () async {
      final decoded = const RemoteCatalogArchiveDecoder().decode(
        manifest: _remoteManifest(validArchiveBytes),
        archiveBytes: validArchiveBytes,
      );
      final installer = LocalCatalogInstaller(
        '${temporary.path}/support',
        backgroundWork: false,
      );

      await expectLater(
        decoded.installWith(installer),
        _installFailure('remote_base_missing'),
      );
      expect(await installer.readHighestAcceptedRemoteReleaseSequence(), 0);

      final bundled = BundledCatalogBundle(
        manifestText: File('assets/catalog/bundled_catalog.json')
            .readAsStringSync(),
        databaseBytes: File('assets/catalog/catalog.db').readAsBytesSync(),
        attributionText: attributionText,
      );
      await installer.prepareBundledCatalog(bundled);
      await decoded.installWith(installer);
      await installer.restoreBundledCatalog(bundled);

      expect(await installer.readHighestAcceptedRemoteReleaseSequence(), 2);
      await expectLater(
        decoded.installWith(installer),
        _installFailure('remote_release_sequence'),
      );
    },
  );

  test(
    'burns a sequence if activation fails after its safe-state commit',
    () async {
      final decoded = const RemoteCatalogArchiveDecoder().decode(
        manifest: _remoteManifest(validArchiveBytes),
        archiveBytes: validArchiveBytes,
      );
      final supportPath = '${temporary.path}/support';
      final bundled = BundledCatalogBundle(
        manifestText: File('assets/catalog/bundled_catalog.json')
            .readAsStringSync(),
        databaseBytes: File('assets/catalog/catalog.db').readAsBytesSync(),
        attributionText: attributionText,
      );
      await LocalCatalogInstaller(
        supportPath,
        backgroundWork: false,
      ).prepareBundledCatalog(bundled);

      final failed = await decoded.installWith(
        LocalCatalogInstaller(
          supportPath,
          backgroundWork: false,
          faultPoint: CatalogInstallerFaultPoint.failAfterPointerCommit,
        ),
      );

      expect(failed.outcome, CatalogOpenOutcome.recoveredPrevious);
      expect(failed.manifest.dataVersion, 1);
      expect(
        await LocalCatalogInstaller(
          supportPath,
          backgroundWork: false,
        ).readHighestAcceptedRemoteReleaseSequence(),
        2,
      );
    },
  );

  test(
    'does not advance replay state for a database rejected before activation',
    () async {
      final supportPath = '${temporary.path}/support';
      final bundledDatabase = File('assets/catalog/catalog.db')
          .readAsBytesSync();
      final bundled = BundledCatalogBundle(
        manifestText: File('assets/catalog/bundled_catalog.json')
            .readAsStringSync(),
        databaseBytes: bundledDatabase,
        attributionText: attributionText,
      );
      final installer = LocalCatalogInstaller(
        supportPath,
        backgroundWork: false,
      );
      await installer.prepareBundledCatalog(bundled);

      final invalidInner =
          jsonDecode(catalogManifestText) as Map<String, dynamic>
            ..['database_bytes'] = bundledDatabase.length
            ..['database_sha256'] = sha256.convert(bundledDatabase).toString();
      final archiveBytes = _encode(
        _entries(
          manifestText: jsonEncode(invalidInner),
          databaseBytes: bundledDatabase,
          attributionText: attributionText,
        ),
      );
      final decoded = const RemoteCatalogArchiveDecoder().decode(
        manifest: _remoteManifest(archiveBytes),
        archiveBytes: archiveBytes,
      );

      final result = await decoded.installWith(installer);
      expect(result.outcome, CatalogOpenOutcome.recoveredPrevious);
      expect(result.manifest.dataVersion, 1);
      expect(await installer.readHighestAcceptedRemoteReleaseSequence(), 0);
    },
  );

  test('fails closed when the persisted replay state is malformed', () async {
    final supportPath = '${temporary.path}/support';
    final state = Directory('$supportPath/catalog-state')
      ..createSync(recursive: true);
    File('${state.path}/catalog_update_state.json')
        .writeAsStringSync('{malformed', flush: true);
    final installer = LocalCatalogInstaller(supportPath, backgroundWork: false);

    await expectLater(
      installer.readHighestAcceptedRemoteReleaseSequence(),
      _installFailure('catalog_update_state'),
    );
  });

  test('checks the signed archive length and hash before ZIP decoding', () {
    final changed = Uint8List.fromList(validArchiveBytes)..[0] ^= 1;

    expect(
      () => const RemoteCatalogArchiveDecoder().decode(
        manifest: _remoteManifest(validArchiveBytes),
        archiveBytes: changed,
      ),
      _manifestFailure('package_hash'),
    );
  });

  test('rejects missing, unexpected, duplicate, and trailing entries', () {
    final baseEntries = _entries(
      manifestText: catalogManifestText,
      databaseBytes: databaseBytes,
      attributionText: attributionText,
    );
    final variants = <({Uint8List bytes, String code})>[
      (bytes: _encode(baseEntries.sublist(0, 2)), code: 'archive_shape'),
      (
        bytes: _encode(<ArchiveFile>[
          ...baseEntries.sublist(0, 2),
          ArchiveFile.string('../ATTRIBUTION.txt', attributionText),
        ]),
        code: 'archive_entries',
      ),
      (
        bytes: _encode(<ArchiveFile>[
          ...baseEntries,
          ArchiveFile.string(
            RemoteCatalogArchiveDecoder.manifestPath,
            catalogManifestText,
          ),
        ]),
        code: 'archive_shape',
      ),
      (
        bytes: Uint8List.fromList(<int>[...validArchiveBytes, 0]),
        code: 'archive_shape',
      ),
    ];

    for (final variant in variants) {
      expect(
        () => const RemoteCatalogArchiveDecoder().decode(
          manifest: _remoteManifest(variant.bytes),
          archiveBytes: variant.bytes,
        ),
        _archiveFailure(variant.code),
      );
    }
  });

  test('rejects encrypted and oversized entries before decompression', () {
    final encrypted = _encode(
      _entries(
        manifestText: catalogManifestText,
        databaseBytes: databaseBytes,
        attributionText: attributionText,
      ),
      password: 'test-only-password',
    );
    final oversized = _encode(<ArchiveFile>[
      ArchiveFile.string(
        RemoteCatalogArchiveDecoder.manifestPath,
        'A' * (64 * 1024 + 1),
      ),
      ArchiveFile.bytes(
        RemoteCatalogArchiveDecoder.databasePath,
        databaseBytes,
      ),
      ArchiveFile.string(
        RemoteCatalogArchiveDecoder.attributionPath,
        attributionText,
      ),
    ]);

    for (final bytes in <Uint8List>[encrypted, oversized]) {
      expect(
        () => const RemoteCatalogArchiveDecoder().decode(
          manifest: _remoteManifest(bytes),
          archiveBytes: bytes,
        ),
        _archiveFailure('archive_entry_contract'),
      );
    }
  });

  test('bounds actual output when a ZIP header understates its size', () {
    final oversized = _encode(<ArchiveFile>[
      ArchiveFile.string(
        RemoteCatalogArchiveDecoder.manifestPath,
        'A' * (64 * 1024 + 1),
      ),
      ArchiveFile.bytes(
        RemoteCatalogArchiveDecoder.databasePath,
        databaseBytes,
      ),
      ArchiveFile.string(
        RemoteCatalogArchiveDecoder.attributionPath,
        attributionText,
      ),
    ]);
    final understated = _replaceCentralUncompressedSize(
      oversized,
      RemoteCatalogArchiveDecoder.manifestPath,
      16,
    );

    expect(
      () => const RemoteCatalogArchiveDecoder().decode(
        manifest: _remoteManifest(understated),
        archiveBytes: understated,
      ),
      _archiveFailure('archive_entry_size'),
    );
  });

  test('rejects a CRC mismatch in a signed uncompressed ZIP', () {
    final bytes = _encode(
      _entries(
        manifestText: catalogManifestText,
        databaseBytes: databaseBytes,
        attributionText: attributionText,
        uncompressed: true,
      ),
    );
    final marker = utf8.encode('snapshot-phase7-archive-v2');
    final offset = _indexOf(bytes, marker);
    expect(offset, isNonNegative);
    final changed = Uint8List.fromList(bytes)
      ..[offset + marker.length - 1] ^= 1;

    expect(
      () => const RemoteCatalogArchiveDecoder().decode(
        manifest: _remoteManifest(changed),
        archiveBytes: changed,
      ),
      _archiveFailure('archive_entry_integrity'),
    );
  });

  test('rejects incomplete attribution and signed-to-inner mismatches', () {
    final incompleteAttribution = _encode(
      _entries(
        manifestText: catalogManifestText,
        databaseBytes: databaseBytes,
        attributionText: 'Roco World Offline Handbook - Catalog Attribution\n',
      ),
    );

    expect(
      () => const RemoteCatalogArchiveDecoder().decode(
        manifest: _remoteManifest(incompleteAttribution),
        archiveBytes: incompleteAttribution,
      ),
      _archiveFailure('archive_attribution_contract'),
    );
    expect(
      () => const RemoteCatalogArchiveDecoder().decode(
        manifest: _remoteManifest(validArchiveBytes, dataVersion: 3),
        archiveBytes: validArchiveBytes,
      ),
      _archiveFailure('archive_manifest_mismatch'),
    );
  });
}

List<ArchiveFile> _entries({
  required String manifestText,
  required Uint8List databaseBytes,
  required String attributionText,
  bool uncompressed = false,
}) {
  ArchiveFile file(String path, List<int> bytes) => uncompressed
      ? ArchiveFile.noCompress(path, bytes.length, bytes)
      : ArchiveFile.bytes(path, bytes);
  return <ArchiveFile>[
    file(RemoteCatalogArchiveDecoder.manifestPath, utf8.encode(manifestText)),
    file(RemoteCatalogArchiveDecoder.databasePath, databaseBytes),
    file(
      RemoteCatalogArchiveDecoder.attributionPath,
      utf8.encode(attributionText),
    ),
  ];
}

Uint8List _encode(
  List<ArchiveFile> entries, {
  String? password,
  String comment = '',
}) {
  final output = OutputMemoryStream();
  final encoder = ZipEncoder(password: password)
    ..startEncode(output, modified: DateTime.utc(2026, 9, 9));
  for (final entry in entries) {
    encoder.add(entry, autoClose: false);
  }
  encoder.endEncode(comment: comment);
  return output.getBytes();
}

VerifiedRemoteCatalogManifest _remoteManifest(
  Uint8List archiveBytes, {
  int dataVersion = 2,
}) {
  return VerifiedRemoteCatalogManifest(
    keyId: 'test-key',
    protocolVersion: 1,
    minimumProtocolVersion: 1,
    datasetId: 'roco-world-zh-cn',
    catalogSchemaVersion: 1,
    dataVersion: dataVersion,
    releaseSequence: dataVersion,
    minimumAppVersion: '1.0.0',
    publishedAtUtc: DateTime.utc(2026, 9, 9, 14),
    snapshotId: 'snapshot-phase7-archive-v$dataVersion',
    coverage: const <String, bool>{
      'pets': true,
      'skills': true,
      'evolutions': true,
      'topic_rewards': false,
      'skill_stone_topics': false,
      'description_note_definitions': false,
    },
    package: RemoteCatalogPackage(
      url: Uri.parse(
        'https://updates.example.test/full/catalog-v$dataVersion.zip',
      ),
      archiveBytes: archiveBytes.length,
      archiveSha256: sha256.convert(archiveBytes).toString(),
    ),
    signedPayloadBytes: Uint8List(0),
  );
}

int _indexOf(List<int> bytes, List<int> marker) {
  for (var offset = 0; offset <= bytes.length - marker.length; offset += 1) {
    var matches = true;
    for (var index = 0; index < marker.length; index += 1) {
      if (bytes[offset + index] != marker[index]) {
        matches = false;
        break;
      }
    }
    if (matches) {
      return offset;
    }
  }
  return -1;
}

Uint8List _replaceCentralUncompressedSize(
  Uint8List source,
  String targetName,
  int replacement,
) {
  final bytes = Uint8List.fromList(source);
  final view = ByteData.sublistView(bytes);
  const signature = 0x02014b50;
  const fixedHeaderBytes = 46;
  for (var offset = 0; offset <= bytes.length - fixedHeaderBytes;) {
    if (view.getUint32(offset, Endian.little) != signature) {
      offset += 1;
      continue;
    }
    final nameLength = view.getUint16(offset + 28, Endian.little);
    final extraLength = view.getUint16(offset + 30, Endian.little);
    final commentLength = view.getUint16(offset + 32, Endian.little);
    final nameStart = offset + fixedHeaderBytes;
    final name = utf8.decode(bytes.sublist(nameStart, nameStart + nameLength));
    if (name == targetName) {
      view.setUint32(offset + 24, replacement, Endian.little);
      return bytes;
    }
    offset = nameStart + nameLength + extraLength + commentLength;
  }
  throw StateError('The target ZIP entry was not found.');
}

Matcher _archiveFailure(String code) => throwsA(
  isA<RemoteCatalogArchiveException>().having(
    (error) => error.code,
    'code',
    code,
  ),
);

Matcher _manifestFailure(String code) => throwsA(
  isA<RemoteCatalogManifestException>().having(
    (error) => error.code,
    'code',
    code,
  ),
);

Matcher _installFailure(String code) => throwsA(
  isA<CatalogInstallException>().having((error) => error.code, 'code', code),
);

Future<({String envelopeText, RemoteCatalogManifestVerifier verifier})>
_signArchiveManifest(Uint8List archiveBytes) async {
  final payloadText = jsonEncode(<String, Object?>{
    'catalog_schema_version': 1,
    'coverage': const <String, bool>{
      'description_note_definitions': false,
      'evolutions': true,
      'pets': true,
      'skill_stone_topics': false,
      'skills': true,
      'topic_rewards': false,
    },
    'data_version': 2,
    'dataset_id': 'roco-world-zh-cn',
    'minimum_app_version': '1.0.0',
    'minimum_protocol_version': 1,
    'package': <String, Object>{
      'archive_bytes': archiveBytes.length,
      'archive_format': 'zip',
      'archive_sha256': sha256.convert(archiveBytes).toString(),
      'kind': 'complete_catalog',
      'url': 'https://updates.example.test/full/catalog-v2.zip',
    },
    'protocol_version': 1,
    'published_at_utc': '2026-09-09T14:00:00Z',
    'release_sequence': 2,
    'snapshot_id': 'snapshot-phase7-archive-v2',
  });
  final algorithm = Ed25519();
  final keyPair = await algorithm.newKeyPair();
  final publicKey = await keyPair.extractPublicKey();
  final payloadBytes = utf8.encode(payloadText);
  final signature = await algorithm.sign(payloadBytes, keyPair: keyPair);
  const keyId = 'ephemeral-archive-key';
  return (
    envelopeText: jsonEncode(<String, Object>{
      'envelope_version': 1,
      'key_id': keyId,
      'payload': _base64UrlNoPadding(payloadBytes),
      'payload_encoding': 'base64url',
      'signature': _base64UrlNoPadding(signature.bytes),
      'signature_algorithm': 'ed25519',
    }),
    verifier: RemoteCatalogManifestVerifier(
      CatalogManifestTrustStore(<CatalogManifestTrustedKey>[
        CatalogManifestTrustedKey(
          keyId: keyId,
          publicKeyBytes: publicKey.bytes,
          firstReleaseSequence: 1,
        ),
      ]),
    ),
  );
}

String _base64UrlNoPadding(List<int> bytes) =>
    base64UrlEncode(bytes).replaceAll('=', '');
