import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

import 'catalog_installer.dart';
import 'remote_catalog_manifest.dart';

final class RemoteCatalogArchiveException implements Exception {
  const RemoteCatalogArchiveException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => '$code: $message';
}

final class VerifiedRemoteCatalogArchive {
  const VerifiedRemoteCatalogArchive._({
    required this.remoteManifest,
    required this.bundle,
  });

  final VerifiedRemoteCatalogManifest remoteManifest;
  final BundledCatalogBundle bundle;

  Future<CatalogOpenResult> installWith(CatalogInstaller installer) {
    return installer.installVerifiedRemoteCatalog(
      bundle,
      releaseSequence: remoteManifest.releaseSequence,
    );
  }
}

final class RemoteCatalogPackagePipeline {
  const RemoteCatalogPackagePipeline({
    this.archiveDecoder = const RemoteCatalogArchiveDecoder(),
  });

  final RemoteCatalogArchiveDecoder archiveDecoder;

  Future<CatalogOpenResult> verifyAndInstall({
    required String envelopeText,
    required Uint8List archiveBytes,
    required RemoteCatalogValidationContext context,
    required RemoteCatalogManifestVerifier verifier,
    required CatalogInstaller installer,
  }) async {
    final persistedSequence = await installer
        .readHighestAcceptedRemoteReleaseSequence();
    final verified = await verifier.verify(
      envelopeText,
      context: context.withHighestAcceptedReleaseSequence(persistedSequence),
    );
    final archive = archiveDecoder.decode(
      manifest: verified,
      archiveBytes: archiveBytes,
    );
    return archive.installWith(installer);
  }
}

final class RemoteCatalogArchiveDecoder {
  const RemoteCatalogArchiveDecoder();

  static const manifestPath = 'assets/catalog/bundled_catalog.json';
  static const databasePath = 'assets/catalog/catalog.db';
  static const attributionPath = 'assets/catalog/ATTRIBUTION.txt';

  static const _maximumManifestBytes = 64 * 1024;
  static const _maximumAttributionBytes = 256 * 1024;
  static const _maximumDatabaseBytes = 128 * 1024 * 1024;
  static const _endOfCentralDirectoryBytes = 22;
  static const _allowedFlags = 0x0008 | 0x0800;
  static const _requiredPaths = <String>{
    manifestPath,
    databasePath,
    attributionPath,
  };

  VerifiedRemoteCatalogArchive decode({
    required VerifiedRemoteCatalogManifest manifest,
    required Uint8List archiveBytes,
  }) {
    manifest.package.validateBytes(archiveBytes);

    final decoder = ZipDecoder();
    final Archive archive;
    try {
      archive = decoder.decodeBytes(archiveBytes);
    } on Object catch (error) {
      throw RemoteCatalogArchiveException(
        'archive_decode',
        'The complete Catalog ZIP cannot be decoded: $error',
      );
    }

    final directory = decoder.directory;
    final headers = directory.fileHeaders;
    if (directory.filePosition < 0 ||
        directory.numberOfThisDisk != 0 ||
        directory.diskWithTheStartOfTheCentralDirectory != 0 ||
        directory.totalCentralDirectoryEntriesOnThisDisk !=
            _requiredPaths.length ||
        directory.totalCentralDirectoryEntries != _requiredPaths.length ||
        directory.zipFileComment.isNotEmpty ||
        directory.centralDirectoryOffset < 0 ||
        directory.centralDirectorySize < 1 ||
        directory.centralDirectoryOffset + directory.centralDirectorySize !=
            directory.filePosition ||
        directory.filePosition + _endOfCentralDirectoryBytes !=
            archiveBytes.length ||
        headers.length != _requiredPaths.length ||
        archive.length != _requiredPaths.length) {
      throw const RemoteCatalogArchiveException(
        'archive_shape',
        'The complete Catalog ZIP container has an invalid shape.',
      );
    }

    final headerNames = headers.map((header) => header.filename).toList();
    if (headerNames.toSet().length != headerNames.length ||
        headerNames.toSet().difference(_requiredPaths).isNotEmpty ||
        _requiredPaths.difference(headerNames.toSet()).isNotEmpty) {
      throw const RemoteCatalogArchiveException(
        'archive_entries',
        'The complete Catalog ZIP must contain exactly the allowed files.',
      );
    }

    final contents = <String, Uint8List>{};
    for (final header in headers) {
      final maximumBytes = switch (header.filename) {
        manifestPath => _maximumManifestBytes,
        databasePath => _maximumDatabaseBytes,
        attributionPath => _maximumAttributionBytes,
        _ => 0,
      };
      final local = header.file;
      final expectedCompression = switch (header.compressionMethod) {
        0 => CompressionType.none,
        8 => CompressionType.deflate,
        _ => null,
      };
      if (header.diskNumberStart != 0 ||
          header.versionNeededToExtract > 20 ||
          header.generalPurposeBitFlag & ~_allowedFlags != 0 ||
          header.extraField?.isNotEmpty == true ||
          header.fileComment.isNotEmpty ||
          header.compressedSize < 1 ||
          header.compressedSize > archiveBytes.length ||
          header.uncompressedSize < 1 ||
          header.uncompressedSize > maximumBytes ||
          local == null ||
          local.filename != header.filename ||
          local.flags != header.generalPurposeBitFlag ||
          local.extraField?.isNotEmpty == true ||
          local.compressionMethod != expectedCompression) {
        throw const RemoteCatalogArchiveException(
          'archive_entry_contract',
          'A complete Catalog ZIP entry violates its safety contract.',
        );
      }

      final entry = archive.find(header.filename);
      if (entry == null ||
          !entry.isFile ||
          entry.isSymbolicLink ||
          entry.size != header.uncompressedSize) {
        throw const RemoteCatalogArchiveException(
          'archive_entry_type',
          'A complete Catalog ZIP entry has an unsupported type.',
        );
      }
      final output = _BoundedOutputMemoryStream(maximumBytes);
      final Uint8List bytes;
      try {
        entry.writeContent(output, freeMemory: false);
        bytes = Uint8List.fromList(output.getBytes());
      } on _ArchiveOutputLimitException {
        throw const RemoteCatalogArchiveException(
          'archive_entry_size',
          'A complete Catalog ZIP entry exceeds its extraction limit.',
        );
      } on Object catch (error) {
        throw RemoteCatalogArchiveException(
          'archive_entry_decode',
          'A complete Catalog ZIP entry cannot be decoded: $error',
        );
      }
      if (bytes.length != header.uncompressedSize ||
          getCrc32(bytes) != header.crc32) {
        throw const RemoteCatalogArchiveException(
          'archive_entry_integrity',
          'A complete Catalog ZIP entry failed length or CRC validation.',
        );
      }
      contents[header.filename] = bytes;
    }

    final manifestText = _decodeText(
      contents[manifestPath]!,
      code: 'archive_manifest_text',
    );
    final attributionText = _decodeText(
      contents[attributionPath]!,
      code: 'archive_attribution_text',
    );
    try {
      CatalogAttributionValidator.validateText(attributionText);
    } on CatalogInstallException {
      throw const RemoteCatalogArchiveException(
        'archive_attribution_contract',
        'The complete Catalog package attribution is incomplete.',
      );
    }

    final CatalogManifest catalogManifest;
    try {
      catalogManifest = CatalogManifest.fromJsonText(manifestText);
    } on CatalogInstallException catch (error) {
      throw RemoteCatalogArchiveException(
        'archive_catalog_manifest',
        'The packaged Catalog manifest is invalid: ${error.code}.',
      );
    }
    if (catalogManifest.datasetId != manifest.datasetId ||
        catalogManifest.catalogSchemaVersion != manifest.catalogSchemaVersion ||
        catalogManifest.dataVersion != manifest.dataVersion ||
        catalogManifest.snapshotId != manifest.snapshotId ||
        !_sameCoverage(catalogManifest.coverage, manifest.coverage)) {
      throw const RemoteCatalogArchiveException(
        'archive_manifest_mismatch',
        'The packaged Catalog manifest does not match the signed manifest.',
      );
    }

    return VerifiedRemoteCatalogArchive._(
      remoteManifest: manifest,
      bundle: BundledCatalogBundle(
        manifestText: manifestText,
        databaseBytes: contents[databasePath]!,
        attributionText: attributionText,
      ),
    );
  }
}

String _decodeText(Uint8List bytes, {required String code}) {
  try {
    return utf8.decode(bytes, allowMalformed: false);
  } on FormatException {
    throw RemoteCatalogArchiveException(
      code,
      'A complete Catalog package text file is not valid UTF-8.',
    );
  }
}

bool _sameCoverage(Map<String, bool> left, Map<String, bool> right) {
  return left.length == right.length &&
      left.entries.every((entry) => right[entry.key] == entry.value);
}

final class _ArchiveOutputLimitException implements Exception {
  const _ArchiveOutputLimitException();
}

final class _BoundedOutputMemoryStream extends OutputMemoryStream {
  _BoundedOutputMemoryStream(this.maximumBytes)
    : super(
        size: maximumBytes < OutputMemoryStream.defaultBufferSize
            ? maximumBytes
            : OutputMemoryStream.defaultBufferSize,
      );

  final int maximumBytes;

  void _checkAdditional(int value) {
    if (value < 0 || length + value > maximumBytes) {
      throw const _ArchiveOutputLimitException();
    }
  }

  @override
  void writeByte(int value) {
    _checkAdditional(1);
    super.writeByte(value);
  }

  @override
  void writeBytes(List<int> bytes, {int? length}) {
    _checkAdditional(length ?? bytes.length);
    super.writeBytes(bytes, length: length);
  }

  @override
  void writeStream(InputStream stream) {
    _checkAdditional(stream.length);
    super.writeStream(stream);
  }

  @override
  void writeBackReference(int distance, int count) {
    _checkAdditional(count);
    super.writeBackReference(distance, count);
  }
}
