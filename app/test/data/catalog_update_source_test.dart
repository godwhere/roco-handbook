import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roco_handbook/data/catalog/catalog_update_source.dart';
import 'package:roco_handbook/data/catalog/remote_catalog_manifest.dart';

void main() {
  test(
    'checks the signed discovery asset through one allowed redirect',
    () async {
      final fixture = await _CatalogUpdateFixture.create(<int>[1, 2, 3, 4]);
      final transport = _FakeTransport(<CatalogHttpResponse>[
        _redirectResponse(_releaseAssetUri),
        _bytesResponse(utf8.encode(fixture.envelopeText)),
      ]);
      final source = GitHubReleaseCatalogSource(
        verifier: fixture.verifier,
        transportFactory: () => transport,
      );

      final result = await source.check(
        context: _context(),
        cancellation: CatalogUpdateCancellationToken(),
      );

      expect(result, isA<CatalogUpdateAvailable>());
      final candidate = (result as CatalogUpdateAvailable).candidate;
      expect(candidate.manifest.dataVersion, 2);
      expect(candidate.manifest.package.url, fixture.packageUri);
      expect(transport.requested, <Uri>[
        GitHubReleaseCatalogSource.manifestUri,
        _releaseAssetUri,
      ]);
      expect(transport.closed, isTrue);
    },
  );

  test(
    'treats a missing discovery asset and installed manifest as current',
    () async {
      final missing = _FakeTransport(<CatalogHttpResponse>[
        _response(statusCode: 404),
      ]);
      final fixture = await _CatalogUpdateFixture.create(<int>[1, 2, 3, 4]);
      final installed = _FakeTransport(<CatalogHttpResponse>[
        _bytesResponse(utf8.encode(fixture.envelopeText)),
      ]);
      final transports = <_FakeTransport>[missing, installed];
      final source = GitHubReleaseCatalogSource(
        verifier: fixture.verifier,
        transportFactory: () => transports.removeAt(0),
      );

      expect(
        await source.check(
          context: _context(),
          cancellation: CatalogUpdateCancellationToken(),
        ),
        isA<CatalogUpdateCurrent>(),
      );
      expect(
        await source.check(
          context: _context(currentDataVersion: 2, highestSequence: 2),
          cancellation: CatalogUpdateCancellationToken(),
        ),
        isA<CatalogUpdateCurrent>(),
      );
    },
  );

  test('downloads exact package bytes and reports bounded progress', () async {
    final bytes = Uint8List.fromList(<int>[8, 6, 7, 5]);
    final fixture = await _CatalogUpdateFixture.create(bytes);
    final transport = _FakeTransport(<CatalogHttpResponse>[
      _redirectResponse(_releaseAssetUri),
      _response(
        statusCode: 200,
        contentLength: bytes.length,
        body: Stream<List<int>>.fromIterable(<List<int>>[
          bytes.sublist(0, 2),
          bytes.sublist(2),
        ]),
      ),
    ]);
    final source = GitHubReleaseCatalogSource(
      verifier: fixture.verifier,
      transportFactory: () => transport,
    );
    final progress = <CatalogUpdateProgress>[];

    final downloaded = await source.downloadCompletePackage(
      candidate: fixture.candidate,
      cancellation: CatalogUpdateCancellationToken(),
      onProgress: progress.add,
    );

    expect(downloaded, bytes);
    expect(progress.map((value) => value.receivedBytes), <int>[0, 2, 4]);
    expect(progress.last.fraction, 1);
    expect(transport.closed, isTrue);
  });

  test('rejects unapproved redirects and a second redirect', () async {
    final fixture = await _CatalogUpdateFixture.create(<int>[1, 2, 3, 4]);
    final badHost = _FakeTransport(<CatalogHttpResponse>[
      _redirectResponse(Uri.parse('https://example.test/package')),
    ]);
    final secondRedirect = _FakeTransport(<CatalogHttpResponse>[
      _redirectResponse(_releaseAssetUri),
      _redirectResponse(
        _releaseAssetUri.replace(path: '${_releaseAssetUri.path}2'),
      ),
    ]);
    final transports = <_FakeTransport>[badHost, secondRedirect];
    final source = GitHubReleaseCatalogSource(
      verifier: fixture.verifier,
      transportFactory: () => transports.removeAt(0),
    );

    await expectLater(
      source.check(
        context: _context(),
        cancellation: CatalogUpdateCancellationToken(),
      ),
      _updateFailure('redirect_policy'),
    );
    await expectLater(
      source.downloadCompletePackage(
        candidate: fixture.candidate,
        cancellation: CatalogUpdateCancellationToken(),
        onProgress: (_) {},
      ),
      _updateFailure('redirect_limit'),
    );
  });

  test('rejects declared and actual package length violations', () async {
    final fixture = await _CatalogUpdateFixture.create(<int>[1, 2, 3, 4]);
    final declared = _FakeTransport(<CatalogHttpResponse>[
      _response(
        statusCode: 200,
        contentLength: 3,
        body: Stream<List<int>>.value(<int>[1, 2, 3]),
      ),
    ]);
    final actual = _FakeTransport(<CatalogHttpResponse>[
      _response(
        statusCode: 200,
        body: Stream<List<int>>.value(<int>[1, 2, 3, 4, 5]),
      ),
    ]);
    final transports = <_FakeTransport>[declared, actual];
    final source = GitHubReleaseCatalogSource(
      verifier: fixture.verifier,
      transportFactory: () => transports.removeAt(0),
    );

    await expectLater(
      source.downloadCompletePackage(
        candidate: fixture.candidate,
        cancellation: CatalogUpdateCancellationToken(),
        onProgress: (_) {},
      ),
      _updateFailure('content_length'),
    );
    await expectLater(
      source.downloadCompletePackage(
        candidate: fixture.candidate,
        cancellation: CatalogUpdateCancellationToken(),
        onProgress: (_) {},
      ),
      _updateFailure('body_size'),
    );
  });

  test('rejects package bytes that do not match the signed hash', () async {
    final fixture = await _CatalogUpdateFixture.create(<int>[1, 2, 3, 4]);
    final transport = _FakeTransport(<CatalogHttpResponse>[
      _bytesResponse(<int>[1, 2, 3, 5]),
    ]);
    final source = GitHubReleaseCatalogSource(
      verifier: fixture.verifier,
      transportFactory: () => transport,
    );

    await expectLater(
      source.downloadCompletePackage(
        candidate: fixture.candidate,
        cancellation: CatalogUpdateCancellationToken(),
        onProgress: (_) {},
      ),
      _updateFailure('package_hash'),
    );
  });

  test(
    'cancels an active package transfer without returning partial bytes',
    () async {
      final fixture = await _CatalogUpdateFixture.create(<int>[1, 2, 3, 4]);
      final cancellation = CatalogUpdateCancellationToken();
      final transport = _FakeTransport(<CatalogHttpResponse>[
        _response(
          statusCode: 200,
          contentLength: 4,
          body: Stream<List<int>>.fromIterable(<List<int>>[
            <int>[1, 2],
            <int>[3, 4],
          ]),
        ),
      ]);
      final source = GitHubReleaseCatalogSource(
        verifier: fixture.verifier,
        transportFactory: () => transport,
      );

      await expectLater(
        source.downloadCompletePackage(
          candidate: fixture.candidate,
          cancellation: cancellation,
          onProgress: (progress) {
            if (progress.receivedBytes == 2) {
              cancellation.cancel();
            }
          },
        ),
        _updateFailure('cancelled'),
      );
    },
  );

  test('rejects a signed package outside the versioned release path', () async {
    final fixture = await _CatalogUpdateFixture.create(
      <int>[1, 2, 3, 4],
      packageUri: Uri.parse(
        'https://github.com/godwhere/roco-handbook/releases/download/'
        'catalog-channel/catalog-v2.zip',
      ),
    );
    final transport = _FakeTransport(<CatalogHttpResponse>[
      _bytesResponse(utf8.encode(fixture.envelopeText)),
    ]);
    final source = GitHubReleaseCatalogSource(
      verifier: fixture.verifier,
      transportFactory: () => transport,
    );

    await expectLater(
      source.check(
        context: _context(currentDataVersion: 2, highestSequence: 2),
        cancellation: CatalogUpdateCancellationToken(),
      ),
      _updateFailure('initial_url_policy'),
    );
  });
}

final Uri _releaseAssetUri = Uri.parse(
  'https://release-assets.githubusercontent.com/'
  'github-production-release-asset/123/catalog?sp=read',
);

CatalogHttpResponse _redirectResponse(Uri location) =>
    _response(statusCode: 302, location: location.toString());

CatalogHttpResponse _bytesResponse(List<int> bytes) => _response(
  statusCode: 200,
  contentLength: bytes.length,
  body: Stream<List<int>>.value(bytes),
);

CatalogHttpResponse _response({
  required int statusCode,
  int contentLength = -1,
  String? location,
  String? contentEncoding,
  Stream<List<int>>? body,
}) => CatalogHttpResponse(
  statusCode: statusCode,
  contentLength: contentLength,
  location: location,
  contentEncoding: contentEncoding,
  body: body ?? const Stream<List<int>>.empty(),
);

RemoteCatalogValidationContext _context({
  int currentDataVersion = 1,
  int highestSequence = 1,
}) => RemoteCatalogValidationContext(
  currentAppVersion: '1.0.0',
  currentDataVersion: currentDataVersion,
  highestAcceptedReleaseSequence: highestSequence,
  allowedHosts: const <String>{'github.com'},
);

Matcher _updateFailure(String code) => throwsA(
  isA<CatalogUpdateException>().having((error) => error.code, 'code', code),
);

final class _FakeTransport implements CatalogHttpTransport {
  _FakeTransport(this._responses);

  final List<CatalogHttpResponse> _responses;
  final List<Uri> requested = <Uri>[];
  bool closed = false;

  @override
  Future<CatalogHttpResponse> get(
    Uri uri, {
    required CatalogUpdateCancellationToken cancellation,
  }) async {
    cancellation.throwIfCancelled();
    requested.add(uri);
    if (_responses.isEmpty) {
      throw StateError('No fake Catalog response remains.');
    }
    return _responses.removeAt(0);
  }

  @override
  void close() {
    closed = true;
  }
}

final class _CatalogUpdateFixture {
  const _CatalogUpdateFixture({
    required this.envelopeText,
    required this.verifier,
    required this.candidate,
    required this.packageUri,
  });

  final String envelopeText;
  final RemoteCatalogManifestVerifier verifier;
  final CatalogUpdateCandidate candidate;
  final Uri packageUri;

  static Future<_CatalogUpdateFixture> create(
    List<int> archiveBytes, {
    Uri? packageUri,
  }) async {
    final selectedPackageUri =
        packageUri ??
        Uri.parse(
          'https://github.com/godwhere/roco-handbook/releases/download/'
          'catalog-data-v2/catalog-v2.zip',
        );
    final payload = <String, Object?>{
      'catalog_schema_version': 1,
      'coverage': <String, bool>{
        'description_note_definitions': true,
        'evolutions': true,
        'pets': true,
        'skill_stone_topics': true,
        'skills': true,
        'topic_rewards': true,
      },
      'data_version': 2,
      'dataset_id': 'roco-world-zh-cn',
      'minimum_app_version': '1.0.0',
      'minimum_protocol_version': 1,
      'package': <String, Object?>{
        'archive_bytes': archiveBytes.length,
        'archive_format': 'zip',
        'archive_sha256': sha256.convert(archiveBytes).toString(),
        'kind': 'complete_catalog',
        'url': selectedPackageUri.toString(),
      },
      'protocol_version': 1,
      'published_at_utc': '2026-09-10T00:00:00Z',
      'release_sequence': 2,
      'snapshot_id': 'snapshot-source-test-v2',
    };
    final payloadText = encodeCanonicalCatalogManifestJson(payload);
    final payloadBytes = utf8.encode(payloadText);
    final algorithm = Ed25519();
    final keyPair = await algorithm.newKeyPair();
    final publicKey = await keyPair.extractPublicKey();
    final signature = await algorithm.sign(payloadBytes, keyPair: keyPair);
    const keyId = 'source-test-key';
    final envelopeText = jsonEncode(<String, Object?>{
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
    final manifest = await verifier.verify(envelopeText, context: _context());
    return _CatalogUpdateFixture(
      envelopeText: envelopeText,
      verifier: verifier,
      candidate: CatalogUpdateCandidate(
        envelopeText: envelopeText,
        manifest: manifest,
      ),
      packageUri: selectedPackageUri,
    );
  }
}

String _base64UrlNoPadding(List<int> value) =>
    base64UrlEncode(value).replaceAll('=', '');
