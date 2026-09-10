import 'package:flutter_test/flutter_test.dart';
import 'package:roco_handbook/data/catalog/asset_tool_catalog_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads the complete frozen activity timeline contract', () async {
    const repository = AssetActivityTimelineRepository();
    final catalog = await repository.load();

    expect(catalog.entries, hasLength(547));
    expect(
      catalog.categoryOrder,
      orderedEquals(<String>[
        'gifts',
        'pets',
        'challenge',
        'fashion',
        'events',
      ]),
    );
    final observation = catalog.entries.singleWhere(
      (entry) => entry.activityId == 'activity_1600027',
    );
    expect(observation.name, '大世界观察笔记');
    expect(observation.startAt, DateTime.parse('2026-09-04T04:00:00+08:00'));
    expect(
      observation.iconPath,
      'assets/wiki/tools/v1/activities/icons/'
      'Activity_Image_84afaafa24d2f619.png',
    );
  });

  test('loads every frozen outfit and both display variants', () async {
    const repository = AssetFashionCatalogRepository();
    final catalog = await repository.load();

    expect(catalog.entries, hasLength(110));
    expect(catalog.genderOrder, orderedEquals(<String>['female', 'male']));
    final uniform = catalog.entries.first;
    expect(uniform.outfitId, 'fashion_000001');
    expect(uniform.name, '魔法学院校服');
    expect(uniform.variants, hasLength(2));
    expect(
      uniform.variantFor('female').imagePath,
      'assets/wiki/tools/v1/fashions/cards/fashion_000001-female.png',
    );
  });
}
