import 'package:flutter_test/flutter_test.dart';
import 'package:roco_handbook/data/catalog/asset_game_description_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads the complete frozen game description contract', () async {
    const repository = AssetGameDescriptionRepository();
    final catalog = await repository.load();

    expect(catalog.entries, hasLength(54));
    expect(
      catalog.categoryOrder,
      orderedEquals(<String>[
        'status',
        'mark',
        'weather',
        'action',
        'rule',
        'other',
      ]),
    );
    expect(catalog.entries.first.noteId, '1001');
    expect(catalog.entries.first.name, '中毒');
    expect(catalog.entries.first.category, 'status');
    expect(catalog.entries.last.noteId, '3026');
    expect(catalog.entries.last.name, '透射');
  });
}
