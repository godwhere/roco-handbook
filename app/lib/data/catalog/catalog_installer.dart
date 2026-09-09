import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as paths;
import 'package:sqlite3/sqlite3.dart';

final class CatalogManifest {
  const CatalogManifest({
    required this.manifestVersion,
    required this.datasetId,
    required this.catalogSchemaVersion,
    required this.dataVersion,
    required this.snapshotId,
    required this.databaseAsset,
    required this.databaseBytes,
    required this.databaseSha256,
    required this.coverage,
  });

  static const _fields = <String>{
    'manifest_version',
    'dataset_id',
    'catalog_schema_version',
    'data_version',
    'snapshot_id',
    'database_asset',
    'database_bytes',
    'database_sha256',
    'coverage',
  };

  static const _coverageFields = <String>{
    'pets',
    'skills',
    'evolutions',
    'topic_rewards',
    'skill_stone_topics',
    'description_note_definitions',
  };

  final int manifestVersion;
  final String datasetId;
  final int catalogSchemaVersion;
  final int dataVersion;
  final String snapshotId;
  final String databaseAsset;
  final int databaseBytes;
  final String databaseSha256;
  final Map<String, bool> coverage;

  factory CatalogManifest.fromJsonText(String text) {
    final Object? decoded;
    try {
      decoded = jsonDecode(text);
    } on FormatException catch (error) {
      throw CatalogInstallException('manifest_json', error.message);
    }
    if (decoded is! Map<String, dynamic> ||
        !decoded.keys.toSet().containsAll(_fields) ||
        decoded.keys.toSet().length != _fields.length) {
      throw const CatalogInstallException(
        'manifest_shape',
        'The bundled manifest fields do not match version 1.',
      );
    }
    final coverageValue = decoded['coverage'];
    if (coverageValue is! Map<String, dynamic> ||
        coverageValue.length != _coverageFields.length ||
        !coverageValue.keys.toSet().containsAll(_coverageFields) ||
        coverageValue.values.any((value) => value is! bool)) {
      throw const CatalogInstallException(
        'manifest_coverage',
        'The bundled manifest coverage map is invalid.',
      );
    }
    final manifest = CatalogManifest(
      manifestVersion: _integer(decoded, 'manifest_version'),
      datasetId: _string(decoded, 'dataset_id'),
      catalogSchemaVersion: _integer(decoded, 'catalog_schema_version'),
      dataVersion: _integer(decoded, 'data_version'),
      snapshotId: _string(decoded, 'snapshot_id'),
      databaseAsset: _string(decoded, 'database_asset'),
      databaseBytes: _integer(decoded, 'database_bytes'),
      databaseSha256: _string(decoded, 'database_sha256'),
      coverage: coverageValue.map((key, value) => MapEntry(key, value as bool)),
    );
    manifest._validateContract();
    return manifest;
  }

  static int _integer(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! int) {
      throw CatalogInstallException(
        'manifest_field',
        '$key must be an integer.',
      );
    }
    return value;
  }

  static String _string(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! String) {
      throw CatalogInstallException('manifest_field', '$key must be a string.');
    }
    return value;
  }

  void _validateContract() {
    if (manifestVersion != 1 ||
        datasetId != 'roco-world-zh-cn' ||
        catalogSchemaVersion != 1 ||
        dataVersion < 1 ||
        snapshotId.isEmpty ||
        databaseAsset != 'assets/catalog/catalog.db' ||
        databaseBytes < 1 ||
        !RegExp(r'^[0-9a-f]{64}$').hasMatch(databaseSha256)) {
      throw const CatalogInstallException(
        'manifest_contract',
        'The bundled manifest is not compatible with this App.',
      );
    }
    if (coverage['pets'] != true ||
        coverage['skills'] != true ||
        coverage['evolutions'] != true) {
      throw const CatalogInstallException(
        'manifest_core_coverage',
        'The bundled Catalog does not cover required creatures, skills, and evolutions.',
      );
    }
  }
}

final class CatalogAttributionValidator {
  const CatalogAttributionValidator._();

  static const maximumBytes = 256 * 1024;

  static void validateText(String text) {
    final bytes = utf8.encode(text);
    if (bytes.isEmpty ||
        bytes.length > maximumBytes ||
        text.contains('\u0000') ||
        !text.startsWith(
          'Roco World Offline Handbook - Catalog Attribution\n',
        ) ||
        !text.contains('\nSource: ') ||
        !text.contains('\nLicense: ') ||
        !text.contains('\nLicense URL: https://')) {
      throw const CatalogInstallException(
        'attribution_contract',
        'The Catalog attribution text is incomplete or too large.',
      );
    }
  }
}

final class _CatalogAttribution {
  _CatalogAttribution.fromText(this.text)
    : bytes = utf8.encode(text),
      sha256Value = sha256.convert(utf8.encode(text)).toString() {
    CatalogAttributionValidator.validateText(text);
  }

  final String text;
  final List<int> bytes;
  final String sha256Value;
}

final class BundledCatalogBundle {
  const BundledCatalogBundle({
    required this.manifestText,
    required this.databaseBytes,
    required this.attributionText,
  });

  final String manifestText;
  final Uint8List databaseBytes;
  final String attributionText;
}

abstract interface class BundledCatalogSource {
  Future<BundledCatalogBundle> load();
}

final class AssetBundledCatalogSource implements BundledCatalogSource {
  const AssetBundledCatalogSource();

  @override
  Future<BundledCatalogBundle> load() async {
    final manifest = await rootBundle.loadString(
      'assets/catalog/bundled_catalog.json',
    );
    final database = await rootBundle.load('assets/catalog/catalog.db');
    final attribution = await rootBundle.loadString(
      'assets/catalog/ATTRIBUTION.txt',
    );
    return BundledCatalogBundle(
      manifestText: manifest,
      databaseBytes: database.buffer.asUint8List(
        database.offsetInBytes,
        database.lengthInBytes,
      ),
      attributionText: attribution,
    );
  }
}

abstract interface class CatalogInstaller {
  Future<CatalogOpenResult> prepareBundledCatalog(BundledCatalogBundle bundle);

  Future<CatalogOpenResult> restoreBundledCatalog(BundledCatalogBundle bundle);

  Future<CatalogOpenResult> installVerifiedRemoteCatalog(
    BundledCatalogBundle bundle, {
    required int releaseSequence,
  });

  Future<int> readHighestAcceptedRemoteReleaseSequence();
}

enum CatalogOpenOutcome {
  reused,
  installedBundled,
  installedRemote,
  recoveredPrevious,
  restoredBundled,
}

enum CatalogInstallerFaultPoint {
  leaveStagingAfterCopy,
  failStagingWrite,
  failAfterPointerCommit,
}

final class CatalogOpenResult {
  const CatalogOpenResult({
    required this.databasePath,
    required this.manifest,
    required this.attributionText,
    required this.outcome,
    this.previousDataVersion,
  });

  final String databasePath;
  final CatalogManifest manifest;
  final String attributionText;
  final CatalogOpenOutcome outcome;
  final int? previousDataVersion;

  bool get installed =>
      outcome == CatalogOpenOutcome.installedBundled ||
      outcome == CatalogOpenOutcome.installedRemote ||
      outcome == CatalogOpenOutcome.restoredBundled;
}

final class CatalogInstallException implements Exception {
  const CatalogInstallException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => '$code: $message';
}

final class LocalCatalogInstaller implements CatalogInstaller {
  const LocalCatalogInstaller(
    this.applicationSupportPath, {
    this.backgroundWork = true,
    this.faultPoint,
  });

  final String applicationSupportPath;
  final bool backgroundWork;
  final CatalogInstallerFaultPoint? faultPoint;

  @override
  Future<CatalogOpenResult> prepareBundledCatalog(BundledCatalogBundle bundle) {
    return _run(bundle, _CatalogPreparationMode.startup, null);
  }

  @override
  Future<CatalogOpenResult> restoreBundledCatalog(BundledCatalogBundle bundle) {
    return _run(bundle, _CatalogPreparationMode.restoreBundled, null);
  }

  @override
  Future<CatalogOpenResult> installVerifiedRemoteCatalog(
    BundledCatalogBundle bundle, {
    required int releaseSequence,
  }) {
    if (releaseSequence < 1) {
      return Future<CatalogOpenResult>.error(
        const CatalogInstallException(
          'remote_release_sequence',
          'A remote Catalog release sequence must be positive.',
        ),
      );
    }
    return _run(bundle, _CatalogPreparationMode.remote, releaseSequence);
  }

  @override
  Future<int> readHighestAcceptedRemoteReleaseSequence() {
    int execute() =>
        _CatalogFileStore(Directory(applicationSupportPath))
            .readHighestAcceptedRemoteReleaseSequence();
    return backgroundWork ? Isolate.run(execute) : Future.sync(execute);
  }

  Future<CatalogOpenResult> _run(
    BundledCatalogBundle bundle,
    _CatalogPreparationMode mode,
    int? remoteReleaseSequence,
  ) {
    CatalogOpenResult execute() => _prepareCatalog(
      applicationSupportPath,
      bundle,
      mode,
      remoteReleaseSequence,
      faultPoint,
    );
    return backgroundWork ? Isolate.run(execute) : Future.sync(execute);
  }
}

enum _CatalogPreparationMode { startup, restoreBundled, remote }

CatalogOpenResult _prepareCatalog(
  String applicationSupportPath,
  BundledCatalogBundle bundle,
  _CatalogPreparationMode mode,
  int? remoteReleaseSequence,
  CatalogInstallerFaultPoint? faultPoint,
) {
  final store = _CatalogFileStore(Directory(applicationSupportPath));
  final CatalogManifest manifest;
  final _CatalogAttribution attribution;
  try {
    manifest = CatalogManifest.fromJsonText(bundle.manifestText);
    attribution = _CatalogAttribution.fromText(bundle.attributionText);
  } on CatalogInstallException catch (error) {
    store.writeFailureReport(error.code, 0);
    rethrow;
  }
  store.ensureDirectories();
  final lock = store.acquireOperationLock();
  try {
    store.cleanupTransientFiles();
    return _prepareLocked(
      store,
      bundle,
      manifest,
      attribution,
      mode,
      remoteReleaseSequence,
      faultPoint,
    );
  } on CatalogInstallException catch (error) {
    store.writeFailureReport(error.code, manifest.dataVersion);
    rethrow;
  } on FileSystemException catch (error) {
    final wrapped = CatalogInstallException(
      'catalog_file',
      'Cannot prepare the bundled Catalog: ${error.message}',
    );
    store.writeFailureReport(wrapped.code, manifest.dataVersion);
    throw wrapped;
  } finally {
    lock.unlockSync();
    lock.closeSync();
  }
}

CatalogOpenResult _prepareLocked(
  _CatalogFileStore store,
  BundledCatalogBundle bundle,
  CatalogManifest manifest,
  _CatalogAttribution attribution,
  _CatalogPreparationMode mode,
  int? remoteReleaseSequence,
  CatalogInstallerFaultPoint? faultPoint,
) {
  final activeRecord = store.readActivePointer(
    legacyManifest: manifest,
    migrationAttribution: attribution,
  );
  final previousRecord = store.readPreviousPointer(
    migrationAttribution: attribution,
  );
  final active = _validateDescriptor(store, activeRecord);
  final previous = _validateDescriptor(store, previousRecord);

  if (mode == _CatalogPreparationMode.remote) {
    if (remoteReleaseSequence == null ||
        remoteReleaseSequence <=
            store.readHighestAcceptedRemoteReleaseSequence()) {
      throw const CatalogInstallException(
        'remote_release_sequence',
        'The remote Catalog release sequence is stale or replayed.',
      );
    }
    if (active == null) {
      throw const CatalogInstallException(
        'remote_base_missing',
        'A validated active Catalog is required before remote installation.',
      );
    }
    if (manifest.dataVersion <= active.dataVersion) {
      throw const CatalogInstallException(
        'remote_data_version',
        'A remote Catalog must advance the active data version.',
      );
    }
  }

  if (mode == _CatalogPreparationMode.startup && active != null) {
    if (active.hasSameDataVersion(manifest) &&
        !active.matches(manifest, attribution)) {
      throw const CatalogInstallException(
        'data_version_conflict',
        'The bundled Catalog reuses an installed data version with different bytes.',
      );
    }
    if (active.dataVersion >= manifest.dataVersion) {
      store.commitActivePointer(active);
      final retainedPrevious = _distinctDescriptor(previous, active);
      store.commitPreviousPointer(retainedPrevious);
      store.cleanupRetainedCatalogs(active, retainedPrevious);
      store.clearFailureReport();
      return CatalogOpenResult(
        databasePath: store.fileFor(active).path,
        manifest: active.toManifest(),
        attributionText: store.readAttributionText(active),
        outcome: CatalogOpenOutcome.reused,
        previousDataVersion: retainedPrevious?.dataVersion,
      );
    }
  }

  if (mode == _CatalogPreparationMode.startup &&
      active == null &&
      previous != null &&
      previous.dataVersion >= manifest.dataVersion) {
    if (previous.hasSameDataVersion(manifest) &&
        !previous.matches(manifest, attribution)) {
      throw const CatalogInstallException(
        'data_version_conflict',
        'The bundled Catalog reuses a recoverable data version with different bytes.',
      );
    }
    store.commitActivePointer(previous);
    store.commitPreviousPointer(null);
    store.cleanupRetainedCatalogs(previous, null);
    store.clearFailureReport();
    return CatalogOpenResult(
      databasePath: store.fileFor(previous).path,
      manifest: previous.toManifest(),
      attributionText: store.readAttributionText(previous),
      outcome: CatalogOpenOutcome.recoveredPrevious,
    );
  }

  final fallback = active ?? previous;
  try {
    return _activateBundledCatalog(
      store,
      bundle,
      manifest,
      attribution,
      fallback,
      mode,
      remoteReleaseSequence,
      faultPoint,
    );
  } on Object catch (error) {
    if (fallback == null) {
      rethrow;
    }
    store.commitActivePointer(fallback);
    store.commitPreviousPointer(null);
    store.cleanupRetainedCatalogs(fallback, null);
    final code = error is CatalogInstallException
        ? error.code
        : error is FileSystemException
        ? 'catalog_file'
        : 'catalog_activation';
    store.writeFailureReport(code, manifest.dataVersion);
    return CatalogOpenResult(
      databasePath: store.fileFor(fallback).path,
      manifest: fallback.toManifest(),
      attributionText: store.readAttributionText(fallback),
      outcome: CatalogOpenOutcome.recoveredPrevious,
    );
  }
}

CatalogOpenResult _activateBundledCatalog(
  _CatalogFileStore store,
  BundledCatalogBundle bundle,
  CatalogManifest manifest,
  _CatalogAttribution attribution,
  _CatalogDescriptor? fallback,
  _CatalogPreparationMode mode,
  int? remoteReleaseSequence,
  CatalogInstallerFaultPoint? faultPoint,
) {
  if (fallback != null &&
      fallback.hasSameDataVersion(manifest) &&
      !fallback.matches(manifest, attribution)) {
    throw const CatalogInstallException(
      'data_version_conflict',
      'The bundled Catalog reuses an installed data version with different bytes.',
    );
  }
  if (bundle.databaseBytes.length != manifest.databaseBytes ||
      sha256.convert(bundle.databaseBytes).toString() !=
          manifest.databaseSha256) {
    throw const CatalogInstallException(
      'asset_hash',
      'The bundled Catalog bytes do not match the manifest.',
    );
  }

  var candidate = store.descriptorFor(manifest, attribution);
  var target = store.fileFor(candidate);
  var copied = false;
  if (!target.existsSync() || !_isValidCatalogFile(manifest, target)) {
    final staging = store.newStagingFile(manifest);
    var ownsStaging = false;
    try {
      staging.writeAsBytesSync(bundle.databaseBytes, flush: true);
      ownsStaging = true;
      if (faultPoint == CatalogInstallerFaultPoint.leaveStagingAfterCopy) {
        ownsStaging = false;
        throw const CatalogInstallException(
          'injected_copy_interruption',
          'A test interruption occurred after the staging copy.',
        );
      }
      if (faultPoint == CatalogInstallerFaultPoint.failStagingWrite) {
        throw const FileSystemException(
          'A test storage exhaustion occurred while writing staging.',
        );
      }
      CatalogPackageValidator.validateFile(manifest, staging);
      final targetType = FileSystemEntity.typeSync(
        target.path,
        followLinks: false,
      );
      if (targetType == FileSystemEntityType.file) {
        target.deleteSync();
      } else if (targetType == FileSystemEntityType.link) {
        Link(target.path).deleteSync();
      }
      staging.renameSync(target.path);
      ownsStaging = false;
      copied = true;
    } finally {
      if (ownsStaging && staging.existsSync()) {
        staging.deleteSync();
      }
    }
  }
  CatalogPackageValidator.validateFile(manifest, target);
  store.ensureAttribution(candidate, attribution);

  candidate = store.descriptorFor(
    manifest,
    attribution,
    fileName: paths.basename(target.path),
  );
  final retainedFallback = _distinctDescriptor(fallback, candidate);
  if (mode == _CatalogPreparationMode.remote) {
    store.commitHighestAcceptedRemoteReleaseSequence(remoteReleaseSequence!);
  }
  store.commitPreviousPointer(retainedFallback);
  store.commitActivePointer(candidate);

  try {
    if (faultPoint == CatalogInstallerFaultPoint.failAfterPointerCommit) {
      throw const CatalogInstallException(
        'injected_post_activation_open',
        'A test failure occurred after the active pointer was committed.',
      );
    }
    CatalogPackageValidator.validateFile(manifest, target);
    store.validateAttributionFile(candidate);
  } on Object catch (error) {
    if (retainedFallback == null) {
      store.commitActivePointer(null);
      Error.throwWithStackTrace(error, StackTrace.current);
    }
    store.commitActivePointer(retainedFallback);
    store.commitPreviousPointer(null);
    store.cleanupRetainedCatalogs(retainedFallback, null);
    final code = error is CatalogInstallException
        ? error.code
        : 'post_activation_open';
    store.writeFailureReport(code, manifest.dataVersion);
    return CatalogOpenResult(
      databasePath: store.fileFor(retainedFallback).path,
      manifest: retainedFallback.toManifest(),
      attributionText: store.readAttributionText(retainedFallback),
      outcome: CatalogOpenOutcome.recoveredPrevious,
    );
  }

  store.cleanupRetainedCatalogs(candidate, retainedFallback);
  store.clearFailureReport();
  return CatalogOpenResult(
    databasePath: target.path,
    manifest: manifest,
    attributionText: attribution.text,
    outcome: switch (mode) {
      _CatalogPreparationMode.restoreBundled =>
        CatalogOpenOutcome.restoredBundled,
      _CatalogPreparationMode.remote => CatalogOpenOutcome.installedRemote,
      _CatalogPreparationMode.startup =>
        copied
            ? CatalogOpenOutcome.installedBundled
            : CatalogOpenOutcome.reused,
    },
    previousDataVersion: retainedFallback?.dataVersion,
  );
}

_CatalogDescriptor? _validateDescriptor(
  _CatalogFileStore store,
  _CatalogDescriptor? descriptor,
) {
  if (descriptor == null) {
    return null;
  }
  try {
    CatalogPackageValidator.validateFile(
      descriptor.toManifest(),
      store.fileFor(descriptor),
    );
    final migrated = descriptor.migrationAttribution == null
        ? descriptor
        : store.completeAttributionMigration(descriptor);
    store.validateAttributionFile(migrated);
    return migrated;
  } on CatalogInstallException {
    return null;
  } on FileSystemException {
    return null;
  }
}

bool _isValidCatalogFile(CatalogManifest manifest, File file) {
  try {
    CatalogPackageValidator.validateFile(manifest, file);
    return true;
  } on CatalogInstallException {
    return false;
  } on FileSystemException {
    return false;
  }
}

_CatalogDescriptor? _distinctDescriptor(
  _CatalogDescriptor? candidate,
  _CatalogDescriptor active,
) {
  return candidate != null && !candidate.sameArtifact(active)
      ? candidate
      : null;
}

final class CatalogPackageValidator {
  const CatalogPackageValidator._();

  static const requiredTables = <String>{
    'catalog_meta',
    'source_revisions',
    'handbook_entries',
    'types',
    'skills',
    'skill_description_notes',
    'pets',
    'handbook_display',
    'pet_aliases',
    'pet_types',
    'learnsets',
    'pet_learnsets',
    'learnset_native_skills',
    'learnset_blood_skills',
    'learnset_skill_stones',
    'learnset_legendary_skills',
    'evolution_groups',
    'pet_evolution_groups',
    'evolution_edges',
    'entity_sources',
  };

  static const requiredViews = <String>{
    'pet_skill_sources',
    'pet_feature_skills',
  };

  static void validateFile(CatalogManifest manifest, File file) {
    if (FileSystemEntity.typeSync(file.path, followLinks: false) !=
        FileSystemEntityType.file) {
      throw const CatalogInstallException(
        'database_missing',
        'The Catalog database file is missing.',
      );
    }
    final bytes = file.readAsBytesSync();
    if (bytes.length != manifest.databaseBytes ||
        sha256.convert(bytes).toString() != manifest.databaseSha256) {
      throw const CatalogInstallException(
        'database_hash',
        'The Catalog database does not match its manifest.',
      );
    }

    Database? database;
    try {
      database = sqlite3.open(file.path, mode: OpenMode.readOnly);
      final meta = database.select(
        'SELECT dataset_id, schema_version, data_version, snapshot_id '
        'FROM catalog_meta WHERE singleton = 1',
      );
      if (meta.length != 1 ||
          meta.first['dataset_id'] != manifest.datasetId ||
          meta.first['schema_version'] != manifest.catalogSchemaVersion ||
          meta.first['data_version'] != manifest.dataVersion ||
          meta.first['snapshot_id'] != manifest.snapshotId) {
        throw const CatalogInstallException(
          'database_metadata',
          'Catalog metadata does not match the manifest.',
        );
      }
      final tables = database
          .select(
            "SELECT name FROM sqlite_master WHERE type = 'table' "
            "AND name NOT LIKE 'sqlite_%'",
          )
          .map((row) => row['name'] as String)
          .toSet();
      final views = database
          .select("SELECT name FROM sqlite_master WHERE type = 'view'")
          .map((row) => row['name'] as String)
          .toSet();
      if (!tables.containsAll(requiredTables) ||
          !views.containsAll(requiredViews)) {
        throw const CatalogInstallException(
          'database_contract',
          'The Catalog database is missing required objects.',
        );
      }
      final integrity = database.select('PRAGMA integrity_check');
      final foreignKeys = database.select('PRAGMA foreign_key_check');
      if (integrity.length != 1 ||
          integrity.first.values.first != 'ok' ||
          foreignKeys.isNotEmpty) {
        throw const CatalogInstallException(
          'database_integrity',
          'The Catalog database did not pass integrity checks.',
        );
      }
      final probe = database.select(
        'SELECT h.dex_no, f.skill_id FROM pets p '
        'JOIN handbook_entries h ON h.handbook_id = p.handbook_id '
        'JOIN pet_feature_skills f ON f.pet_id = p.pet_id '
        'WHERE p.pet_id = ?',
        <Object?>['pet_000007'],
      );
      if (probe.length != 1 ||
          probe.first['dex_no'] != '004' ||
          probe.first['skill_id'] != 'skill_000003') {
        throw const CatalogInstallException(
          'database_probe',
          'The Catalog database failed its required probe query.',
        );
      }
    } on SqliteException catch (error) {
      throw CatalogInstallException(
        'database_sqlite',
        'Cannot verify the Catalog database: $error',
      );
    } finally {
      database?.close();
    }
  }
}

final class _CatalogDescriptor {
  const _CatalogDescriptor({
    required this.datasetId,
    required this.schemaVersion,
    required this.dataVersion,
    required this.snapshotId,
    required this.databaseBytes,
    required this.databaseSha256,
    required this.attributionBytes,
    required this.attributionSha256,
    required this.coverage,
    required this.fileName,
    this.migrationAttribution,
  });

  static const fieldsV1 = <String>{
    'pointer_version',
    'dataset_id',
    'schema_version',
    'data_version',
    'snapshot_id',
    'database_bytes',
    'database_sha256',
    'coverage',
    'file_name',
  };

  static const fieldsV2 = <String>{
    ...fieldsV1,
    'attribution_bytes',
    'attribution_sha256',
  };

  final String datasetId;
  final int schemaVersion;
  final int dataVersion;
  final String snapshotId;
  final int databaseBytes;
  final String databaseSha256;
  final int attributionBytes;
  final String attributionSha256;
  final Map<String, bool> coverage;
  final String fileName;
  final _CatalogAttribution? migrationAttribution;

  bool matches(CatalogManifest manifest, _CatalogAttribution attribution) {
    return datasetId == manifest.datasetId &&
        schemaVersion == manifest.catalogSchemaVersion &&
        dataVersion == manifest.dataVersion &&
        snapshotId == manifest.snapshotId &&
        databaseBytes == manifest.databaseBytes &&
        databaseSha256 == manifest.databaseSha256 &&
        attributionBytes == attribution.bytes.length &&
        attributionSha256 == attribution.sha256Value &&
        _sameCoverage(coverage, manifest.coverage);
  }

  bool hasSameDataVersion(CatalogManifest manifest) {
    return datasetId == manifest.datasetId &&
        schemaVersion == manifest.catalogSchemaVersion &&
        dataVersion == manifest.dataVersion;
  }

  bool sameArtifact(_CatalogDescriptor other) {
    return datasetId == other.datasetId &&
        schemaVersion == other.schemaVersion &&
        dataVersion == other.dataVersion &&
        databaseSha256 == other.databaseSha256 &&
        attributionSha256 == other.attributionSha256;
  }

  CatalogManifest toManifest() {
    final manifest = CatalogManifest(
      manifestVersion: 1,
      datasetId: datasetId,
      catalogSchemaVersion: schemaVersion,
      dataVersion: dataVersion,
      snapshotId: snapshotId,
      databaseAsset: 'assets/catalog/catalog.db',
      databaseBytes: databaseBytes,
      databaseSha256: databaseSha256,
      coverage: coverage,
    );
    manifest._validateContract();
    return manifest;
  }

  Map<String, Object> toJson() => <String, Object>{
    'pointer_version': 2,
    'dataset_id': datasetId,
    'schema_version': schemaVersion,
    'data_version': dataVersion,
    'snapshot_id': snapshotId,
    'database_bytes': databaseBytes,
    'database_sha256': databaseSha256,
    'attribution_bytes': attributionBytes,
    'attribution_sha256': attributionSha256,
    'coverage': coverage,
    'file_name': fileName,
  };

  _CatalogDescriptor withoutMigration() => _CatalogDescriptor(
    datasetId: datasetId,
    schemaVersion: schemaVersion,
    dataVersion: dataVersion,
    snapshotId: snapshotId,
    databaseBytes: databaseBytes,
    databaseSha256: databaseSha256,
    attributionBytes: attributionBytes,
    attributionSha256: attributionSha256,
    coverage: coverage,
    fileName: fileName,
  );

  _CatalogDescriptor withMigrationAttribution(_CatalogAttribution value) =>
      _CatalogDescriptor(
        datasetId: datasetId,
        schemaVersion: schemaVersion,
        dataVersion: dataVersion,
        snapshotId: snapshotId,
        databaseBytes: databaseBytes,
        databaseSha256: databaseSha256,
        attributionBytes: value.bytes.length,
        attributionSha256: value.sha256Value,
        coverage: coverage,
        fileName: fileName,
        migrationAttribution: value,
      );

  static _CatalogDescriptor? fromJson(
    Object? value, {
    required _CatalogAttribution migrationAttribution,
  }) {
    if (value is! Map<String, dynamic>) {
      return null;
    }
    final pointerVersion = value['pointer_version'];
    final fields = pointerVersion == 2
        ? fieldsV2
        : pointerVersion == 1
        ? fieldsV1
        : null;
    if (fields == null ||
        value.keys.toSet().length != fields.length ||
        !value.keys.toSet().containsAll(fields)) {
      return null;
    }
    final coverageValue = value['coverage'];
    if (coverageValue is! Map<String, dynamic> ||
        coverageValue.length != CatalogManifest._coverageFields.length ||
        !coverageValue.keys.toSet().containsAll(
          CatalogManifest._coverageFields,
        ) ||
        coverageValue.values.any((entry) => entry is! bool)) {
      return null;
    }
    final attributionBytes = pointerVersion == 2
        ? value['attribution_bytes']
        : migrationAttribution.bytes.length;
    final attributionSha256 = pointerVersion == 2
        ? value['attribution_sha256']
        : migrationAttribution.sha256Value;
    if (attributionBytes is! int ||
        attributionBytes < 1 ||
        attributionBytes > CatalogAttributionValidator.maximumBytes ||
        attributionSha256 is! String ||
        !RegExp(r'^[0-9a-f]{64}$').hasMatch(attributionSha256)) {
      return null;
    }
    final descriptor = _CatalogDescriptor(
      datasetId: value['dataset_id'] is String
          ? value['dataset_id'] as String
          : '',
      schemaVersion: value['schema_version'] is int
          ? value['schema_version'] as int
          : 0,
      dataVersion: value['data_version'] is int
          ? value['data_version'] as int
          : 0,
      snapshotId: value['snapshot_id'] is String
          ? value['snapshot_id'] as String
          : '',
      databaseBytes: value['database_bytes'] is int
          ? value['database_bytes'] as int
          : 0,
      databaseSha256: value['database_sha256'] is String
          ? value['database_sha256'] as String
          : '',
      attributionBytes: attributionBytes,
      attributionSha256: attributionSha256,
      coverage: coverageValue.map((key, entry) => MapEntry(key, entry as bool)),
      fileName: value['file_name'] is String
          ? value['file_name'] as String
          : '',
      migrationAttribution: pointerVersion == 1 ? migrationAttribution : null,
    );
    try {
      descriptor.toManifest();
    } on CatalogInstallException {
      return null;
    }
    return descriptor;
  }
}

bool _sameCoverage(Map<String, bool> left, Map<String, bool> right) {
  return left.length == right.length &&
      left.entries.every((entry) => right[entry.key] == entry.value);
}

final class _CatalogFileStore {
  _CatalogFileStore(this.root);

  final Directory root;

  Directory get catalogs => Directory(paths.join(root.path, 'catalogs'));

  Directory get state => Directory(paths.join(root.path, 'catalog-state'));

  File get activePointer => File(paths.join(state.path, 'active_catalog.json'));

  File get previousPointer =>
      File(paths.join(state.path, 'previous_catalog.json'));

  File get failureReport =>
      File(paths.join(state.path, 'last_catalog_failure.json'));

  File get updateState =>
      File(paths.join(state.path, 'catalog_update_state.json'));

  File get operationLock =>
      File(paths.join(state.path, 'catalog_install.lock'));

  void ensureDirectories() {
    catalogs.createSync(recursive: true);
    state.createSync(recursive: true);
  }

  RandomAccessFile acquireOperationLock() {
    final lock = operationLock.openSync(mode: FileMode.append);
    try {
      lock.lockSync(FileLock.exclusive);
      return lock;
    } on Object {
      lock.closeSync();
      rethrow;
    }
  }

  int readHighestAcceptedRemoteReleaseSequence() {
    if (!updateState.existsSync()) {
      return 0;
    }
    final Object? decoded;
    try {
      decoded = jsonDecode(updateState.readAsStringSync());
    } on Object {
      throw const CatalogInstallException(
        'catalog_update_state',
        'The Catalog update state is invalid.',
      );
    }
    if (decoded is! Map<String, dynamic> ||
        decoded.length != 2 ||
        decoded['state_version'] != 1 ||
        decoded['highest_accepted_release_sequence'] is! int ||
        (decoded['highest_accepted_release_sequence'] as int) < 0) {
      throw const CatalogInstallException(
        'catalog_update_state',
        'The Catalog update state is invalid.',
      );
    }
    return decoded['highest_accepted_release_sequence'] as int;
  }

  void commitHighestAcceptedRemoteReleaseSequence(int value) {
    final current = readHighestAcceptedRemoteReleaseSequence();
    if (value <= current) {
      throw const CatalogInstallException(
        'remote_release_sequence',
        'The remote Catalog release sequence is stale or replayed.',
      );
    }
    final temporary = File(
      paths.join(
        state.path,
        '.update-$pid-${DateTime.now().microsecondsSinceEpoch}.tmp',
      ),
    );
    var ownsTemporary = false;
    try {
      temporary.writeAsStringSync(
        '${jsonEncode(<String, Object>{'state_version': 1, 'highest_accepted_release_sequence': value})}\n',
        flush: true,
      );
      ownsTemporary = true;
      temporary.renameSync(updateState.path);
      ownsTemporary = false;
    } on FileSystemException catch (error) {
      throw CatalogInstallException(
        'catalog_update_state',
        'Cannot persist the Catalog update state: ${error.message}',
      );
    } finally {
      if (ownsTemporary && temporary.existsSync()) {
        temporary.deleteSync();
      }
    }
  }

  _CatalogDescriptor descriptorFor(
    CatalogManifest manifest,
    _CatalogAttribution attribution, {
    String? fileName,
  }) {
    return _CatalogDescriptor(
      datasetId: manifest.datasetId,
      schemaVersion: manifest.catalogSchemaVersion,
      dataVersion: manifest.dataVersion,
      snapshotId: manifest.snapshotId,
      databaseBytes: manifest.databaseBytes,
      databaseSha256: manifest.databaseSha256,
      attributionBytes: attribution.bytes.length,
      attributionSha256: attribution.sha256Value,
      coverage: Map<String, bool>.unmodifiable(manifest.coverage),
      fileName: fileName ?? _canonicalFileName(manifest),
    );
  }

  File fileFor(_CatalogDescriptor descriptor) {
    final canonical = _canonicalFileName(descriptor.toManifest());
    final legacy = _legacyFileName(descriptor.toManifest());
    if (descriptor.fileName != canonical && descriptor.fileName != legacy) {
      throw const CatalogInstallException(
        'catalog_pointer_path',
        'The Catalog pointer contains a file outside its allowlist.',
      );
    }
    return File(paths.join(catalogs.path, descriptor.fileName));
  }

  File attributionFileFor(_CatalogDescriptor descriptor) {
    fileFor(descriptor);
    final baseName = descriptor.fileName.substring(
      0,
      descriptor.fileName.length - '.db'.length,
    );
    return File(paths.join(catalogs.path, '$baseName.attribution.txt'));
  }

  File newStagingFile(CatalogManifest manifest) {
    final operation = '$pid-${DateTime.now().microsecondsSinceEpoch}';
    return File(
      paths.join(
        catalogs.path,
        '.staging-v${manifest.dataVersion}-s'
        '${manifest.catalogSchemaVersion}-$operation.db',
      ),
    );
  }

  void ensureAttribution(
    _CatalogDescriptor descriptor,
    _CatalogAttribution attribution,
  ) {
    final target = attributionFileFor(descriptor);
    try {
      validateAttributionFile(descriptor);
      return;
    } on CatalogInstallException {
      final targetType = FileSystemEntity.typeSync(
        target.path,
        followLinks: false,
      );
      if (targetType == FileSystemEntityType.file) {
        target.deleteSync();
      } else if (targetType == FileSystemEntityType.link) {
        Link(target.path).deleteSync();
      }
    }

    final operation = '$pid-${DateTime.now().microsecondsSinceEpoch}';
    final staging = File(
      paths.join(
        catalogs.path,
        '.staging-v${descriptor.dataVersion}-s${descriptor.schemaVersion}-'
        '$operation.attribution.tmp',
      ),
    );
    var ownsStaging = false;
    try {
      staging.writeAsBytesSync(attribution.bytes, flush: true);
      ownsStaging = true;
      _validateAttributionBytes(descriptor, staging.readAsBytesSync());
      staging.renameSync(target.path);
      ownsStaging = false;
    } finally {
      if (ownsStaging && staging.existsSync()) {
        staging.deleteSync();
      }
    }
  }

  _CatalogDescriptor completeAttributionMigration(
    _CatalogDescriptor descriptor,
  ) {
    final attribution = descriptor.migrationAttribution!;
    ensureAttribution(descriptor, attribution);
    return descriptor.withoutMigration();
  }

  void validateAttributionFile(_CatalogDescriptor descriptor) {
    final file = attributionFileFor(descriptor);
    if (FileSystemEntity.typeSync(file.path, followLinks: false) !=
        FileSystemEntityType.file) {
      throw const CatalogInstallException(
        'attribution_missing',
        'The Catalog attribution file is missing.',
      );
    }
    _validateAttributionBytes(descriptor, file.readAsBytesSync());
  }

  String readAttributionText(_CatalogDescriptor descriptor) {
    final file = attributionFileFor(descriptor);
    if (FileSystemEntity.typeSync(file.path, followLinks: false) !=
        FileSystemEntityType.file) {
      throw const CatalogInstallException(
        'attribution_missing',
        'The Catalog attribution file is missing.',
      );
    }
    final bytes = file.readAsBytesSync();
    _validateAttributionBytes(descriptor, bytes);
    try {
      return utf8.decode(bytes, allowMalformed: false);
    } on FormatException {
      throw const CatalogInstallException(
        'attribution_encoding',
        'The Catalog attribution file is not valid UTF-8.',
      );
    }
  }

  void _validateAttributionBytes(
    _CatalogDescriptor descriptor,
    List<int> bytes,
  ) {
    if (bytes.length != descriptor.attributionBytes ||
        sha256.convert(bytes).toString() != descriptor.attributionSha256) {
      throw const CatalogInstallException(
        'attribution_hash',
        'The Catalog attribution file does not match its descriptor.',
      );
    }
    final String text;
    try {
      text = utf8.decode(bytes, allowMalformed: false);
    } on FormatException {
      throw const CatalogInstallException(
        'attribution_encoding',
        'The Catalog attribution file is not valid UTF-8.',
      );
    }
    CatalogAttributionValidator.validateText(text);
  }

  _CatalogDescriptor? readActivePointer({
    CatalogManifest? legacyManifest,
    required _CatalogAttribution migrationAttribution,
  }) {
    final decoded = _readPointerJson(activePointer);
    final descriptor = _CatalogDescriptor.fromJson(
      decoded,
      migrationAttribution: migrationAttribution,
    );
    if (descriptor != null) {
      return _hasAllowedFileName(descriptor) ? descriptor : null;
    }
    if (decoded is! Map<String, dynamic> || legacyManifest == null) {
      return null;
    }
    final legacyMatches =
        decoded['dataset_id'] == legacyManifest.datasetId &&
        decoded['schema_version'] == legacyManifest.catalogSchemaVersion &&
        decoded['data_version'] == legacyManifest.dataVersion &&
        decoded['database_sha256'] == legacyManifest.databaseSha256;
    if (!legacyMatches) {
      return null;
    }
    return descriptorFor(
      legacyManifest,
      migrationAttribution,
      fileName: _legacyFileName(legacyManifest),
    ).withMigrationAttribution(migrationAttribution);
  }

  _CatalogDescriptor? readPreviousPointer({
    required _CatalogAttribution migrationAttribution,
  }) {
    final descriptor = _CatalogDescriptor.fromJson(
      _readPointerJson(previousPointer),
      migrationAttribution: migrationAttribution,
    );
    return descriptor != null && _hasAllowedFileName(descriptor)
        ? descriptor
        : null;
  }

  Object? _readPointerJson(File pointer) {
    if (!pointer.existsSync()) {
      return null;
    }
    try {
      return jsonDecode(pointer.readAsStringSync());
    } on FileSystemException {
      return null;
    } on FormatException {
      return null;
    }
  }

  void commitActivePointer(_CatalogDescriptor? descriptor) {
    _commitPointer(activePointer, descriptor, '.active');
  }

  void commitPreviousPointer(_CatalogDescriptor? descriptor) {
    _commitPointer(previousPointer, descriptor, '.previous');
  }

  void _commitPointer(
    File pointer,
    _CatalogDescriptor? descriptor,
    String temporaryPrefix,
  ) {
    if (descriptor == null) {
      if (pointer.existsSync()) {
        pointer.deleteSync();
      }
      return;
    }
    fileFor(descriptor);
    final temporary = File(
      paths.join(
        state.path,
        '$temporaryPrefix-$pid-'
        '${DateTime.now().microsecondsSinceEpoch}.tmp',
      ),
    );
    var ownsTemporary = false;
    try {
      temporary.writeAsStringSync(
        '${jsonEncode(descriptor.toJson())}\n',
        flush: true,
      );
      ownsTemporary = true;
      temporary.renameSync(pointer.path);
      ownsTemporary = false;
    } on FileSystemException catch (error) {
      throw CatalogInstallException(
        'catalog_pointer',
        'Cannot activate the bundled Catalog: ${error.message}',
      );
    } finally {
      if (ownsTemporary && temporary.existsSync()) {
        temporary.deleteSync();
      }
    }
  }

  void cleanupTransientFiles() {
    _deleteDirectMatches(
      catalogs,
      RegExp(r'^\.staging-v[1-9][0-9]*-s[1-9][0-9]*-[A-Za-z0-9-]+\.db$'),
    );
    _deleteDirectMatches(
      catalogs,
      RegExp(
        r'^\.staging-v[1-9][0-9]*-s[1-9][0-9]*-'
        r'[A-Za-z0-9-]+\.attribution\.tmp$',
      ),
    );
    _deleteDirectMatches(
      state,
      RegExp(r'^\.(active|previous|failure|update)-[A-Za-z0-9-]+\.tmp$'),
    );
  }

  void cleanupRetainedCatalogs(
    _CatalogDescriptor active,
    _CatalogDescriptor? previous,
  ) {
    final retained = <String>{
      active.fileName,
      paths.basename(attributionFileFor(active).path),
      if (previous != null) previous.fileName,
      if (previous != null) paths.basename(attributionFileFor(previous).path),
    };
    final allowed = RegExp(
      r'^catalog-v[1-9][0-9]*-s[1-9][0-9]*'
      r'(?:-[0-9a-f]{12})?\.(?:db|attribution\.txt)$',
    );
    for (final entity in catalogs.listSync(followLinks: false)) {
      if (entity is! File) {
        continue;
      }
      final name = paths.basename(entity.path);
      if (allowed.hasMatch(name) && !retained.contains(name)) {
        entity.deleteSync();
      }
    }
  }

  void writeFailureReport(String code, int dataVersion) {
    state.createSync(recursive: true);
    final temporary = File(
      paths.join(
        state.path,
        '.failure-$pid-${DateTime.now().microsecondsSinceEpoch}.tmp',
      ),
    );
    var ownsTemporary = false;
    try {
      temporary.writeAsStringSync(
        '${jsonEncode(<String, Object>{'report_version': 1, 'code': code, 'data_version': dataVersion})}\n',
        flush: true,
      );
      ownsTemporary = true;
      temporary.renameSync(failureReport.path);
      ownsTemporary = false;
    } on FileSystemException {
      if (ownsTemporary && temporary.existsSync()) {
        temporary.deleteSync();
      }
    }
  }

  void clearFailureReport() {
    if (failureReport.existsSync()) {
      failureReport.deleteSync();
    }
  }

  void _deleteDirectMatches(Directory directory, RegExp pattern) {
    if (!directory.existsSync()) {
      return;
    }
    for (final entity in directory.listSync(followLinks: false)) {
      if (entity is File && pattern.hasMatch(paths.basename(entity.path))) {
        entity.deleteSync();
      }
    }
  }

  bool _hasAllowedFileName(_CatalogDescriptor descriptor) {
    try {
      fileFor(descriptor);
      return true;
    } on CatalogInstallException {
      return false;
    }
  }

  String _canonicalFileName(CatalogManifest manifest) {
    return 'catalog-v${manifest.dataVersion}-s'
        '${manifest.catalogSchemaVersion}-'
        '${manifest.databaseSha256.substring(0, 12)}.db';
  }

  String _legacyFileName(CatalogManifest manifest) {
    return 'catalog-v${manifest.dataVersion}-s'
        '${manifest.catalogSchemaVersion}.db';
  }
}
