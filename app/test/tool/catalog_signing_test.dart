import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:roco_handbook/data/catalog/remote_catalog_manifest.dart';

import '../../tool/catalog_signing.dart';

void main() {
  late Directory temporary;
  late Directory repositoryRoot;

  setUp(() {
    temporary = Directory.systemTemp.createTempSync('roco-catalog-signing-');
    if (Platform.isMacOS || Platform.isLinux) {
      expect(
        Process.runSync('chmod', <String>['700', temporary.path]).exitCode,
        0,
      );
    }
    repositoryRoot = Directory.current.parent;
  });

  tearDown(() {
    temporary.deleteSync(recursive: true);
  });

  test('production trust store contains public verification material only', () {
    final text = File('assets/catalog/catalog_trust_store.json')
        .readAsStringSync();
    final decoded = jsonDecode(text) as Map<String, dynamic>;
    final trustStore = CatalogManifestTrustStore.fromJsonText(text);

    expect(decoded.toString(), isNot(contains('private_key')));
    expect(decoded.toString(), isNot(contains('private-key')));
    expect(trustStore.keyFor('catalog-prod-2026-01'), isNotNull);
  });

  test(
    'generates an external key and signs a verifiable canonical payload',
    () async {
      final privateKey = File('${temporary.path}/private-key.json');
      final trustStoreFile = File('${temporary.path}/trust-store.json');
      final generated = await generateCatalogSigningKey(
        keyId: 'catalog-test-2026-01',
        firstReleaseSequence: 1,
        lastReleaseSequence: 10,
        privateKeyOutput: privateKey,
        trustStoreOutput: trustStoreFile,
        repositoryRoot: repositoryRoot,
      );

      expect(generated['public_key'], hasLength(43));
      expect(
        FileSystemEntity.typeSync(privateKey.path, followLinks: false),
        FileSystemEntityType.file,
      );
      if (Platform.isMacOS || Platform.isLinux) {
        expect(FileStat.statSync(privateKey.path).mode & 0x3f, 0);
      }

      final envelope = File('${temporary.path}/envelope.json');
      await signCatalogManifestPayload(
        privateKeyFile: privateKey,
        payloadFile: File(
          'test/fixtures/catalog_update/remote_catalog_payload_v1.json',
        ),
        envelopeOutput: envelope,
        repositoryRoot: repositoryRoot,
      );

      final verifier = RemoteCatalogManifestVerifier(
        CatalogManifestTrustStore.fromJsonText(
          trustStoreFile.readAsStringSync(),
        ),
      );
      final verified = await verifier.verify(
        envelope.readAsStringSync(),
        context: RemoteCatalogValidationContext(
          currentAppVersion: '1.0.0',
          currentDataVersion: 1,
          highestAcceptedReleaseSequence: 1,
          allowedHosts: const {'updates.example.test'},
        ),
      );
      expect(verified.keyId, 'catalog-test-2026-01');
      expect(verified.releaseSequence, 2);
      expect(
        utf8.decode(verified.signedPayloadBytes),
        encodeCanonicalCatalogManifestJson(
          jsonDecode(
            File('test/fixtures/catalog_update/remote_catalog_payload_v1.json')
                .readAsStringSync(),
          ),
        ),
      );

      await expectLater(
        signCatalogManifestPayload(
          privateKeyFile: privateKey,
          payloadFile: File(
            'test/fixtures/catalog_update/remote_catalog_payload_v1.json',
          ),
          envelopeOutput: envelope,
          repositoryRoot: repositoryRoot,
        ),
        throwsA(isA<CatalogSigningException>()),
      );
    },
  );

  test('refuses repository keys, links, and out-of-range payloads', () async {
    await expectLater(
      generateCatalogSigningKey(
        keyId: 'catalog-test-repository',
        firstReleaseSequence: 1,
        privateKeyOutput: File('test/repository-private-key.json'),
        trustStoreOutput: File('${temporary.path}/unused-trust-store.json'),
        repositoryRoot: repositoryRoot,
      ),
      throwsA(isA<CatalogSigningException>()),
    );

    final linkedRepository = Directory('${temporary.path}/repository')
      ..createSync();
    final linkedSecrets = Directory('${linkedRepository.path}/secrets')
      ..createSync();
    if (Platform.isMacOS || Platform.isLinux) {
      expect(
        Process.runSync('chmod', <String>['700', linkedSecrets.path]).exitCode,
        0,
      );
    }
    final repositoryAlias = Link('${temporary.path}/repository-alias')
      ..createSync(linkedRepository.path);
    await expectLater(
      generateCatalogSigningKey(
        keyId: 'catalog-test-linked-repository',
        firstReleaseSequence: 1,
        privateKeyOutput: File(
          '${repositoryAlias.path}/secrets/catalog.private.json',
        ),
        trustStoreOutput: File('${temporary.path}/linked-trust-store.json'),
        repositoryRoot: linkedRepository,
      ),
      throwsA(isA<CatalogSigningException>()),
    );

    final privateKey = File('${temporary.path}/private-key.json');
    await generateCatalogSigningKey(
      keyId: 'catalog-test-range',
      firstReleaseSequence: 1,
      lastReleaseSequence: 1,
      privateKeyOutput: privateKey,
      trustStoreOutput: File('${temporary.path}/trust-store.json'),
      repositoryRoot: repositoryRoot,
    );
    final linkedKey = Link('${temporary.path}/linked-key.json')
      ..createSync(privateKey.path);
    await expectLater(
      signCatalogManifestPayload(
        privateKeyFile: File(linkedKey.path),
        payloadFile: File(
          'test/fixtures/catalog_update/remote_catalog_payload_v1.json',
        ),
        envelopeOutput: File('${temporary.path}/linked-envelope.json'),
        repositoryRoot: repositoryRoot,
      ),
      throwsA(isA<CatalogSigningException>()),
    );
    await expectLater(
      signCatalogManifestPayload(
        privateKeyFile: privateKey,
        payloadFile: File(
          'test/fixtures/catalog_update/remote_catalog_payload_v1.json',
        ),
        envelopeOutput: File('${temporary.path}/range-envelope.json'),
        repositoryRoot: repositoryRoot,
      ),
      throwsA(isA<CatalogSigningException>()),
    );
  });
}
