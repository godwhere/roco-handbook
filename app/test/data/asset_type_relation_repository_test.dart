import 'package:flutter_test/flutter_test.dart';
import 'package:roco_handbook/data/catalog/asset_type_relation_repository.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  const repository = AssetTypeRelationRepository();

  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads source-backed single-type relationships', () async {
    final result = await repository.forCreatureTypes(const <String>[
      '\u8349\u7cfb',
    ]);

    expect(result.outgoing.single.typeName, '\u8349');
    expect(result.outgoing.single.strongAgainst, contains('\u6c34'));
    expect(
      result.incoming
          .singleWhere((item) => item.typeName == '\u706b')
          .multiplier,
      2,
    );
    expect(
      result.incoming
          .singleWhere((item) => item.typeName == '\u6c34')
          .multiplier,
      0.5,
    );
  });

  test('caps a double weakness for dual types at three times damage', () async {
    final result = await repository.forCreatureTypes(const <String>[
      '\u8349\u7cfb',
      '\u866b\u7cfb',
    ]);

    expect(
      result.incoming
          .singleWhere((item) => item.typeName == '\u706b')
          .multiplier,
      3,
    );
  });

  test('resolves every active Catalog creature type combination', () async {
    final database = sqlite3.open(
      'assets/catalog/catalog.db',
      mode: OpenMode.readOnly,
    );
    final typesByPet = <String, List<String>>{};
    try {
      final rows = database.select(
        'SELECT p.pet_id, t.name FROM pets p '
        'JOIN pet_types pt ON pt.pet_id = p.pet_id '
        'JOIN types t ON t.type_id = pt.type_id '
        "WHERE p.status = 'active' ORDER BY p.pet_id, pt.slot",
      );
      for (final row in rows) {
        typesByPet
            .putIfAbsent(row['pet_id'] as String, () => <String>[])
            .add(row['name'] as String);
      }
    } finally {
      database.close();
    }

    expect(typesByPet, hasLength(596));
    for (final entry in typesByPet.entries) {
      final result = await repository.forCreatureTypes(entry.value);
      expect(result.outgoing, hasLength(entry.value.length), reason: entry.key);
      expect(
        result.incoming.map((item) => item.multiplier),
        everyElement(isIn(<double>[0.25, 0.5, 2, 3])),
        reason: entry.key,
      );
    }
  });
}
