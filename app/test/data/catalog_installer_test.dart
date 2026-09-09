import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:roco_handbook/data/catalog/catalog_installer.dart';
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

  test(
    'installs, validates, points to, and reuses the bundled Catalog',
    () async {
      final installer = LocalCatalogInstaller(temporary.path);
      final first = await installer.prepareBundledCatalog(bundle());

      expect(first.installed, isTrue);
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
  });
}
