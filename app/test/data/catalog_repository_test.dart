import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:roco_handbook/data/catalog/sqlite_catalog_repository.dart';
import 'package:roco_handbook/domain/catalog_models.dart';

void main() {
  final databasePath = File('assets/catalog/catalog.db').absolute.path;
  late SqliteCatalogRepository repository;

  setUp(() {
    repository = SqliteCatalogRepository(databasePath);
  });

  test('reads current Catalog metadata', () async {
    final info = await repository.getCatalogInfo();

    expect(info.datasetId, 'roco-world-zh-cn');
    expect(info.schemaVersion, 1);
    expect(info.dataVersion, 1);
    expect(info.snapshotId, 'snapshot-19235f9b9b34dc4e');
    expect(info.coverage['pets'], isTrue);
    expect(info.coverage['description_note_definitions'], isFalse);
  });

  test('finds an exact special form by its canonical name', () async {
    final results = await repository.searchPets(
      const PetQuery(keyword: '武斗酷猫'),
    );

    expect(results, hasLength(1));
    expect(results.single.petId, 'pet_000595');
    expect(results.single.handbookId, 'handbook_000004');
    expect(results.single.dexNo, '004');
    expect(results.single.isDefaultForm, isFalse);
  });

  test(
    'normalizes numeric search without changing stored display number',
    () async {
      final results = await repository.searchHandbooks(
        const PetQuery(keyword: '4'),
      );

      expect(results, hasLength(1));
      expect(results.single.dexNo, '004');
      expect(results.single.petId, 'pet_000007');
    },
  );

  test('paginates the complete creature and skill collections', () async {
    final firstPets = await repository.searchHandbooks(
      const PetQuery(limit: 60),
    );
    final secondPets = await repository.searchHandbooks(
      const PetQuery(limit: 60, offset: 60),
    );
    final firstSkills = await repository.searchSkills(
      const SkillQuery(limit: 60),
    );
    final secondSkills = await repository.searchSkills(
      const SkillQuery(limit: 60, offset: 60),
    );

    expect(firstPets, hasLength(60));
    expect(secondPets, hasLength(60));
    expect(
      firstPets
          .map((pet) => pet.handbookId)
          .toSet()
          .intersection(secondPets.map((pet) => pet.handbookId).toSet()),
      isEmpty,
    );
    expect(firstSkills, hasLength(60));
    expect(secondSkills, hasLength(60));
    expect(
      firstSkills
          .map((skill) => skill.skillId)
          .toSet()
          .intersection(secondSkills.map((skill) => skill.skillId).toSet()),
      isEmpty,
    );
  });

  test('filters by type ID and uses whitelisted stat sorting', () async {
    final types = await repository.getTypes();
    final grass = types.singleWhere((type) => type.name == '草系');
    final filtered = await repository.searchPets(
      PetQuery(typeIds: <String>[grass.typeId], limit: 20),
    );
    final strongest = await repository.searchPets(
      const PetQuery(sort: PetSort.attack, limit: 5),
    );
    final attacks = await Future.wait<int?>(
      strongest.map(
        (pet) async =>
            (await repository.getPetDetail(pet.petId)).stats['Attack'],
      ),
    );
    final sortedAttacks = attacks.whereType<int>().toList()
      ..sort((left, right) => right.compareTo(left));

    expect(types, hasLength(18));
    expect(filtered, isNotEmpty);
    expect(filtered.every((pet) => pet.types.contains('草系')), isTrue);
    expect(attacks, everyElement(isNotNull));
    expect(attacks.cast<int>(), orderedEquals(sortedAttacks));
  });

  test(
    'combines source-backed creature filters without inferring forms',
    () async {
      final shiny = await repository.searchPets(
        const PetQuery(shiny: PetShinyFilter.hasShiny, limit: 200),
      );
      final firstStage = await repository.searchPets(
        const PetQuery(stages: <int>[1], limit: 200),
      );
      final mainForms = await repository.searchPets(
        const PetQuery(forms: <PetFormFilter>[PetFormFilter.main], limit: 200),
      );
      final regionalForms = await repository.searchPets(
        const PetQuery(
          forms: <PetFormFilter>[PetFormFilter.regional],
          limit: 200,
        ),
      );
      final lordForms = await repository.searchPets(
        const PetQuery(forms: <PetFormFilter>[PetFormFilter.lord], limit: 200),
      );
      final seasonThree = await repository.searchPets(
        const PetQuery(seasons: <String>['3'], limit: 200),
      );

      expect(shiny, isNotEmpty);
      expect(shiny.every((pet) => pet.hasShiny), isTrue);
      expect(firstStage.every((pet) => pet.stage == 1), isTrue);
      expect(mainForms.every((pet) => pet.isDefaultForm), isTrue);
      expect(regionalForms, isNotEmpty);
      expect(
        regionalForms.every(
          (pet) =>
              !pet.isLordEvolution &&
              pet.stage != 4 &&
              pet.form != null &&
              pet.form != '本来的样子' &&
              pet.form != '原本的样子' &&
              pet.form != '首领形态',
        ),
        isTrue,
      );
      expect(lordForms, isNotEmpty);
      expect(
        lordForms.every((pet) => pet.isLordEvolution || pet.form == '首领形态'),
        isTrue,
      );
      expect(seasonThree, isNotEmpty);
      expect(seasonThree.every((pet) => pet.belongSeason == '3'), isTrue);
    },
  );

  test('loads every source egg group and filters its members', () async {
    final groups = await repository.getEggGroups();
    final undiscovered = await repository.searchPets(
      const PetQuery(eggGroupIds: <int>[1], limit: 200),
    );

    expect(
      groups.map((group) => group.eggGroupId),
      orderedEquals(<int>[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]),
    );
    expect(groups.every((group) => group.memberCount > 0), isTrue);
    expect(undiscovered.map((pet) => pet.name), contains('迪莫'));
  });

  test('pages through the complete feature handbook', () async {
    final firstPage = await repository.searchSkills(
      const SkillQuery(filter: SkillFilter.features, limit: 200),
    );
    final secondPage = await repository.searchSkills(
      const SkillQuery(filter: SkillFilter.features, limit: 200, offset: 200),
    );

    expect(firstPage, hasLength(200));
    expect(secondPage, hasLength(31));
    expect(<String>{
      ...firstPage.map((skill) => skill.skillId),
      ...secondPage.map((skill) => skill.skillId),
    }, hasLength(231));
  });

  test('loads deduplicated skills related to a game description', () async {
    final related = await repository.getSkillsForDescriptionNote('1001');

    expect(related.where((skill) => skill.isFeature), hasLength(10));
    expect(related.where((skill) => !skill.isFeature), hasLength(10));
    expect(related.map((skill) => skill.skillId).toSet(), hasLength(20));
    expect(related.map((skill) => skill.name), contains('连续毒针'));
  });

  test('filters learnable skills by type, tag, and element', () async {
    final poison = (await repository.getTypes()).singleWhere(
      (type) => type.name == '\u6bd2\u7cfb',
    );
    final filtered = await repository.searchSkills(
      SkillQuery(
        filter: SkillFilter.learnable,
        skillTypes: const <String>['\u7269\u653b'],
        tags: const <String>['\u8fde\u51fb'],
        typeIds: <String>[poison.typeId],
        limit: 100,
      ),
    );
    final featureOnly = await repository.searchSkills(
      const SkillQuery(
        keyword: '\u6c27\u5faa\u73af',
        filter: SkillFilter.learnable,
      ),
    );

    expect(
      filtered.map((skill) => skill.name),
      orderedEquals(<String>['\u8fde\u7eed\u6bd2\u9488']),
    );
    expect(filtered.single.damageClass, '\u7269\u653b');
    expect(filtered.single.element, '\u6bd2\u7cfb');
    expect(featureOnly, isEmpty);
  });

  test(
    'calculates complete base stats without filling missing source data',
    () async {
      final complete = await repository.getPetDetail('pet_000004');
      final incomplete = await repository.getPetDetail('pet_000535');

      expect(complete.totalBaseStats, 582);
      expect(incomplete.stats.values, everyElement(isNull));
      expect(incomplete.totalBaseStats, isNull);
    },
  );

  test('escapes SQL wildcard characters in user search', () async {
    final percent = await repository.searchPets(const PetQuery(keyword: '%'));
    final underscore = await repository.searchPets(
      const PetQuery(keyword: '_'),
    );

    expect(percent, isEmpty);
    expect(underscore, isEmpty);
  });

  test(
    'keeps all three sample forms and switches every detail contract',
    () async {
      final forms = await repository.getFormsForHandbook('handbook_000004');
      final base = await repository.getPetDetail('pet_000007');
      final special = await repository.getPetDetail('pet_000595');

      expect(
        forms.map((form) => form.petId),
        containsAll(<String>['pet_000007', 'pet_000538', 'pet_000595']),
      );
      expect(base.summary.name, '魔力猫');
      expect(special.summary.name, '武斗酷猫');
      expect(base.summary.dexNo, '004');
      expect(special.summary.dexNo, '004');
      expect(base.stats, isNot(special.stats));
      expect(base.illustrationKey, isNotNull);
      expect(special.illustrationKey, isNotNull);

      final baseSkills = await repository.getSkillsForPet(base.summary.petId);
      final specialSkills = await repository.getSkillsForPet(
        special.summary.petId,
      );
      expect(baseSkills.featureSkill?.skillId, 'skill_000003');
      expect(specialSkills.featureSkill?.skillId, 'skill_000226');
      expect(baseSkills.featureSkill?.iconKey, isNotNull);
    },
  );

  test('keeps feature and learnable relationships separate', () async {
    final bundle = await repository.getSkillsForPet('pet_000007');

    expect(bundle.featureSkill?.skillId, 'skill_000003');
    expect(bundle.featureSkill?.description, '使用草系技能后，回复10%生命。');
    expect(bundle.learnableSkills, isNotEmpty);
    expect(
      bundle.learnableSkills.map((skill) => skill.sourceKind).toSet(),
      containsAll(<String>{'native', 'blood', 'stone'}),
    );
    expect(
      bundle.learnableSkills.any((skill) => skill.sourceKind == 'feature'),
      isFalse,
    );
    expect(
      bundle.learnableSkills
          .firstWhere((skill) => skill.skill.name == '抓挠')
          .skill
          .damageClass,
      '物攻',
    );
  });

  test('returns only evidence-backed evolution edges', () async {
    final graph = await repository.getEvolutionGraph('pet_000007');

    expect(graph.groupIds, contains('evo_000004'));
    expect(graph.nodes.map((node) => node.petId), contains('pet_000595'));
    expect(
      graph.edges.where(
        (edge) =>
            edge.fromPetId == 'pet_000007' &&
            edge.toPetId == 'pet_000595' &&
            edge.methodCode == 'lord_branch',
      ),
      hasLength(1),
    );
  });

  test('returns explicit not-found errors', () async {
    await expectLater(
      repository.getPetDetail('pet_missing'),
      throwsA(isA<CatalogNotFoundException>()),
    );
  });
}
