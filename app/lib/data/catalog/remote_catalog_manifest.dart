import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:cryptography/cryptography.dart';

final class RemoteCatalogManifestException implements Exception {
  const RemoteCatalogManifestException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => '$code: $message';
}

final class CatalogManifestTrustedKey {
  CatalogManifestTrustedKey({
    required this.keyId,
    required List<int> publicKeyBytes,
    required this.firstReleaseSequence,
    this.lastReleaseSequence,
  }) : publicKeyBytes = Uint8List.fromList(publicKeyBytes) {
    if (!RegExp(r'^[a-z0-9][a-z0-9._-]{0,63}$').hasMatch(keyId) ||
        this.publicKeyBytes.length != 32 ||
        firstReleaseSequence < 1 ||
        (lastReleaseSequence != null &&
            lastReleaseSequence! < firstReleaseSequence)) {
      throw const RemoteCatalogManifestException(
        'trust_store_key',
        'A trusted manifest key has an invalid contract.',
      );
    }
  }

  final String keyId;
  final Uint8List publicKeyBytes;
  final int firstReleaseSequence;
  final int? lastReleaseSequence;

  bool acceptsReleaseSequence(int value) =>
      value >= firstReleaseSequence &&
      (lastReleaseSequence == null || value <= lastReleaseSequence!);
}

final class CatalogManifestTrustStore {
  CatalogManifestTrustStore(Iterable<CatalogManifestTrustedKey> keys)
    : _keys = _index(keys);

  static const _storeFields = <String>{'trust_store_version', 'keys'};
  static const _keyFields = <String>{
    'algorithm',
    'key_id',
    'public_key',
    'first_release_sequence',
    'last_release_sequence',
  };

  final Map<String, CatalogManifestTrustedKey> _keys;

  factory CatalogManifestTrustStore.fromJsonText(String text) {
    final Object? decoded;
    try {
      decoded = jsonDecode(text);
    } on FormatException catch (error) {
      throw RemoteCatalogManifestException('trust_store_json', error.message);
    }
    final document = _strictObject(
      decoded,
      _storeFields,
      code: 'trust_store_shape',
      message: 'The Catalog manifest trust store has an invalid shape.',
    );
    if (_integer(document, 'trust_store_version') != 1) {
      throw const RemoteCatalogManifestException(
        'trust_store_version',
        'The Catalog manifest trust-store version is unsupported.',
      );
    }
    final rawKeys = document['keys'];
    if (rawKeys is! List || rawKeys.isEmpty || rawKeys.length > 8) {
      throw const RemoteCatalogManifestException(
        'trust_store_keys',
        'The Catalog manifest trust store must contain one to eight keys.',
      );
    }
    final keys = <CatalogManifestTrustedKey>[];
    for (final rawKey in rawKeys) {
      final key = _strictObject(
        rawKey,
        _keyFields,
        code: 'trust_store_key',
        message: 'A trusted manifest key has an invalid shape.',
      );
      if (_string(key, 'algorithm') != 'ed25519') {
        throw const RemoteCatalogManifestException(
          'trust_store_algorithm',
          'Only Ed25519 manifest keys are supported.',
        );
      }
      final lastSequence = key['last_release_sequence'];
      if (lastSequence != null && lastSequence is! int) {
        throw const RemoteCatalogManifestException(
          'trust_store_key',
          'A trusted manifest key has an invalid sequence range.',
        );
      }
      keys.add(
        CatalogManifestTrustedKey(
          keyId: _string(key, 'key_id'),
          publicKeyBytes: _decodeBase64UrlNoPadding(
            _string(key, 'public_key'),
            code: 'trust_store_key',
            expectedBytes: 32,
          ),
          firstReleaseSequence: _integer(key, 'first_release_sequence'),
          lastReleaseSequence: lastSequence as int?,
        ),
      );
    }
    return CatalogManifestTrustStore(keys);
  }

  static Map<String, CatalogManifestTrustedKey> _index(
    Iterable<CatalogManifestTrustedKey> keys,
  ) {
    final indexed = <String, CatalogManifestTrustedKey>{};
    for (final key in keys) {
      if (indexed.containsKey(key.keyId)) {
        throw const RemoteCatalogManifestException(
          'trust_store_duplicate_key',
          'Trusted manifest key identifiers must be unique.',
        );
      }
      indexed[key.keyId] = key;
    }
    if (indexed.isEmpty || indexed.length > 8) {
      throw const RemoteCatalogManifestException(
        'trust_store_keys',
        'The Catalog manifest trust store must contain one to eight keys.',
      );
    }
    return Map.unmodifiable(indexed);
  }

  CatalogManifestTrustedKey? keyFor(String keyId) => _keys[keyId];
}

final class RemoteCatalogValidationContext {
  RemoteCatalogValidationContext({
    required this.currentAppVersion,
    required this.currentDataVersion,
    required this.highestAcceptedReleaseSequence,
    required Set<String> allowedHosts,
    this.supportedProtocolVersion = 1,
    this.supportedCatalogSchemaVersion = 1,
    this.maximumPackageBytes = 128 * 1024 * 1024,
  }) : allowedHosts = Set.unmodifiable(allowedHosts) {
    if (_parseVersion(currentAppVersion) == null ||
        currentDataVersion < 1 ||
        highestAcceptedReleaseSequence < 0 ||
        supportedProtocolVersion < 1 ||
        supportedCatalogSchemaVersion < 1 ||
        maximumPackageBytes < 1 ||
        this.allowedHosts.isEmpty ||
        this.allowedHosts.any(
          (host) =>
              host != host.toLowerCase() ||
              !RegExp(r'^[a-z0-9.-]+$').hasMatch(host),
        )) {
      throw ArgumentError('The remote Catalog validation context is invalid.');
    }
  }

  final String currentAppVersion;
  final int currentDataVersion;
  final int highestAcceptedReleaseSequence;
  final Set<String> allowedHosts;
  final int supportedProtocolVersion;
  final int supportedCatalogSchemaVersion;
  final int maximumPackageBytes;
}

final class RemoteCatalogPackage {
  const RemoteCatalogPackage({
    required this.url,
    required this.archiveBytes,
    required this.archiveSha256,
  });

  final Uri url;
  final int archiveBytes;
  final String archiveSha256;

  void validateBytes(List<int> bytes) {
    if (bytes.length != archiveBytes) {
      throw const RemoteCatalogManifestException(
        'package_length',
        'The complete Catalog package length does not match its manifest.',
      );
    }
    if (sha256.convert(bytes).toString() != archiveSha256) {
      throw const RemoteCatalogManifestException(
        'package_hash',
        'The complete Catalog package hash does not match its manifest.',
      );
    }
  }
}

final class VerifiedRemoteCatalogManifest {
  const VerifiedRemoteCatalogManifest({
    required this.keyId,
    required this.protocolVersion,
    required this.minimumProtocolVersion,
    required this.datasetId,
    required this.catalogSchemaVersion,
    required this.dataVersion,
    required this.releaseSequence,
    required this.minimumAppVersion,
    required this.publishedAtUtc,
    required this.snapshotId,
    required this.coverage,
    required this.package,
    required this.signedPayloadBytes,
  });

  final String keyId;
  final int protocolVersion;
  final int minimumProtocolVersion;
  final String datasetId;
  final int catalogSchemaVersion;
  final int dataVersion;
  final int releaseSequence;
  final String minimumAppVersion;
  final DateTime publishedAtUtc;
  final String snapshotId;
  final Map<String, bool> coverage;
  final RemoteCatalogPackage package;
  final Uint8List signedPayloadBytes;
}

final class RemoteCatalogManifestVerifier {
  RemoteCatalogManifestVerifier(this.trustStore, {Ed25519? signatureAlgorithm})
    : _signatureAlgorithm = signatureAlgorithm ?? Ed25519();

  static const _maximumEnvelopeCharacters = 128 * 1024;
  static const _maximumPayloadBytes = 64 * 1024;
  static const _envelopeFields = <String>{
    'envelope_version',
    'payload_encoding',
    'signature_algorithm',
    'key_id',
    'payload',
    'signature',
  };
  static const _payloadFields = <String>{
    'protocol_version',
    'minimum_protocol_version',
    'dataset_id',
    'catalog_schema_version',
    'data_version',
    'release_sequence',
    'minimum_app_version',
    'published_at_utc',
    'snapshot_id',
    'coverage',
    'package',
  };
  static const _packageFields = <String>{
    'kind',
    'archive_format',
    'url',
    'archive_bytes',
    'archive_sha256',
  };
  static const _coverageFields = <String>{
    'pets',
    'skills',
    'evolutions',
    'topic_rewards',
    'skill_stone_topics',
    'description_note_definitions',
  };

  final CatalogManifestTrustStore trustStore;
  final Ed25519 _signatureAlgorithm;

  Future<VerifiedRemoteCatalogManifest> verify(
    String envelopeText, {
    required RemoteCatalogValidationContext context,
  }) async {
    if (envelopeText.length > _maximumEnvelopeCharacters) {
      throw const RemoteCatalogManifestException(
        'envelope_size',
        'The remote Catalog manifest envelope is too large.',
      );
    }
    final Object? decodedEnvelope;
    try {
      decodedEnvelope = jsonDecode(envelopeText);
    } on FormatException catch (error) {
      throw RemoteCatalogManifestException('envelope_json', error.message);
    }
    final envelope = _strictObject(
      decodedEnvelope,
      _envelopeFields,
      code: 'envelope_shape',
      message: 'The remote Catalog manifest envelope has an invalid shape.',
    );
    if (_integer(envelope, 'envelope_version') != 1) {
      throw const RemoteCatalogManifestException(
        'envelope_version',
        'The remote Catalog manifest envelope version is unsupported.',
      );
    }
    if (_string(envelope, 'payload_encoding') != 'base64url') {
      throw const RemoteCatalogManifestException(
        'payload_encoding',
        'The remote Catalog manifest payload encoding is unsupported.',
      );
    }
    if (_string(envelope, 'signature_algorithm') != 'ed25519') {
      throw const RemoteCatalogManifestException(
        'signature_algorithm',
        'The remote Catalog manifest signature algorithm is unsupported.',
      );
    }
    final keyId = _string(envelope, 'key_id');
    if (!RegExp(r'^[a-z0-9][a-z0-9._-]{0,63}$').hasMatch(keyId)) {
      throw const RemoteCatalogManifestException(
        'key_id',
        'The remote Catalog manifest key identifier is invalid.',
      );
    }
    final trustedKey = trustStore.keyFor(keyId);
    if (trustedKey == null) {
      throw const RemoteCatalogManifestException(
        'unknown_key',
        'The remote Catalog manifest key is not trusted by this App.',
      );
    }
    final payloadBytes = _decodeBase64UrlNoPadding(
      _string(envelope, 'payload'),
      code: 'payload_encoding',
      maximumBytes: _maximumPayloadBytes,
    );
    final signatureBytes = _decodeBase64UrlNoPadding(
      _string(envelope, 'signature'),
      code: 'signature_encoding',
      expectedBytes: 64,
    );
    final signature = Signature(
      signatureBytes,
      publicKey: SimplePublicKey(
        trustedKey.publicKeyBytes,
        type: KeyPairType.ed25519,
      ),
    );
    if (!await _signatureAlgorithm.verify(payloadBytes, signature: signature)) {
      throw const RemoteCatalogManifestException(
        'signature_invalid',
        'The remote Catalog manifest signature is invalid.',
      );
    }
    final payloadText = _decodeUtf8(payloadBytes);
    final Object? decodedPayload;
    try {
      decodedPayload = jsonDecode(payloadText);
    } on FormatException catch (error) {
      throw RemoteCatalogManifestException('payload_json', error.message);
    }
    if (_canonicalJson(decodedPayload) != payloadText) {
      throw const RemoteCatalogManifestException(
        'payload_canonical',
        'The signed Catalog manifest payload is not canonical JSON.',
      );
    }
    final payload = _strictObject(
      decodedPayload,
      _payloadFields,
      code: 'payload_shape',
      message: 'The signed Catalog manifest payload has an invalid shape.',
    );
    return _validatePayload(payload, payloadBytes, keyId, trustedKey, context);
  }

  VerifiedRemoteCatalogManifest _validatePayload(
    Map<String, dynamic> payload,
    Uint8List payloadBytes,
    String keyId,
    CatalogManifestTrustedKey trustedKey,
    RemoteCatalogValidationContext context,
  ) {
    final protocolVersion = _integer(payload, 'protocol_version');
    final minimumProtocolVersion = _integer(
      payload,
      'minimum_protocol_version',
    );
    if (protocolVersion != context.supportedProtocolVersion ||
        minimumProtocolVersion < 1 ||
        minimumProtocolVersion > context.supportedProtocolVersion ||
        minimumProtocolVersion > protocolVersion) {
      throw const RemoteCatalogManifestException(
        'protocol_version',
        'The signed Catalog manifest protocol is incompatible with this App.',
      );
    }
    final datasetId = _string(payload, 'dataset_id');
    if (datasetId != 'roco-world-zh-cn') {
      throw const RemoteCatalogManifestException(
        'dataset_id',
        'The signed Catalog manifest targets a different dataset.',
      );
    }
    final catalogSchemaVersion = _integer(payload, 'catalog_schema_version');
    if (catalogSchemaVersion != context.supportedCatalogSchemaVersion) {
      throw const RemoteCatalogManifestException(
        'catalog_schema_version',
        'The signed Catalog manifest schema is incompatible with this App.',
      );
    }
    final dataVersion = _integer(payload, 'data_version');
    if (dataVersion <= context.currentDataVersion) {
      throw const RemoteCatalogManifestException(
        'data_version',
        'The signed Catalog manifest does not target a newer data version.',
      );
    }
    final releaseSequence = _integer(payload, 'release_sequence');
    if (releaseSequence <= context.highestAcceptedReleaseSequence) {
      throw const RemoteCatalogManifestException(
        'release_sequence',
        'The signed Catalog manifest release sequence is stale or replayed.',
      );
    }
    if (!trustedKey.acceptsReleaseSequence(releaseSequence)) {
      throw const RemoteCatalogManifestException(
        'key_sequence',
        'The signing key is not valid for this release sequence.',
      );
    }
    final minimumAppVersion = _string(payload, 'minimum_app_version');
    final currentVersion = _parseVersion(context.currentAppVersion);
    final requiredVersion = _parseVersion(minimumAppVersion);
    if (requiredVersion == null ||
        currentVersion == null ||
        _compareVersions(currentVersion, requiredVersion) < 0) {
      throw const RemoteCatalogManifestException(
        'minimum_app_version',
        'The signed Catalog manifest requires a newer App version.',
      );
    }
    final publishedAtText = _string(payload, 'published_at_utc');
    final publishedAtUtc = _parseUtcTimestamp(publishedAtText);
    if (publishedAtUtc == null) {
      throw const RemoteCatalogManifestException(
        'published_at_utc',
        'The signed Catalog manifest publication time is invalid.',
      );
    }
    final snapshotId = _string(payload, 'snapshot_id');
    if (!RegExp(r'^snapshot-[0-9a-z-]{8,80}$').hasMatch(snapshotId)) {
      throw const RemoteCatalogManifestException(
        'snapshot_id',
        'The signed Catalog manifest snapshot identifier is invalid.',
      );
    }
    final coverage = _validateCoverage(payload['coverage']);
    final package = _validatePackage(payload['package'], context);
    return VerifiedRemoteCatalogManifest(
      keyId: keyId,
      protocolVersion: protocolVersion,
      minimumProtocolVersion: minimumProtocolVersion,
      datasetId: datasetId,
      catalogSchemaVersion: catalogSchemaVersion,
      dataVersion: dataVersion,
      releaseSequence: releaseSequence,
      minimumAppVersion: minimumAppVersion,
      publishedAtUtc: publishedAtUtc,
      snapshotId: snapshotId,
      coverage: Map.unmodifiable(coverage),
      package: package,
      signedPayloadBytes: Uint8List.fromList(payloadBytes),
    );
  }

  Map<String, bool> _validateCoverage(Object? value) {
    final coverage = _strictObject(
      value,
      _coverageFields,
      code: 'coverage',
      message: 'The signed Catalog manifest coverage is invalid.',
    );
    final result = <String, bool>{};
    for (final field in _coverageFields) {
      final fieldValue = coverage[field];
      if (fieldValue is! bool) {
        throw const RemoteCatalogManifestException(
          'coverage',
          'The signed Catalog manifest coverage is invalid.',
        );
      }
      result[field] = fieldValue;
    }
    if (result['pets'] != true ||
        result['skills'] != true ||
        result['evolutions'] != true) {
      throw const RemoteCatalogManifestException(
        'coverage',
        'The signed Catalog manifest omits required core coverage.',
      );
    }
    return result;
  }

  RemoteCatalogPackage _validatePackage(
    Object? value,
    RemoteCatalogValidationContext context,
  ) {
    final package = _strictObject(
      value,
      _packageFields,
      code: 'package_shape',
      message: 'The complete Catalog package metadata has an invalid shape.',
    );
    if (_string(package, 'kind') != 'complete_catalog' ||
        _string(package, 'archive_format') != 'zip') {
      throw const RemoteCatalogManifestException(
        'package_format',
        'Only complete ZIP Catalog packages are supported.',
      );
    }
    final archiveBytes = _integer(package, 'archive_bytes');
    if (archiveBytes < 1 || archiveBytes > context.maximumPackageBytes) {
      throw const RemoteCatalogManifestException(
        'package_size',
        'The complete Catalog package size is outside the allowed range.',
      );
    }
    final archiveSha256 = _string(package, 'archive_sha256');
    if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(archiveSha256)) {
      throw const RemoteCatalogManifestException(
        'package_hash',
        'The complete Catalog package hash is invalid.',
      );
    }
    final urlText = _string(package, 'url');
    final url = Uri.tryParse(urlText);
    if (url == null ||
        !url.isAbsolute ||
        url.scheme != 'https' ||
        url.host.isEmpty ||
        url.userInfo.isNotEmpty ||
        url.fragment.isNotEmpty ||
        url.query.isNotEmpty ||
        url.port != 443 ||
        !url.path.endsWith('.zip') ||
        url.pathSegments.any((segment) => segment == '.' || segment == '..') ||
        !context.allowedHosts.contains(url.host)) {
      throw const RemoteCatalogManifestException(
        'package_url',
        'The complete Catalog package URL is not allowed.',
      );
    }
    return RemoteCatalogPackage(
      url: url,
      archiveBytes: archiveBytes,
      archiveSha256: archiveSha256,
    );
  }
}

Map<String, dynamic> _strictObject(
  Object? value,
  Set<String> fields, {
  required String code,
  required String message,
}) {
  if (value is! Map<String, dynamic> ||
      value.length != fields.length ||
      !value.keys.toSet().containsAll(fields)) {
    throw RemoteCatalogManifestException(code, message);
  }
  return value;
}

int _integer(Map<String, dynamic> value, String key) {
  final field = value[key];
  if (field is! int) {
    throw RemoteCatalogManifestException(
      'manifest_field',
      '$key must be an integer.',
    );
  }
  return field;
}

String _string(Map<String, dynamic> value, String key) {
  final field = value[key];
  if (field is! String || field.isEmpty) {
    throw RemoteCatalogManifestException(
      'manifest_field',
      '$key must be a non-empty string.',
    );
  }
  return field;
}

Uint8List _decodeBase64UrlNoPadding(
  String value, {
  required String code,
  int? expectedBytes,
  int? maximumBytes,
}) {
  if (!RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(value) || value.length % 4 == 1) {
    throw RemoteCatalogManifestException(
      code,
      'A manifest value is not canonical unpadded base64url.',
    );
  }
  final List<int> decoded;
  try {
    decoded = base64Url.decode(base64Url.normalize(value));
  } on FormatException {
    throw RemoteCatalogManifestException(
      code,
      'A manifest value is not valid base64url.',
    );
  }
  if ((expectedBytes != null && decoded.length != expectedBytes) ||
      (maximumBytes != null && decoded.length > maximumBytes) ||
      _base64UrlNoPadding(decoded) != value) {
    throw RemoteCatalogManifestException(
      code,
      'A manifest value has an invalid decoded length or encoding.',
    );
  }
  return Uint8List.fromList(decoded);
}

String _base64UrlNoPadding(List<int> bytes) =>
    base64UrlEncode(bytes).replaceAll('=', '');

String _decodeUtf8(Uint8List bytes) {
  try {
    return utf8.decode(bytes, allowMalformed: false);
  } on FormatException {
    throw const RemoteCatalogManifestException(
      'payload_utf8',
      'The signed Catalog manifest payload is not valid UTF-8.',
    );
  }
}

String _canonicalJson(Object? value) {
  if (value == null || value is bool || value is int || value is String) {
    return jsonEncode(value);
  }
  if (value is List) {
    return '[${value.map(_canonicalJson).join(',')}]';
  }
  if (value is Map<String, dynamic>) {
    final keys = value.keys.toList()..sort();
    return '{${keys.map((key) => '${jsonEncode(key)}:${_canonicalJson(value[key])}').join(',')}}';
  }
  throw const RemoteCatalogManifestException(
    'payload_canonical',
    'The signed Catalog manifest payload uses an unsupported JSON value.',
  );
}

List<int>? _parseVersion(String value) {
  final match = RegExp(r'^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$')
      .firstMatch(value);
  if (match == null) {
    return null;
  }
  return <int>[
    int.parse(match.group(1)!),
    int.parse(match.group(2)!),
    int.parse(match.group(3)!),
  ];
}

int _compareVersions(List<int> left, List<int> right) {
  for (var index = 0; index < 3; index += 1) {
    final compared = left[index].compareTo(right[index]);
    if (compared != 0) {
      return compared;
    }
  }
  return 0;
}

DateTime? _parseUtcTimestamp(String value) {
  if (!RegExp(r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$').hasMatch(value)) {
    return null;
  }
  final parsed = DateTime.tryParse(value);
  if (parsed == null || !parsed.isUtc) {
    return null;
  }
  final normalized =
      '${parsed.year.toString().padLeft(4, '0')}-'
      '${parsed.month.toString().padLeft(2, '0')}-'
      '${parsed.day.toString().padLeft(2, '0')}T'
      '${parsed.hour.toString().padLeft(2, '0')}:'
      '${parsed.minute.toString().padLeft(2, '0')}:'
      '${parsed.second.toString().padLeft(2, '0')}Z';
  return normalized == value ? parsed : null;
}
