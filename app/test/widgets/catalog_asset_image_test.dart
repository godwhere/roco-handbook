import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roco_handbook/domain/catalog_models.dart';
import 'package:roco_handbook/widgets/catalog_asset_image.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  testWidgets('keeps missing and failed asset fallbacks accessible', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      for (final path in <String?>[null, 'assets/wiki/v1/does-not-exist.png']) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CatalogAssetImage(
                assetPath: path,
                semanticLabel: 'Missing creature image',
                fallbackIcon: Icons.image_not_supported_outlined,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.image_not_supported_outlined), findsOneWidget);
        expect(find.bySemanticsLabel('Missing creature image'), findsOneWidget);
      }
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('every active Catalog image key resolves to a bundled asset', (
    tester,
  ) async {
    final assetManifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final bundledPaths = assetManifest.listAssets().toSet();
    final database = sqlite3.open(
      'assets/catalog/catalog.db',
      mode: OpenMode.readOnly,
    );
    final missing = <String>[];

    try {
      final pets = database.select(
        "SELECT pet_id, illustration_key FROM pets WHERE status = 'active'",
      );
      expect(pets, hasLength(596));
      for (final row in pets) {
        _requireBundled(
          missing,
          bundledPaths,
          'pet ${row['pet_id']} illustration',
          petIllustrationAsset(row['illustration_key'] as String?),
        );
      }

      final skills = database.select(
        "SELECT skill_id, name, category, icon_key FROM skills WHERE status = 'active'",
      );
      expect(skills, hasLength(788));
      for (final row in skills) {
        final skill = SkillSummary(
          skillId: row['skill_id'] as String,
          name: row['name'] as String,
          category: row['category'] as String?,
          iconKey: row['icon_key'] as String?,
          isFeature: row['category'] == '\u7279\u6027',
        );
        _requireBundled(
          missing,
          bundledPaths,
          'skill ${skill.skillId}',
          skillIconAsset(skill),
        );
      }

      final types = database.select('SELECT type_id, name FROM types');
      expect(types, hasLength(18));
      for (final row in types) {
        _requireBundled(
          missing,
          bundledPaths,
          'type ${row['type_id']}',
          typeIconAsset(row['name'] as String),
        );
      }
    } finally {
      database.close();
    }

    expect(missing, isEmpty);
  });
}

void _requireBundled(
  List<String> missing,
  Set<String> bundledPaths,
  String identity,
  String? path,
) {
  if (path == null || !bundledPaths.contains(path)) {
    missing.add('$identity: ${path ?? 'no runtime path'}');
  }
}
