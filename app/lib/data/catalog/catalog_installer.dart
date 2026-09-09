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
}

final class CatalogOpenResult {
  const CatalogOpenResult({
    required this.databasePath,
    required this.manifest,
    required this.installed,
  });

  final String databasePath;
  final CatalogManifest manifest;
  final bool installed;
}

final class CatalogInstallException implements Exception {
  const CatalogInstallException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => '$code: $message';
}

final class LocalCatalogInstaller implements CatalogInstaller {
  const LocalCatalogInstaller(this.applicationSupportPath);

  final String applicationSupportPath;

  @override
  Future<CatalogOpenResult> prepareBundledCatalog(BundledCatalogBundle bundle) {
    return Isolate.run(() => _prepareCatalog(applicationSupportPath, bundle));
  }
}

CatalogOpenResult _prepareCatalog(
  String applicationSupportPath,
  BundledCatalogBundle bundle,
) {
  final manifest = CatalogManifest.fromJsonText(bundle.manifestText);
  final store = _CatalogFileStore(Directory(applicationSupportPath));
  store.ensureDirectories();
  final target = store.catalogFile(manifest);
  final active = store.readActivePointer();

  if (active != null && active.matches(manifest) && target.existsSync()) {
    CatalogPackageValidator.validateFile(manifest, target);
    return CatalogOpenResult(
      databasePath: target.path,
      manifest: manifest,
      installed: false,
    );
  }

  if (target.existsSync()) {
    CatalogPackageValidator.validateFile(manifest, target);
    store.commitActivePointer(manifest);
    return CatalogOpenResult(
      databasePath: target.path,
      manifest: manifest,
      installed: false,
    );
  }

  final staging = store.newStagingFile(manifest);
  var ownsStaging = false;
  try {
    if (bundle.databaseBytes.length != manifest.databaseBytes ||
        sha256.convert(bundle.databaseBytes).toString() !=
            manifest.databaseSha256) {
      throw const CatalogInstallException(
        'asset_hash',
        'The bundled Catalog bytes do not match the manifest.',
      );
    }
    staging.writeAsBytesSync(bundle.databaseBytes, flush: true);
    ownsStaging = true;
    CatalogPackageValidator.validateFile(manifest, staging);
    staging.renameSync(target.path);
    ownsStaging = false;
    CatalogPackageValidator.validateFile(manifest, target);
    store.commitActivePointer(manifest);
    return CatalogOpenResult(
      databasePath: target.path,
      manifest: manifest,
      installed: true,
    );
  } on CatalogInstallException {
    rethrow;
  } on FileSystemException catch (error) {
    throw CatalogInstallException(
      'catalog_file',
      'Cannot prepare the bundled Catalog: ${error.message}',
    );
  } finally {
    if (ownsStaging && staging.existsSync()) {
      staging.deleteSync();
    }
  }
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
    if (!file.existsSync()) {
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

final class _ActiveCatalogPointer {
  const _ActiveCatalogPointer({
    required this.datasetId,
    required this.schemaVersion,
    required this.dataVersion,
    required this.databaseSha256,
  });

  final String datasetId;
  final int schemaVersion;
  final int dataVersion;
  final String databaseSha256;

  bool matches(CatalogManifest manifest) {
    return datasetId == manifest.datasetId &&
        schemaVersion == manifest.catalogSchemaVersion &&
        dataVersion == manifest.dataVersion &&
        databaseSha256 == manifest.databaseSha256;
  }
}

final class _CatalogFileStore {
  _CatalogFileStore(this.root);

  final Directory root;

  Directory get catalogs => Directory(paths.join(root.path, 'catalogs'));

  Directory get state => Directory(paths.join(root.path, 'catalog-state'));

  File get activePointer => File(paths.join(state.path, 'active_catalog.json'));

  void ensureDirectories() {
    catalogs.createSync(recursive: true);
    state.createSync(recursive: true);
  }

  File catalogFile(CatalogManifest manifest) {
    return File(
      paths.join(
        catalogs.path,
        'catalog-v${manifest.dataVersion}-s${manifest.catalogSchemaVersion}.db',
      ),
    );
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

  _ActiveCatalogPointer? readActivePointer() {
    if (!activePointer.existsSync()) {
      return null;
    }
    try {
      final decoded = jsonDecode(activePointer.readAsStringSync());
      if (decoded is! Map<String, dynamic>) {
        return null;
      }
      final datasetId = decoded['dataset_id'];
      final schemaVersion = decoded['schema_version'];
      final dataVersion = decoded['data_version'];
      final databaseSha256 = decoded['database_sha256'];
      if (datasetId is! String ||
          schemaVersion is! int ||
          dataVersion is! int ||
          databaseSha256 is! String) {
        return null;
      }
      return _ActiveCatalogPointer(
        datasetId: datasetId,
        schemaVersion: schemaVersion,
        dataVersion: dataVersion,
        databaseSha256: databaseSha256,
      );
    } on FileSystemException {
      return null;
    } on FormatException {
      return null;
    }
  }

  void commitActivePointer(CatalogManifest manifest) {
    final pointer = <String, Object>{
      'dataset_id': manifest.datasetId,
      'schema_version': manifest.catalogSchemaVersion,
      'data_version': manifest.dataVersion,
      'database_sha256': manifest.databaseSha256,
    };
    final temporary = File(
      paths.join(
        state.path,
        '.active-$pid-${DateTime.now().microsecondsSinceEpoch}.tmp',
      ),
    );
    var ownsTemporary = false;
    try {
      temporary.writeAsStringSync('${jsonEncode(pointer)}\n', flush: true);
      ownsTemporary = true;
      temporary.renameSync(activePointer.path);
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
}
