import 'package:flutter_test/flutter_test.dart';
import 'package:roco_handbook/data/catalog/asset_type_relation_repository.dart';

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
}
