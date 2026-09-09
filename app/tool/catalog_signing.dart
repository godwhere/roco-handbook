import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:path/path.dart' as paths;
import 'package:roco_handbook/data/catalog/remote_catalog_manifest.dart';

final class CatalogSigningException implements Exception {
  const CatalogSigningException(this.message);

  final String message;

  @override
  String toString() => message;
}

final class CatalogSigningKey {
  const CatalogSigningKey({
    required this.keyId,
    required this.privateKeyBytes,
    required this.publicKeyBytes,
    required this.firstReleaseSequence,
    required this.lastReleaseSequence,
  });

  static const _fields = <String>{
    'key_file_version',
    'algorithm',
    'key_id',
    'private_key',
    'public_key',
    'first_release_sequence',
    'last_release_sequence',
  };

  final String keyId;
  final Uint8List privateKeyBytes;
  final Uint8List publicKeyBytes;
  final int firstReleaseSequence;
  final int? lastReleaseSequence;

  factory CatalogSigningKey.fromJsonText(String text) {
    final Object? decoded;
    try {
      decoded = jsonDecode(text);
    } on FormatException catch (error) {
      throw CatalogSigningException('Private key JSON is invalid: $error');
    }
    if (decoded is! Map<String, dynamic> ||
        decoded.keys.toSet().length != _fields.length ||
        !decoded.keys.toSet().containsAll(_fields) ||
        decoded['key_file_version'] != 1 ||
        decoded['algorithm'] != 'ed25519') {
      throw const CatalogSigningException(
        'Private key fields do not match version 1.',
      );
    }
    final keyId = decoded['key_id'];
    final firstSequence = decoded['first_release_sequence'];
    final lastSequence = decoded['last_release_sequence'];
    if (keyId is! String ||
        !RegExp(r'^[a-z0-9][a-z0-9._-]{0,63}$').hasMatch(keyId) ||
        firstSequence is! int ||
        firstSequence < 1 ||
        (lastSequence != null &&
            (lastSequence is! int || lastSequence < firstSequence))) {
      throw const CatalogSigningException(
        'Private key identity or release range is invalid.',
      );
    }
    return CatalogSigningKey(
      keyId: keyId,
      privateKeyBytes: _decodeKeyBytes(decoded['private_key'], 'private'),
      publicKeyBytes: _decodeKeyBytes(decoded['public_key'], 'public'),
      firstReleaseSequence: firstSequence,
      lastReleaseSequence: lastSequence as int?,
    );
  }

  bool acceptsSequence(int value) =>
      value >= firstReleaseSequence &&
      (lastReleaseSequence == null || value <= lastReleaseSequence!);

  Map<String, Object?> toPrivateJson() => <String, Object?>{
    'algorithm': 'ed25519',
    'first_release_sequence': firstReleaseSequence,
    'key_file_version': 1,
    'key_id': keyId,
    'last_release_sequence': lastReleaseSequence,
    'private_key': _base64UrlNoPadding(privateKeyBytes),
    'public_key': _base64UrlNoPadding(publicKeyBytes),
  };

  Map<String, Object?> toTrustedPublicJson() => <String, Object?>{
    'algorithm': 'ed25519',
    'first_release_sequence': firstReleaseSequence,
    'key_id': keyId,
    'last_release_sequence': lastReleaseSequence,
    'public_key': _base64UrlNoPadding(publicKeyBytes),
  };
}

Future<Map<String, Object?>> generateCatalogSigningKey({
  required String keyId,
  required int firstReleaseSequence,
  int? lastReleaseSequence,
  required File privateKeyOutput,
  required File trustStoreOutput,
  required Directory repositoryRoot,
}) async {
  if (!RegExp(r'^[a-z0-9][a-z0-9._-]{0,63}$').hasMatch(keyId) ||
      firstReleaseSequence < 1 ||
      (lastReleaseSequence != null &&
          lastReleaseSequence < firstReleaseSequence)) {
    throw const CatalogSigningException(
      'Key identity or release range is invalid.',
    );
  }
  _requirePrivatePathOutsideRepository(privateKeyOutput, repositoryRoot);
  _requireSafePrivateKeyDirectory(privateKeyOutput.parent);
  _requireNewFile(privateKeyOutput);
  _requireNewFile(trustStoreOutput);

  final algorithm = Ed25519();
  final keyPair = await algorithm.newKeyPair();
  final extracted = await keyPair.extract();
  try {
    final privateBytes = await extracted.extractPrivateKeyBytes();
    final publicKey = await extracted.extractPublicKey();
    final key = CatalogSigningKey(
      keyId: keyId,
      privateKeyBytes: Uint8List.fromList(privateBytes),
      publicKeyBytes: Uint8List.fromList(publicKey.bytes),
      firstReleaseSequence: firstReleaseSequence,
      lastReleaseSequence: lastReleaseSequence,
    );
    try {
      final trustStore = <String, Object?>{
        'keys': <Object?>[key.toTrustedPublicJson()],
        'trust_store_version': 1,
      };
      CatalogManifestTrustStore.fromJsonText(jsonEncode(trustStore));

      _writeNewTextFile(
        trustStoreOutput,
        '${const JsonEncoder.withIndent('  ').convert(trustStore)}\n',
        mode: '644',
      );
      try {
        _writeNewTextFile(
          privateKeyOutput,
          '${const JsonEncoder.withIndent('  ').convert(key.toPrivateJson())}\n',
          mode: '600',
        );
      } on Object {
        if (trustStoreOutput.existsSync()) {
          trustStoreOutput.deleteSync();
        }
        rethrow;
      }
      return <String, Object?>{
        'status': 'generated',
        'key_id': keyId,
        'first_release_sequence': firstReleaseSequence,
        'last_release_sequence': lastReleaseSequence,
        'private_key_path': privateKeyOutput.absolute.path,
        'trust_store_path': trustStoreOutput.absolute.path,
        'public_key': _base64UrlNoPadding(publicKey.bytes),
      };
    } finally {
      key.privateKeyBytes.fillRange(0, key.privateKeyBytes.length, 0);
    }
  } finally {
    extracted.destroy();
  }
}

Future<Map<String, Object?>> signCatalogManifestPayload({
  required File privateKeyFile,
  required File payloadFile,
  required File envelopeOutput,
  required Directory repositoryRoot,
}) async {
  _requirePrivatePathOutsideRepository(privateKeyFile, repositoryRoot);
  _requireSafePrivateKeyFile(privateKeyFile);
  _requireNewFile(envelopeOutput);
  final key = CatalogSigningKey.fromJsonText(privateKeyFile.readAsStringSync());
  try {
    _requireSafePayloadFile(payloadFile);
    final Object? decodedPayload;
    try {
      decodedPayload = jsonDecode(payloadFile.readAsStringSync());
    } on Object catch (error) {
      throw CatalogSigningException(
        'Catalog manifest payload is invalid: $error',
      );
    }
    if (decodedPayload is! Map<String, dynamic>) {
      throw const CatalogSigningException(
        'Catalog manifest payload must contain one JSON object.',
      );
    }
    final payloadText = encodeCanonicalCatalogManifestJson(decodedPayload);
    final payloadBytes = utf8.encode(payloadText);
    final releaseSequence = decodedPayload['release_sequence'];
    if (releaseSequence is! int || !key.acceptsSequence(releaseSequence)) {
      throw const CatalogSigningException(
        'Catalog manifest release sequence is outside the key range.',
      );
    }

    final algorithm = Ed25519();
    final keyPair = await algorithm.newKeyPairFromSeed(key.privateKeyBytes);
    try {
      final derivedPublicKey = await keyPair.extractPublicKey();
      if (!_sameBytes(derivedPublicKey.bytes, key.publicKeyBytes)) {
        throw const CatalogSigningException(
          'The private key does not match its recorded public key.',
        );
      }
      final signature = await algorithm.sign(payloadBytes, keyPair: keyPair);
      final envelope = <String, Object?>{
        'envelope_version': 1,
        'key_id': key.keyId,
        'payload': _base64UrlNoPadding(payloadBytes),
        'payload_encoding': 'base64url',
        'signature': _base64UrlNoPadding(signature.bytes),
        'signature_algorithm': 'ed25519',
      };
      await _verifyEnvelopeBeforeWriting(
        envelope,
        payload: decodedPayload,
        key: key,
      );
      _writeNewTextFile(
        envelopeOutput,
        '${const JsonEncoder.withIndent('  ').convert(envelope)}\n',
        mode: '644',
      );
      return <String, Object?>{
        'status': 'signed',
        'key_id': key.keyId,
        'release_sequence': releaseSequence,
        'envelope_path': envelopeOutput.absolute.path,
        'public_key': _base64UrlNoPadding(key.publicKeyBytes),
      };
    } finally {
      keyPair.destroy();
    }
  } finally {
    key.privateKeyBytes.fillRange(0, key.privateKeyBytes.length, 0);
  }
}

Future<void> _verifyEnvelopeBeforeWriting(
  Map<String, Object?> envelope, {
  required Map<String, dynamic> payload,
  required CatalogSigningKey key,
}) async {
  final package = payload['package'];
  final packageUrl = package is Map<String, dynamic>
      ? Uri.tryParse(package['url'] is String ? package['url'] as String : '')
      : null;
  final dataVersion = payload['data_version'];
  final releaseSequence = payload['release_sequence'];
  final minimumAppVersion = payload['minimum_app_version'];
  final protocolVersion = payload['protocol_version'];
  final schemaVersion = payload['catalog_schema_version'];
  final archiveBytes = package is Map<String, dynamic>
      ? package['archive_bytes']
      : null;
  if (packageUrl == null ||
      packageUrl.host.isEmpty ||
      dataVersion is! int ||
      dataVersion < 2 ||
      releaseSequence is! int ||
      releaseSequence < 1 ||
      minimumAppVersion is! String ||
      protocolVersion is! int ||
      protocolVersion < 1 ||
      schemaVersion is! int ||
      schemaVersion < 1 ||
      archiveBytes is! int ||
      archiveBytes < 1) {
    throw const CatalogSigningException(
      'Catalog manifest payload cannot form a valid release context.',
    );
  }
  final verifier = RemoteCatalogManifestVerifier(
    CatalogManifestTrustStore(<CatalogManifestTrustedKey>[
      CatalogManifestTrustedKey(
        keyId: key.keyId,
        publicKeyBytes: key.publicKeyBytes,
        firstReleaseSequence: key.firstReleaseSequence,
        lastReleaseSequence: key.lastReleaseSequence,
      ),
    ]),
  );
  try {
    await verifier.verify(
      jsonEncode(envelope),
      context: RemoteCatalogValidationContext(
        currentAppVersion: minimumAppVersion,
        currentDataVersion: dataVersion - 1,
        highestAcceptedReleaseSequence: releaseSequence - 1,
        allowedHosts: <String>{packageUrl.host},
        supportedProtocolVersion: protocolVersion,
        supportedCatalogSchemaVersion: schemaVersion,
        maximumPackageBytes: archiveBytes,
      ),
    );
  } on Object catch (error) {
    throw CatalogSigningException(
      'Generated envelope failed production verification: $error',
    );
  }
}

void _requirePrivatePathOutsideRepository(File file, Directory repositoryRoot) {
  final String parentPath;
  final String rootPath;
  try {
    parentPath = paths.normalize(file.parent.resolveSymbolicLinksSync());
    rootPath = paths.normalize(repositoryRoot.resolveSymbolicLinksSync());
  } on FileSystemException catch (error) {
    throw CatalogSigningException(
      'Cannot resolve the private key custody boundary: $error',
    );
  }
  final privatePath = paths.join(parentPath, paths.basename(file.path));
  if (privatePath == rootPath || paths.isWithin(rootPath, privatePath)) {
    throw const CatalogSigningException(
      'The private key path must be outside the repository.',
    );
  }
}

void _requireSafePrivateKeyFile(File file) {
  if (FileSystemEntity.typeSync(file.path, followLinks: false) !=
      FileSystemEntityType.file) {
    throw const CatalogSigningException(
      'The private key must be a regular non-link file.',
    );
  }
  final stat = FileStat.statSync(file.path);
  if (stat.size < 1 || stat.size > 4096) {
    throw const CatalogSigningException(
      'The private key file has an invalid size.',
    );
  }
  if ((Platform.isMacOS || Platform.isLinux) && stat.mode & 0x3f != 0) {
    throw const CatalogSigningException(
      'The private key must not grant group or other permissions.',
    );
  }
}

void _requireSafePrivateKeyDirectory(Directory directory) {
  if (FileSystemEntity.typeSync(directory.path, followLinks: false) !=
      FileSystemEntityType.directory) {
    throw const CatalogSigningException(
      'The private key directory must exist and must not be a link.',
    );
  }
  if ((Platform.isMacOS || Platform.isLinux) &&
      FileStat.statSync(directory.path).mode & 0x3f != 0) {
    throw const CatalogSigningException(
      'The private key directory must not grant group or other permissions.',
    );
  }
}

void _requireSafePayloadFile(File file) {
  if (FileSystemEntity.typeSync(file.path, followLinks: false) !=
      FileSystemEntityType.file) {
    throw const CatalogSigningException(
      'The Catalog manifest payload must be a regular non-link file.',
    );
  }
  final size = FileStat.statSync(file.path).size;
  if (size < 1 || size > 64 * 1024) {
    throw const CatalogSigningException(
      'Catalog manifest payload exceeds its size limit.',
    );
  }
}

void _requireNewFile(File file) {
  if (file.existsSync() ||
      FileSystemEntity.typeSync(file.path, followLinks: false) ==
          FileSystemEntityType.link) {
    throw CatalogSigningException('Output already exists: ${file.path}');
  }
}

void _writeNewTextFile(File file, String text, {required String mode}) {
  _requireNewFile(file);
  file.parent.createSync(recursive: true);
  var ownsFile = false;
  try {
    file.createSync(exclusive: true);
    ownsFile = true;
    if (Platform.isMacOS || Platform.isLinux) {
      final result = Process.runSync('chmod', <String>[mode, file.path]);
      if (result.exitCode != 0) {
        throw CatalogSigningException(
          'Cannot restrict file permissions for ${file.path}.',
        );
      }
    }
    file.writeAsStringSync(text, flush: true);
    ownsFile = false;
  } on FileSystemException catch (error) {
    throw CatalogSigningException('Cannot create ${file.path}: $error');
  } finally {
    if (ownsFile && file.existsSync()) {
      file.deleteSync();
    }
  }
}

Uint8List _decodeKeyBytes(Object? value, String label) {
  if (value is! String || !RegExp(r'^[A-Za-z0-9_-]{43}$').hasMatch(value)) {
    throw CatalogSigningException('The $label key encoding is invalid.');
  }
  try {
    final bytes = base64Url.decode('$value=');
    if (bytes.length != 32 || _base64UrlNoPadding(bytes) != value) {
      throw const FormatException();
    }
    return Uint8List.fromList(bytes);
  } on FormatException {
    throw CatalogSigningException('The $label key encoding is invalid.');
  }
}

bool _sameBytes(List<int> left, List<int> right) {
  if (left.length != right.length) {
    return false;
  }
  var difference = 0;
  for (var index = 0; index < left.length; index += 1) {
    difference |= left[index] ^ right[index];
  }
  return difference == 0;
}

String _base64UrlNoPadding(List<int> bytes) =>
    base64UrlEncode(bytes).replaceAll('=', '');

Map<String, String> _parseOptions(List<String> arguments) {
  if (arguments.length.isOdd) {
    throw const CatalogSigningException('Every option requires one value.');
  }
  final result = <String, String>{};
  for (var index = 0; index < arguments.length; index += 2) {
    final name = arguments[index];
    if (!name.startsWith('--') || result.containsKey(name)) {
      throw CatalogSigningException('Invalid or duplicate option: $name');
    }
    result[name] = arguments[index + 1];
  }
  return result;
}

String _requiredOption(Map<String, String> options, String name) {
  final value = options[name];
  if (value == null || value.isEmpty) {
    throw CatalogSigningException('Missing required option: $name');
  }
  return value;
}

Future<void> main(List<String> arguments) async {
  if (arguments.isEmpty) {
    throw const CatalogSigningException(
      'Expected generate-key or sign-payload.',
    );
  }
  final command = arguments.first;
  final options = _parseOptions(arguments.sublist(1));
  final repositoryRoot = Directory(
    paths.normalize(
      paths.join(File.fromUri(Platform.script).parent.path, '..', '..'),
    ),
  );
  final Map<String, Object?> report;
  if (command == 'generate-key') {
    final firstSequence = int.tryParse(
      _requiredOption(options, '--first-release-sequence'),
    );
    final lastText = options['--last-release-sequence'];
    final lastSequence = lastText == null ? null : int.tryParse(lastText);
    if (firstSequence == null || (lastText != null && lastSequence == null)) {
      throw const CatalogSigningException('Release ranges must be integers.');
    }
    report = await generateCatalogSigningKey(
      keyId: _requiredOption(options, '--key-id'),
      firstReleaseSequence: firstSequence,
      lastReleaseSequence: lastSequence,
      privateKeyOutput: File(_requiredOption(options, '--private-key-output')),
      trustStoreOutput: File(_requiredOption(options, '--trust-store-output')),
      repositoryRoot: repositoryRoot,
    );
  } else if (command == 'sign-payload') {
    report = await signCatalogManifestPayload(
      privateKeyFile: File(_requiredOption(options, '--private-key')),
      payloadFile: File(_requiredOption(options, '--payload')),
      envelopeOutput: File(_requiredOption(options, '--output')),
      repositoryRoot: repositoryRoot,
    );
  } else {
    throw CatalogSigningException('Unknown command: $command');
  }
  stdout.writeln(const JsonEncoder.withIndent('  ').convert(report));
}
