import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roco_handbook/data/catalog/catalog_installer.dart';
import 'package:roco_handbook/data/user/sqlite_user_repository.dart';
import 'package:roco_handbook/data/user/user_database_migrator.dart';
import 'package:roco_handbook/domain/user_models.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  late Directory temporary;
  late String manifestText;
  late Uint8List databaseBytes;
  late String attributionText;

  setUp(() {
    temporary = Directory.systemTemp.createTempSync('roco-installer-test-');
    manifestText = File('assets/catalog/bundled_catalog.json')
        .readAsStringSync();
    databaseBytes = File('assets/catalog/catalog.db').readAsBytesSync();
    attributionText = File('assets/catalog/ATTRIBUTION.txt').readAsStringSync();
  });

  tearDown(() {
    temporary.deleteSync(recursive: true);
  });

  BundledCatalogBundle bundle({Uint8List? bytes, String? manifest}) {
    return BundledCatalogBundle(
      manifestText: manifest ?? manifestText,
      databaseBytes: bytes ?? databaseBytes,
      attributionText: attributionText,
    );
  }

  BundledCatalogBundle updatedBundle({int dataVersion = 2}) {
    final fixture = File('${temporary.path}/fixture-v$dataVersion.db');
    fixture.writeAsBytesSync(databaseBytes, flush: true);
    final database = sqlite3.open(fixture.path, mode: OpenMode.readWrite);
    database.execute('PRAGMA foreign_keys = ON');
    database.execute(
      'UPDATE catalog_meta SET data_version = ?, snapshot_id = ? '
      'WHERE singleton = 1',
      <Object?>[dataVersion, 'snapshot-phase-5-v$dataVersion'],
    );
    database.execute(
      "UPDATE pets SET name = 'Updated creature' WHERE pet_id = 'pet_000001'",
    );
    database.execute(
      "UPDATE pets SET status = 'retired' WHERE pet_id = 'pet_000002'",
    );
    database.execute(
      "INSERT INTO handbook_entries(handbook_id, dex_no, display_name, "
      "sort_order, status) VALUES('handbook_phase5', '999', "
      "'Added handbook', 9999, 'active')",
    );
    database.execute(
      "INSERT INTO pets(pet_id, handbook_id, name, title, status) "
      "VALUES('pet_phase5', 'handbook_phase5', 'Added creature', "
      "'Added creature', 'active')",
    );
    database.execute(
      "INSERT INTO handbook_display(handbook_id, default_pet_id, "
      "selection_reason) VALUES('handbook_phase5', 'pet_phase5', "
      "'Phase 5 fixture')",
    );
    database.close();
    final bytes = fixture.readAsBytesSync();
    final manifest = jsonDecode(manifestText) as Map<String, dynamic>;
    manifest['data_version'] = dataVersion;
    manifest['snapshot_id'] = 'snapshot-phase-5-v$dataVersion';
    manifest['database_bytes'] = bytes.length;
    manifest['database_sha256'] = sha256.convert(bytes).toString();
    return bundle(bytes: bytes, manifest: jsonEncode(manifest));
  }

  test(
    'installs, validates, points to, and reuses the bundled Catalog',
    () async {
      final installer = LocalCatalogInstaller(temporary.path);
      final first = await installer.prepareBundledCatalog(bundle());

      expect(first.installed, isTrue);
      expect(first.outcome, CatalogOpenOutcome.installedBundled);
      expect(first.manifest.dataVersion, 1);
      expect(File(first.databasePath).existsSync(), isTrue);
      expect(
        File('${temporary.path}/catalog-state/active_catalog.json')
            .existsSync(),
        isTrue,
      );
      expect(
        Directory('${temporary.path}/catalogs')
            .listSync()
            .where((entry) => entry.path.contains('.staging-')),
        isEmpty,
      );

      final second = await installer.prepareBundledCatalog(bundle());
      expect(second.installed, isFalse);
      expect(second.outcome, CatalogOpenOutcome.reused);
      expect(second.databasePath, first.databasePath);
    },
  );

  test(
    'installed Catalog rejects writes through a read-only connection',
    () async {
      final result = await LocalCatalogInstaller(temporary.path)
          .prepareBundledCatalog(bundle());
      final database = sqlite3.open(
        result.databasePath,
        mode: OpenMode.readOnly,
      );
      addTearDown(database.close);

      expect(
        () => database.execute('DELETE FROM pets'),
        throwsA(isA<SqliteException>()),
      );
    },
  );

  test('migrates the Phase 3 active pointer without recopying its database', () async {
    final catalogs = Directory('${temporary.path}/catalogs')..createSync();
    final state = Directory('${temporary.path}/catalog-state')..createSync();
    final legacyDatabase = File('${catalogs.path}/catalog-v1-s1.db')
      ..writeAsBytesSync(databaseBytes, flush: true);
    final manifest = jsonDecode(manifestText) as Map<String, dynamic>;
    File('${state.path}/active_catalog.json').writeAsStringSync(
      '${jsonEncode(<String, Object?>{'dataset_id': manifest['dataset_id'], 'schema_version': manifest['catalog_schema_version'], 'data_version': manifest['data_version'], 'database_sha256': manifest['database_sha256']})}\n',
      flush: true,
    );

    final result = await LocalCatalogInstaller(
      temporary.path,
      backgroundWork: false,
    ).prepareBundledCatalog(bundle());

    expect(result.outcome, CatalogOpenOutcome.reused);
    expect(result.databasePath, legacyDatabase.path);
    final migrated = _readJson('${state.path}/active_catalog.json');
    expect(migrated['pointer_version'], 1);
    expect(migrated['file_name'], 'catalog-v1-s1.db');
  });

  test('rejects changed bytes and cleans only its staging file', () async {
    final changed = Uint8List.fromList(databaseBytes);
    changed[changed.length - 1] ^= 1;
    final installer = LocalCatalogInstaller(temporary.path);

    await expectLater(
      installer.prepareBundledCatalog(bundle(bytes: changed)),
      throwsA(
        isA<CatalogInstallException>().having(
          (error) => error.code,
          'code',
          'asset_hash',
        ),
      ),
    );
    final catalogDirectory = Directory('${temporary.path}/catalogs');
    expect(catalogDirectory.listSync(), isEmpty);
    expect(
      _readJson(
        '${temporary.path}/catalog-state/last_catalog_failure.json',
      )['code'],
      'asset_hash',
    );
  });

  test('rejects incomplete core coverage before writing files', () async {
    final changedManifest = manifestText.replaceFirst(
      '"pets": true',
      '"pets": false',
    );

    await expectLater(
      LocalCatalogInstaller(temporary.path)
          .prepareBundledCatalog(bundle(manifest: changedManifest)),
      throwsA(
        isA<CatalogInstallException>().having(
          (error) => error.code,
          'code',
          'manifest_core_coverage',
        ),
      ),
    );
    expect(Directory('${temporary.path}/catalogs').existsSync(), isFalse);
    expect(
      _readJson(
        '${temporary.path}/catalog-state/last_catalog_failure.json',
      )['code'],
      'manifest_core_coverage',
    );
  });

  test(
    'activates a newer whole Catalog and keeps one previous version',
    () async {
      final installer = LocalCatalogInstaller(
        temporary.path,
        backgroundWork: false,
      );
      final first = await installer.prepareBundledCatalog(bundle());
      final second = await installer.prepareBundledCatalog(updatedBundle());

      expect(second.outcome, CatalogOpenOutcome.installedBundled);
      expect(second.manifest.dataVersion, 2);
      expect(second.previousDataVersion, 1);
      final database = sqlite3.open(
        second.databasePath,
        mode: OpenMode.readOnly,
      );
      expect(
        database
            .select("SELECT name FROM pets WHERE pet_id = 'pet_000001'")
            .single['name'],
        'Updated creature',
      );
      expect(
        database
            .select("SELECT status FROM pets WHERE pet_id = 'pet_000002'")
            .single['status'],
        'retired',
      );
      expect(
        database
            .select("SELECT name FROM pets WHERE pet_id = 'pet_phase5'")
            .single['name'],
        'Added creature',
      );
      database.close();

      final active = _readJson(
        '${temporary.path}/catalog-state/active_catalog.json',
      );
      final previous = _readJson(
        '${temporary.path}/catalog-state/previous_catalog.json',
      );
      expect(active['data_version'], 2);
      expect(previous['data_version'], 1);
      expect(
        Directory('${temporary.path}/catalogs')
            .listSync()
            .whereType<File>()
            .where((file) => file.path.endsWith('.db')),
        hasLength(2),
      );

      final noDowngrade = await installer.prepareBundledCatalog(bundle());
      expect(noDowngrade.outcome, CatalogOpenOutcome.reused);
      expect(noDowngrade.manifest.dataVersion, 2);
      expect(noDowngrade.databasePath, second.databasePath);
      expect(first.databasePath, isNot(second.databasePath));
    },
  );

  test(
    'whole Catalog replacement preserves the User V1 logical snapshot',
    () async {
      final userOpen = await UserDatabaseMigrator(
        temporary.path,
        backgroundWork: false,
      ).prepare(File('../schemas/user_v1.sql').readAsStringSync());
      final users = SqliteUserRepository(
        userOpen.databasePath,
        backgroundQueries: false,
        noteIdGenerator: () => 'note_phase5',
        utcNow: () => '2026-09-09T13:00:00Z',
      );
      const creature = ObjectRef(
        datasetId: 'roco-world-zh-cn',
        objectType: UserObjectType.pet,
        objectId: 'pet_000001',
        nameSnapshot: 'Personal creature snapshot',
      );
      await users.setFavorite(creature, true);
      await users.setCollected(
        datasetId: creature.datasetId,
        handbookId: 'handbook_000001',
        nameSnapshot: creature.nameSnapshot,
        collected: true,
      );
      await users.saveNote(
        const NoteDraft(object: creature, content: 'Personal note survives'),
      );
      final before = _logicalUserSnapshot(userOpen.databasePath);

      final installer = LocalCatalogInstaller(
        temporary.path,
        backgroundWork: false,
      );
      await installer.prepareBundledCatalog(bundle());
      await installer.prepareBundledCatalog(updatedBundle());

      expect(_logicalUserSnapshot(userOpen.databasePath), before);
      await users.close();
    },
  );

  test(
    'an interrupted copy leaves the old version and is cleaned on retry',
    () async {
      final normal = LocalCatalogInstaller(
        temporary.path,
        backgroundWork: false,
      );
      final old = await normal.prepareBundledCatalog(bundle());
      final interrupted = await LocalCatalogInstaller(
        temporary.path,
        backgroundWork: false,
        faultPoint: CatalogInstallerFaultPoint.leaveStagingAfterCopy,
      ).prepareBundledCatalog(updatedBundle());

      expect(interrupted.outcome, CatalogOpenOutcome.recoveredPrevious);
      expect(interrupted.databasePath, old.databasePath);
      expect(
        Directory('${temporary.path}/catalogs')
            .listSync()
            .whereType<File>()
            .where((file) => file.path.contains('.staging-')),
        hasLength(1),
      );

      final retry = await normal.prepareBundledCatalog(updatedBundle());
      expect(retry.manifest.dataVersion, 2);
      expect(
        Directory('${temporary.path}/catalogs')
            .listSync()
            .whereType<File>()
            .where((file) => file.path.contains('.staging-')),
        isEmpty,
      );
    },
  );

  test(
    'invalid candidate contracts never replace the active Catalog',
    () async {
      final installer = LocalCatalogInstaller(
        temporary.path,
        backgroundWork: false,
      );
      final old = await installer.prepareBundledCatalog(bundle());
      final pointer = File(
        '${temporary.path}/catalog-state/active_catalog.json',
      );
      final pointerBefore = pointer.readAsBytesSync();
      final decoded = jsonDecode(manifestText) as Map<String, dynamic>;
      final originalHash = decoded['database_sha256'] as String;
      final variants = <String>[
        jsonEncode(<String, dynamic>{
          ...decoded,
          'database_sha256':
              '${originalHash[0] == '0' ? '1' : '0'}'
              '${originalHash.substring(1)}',
        }),
        jsonEncode(<String, dynamic>{...decoded, 'catalog_schema_version': 2}),
        jsonEncode(<String, dynamic>{...decoded, 'dataset_id': 'unexpected'}),
      ];

      for (final manifest in variants) {
        await expectLater(
          installer.prepareBundledCatalog(bundle(manifest: manifest)),
          throwsA(isA<CatalogInstallException>()),
        );
        expect(pointer.readAsBytesSync(), pointerBefore);
        expect(File(old.databasePath).existsSync(), isTrue);
        CatalogPackageValidator.validateFile(
          old.manifest,
          File(old.databasePath),
        );
      }
    },
  );

  test(
    'a failed post-activation open rolls back the previous pointer',
    () async {
      final normal = LocalCatalogInstaller(
        temporary.path,
        backgroundWork: false,
      );
      final old = await normal.prepareBundledCatalog(bundle());
      final result = await LocalCatalogInstaller(
        temporary.path,
        backgroundWork: false,
        faultPoint: CatalogInstallerFaultPoint.failAfterPointerCommit,
      ).prepareBundledCatalog(updatedBundle());

      expect(result.outcome, CatalogOpenOutcome.recoveredPrevious);
      expect(result.databasePath, old.databasePath);
      expect(
        _readJson(
          '${temporary.path}/catalog-state/active_catalog.json',
        )['data_version'],
        1,
      );
      expect(
        File('${temporary.path}/catalog-state/previous_catalog.json')
            .existsSync(),
        isFalse,
      );
      expect(
        _readJson(
          '${temporary.path}/catalog-state/last_catalog_failure.json',
        )['code'],
        'injected_post_activation_open',
      );
    },
  );

  test(
    'a simulated full disk is controlled and leaves User V1 untouched',
    () async {
      final userOpen = await UserDatabaseMigrator(
        temporary.path,
        backgroundWork: false,
      ).prepare(File('../schemas/user_v1.sql').readAsStringSync());
      final userBefore = File(userOpen.databasePath).readAsBytesSync();
      final normal = LocalCatalogInstaller(
        temporary.path,
        backgroundWork: false,
      );
      final old = await normal.prepareBundledCatalog(bundle());
      final result = await LocalCatalogInstaller(
        temporary.path,
        backgroundWork: false,
        faultPoint: CatalogInstallerFaultPoint.failStagingWrite,
      ).prepareBundledCatalog(updatedBundle());

      expect(result.outcome, CatalogOpenOutcome.recoveredPrevious);
      expect(result.databasePath, old.databasePath);
      expect(File(userOpen.databasePath).readAsBytesSync(), userBefore);
      expect(
        Directory('${temporary.path}/catalogs')
            .listSync()
            .whereType<File>()
            .where((file) => file.path.contains('.staging-')),
        isEmpty,
      );
    },
  );

  test(
    'a damaged active pointer recovers only its recorded previous version',
    () async {
      final installer = LocalCatalogInstaller(
        temporary.path,
        backgroundWork: false,
      );
      await installer.prepareBundledCatalog(bundle());
      await installer.prepareBundledCatalog(updatedBundle());
      File('${temporary.path}/catalog-state/active_catalog.json')
          .writeAsStringSync('{damaged', flush: true);

      final recovered = await installer.prepareBundledCatalog(bundle());
      expect(recovered.outcome, CatalogOpenOutcome.recoveredPrevious);
      expect(recovered.manifest.dataVersion, 1);
      expect(
        File('${temporary.path}/catalog-state/previous_catalog.json')
            .existsSync(),
        isFalse,
      );
      expect(
        Directory('${temporary.path}/catalogs')
            .listSync()
            .whereType<File>()
            .where((file) => file.path.endsWith('.db')),
        hasLength(1),
      );
    },
  );

  test(
    'pointer path injection is rejected and cleanup stays allowlisted',
    () async {
      final installer = LocalCatalogInstaller(
        temporary.path,
        backgroundWork: false,
      );
      await installer.prepareBundledCatalog(bundle());
      final pointerPath = '${temporary.path}/catalog-state/active_catalog.json';
      final pointer = _readJson(pointerPath);
      pointer['file_name'] = '../../outside.db';
      File(pointerPath).writeAsStringSync(jsonEncode(pointer), flush: true);
      final outside = File('${temporary.path}/outside.db')
        ..writeAsStringSync('preserve', flush: true);
      final unrelated = File('${temporary.path}/catalogs/user-note.txt')
        ..writeAsStringSync('preserve', flush: true);
      final nested = Directory('${temporary.path}/catalogs/nested')
        ..createSync();
      File('${nested.path}/catalog-v99-s1-1234567890ab.db')
          .writeAsStringSync('preserve', flush: true);
      File('${temporary.path}/catalogs/catalog-v99-s1-1234567890ab.db')
          .writeAsStringSync('remove', flush: true);

      final recovered = await installer.prepareBundledCatalog(bundle());
      expect(recovered.manifest.dataVersion, 1);
      expect(outside.readAsStringSync(), 'preserve');
      expect(unrelated.readAsStringSync(), 'preserve');
      expect(
        File('${nested.path}/catalog-v99-s1-1234567890ab.db').existsSync(),
        isTrue,
      );
      expect(
        File('${temporary.path}/catalogs/catalog-v99-s1-1234567890ab.db')
            .existsSync(),
        isFalse,
      );
      expect(
        _readJson(pointerPath)['file_name'].toString().contains('..'),
        isFalse,
      );
    },
  );

  test(
    'explicit bundled recovery may downgrade Catalog but preserves User V1',
    () async {
      final userOpen = await UserDatabaseMigrator(
        temporary.path,
        backgroundWork: false,
      ).prepare(File('../schemas/user_v1.sql').readAsStringSync());
      final users = SqliteUserRepository(
        userOpen.databasePath,
        backgroundQueries: false,
        noteIdGenerator: () => 'note_restore',
        utcNow: () => '2026-09-09T14:00:00Z',
      );
      const object = ObjectRef(
        datasetId: 'roco-world-zh-cn',
        objectType: UserObjectType.skill,
        objectId: 'skill_000001',
        nameSnapshot: 'Personal skill snapshot',
      );
      await users.setFavorite(object, true);
      await users.saveNote(
        const NoteDraft(object: object, content: 'Restore keeps this note'),
      );
      final before = _logicalUserSnapshot(userOpen.databasePath);
      final installer = LocalCatalogInstaller(
        temporary.path,
        backgroundWork: false,
      );
      await installer.prepareBundledCatalog(bundle());
      await installer.prepareBundledCatalog(updatedBundle());

      final restored = await installer.restoreBundledCatalog(bundle());
      expect(restored.outcome, CatalogOpenOutcome.restoredBundled);
      expect(restored.manifest.dataVersion, 1);
      expect(restored.previousDataVersion, 2);
      expect(_logicalUserSnapshot(userOpen.databasePath), before);
      await users.close();
    },
  );
}

Map<String, dynamic> _readJson(String path) {
  return jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
}

String _logicalUserSnapshot(String path) {
  final database = sqlite3.open(path, mode: OpenMode.readOnly);
  try {
    List<List<Object?>> rows(String query) {
      return database
          .select(query)
          .map((row) => row.values.toList(growable: false))
          .toList(growable: false);
    }

    return jsonEncode(<String, Object>{
      'meta': rows(
        'SELECT singleton, schema_version, created_at_utc FROM user_meta '
        'ORDER BY singleton',
      ),
      'favorites': rows(
        'SELECT dataset_id, object_type, object_id, name_snapshot, '
        'created_at_utc FROM favorites '
        'ORDER BY dataset_id, object_type, object_id',
      ),
      'collection_marks': rows(
        'SELECT dataset_id, handbook_id, collected, name_snapshot, '
        'updated_at_utc FROM collection_marks '
        'ORDER BY dataset_id, handbook_id',
      ),
      'notes': rows(
        'SELECT note_id, dataset_id, object_type, object_id, name_snapshot, '
        'content, created_at_utc, updated_at_utc FROM notes ORDER BY note_id',
      ),
      'settings': rows(
        'SELECT setting_key, value_json, updated_at_utc FROM settings '
        'ORDER BY setting_key',
      ),
    });
  } finally {
    database.close();
  }
}
