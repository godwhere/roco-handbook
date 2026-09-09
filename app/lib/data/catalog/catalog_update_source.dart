import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'remote_catalog_manifest.dart';

final class CatalogUpdateException implements Exception {
  const CatalogUpdateException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => '$code: $message';
}

enum CatalogUpdatePhase { downloading, verifyingAndInstalling }

final class CatalogUpdateProgress {
  const CatalogUpdateProgress({
    required this.phase,
    required this.receivedBytes,
    required this.totalBytes,
  });

  final CatalogUpdatePhase phase;
  final int receivedBytes;
  final int totalBytes;

  double? get fraction => totalBytes > 0
      ? (receivedBytes / totalBytes).clamp(0.0, 1.0).toDouble()
      : null;
}

final class CatalogUpdateCancellationToken {
  var _cancelled = false;
  final Set<void Function()> _listeners = <void Function()>{};

  bool get isCancelled => _cancelled;

  void cancel() {
    if (_cancelled) {
      return;
    }
    _cancelled = true;
    final listeners = _listeners.toList(growable: false);
    _listeners.clear();
    for (final listener in listeners) {
      listener();
    }
  }

  void throwIfCancelled() {
    if (_cancelled) {
      throw const CatalogUpdateException(
        'cancelled',
        'The Catalog update was cancelled.',
      );
    }
  }

  void Function() addListener(void Function() listener) {
    if (_cancelled) {
      listener();
      return () {};
    }
    _listeners.add(listener);
    return () => _listeners.remove(listener);
  }
}

final class CatalogUpdateCandidate {
  const CatalogUpdateCandidate({
    required this.envelopeText,
    required this.manifest,
  });

  final String envelopeText;
  final VerifiedRemoteCatalogManifest manifest;
}

sealed class CatalogUpdateCheckResult {
  const CatalogUpdateCheckResult();
}

final class CatalogUpdateAvailable extends CatalogUpdateCheckResult {
  const CatalogUpdateAvailable(this.candidate);

  final CatalogUpdateCandidate candidate;
}

final class CatalogUpdateCurrent extends CatalogUpdateCheckResult {
  const CatalogUpdateCurrent();
}

abstract interface class CatalogPackageSource {
  Future<CatalogUpdateCheckResult> check({
    required RemoteCatalogValidationContext context,
    required CatalogUpdateCancellationToken cancellation,
  });

  Future<Uint8List> downloadCompletePackage({
    required CatalogUpdateCandidate candidate,
    required CatalogUpdateCancellationToken cancellation,
    required void Function(CatalogUpdateProgress progress) onProgress,
  });
}

final class CatalogHttpResponse {
  const CatalogHttpResponse({
    required this.statusCode,
    required this.contentLength,
    required this.location,
    required this.contentEncoding,
    required this.body,
  });

  final int statusCode;
  final int contentLength;
  final String? location;
  final String? contentEncoding;
  final Stream<List<int>> body;
}

abstract interface class CatalogHttpTransport {
  Future<CatalogHttpResponse> get(
    Uri uri, {
    required CatalogUpdateCancellationToken cancellation,
  });

  void close();
}

final class IoCatalogHttpTransport implements CatalogHttpTransport {
  IoCatalogHttpTransport._(this._client);

  factory IoCatalogHttpTransport() {
    final client = HttpClient()
      ..autoUncompress = false
      ..connectionTimeout = const Duration(seconds: 15)
      ..idleTimeout = const Duration(seconds: 15)
      ..maxConnectionsPerHost = 1
      ..userAgent = 'RocoHandbook';
    return IoCatalogHttpTransport._(client);
  }

  static const _responseTimeout = Duration(seconds: 20);

  final HttpClient _client;

  @override
  Future<CatalogHttpResponse> get(
    Uri uri, {
    required CatalogUpdateCancellationToken cancellation,
  }) async {
    cancellation.throwIfCancelled();
    HttpClientRequest? request;
    void Function()? removeCancellationListener;
    try {
      request = await _client.getUrl(uri).timeout(_responseTimeout);
      request.followRedirects = false;
      request.headers.set(HttpHeaders.acceptEncodingHeader, 'identity');
      request.headers.set(HttpHeaders.acceptHeader, 'application/octet-stream');
      removeCancellationListener = cancellation.addListener(
        () => request?.abort(
          const CatalogUpdateException(
            'cancelled',
            'The Catalog update was cancelled.',
          ),
        ),
      );
      cancellation.throwIfCancelled();
      final response = await request.close().timeout(_responseTimeout);
      return CatalogHttpResponse(
        statusCode: response.statusCode,
        contentLength: response.contentLength,
        location: response.headers.value(HttpHeaders.locationHeader),
        contentEncoding: response.headers.value(
          HttpHeaders.contentEncodingHeader,
        ),
        body: response,
      );
    } on CatalogUpdateException {
      rethrow;
    } on Object catch (error) {
      if (cancellation.isCancelled) {
        throw const CatalogUpdateException(
          'cancelled',
          'The Catalog update was cancelled.',
        );
      }
      final code = error is TimeoutException ? 'network_timeout' : 'network';
      throw CatalogUpdateException(code, 'The Catalog update request failed.');
    } finally {
      removeCancellationListener?.call();
    }
  }

  @override
  void close() => _client.close(force: true);
}

typedef CatalogHttpTransportFactory = CatalogHttpTransport Function();

final class GitHubReleaseCatalogSource implements CatalogPackageSource {
  GitHubReleaseCatalogSource({
    required this.verifier,
    CatalogHttpTransportFactory? transportFactory,
  }) : _transportFactory = transportFactory ?? IoCatalogHttpTransport.new;

  static final Uri manifestUri = Uri.parse(
    'https://github.com/godwhere/roco-handbook/releases/download/'
    'catalog-channel/catalog-manifest.json',
  );
  static const initialHost = 'github.com';
  static const redirectHost = 'release-assets.githubusercontent.com';
  static const _repositoryPath = '/godwhere/roco-handbook/releases/download/';
  static const _redirectPathPrefix = '/github-production-release-asset/';
  static const _maximumManifestBytes = 128 * 1024;
  static const _streamIdleTimeout = Duration(seconds: 20);

  final RemoteCatalogManifestVerifier verifier;
  final CatalogHttpTransportFactory _transportFactory;

  @override
  Future<CatalogUpdateCheckResult> check({
    required RemoteCatalogValidationContext context,
    required CatalogUpdateCancellationToken cancellation,
  }) async {
    _requireInitialUri(manifestUri, expectedPath: manifestUri.path);
    final transport = _transportFactory();
    try {
      final response = await _openWithOneRedirect(
        transport,
        manifestUri,
        cancellation: cancellation,
        notFoundIsCurrent: true,
      );
      if (response == null) {
        cancellation.throwIfCancelled();
        return const CatalogUpdateCurrent();
      }
      final bytes = await _readBoundedBody(
        response,
        maximumBytes: _maximumManifestBytes,
        cancellation: cancellation,
      );
      final String envelopeText;
      try {
        envelopeText = utf8.decode(bytes, allowMalformed: false);
      } on FormatException {
        throw const CatalogUpdateException(
          'manifest_encoding',
          'The Catalog update manifest is not valid UTF-8.',
        );
      }
      try {
        final manifest = await verifier.verify(
          envelopeText,
          context: context,
          allowInstalledManifest: true,
        );
        cancellation.throwIfCancelled();
        _requirePackageUri(manifest);
        if (manifest.dataVersion <= context.currentDataVersion &&
            manifest.releaseSequence <=
                context.highestAcceptedReleaseSequence) {
          return const CatalogUpdateCurrent();
        }
        return CatalogUpdateAvailable(
          CatalogUpdateCandidate(
            envelopeText: envelopeText,
            manifest: manifest,
          ),
        );
      } on RemoteCatalogManifestException catch (error) {
        throw CatalogUpdateException(
          'manifest_${error.code}',
          'The Catalog update manifest was rejected.',
        );
      }
    } finally {
      transport.close();
    }
  }

  @override
  Future<Uint8List> downloadCompletePackage({
    required CatalogUpdateCandidate candidate,
    required CatalogUpdateCancellationToken cancellation,
    required void Function(CatalogUpdateProgress progress) onProgress,
  }) async {
    final package = candidate.manifest.package;
    _requirePackageUri(candidate.manifest);
    final transport = _transportFactory();
    try {
      final response = await _openWithOneRedirect(
        transport,
        package.url,
        cancellation: cancellation,
        notFoundIsCurrent: false,
      );
      final bytes = await _readBoundedBody(
        response!,
        maximumBytes: package.archiveBytes,
        expectedBytes: package.archiveBytes,
        cancellation: cancellation,
        onProgress: (receivedBytes) => onProgress(
          CatalogUpdateProgress(
            phase: CatalogUpdatePhase.downloading,
            receivedBytes: receivedBytes,
            totalBytes: package.archiveBytes,
          ),
        ),
      );
      try {
        package.validateBytes(bytes);
      } on RemoteCatalogManifestException catch (error) {
        throw CatalogUpdateException(
          error.code,
          'The downloaded Catalog package was rejected.',
        );
      }
      return bytes;
    } finally {
      transport.close();
    }
  }

  Future<CatalogHttpResponse?> _openWithOneRedirect(
    CatalogHttpTransport transport,
    Uri initialUri, {
    required CatalogUpdateCancellationToken cancellation,
    required bool notFoundIsCurrent,
  }) async {
    cancellation.throwIfCancelled();
    final first = await transport.get(initialUri, cancellation: cancellation);
    if (first.statusCode == HttpStatus.ok) {
      return first;
    }
    if (first.statusCode == HttpStatus.notFound && notFoundIsCurrent) {
      await _cancelBody(first.body);
      return null;
    }
    if (first.statusCode != HttpStatus.found) {
      await _cancelBody(first.body);
      throw CatalogUpdateException(
        'http_status',
        'The Catalog update host returned status ${first.statusCode}.',
      );
    }
    final redirect = _validatedRedirect(first.location);
    await _cancelBody(first.body);
    final second = await transport.get(redirect, cancellation: cancellation);
    if (second.statusCode == HttpStatus.ok) {
      return second;
    }
    await _cancelBody(second.body);
    if (_isRedirect(second.statusCode)) {
      throw const CatalogUpdateException(
        'redirect_limit',
        'The Catalog update exceeded its one-redirect limit.',
      );
    }
    throw CatalogUpdateException(
      'http_status',
      'The Catalog update host returned status ${second.statusCode}.',
    );
  }

  Uri _validatedRedirect(String? location) {
    final redirect = location == null ? null : Uri.tryParse(location);
    if (redirect == null ||
        !redirect.isAbsolute ||
        redirect.scheme != 'https' ||
        redirect.host != redirectHost ||
        redirect.port != 443 ||
        redirect.userInfo.isNotEmpty ||
        redirect.fragment.isNotEmpty ||
        !redirect.path.startsWith(_redirectPathPrefix)) {
      throw const CatalogUpdateException(
        'redirect_policy',
        'The Catalog update redirect is not allowed.',
      );
    }
    return redirect;
  }

  static bool _isRedirect(int statusCode) => switch (statusCode) {
    HttpStatus.movedPermanently ||
    HttpStatus.found ||
    HttpStatus.movedTemporarily ||
    HttpStatus.seeOther ||
    HttpStatus.temporaryRedirect ||
    HttpStatus.permanentRedirect => true,
    _ => false,
  };

  static void _requireInitialUri(Uri uri, {required String expectedPath}) {
    if (!uri.isAbsolute ||
        uri.scheme != 'https' ||
        uri.host != initialHost ||
        uri.port != 443 ||
        uri.userInfo.isNotEmpty ||
        uri.query.isNotEmpty ||
        uri.fragment.isNotEmpty ||
        uri.path != expectedPath ||
        !uri.path.startsWith(_repositoryPath)) {
      throw const CatalogUpdateException(
        'initial_url_policy',
        'The Catalog update URL is not allowed.',
      );
    }
  }

  static void _requirePackageUri(VerifiedRemoteCatalogManifest manifest) {
    final dataVersion = manifest.dataVersion;
    final expectedPath =
        '${_repositoryPath}catalog-data-v$dataVersion/catalog-v$dataVersion.zip';
    _requireInitialUri(manifest.package.url, expectedPath: expectedPath);
  }

  static Future<void> _cancelBody(Stream<List<int>> body) async {
    final subscription = body.listen((_) {}, onError: (_) {});
    await subscription.cancel();
  }

  static Future<Uint8List> _readBoundedBody(
    CatalogHttpResponse response, {
    required int maximumBytes,
    int? expectedBytes,
    required CatalogUpdateCancellationToken cancellation,
    void Function(int receivedBytes)? onProgress,
  }) async {
    cancellation.throwIfCancelled();
    final encoding = response.contentEncoding?.toLowerCase();
    if (encoding != null && encoding != 'identity') {
      await _cancelBody(response.body);
      throw const CatalogUpdateException(
        'content_encoding',
        'Compressed HTTP response bodies are not accepted.',
      );
    }
    if (response.contentLength > maximumBytes ||
        (expectedBytes != null &&
            response.contentLength >= 0 &&
            response.contentLength != expectedBytes)) {
      await _cancelBody(response.body);
      throw const CatalogUpdateException(
        'content_length',
        'The Catalog update response length is invalid.',
      );
    }

    final bytes = BytesBuilder(copy: false);
    final completer = Completer<Uint8List>();
    StreamSubscription<List<int>>? subscription;
    void Function()? removeCancellationListener;
    var receivedBytes = 0;
    var completed = false;

    void fail(Object error, [StackTrace? stackTrace]) {
      if (completed) {
        return;
      }
      completed = true;
      unawaited(subscription?.cancel());
      completer.completeError(error, stackTrace ?? StackTrace.current);
    }

    subscription = response.body
        .timeout(
          _streamIdleTimeout,
          onTimeout: (sink) => sink.addError(
            const CatalogUpdateException(
              'network_timeout',
              'The Catalog update response timed out.',
            ),
          ),
        )
        .listen(
          (chunk) {
            if (completed) {
              return;
            }
            if (cancellation.isCancelled) {
              fail(
                const CatalogUpdateException(
                  'cancelled',
                  'The Catalog update was cancelled.',
                ),
              );
              return;
            }
            receivedBytes += chunk.length;
            if (receivedBytes > maximumBytes ||
                (expectedBytes != null && receivedBytes > expectedBytes)) {
              fail(
                const CatalogUpdateException(
                  'body_size',
                  'The Catalog update response exceeded its size limit.',
                ),
              );
              return;
            }
            bytes.add(chunk);
            try {
              onProgress?.call(receivedBytes);
            } on Object catch (error, stackTrace) {
              fail(error, stackTrace);
            }
          },
          onError: (Object error, StackTrace stackTrace) {
            if (error is CatalogUpdateException) {
              fail(error, stackTrace);
            } else if (cancellation.isCancelled) {
              fail(
                const CatalogUpdateException(
                  'cancelled',
                  'The Catalog update was cancelled.',
                ),
                stackTrace,
              );
            } else {
              fail(
                const CatalogUpdateException(
                  'network',
                  'The Catalog update response failed.',
                ),
                stackTrace,
              );
            }
          },
          onDone: () {
            if (completed) {
              return;
            }
            if (expectedBytes != null && receivedBytes != expectedBytes) {
              fail(
                const CatalogUpdateException(
                  'content_length',
                  'The Catalog update response length is invalid.',
                ),
              );
              return;
            }
            completed = true;
            completer.complete(bytes.takeBytes());
          },
          cancelOnError: true,
        );
    removeCancellationListener = cancellation.addListener(
      () => fail(
        const CatalogUpdateException(
          'cancelled',
          'The Catalog update was cancelled.',
        ),
      ),
    );
    try {
      try {
        onProgress?.call(0);
      } on Object catch (error, stackTrace) {
        fail(error, stackTrace);
      }
      return await completer.future;
    } finally {
      removeCancellationListener();
      if (!completed) {
        await subscription.cancel();
      }
    }
  }
}
