import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roco_handbook/data/catalog/remote_catalog_manifest.dart';

void main() {
  late String envelopeText;
  late String payloadText;
  late String trustStoreText;
  late RemoteCatalogManifestVerifier verifier;

  setUp(() {
    envelopeText = _fixture('remote_catalog_envelope_v1.json');
    payloadText = _fixture('remote_catalog_payload_v1.json').trim();
    trustStoreText = _fixture('catalog_trust_store_v1.json');
    verifier = RemoteCatalogManifestVerifier(
      CatalogManifestTrustStore.fromJsonText(trustStoreText),
    );
  });

  test('authenticates the canonical complete Catalog manifest', () async {
    final manifest = await verifier.verify(envelopeText, context: _context());

    expect(manifest.keyId, 'fixture-release-key-1');
    expect(manifest.protocolVersion, 1);
    expect(manifest.minimumProtocolVersion, 1);
    expect(manifest.datasetId, 'roco-world-zh-cn');
    expect(manifest.catalogSchemaVersion, 1);
    expect(manifest.dataVersion, 2);
    expect(manifest.releaseSequence, 2);
    expect(manifest.minimumAppVersion, '1.0.0');
    expect(manifest.publishedAtUtc, DateTime.utc(2026, 9, 9, 13, 40));
    expect(manifest.snapshotId, 'snapshot-phase7-fixture-v2');
    expect(manifest.coverage['pets'], isTrue);
    expect(manifest.package.url.host, 'updates.example.test');
    expect(utf8.decode(manifest.signedPayloadBytes), payloadText);
  });

  test('checks complete package length and SHA-256', () async {
    final manifest = await verifier.verify(envelopeText, context: _context());
    final bytes = utf8.encode(
      'phase-7-offline-complete-catalog-package-fixture-v1',
    );

    manifest.package.validateBytes(bytes);
    expect(
      () => manifest.package.validateBytes(bytes.sublist(1)),
      _failure('package_length'),
    );
    final changed = Uint8List.fromList(bytes)..[0] ^= 1;
    expect(
      () => manifest.package.validateBytes(changed),
      _failure('package_hash'),
    );
  });

  test('rejects signed payload and signature tampering', () async {
    final envelope = _jsonObject(envelopeText);
    final changedPayload = Map<String, dynamic>.from(envelope)
      ..['payload'] = _flipFirstCharacter(envelope['payload'] as String);
    final changedSignature = Map<String, dynamic>.from(envelope)
      ..['signature'] = _flipFirstCharacter(envelope['signature'] as String);

    await expectLater(
      verifier.verify(jsonEncode(changedPayload), context: _context()),
      _failure('signature_invalid'),
    );
    await expectLater(
      verifier.verify(jsonEncode(changedSignature), context: _context()),
      _failure('signature_invalid'),
    );
  });

  test('rejects unknown keys and envelope extensions', () async {
    final envelope = _jsonObject(envelopeText);
    final unknownKey = Map<String, dynamic>.from(envelope)
      ..['key_id'] = 'unknown-key';
    final extended = Map<String, dynamic>.from(envelope)..['extra'] = true;

    await expectLater(
      verifier.verify(jsonEncode(unknownKey), context: _context()),
      _failure('unknown_key'),
    );
    await expectLater(
      verifier.verify(jsonEncode(extended), context: _context()),
      _failure('envelope_shape'),
    );
  });

  test('rejects stale releases and non-newer data versions', () async {
    await expectLater(
      verifier.verify(
        envelopeText,
        context: _context(highestAcceptedReleaseSequence: 2),
      ),
      _failure('release_sequence'),
    );
    await expectLater(
      verifier.verify(envelopeText, context: _context(currentDataVersion: 2)),
      _failure('data_version'),
    );
  });

  test('rejects incompatible Apps, hosts, and key sequence ranges', () async {
    await expectLater(
      verifier.verify(
        envelopeText,
        context: _context(currentAppVersion: '0.9.0'),
      ),
      _failure('minimum_app_version'),
    );
    await expectLater(
      verifier.verify(
        envelopeText,
        context: _context(allowedHosts: const {'other.example.test'}),
      ),
      _failure('package_url'),
    );
    final trust = _jsonObject(trustStoreText);
    final keys = trust['keys'] as List<dynamic>;
    final key = Map<String, dynamic>.from(keys.single as Map)
      ..['last_release_sequence'] = 1;
    trust['keys'] = <Object?>[key];
    final restrictedVerifier = RemoteCatalogManifestVerifier(
      CatalogManifestTrustStore.fromJsonText(jsonEncode(trust)),
    );
    await expectLater(
      restrictedVerifier.verify(envelopeText, context: _context()),
      _failure('key_sequence'),
    );
  });

  test('rejects a validly signed noncanonical payload', () async {
    final dynamicFixture = await _sign(' $payloadText');

    await expectLater(
      dynamicFixture.verifier.verify(
        dynamicFixture.envelopeText,
        context: _context(),
      ),
      _failure('payload_canonical'),
    );
  });

  test('rejects a validly signed insecure package URL', () async {
    final payload = _jsonObject(payloadText);
    final package = Map<String, dynamic>.from(payload['package'] as Map)
      ..['url'] = 'http://updates.example.test/full/catalog-v2.zip';
    payload['package'] = package;
    final dynamicFixture = await _sign(jsonEncode(payload));

    await expectLater(
      dynamicFixture.verifier.verify(
        dynamicFixture.envelopeText,
        context: _context(),
      ),
      _failure('package_url'),
    );
  });

  test('rejects a validly signed normalized calendar date', () async {
    final payload = _jsonObject(payloadText)
      ..['published_at_utc'] = '2026-02-30T13:40:00Z';
    final dynamicFixture = await _sign(jsonEncode(payload));

    await expectLater(
      dynamicFixture.verifier.verify(
        dynamicFixture.envelopeText,
        context: _context(),
      ),
      _failure('published_at_utc'),
    );
  });

  test('rejects malformed trust-store keys', () {
    final trust = _jsonObject(trustStoreText);
    final keys = trust['keys'] as List<dynamic>;
    final key = Map<String, dynamic>.from(keys.single as Map)
      ..['public_key'] = 'too-short';
    trust['keys'] = <Object?>[key];

    expect(
      () => CatalogManifestTrustStore.fromJsonText(jsonEncode(trust)),
      _failure('trust_store_key'),
    );
  });

  test('rejects overlapping trust-store key ranges', () {
    final trust = _jsonObject(trustStoreText);
    final first = Map<String, dynamic>.from(
      (trust['keys'] as List<dynamic>).single as Map,
    )..['last_release_sequence'] = 10;
    final overlapping = Map<String, dynamic>.from(first)
      ..['key_id'] = 'fixture-release-key-2'
      ..['first_release_sequence'] = 10
      ..['last_release_sequence'] = 20;
    trust['keys'] = <Object?>[first, overlapping];

    expect(
      () => CatalogManifestTrustStore.fromJsonText(jsonEncode(trust)),
      _failure('trust_store_key_range'),
    );
  });
}

String _fixture(String name) =>
    File('test/fixtures/catalog_update/$name').readAsStringSync();

RemoteCatalogValidationContext _context({
  String currentAppVersion = '1.0.0',
  int currentDataVersion = 1,
  int highestAcceptedReleaseSequence = 1,
  Set<String> allowedHosts = const {'updates.example.test'},
}) => RemoteCatalogValidationContext(
  currentAppVersion: currentAppVersion,
  currentDataVersion: currentDataVersion,
  highestAcceptedReleaseSequence: highestAcceptedReleaseSequence,
  allowedHosts: allowedHosts,
);

Matcher _failure(String code) => throwsA(
  isA<RemoteCatalogManifestException>().having(
    (error) => error.code,
    'code',
    code,
  ),
);

Map<String, dynamic> _jsonObject(String text) =>
    jsonDecode(text) as Map<String, dynamic>;

String _flipFirstCharacter(String value) {
  final replacement = value.startsWith('A') ? 'B' : 'A';
  return '$replacement${value.substring(1)}';
}

String _base64UrlNoPadding(List<int> value) =>
    base64UrlEncode(value).replaceAll('=', '');

Future<_DynamicFixture> _sign(String payloadText) async {
  final algorithm = Ed25519();
  final keyPair = await algorithm.newKeyPair();
  final publicKey = await keyPair.extractPublicKey();
  final payloadBytes = utf8.encode(payloadText);
  final signature = await algorithm.sign(payloadBytes, keyPair: keyPair);
  const keyId = 'ephemeral-test-key';
  final envelope = jsonEncode(<String, Object?>{
    'envelope_version': 1,
    'key_id': keyId,
    'payload': _base64UrlNoPadding(payloadBytes),
    'payload_encoding': 'base64url',
    'signature': _base64UrlNoPadding(signature.bytes),
    'signature_algorithm': 'ed25519',
  });
  final verifier = RemoteCatalogManifestVerifier(
    CatalogManifestTrustStore(<CatalogManifestTrustedKey>[
      CatalogManifestTrustedKey(
        keyId: keyId,
        publicKeyBytes: publicKey.bytes,
        firstReleaseSequence: 1,
      ),
    ]),
  );
  return _DynamicFixture(envelopeText: envelope, verifier: verifier);
}

final class _DynamicFixture {
  const _DynamicFixture({required this.envelopeText, required this.verifier});

  final String envelopeText;
  final RemoteCatalogManifestVerifier verifier;
}
