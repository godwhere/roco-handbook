import 'dart:convert';
import 'dart:isolate';

import 'package:sqlite3/sqlite3.dart';

import '../../domain/catalog_models.dart';
import '../../domain/catalog_repository.dart';

final class SqliteCatalogRepository implements CatalogRepository {
  const SqliteCatalogRepository(
    this.databasePath, {
    this.backgroundQueries = true,
  });

  final String databasePath;
  final bool backgroundQueries;

  @override
  Future<List<CatalogType>> getTypes() {
    return _read('load creature types', (database) {
      return database
          .select('SELECT type_id, name FROM types ORDER BY name, type_id')
          .map(
            (row) => CatalogType(
              typeId: row['type_id'] as String,
              name: row['name'] as String,
            ),
          )
          .toList();
    });
  }

  Future<T> _read<T>(
    String operation,
    T Function(Database database) query,
  ) async {
    try {
      T execute() {
        final database = sqlite3.open(databasePath, mode: OpenMode.readOnly);
        try {
          database.execute('PRAGMA query_only = ON');
          return query(database);
        } finally {
          database.close();
        }
      }

      return backgroundQueries ? await Isolate.run(execute) : execute();
    } on CatalogNotFoundException {
      rethrow;
    } on Object catch (error) {
      throw CatalogQueryException(operation, error);
    }
  }

  @override
  Future<List<PetSummary>> searchHandbooks(PetQuery query) {
    return _read('search handbooks', (database) {
      final search = _searchClause(query.keyword);
      final type = _typeClause(query.typeIds);
      final rows = database.select(
        'SELECT p.pet_id, p.handbook_id, h.dex_no, p.name, p.title, '
        'p.form, p.illustration_key, 1 AS is_default '
        'FROM handbook_entries h '
        'JOIN handbook_display d ON d.handbook_id = h.handbook_id '
        'JOIN pets p ON p.pet_id = d.default_pet_id '
        "WHERE h.status = 'active' AND p.status = 'active' "
        '${search.sql} ${type.sql} '
        'ORDER BY ${_petOrder(query.sort)} '
        'LIMIT ? OFFSET ?',
        <Object?>[
          ...search.arguments,
          ...type.arguments,
          _limit(query.limit),
          _offset(query.offset),
        ],
      );
      return rows.map((row) => _petSummary(database, row)).toList();
    });
  }

  @override
  Future<List<PetSummary>> searchPets(PetQuery query) {
    return _read('search creatures', (database) {
      final search = _searchClause(query.keyword);
      final type = _typeClause(query.typeIds);
      final rows = database.select(
        'SELECT p.pet_id, p.handbook_id, h.dex_no, p.name, p.title, '
        'p.form, p.illustration_key, '
        'CASE WHEN d.default_pet_id = p.pet_id THEN 1 ELSE 0 END AS is_default '
        'FROM pets p '
        'JOIN handbook_entries h ON h.handbook_id = p.handbook_id '
        'JOIN handbook_display d ON d.handbook_id = p.handbook_id '
        "WHERE p.status = 'active' AND h.status = 'active' "
        '${search.sql} ${type.sql} '
        'ORDER BY CASE WHEN p.name = ? OR p.title = ? THEN 0 ELSE 1 END, '
        '${_petOrder(query.sort)} '
        'LIMIT ? OFFSET ?',
        <Object?>[
          ...search.arguments,
          ...type.arguments,
          query.keyword.trim(),
          query.keyword.trim(),
          _limit(query.limit),
          _offset(query.offset),
        ],
      );
      return rows.map((row) => _petSummary(database, row)).toList();
    });
  }

  @override
  Future<PetDetail> getPetDetail(String petId) {
    return _read('load creature detail', (database) {
      final rows = database.select(
        'SELECT p.*, h.dex_no, '
        'CASE WHEN d.default_pet_id = p.pet_id THEN 1 ELSE 0 END AS is_default '
        'FROM pets p '
        'JOIN handbook_entries h ON h.handbook_id = p.handbook_id '
        'JOIN handbook_display d ON d.handbook_id = p.handbook_id '
        "WHERE p.pet_id = ? AND p.status = 'active'",
        <Object?>[petId],
      );
      if (rows.isEmpty) {
        throw CatalogNotFoundException('Creature', petId);
      }
      final row = rows.first;
      return PetDetail(
        summary: _petSummary(database, row),
        className: row['class_name'] as String?,
        description: row['description'] as String?,
        illustrationKey: row['illustration_key'] as String?,
        stage: row['stage'] as int?,
        heightText: row['height_text'] as String?,
        weightText: row['weight_text'] as String?,
        starlight: row['starlight'] as int?,
        reviewGold: row['review_gold'] as int?,
        canDoubleRide: _nullableBool(row['can_double_ride']),
        hasShiny: _nullableBool(row['has_shiny']),
        isLordEvolution: _nullableBool(row['is_lord_evolution']),
        stats: <String, int?>{
          'HP': row['hp'] as int?,
          'Attack': row['atk'] as int?,
          'Defense': row['def'] as int?,
          'Magic attack': row['spa'] as int?,
          'Magic defense': row['spd'] as int?,
          'Speed': row['spe'] as int?,
        },
        sourceReferences: _sourceReferences(database, 'pet', petId),
      );
    });
  }

  @override
  Future<List<PetSummary>> getFormsForHandbook(String handbookId) {
    return _read('load creature forms', (database) {
      final rows = database.select(
        'SELECT p.pet_id, p.handbook_id, h.dex_no, p.name, p.title, '
        'p.form, p.illustration_key, '
        'CASE WHEN d.default_pet_id = p.pet_id THEN 1 ELSE 0 END AS is_default '
        'FROM pets p '
        'JOIN handbook_entries h ON h.handbook_id = p.handbook_id '
        'JOIN handbook_display d ON d.handbook_id = p.handbook_id '
        "WHERE p.handbook_id = ? AND p.status = 'active' "
        'ORDER BY is_default DESC, p.pet_id',
        <Object?>[handbookId],
      );
      if (rows.isEmpty) {
        throw CatalogNotFoundException('Handbook', handbookId);
      }
      return rows.map((row) => _petSummary(database, row)).toList();
    });
  }

  @override
  Future<PetSkillBundle> getSkillsForPet(String petId) {
    return _read('load creature skills', (database) {
      if (!_petExists(database, petId)) {
        throw CatalogNotFoundException('Creature', petId);
      }
      final featureRows = database.select(
        'SELECT s.*, 1 AS is_feature FROM pet_feature_skills f '
        'JOIN skills s ON s.skill_id = f.skill_id '
        'WHERE f.pet_id = ?',
        <Object?>[petId],
      );
      final learnedRows = database.select(
        'SELECT s.*, x.source_kind, x.learn_level, x.source_stage, '
        'x.blood_raw, x.requirement_text, x.ordinal, '
        'EXISTS(SELECT 1 FROM pet_feature_skills f '
        'WHERE f.skill_id = s.skill_id) AS is_feature '
        'FROM pet_skill_sources x '
        'JOIN skills s ON s.skill_id = x.skill_id '
        'WHERE x.pet_id = ? '
        'ORDER BY CASE x.source_kind '
        "WHEN 'native' THEN 0 WHEN 'blood' THEN 1 "
        "WHEN 'stone' THEN 2 ELSE 3 END, x.ordinal, s.skill_id",
        <Object?>[petId],
      );
      return PetSkillBundle(
        featureSkill: featureRows.isEmpty
            ? null
            : _skillSummary(featureRows.first),
        learnableSkills: learnedRows
            .map(
              (row) => LearnableSkill(
                skill: _skillSummary(row),
                sourceKind: row['source_kind'] as String,
                ordinal: row['ordinal'] as int,
                learnLevel: row['learn_level'] as int?,
                sourceStage: row['source_stage'] as int?,
                bloodRaw: row['blood_raw'] as String?,
                requirementText: row['requirement_text'] as String?,
              ),
            )
            .toList(),
      );
    });
  }

  @override
  Future<List<SkillSummary>> searchSkills(SkillQuery query) {
    return _read('search skills', (database) {
      final keyword = query.keyword.trim();
      final conditions = <String>["s.status = 'active'"];
      final arguments = <Object?>[];
      if (keyword.isNotEmpty) {
        conditions.add("s.name LIKE ? ESCAPE '\\'");
        arguments.add('%${_escapeLike(keyword)}%');
      }
      switch (query.filter) {
        case SkillFilter.features:
          conditions.add(
            'EXISTS(SELECT 1 FROM pet_feature_skills f '
            'WHERE f.skill_id = s.skill_id)',
          );
        case SkillFilter.learnable:
          conditions.add(
            'EXISTS(SELECT 1 FROM pet_skill_sources x '
            'WHERE x.skill_id = s.skill_id)',
          );
        case SkillFilter.all:
          break;
      }
      if (query.skillTypes.isNotEmpty) {
        final skillTypeConditions = <String>[];
        for (final skillType in query.skillTypes) {
          if (skillType == '\u7269\u653b' || skillType == '\u9b54\u653b') {
            skillTypeConditions.add(
              "json_extract(s.extra_json, '\$.damage_class') = ?",
            );
          } else if (skillType == '\u9632\u5fa1' ||
              skillType == '\u72b6\u6001') {
            skillTypeConditions.add('s.category = ?');
          } else {
            skillTypeConditions.add('0 = 1');
            continue;
          }
          arguments.add(skillType);
        }
        conditions.add('(${skillTypeConditions.join(' OR ')})');
      }
      if (query.typeIds.isNotEmpty) {
        conditions.add(
          's.type_id IN (${List.filled(query.typeIds.length, '?').join(', ')})',
        );
        arguments.addAll(query.typeIds);
      }
      if (query.tags.isNotEmpty) {
        final tagConditions = <String>[];
        for (final tag in query.tags) {
          final tagCondition = _skillTagCondition(tag);
          tagConditions.add(tagCondition.sql);
          arguments.addAll(tagCondition.arguments);
        }
        conditions.add('(${tagConditions.join(' OR ')})');
      }
      final rows = database.select(
        'SELECT s.*, EXISTS(SELECT 1 FROM pet_feature_skills f '
        'WHERE f.skill_id = s.skill_id) AS is_feature '
        'FROM skills s WHERE ${conditions.join(' AND ')} '
        'ORDER BY CASE WHEN s.name = ? THEN 0 ELSE 1 END, s.name, s.skill_id '
        'LIMIT ? OFFSET ?',
        <Object?>[
          ...arguments,
          keyword,
          _limit(query.limit),
          _offset(query.offset),
        ],
      );
      return rows.map(_skillSummary).toList();
    });
  }

  @override
  Future<SkillDetail> getSkillDetail(String skillId) {
    return _read('load skill detail', (database) {
      final rows = database.select(
        'SELECT s.*, EXISTS(SELECT 1 FROM pet_feature_skills f '
        'WHERE f.skill_id = s.skill_id) AS is_feature '
        "FROM skills s WHERE s.skill_id = ? AND s.status = 'active'",
        <Object?>[skillId],
      );
      if (rows.isEmpty) {
        throw CatalogNotFoundException('Skill', skillId);
      }
      final notes = database.select(
        'SELECT note_id FROM skill_description_notes '
        'WHERE skill_id = ? ORDER BY ordinal',
        <Object?>[skillId],
      );
      final row = rows.first;
      return SkillDetail(
        summary: _skillSummary(row),
        description: row['description'] as String?,
        targetText: row['target_text'] as String?,
        descriptionNoteIds: notes
            .map((note) => note['note_id'] as String)
            .toList(),
        sourceReferences: _sourceReferences(database, 'skill', skillId),
      );
    });
  }

  @override
  Future<List<SkillUser>> getSkillUsers(
    String skillId, {
    required bool feature,
  }) {
    return _read('load skill users', (database) {
      if (!_skillExists(database, skillId)) {
        throw CatalogNotFoundException('Skill', skillId);
      }
      final rows = feature
          ? database.select(
              'SELECT p.pet_id, p.handbook_id, h.dex_no, p.name, p.title, '
              'p.form, p.illustration_key, '
              'CASE WHEN d.default_pet_id = p.pet_id THEN 1 ELSE 0 END '
              'AS is_default, NULL AS source_kind, NULL AS learn_level, '
              'NULL AS source_stage, NULL AS blood_raw, '
              'NULL AS requirement_text '
              'FROM pet_feature_skills f '
              'JOIN pets p ON p.pet_id = f.pet_id '
              'JOIN handbook_entries h ON h.handbook_id = p.handbook_id '
              'JOIN handbook_display d ON d.handbook_id = p.handbook_id '
              'WHERE f.skill_id = ? ORDER BY h.sort_order, p.pet_id',
              <Object?>[skillId],
            )
          : database.select(
              'SELECT p.pet_id, p.handbook_id, h.dex_no, p.name, p.title, '
              'p.form, p.illustration_key, '
              'CASE WHEN d.default_pet_id = p.pet_id THEN 1 ELSE 0 END '
              'AS is_default, x.source_kind, x.learn_level, x.source_stage, '
              'x.blood_raw, x.requirement_text '
              'FROM pet_skill_sources x '
              'JOIN pets p ON p.pet_id = x.pet_id '
              'JOIN handbook_entries h ON h.handbook_id = p.handbook_id '
              'JOIN handbook_display d ON d.handbook_id = p.handbook_id '
              'WHERE x.skill_id = ? '
              'ORDER BY h.sort_order, p.pet_id, x.source_kind, x.ordinal',
              <Object?>[skillId],
            );
      return rows
          .map(
            (row) => SkillUser(
              pet: _petSummary(database, row),
              relationshipKind: feature
                  ? 'feature'
                  : row['source_kind'] as String,
              learnLevel: row['learn_level'] as int?,
              sourceStage: row['source_stage'] as int?,
              bloodRaw: row['blood_raw'] as String?,
              requirementText: row['requirement_text'] as String?,
            ),
          )
          .toList();
    });
  }

  @override
  Future<EvolutionGraph> getEvolutionGraph(String petId) {
    return _read('load evolution graph', (database) {
      if (!_petExists(database, petId)) {
        throw CatalogNotFoundException('Creature', petId);
      }
      final groupRows = database.select(
        'SELECT evolution_group_id FROM pet_evolution_groups '
        'WHERE pet_id = ? ORDER BY evolution_group_id',
        <Object?>[petId],
      );
      final groupIds = groupRows
          .map((row) => row['evolution_group_id'] as String)
          .toList();
      if (groupIds.isEmpty) {
        return const EvolutionGraph(
          nodes: <PetSummary>[],
          edges: <EvolutionEdge>[],
          groupIds: <String>[],
        );
      }
      final placeholders = List.filled(groupIds.length, '?').join(', ');
      final nodeRows = database.select(
        'SELECT DISTINCT p.pet_id, p.handbook_id, h.dex_no, p.name, p.title, '
        'p.form, p.illustration_key, '
        'CASE WHEN d.default_pet_id = p.pet_id THEN 1 ELSE 0 END AS is_default '
        'FROM pet_evolution_groups m '
        'JOIN pets p ON p.pet_id = m.pet_id '
        'JOIN handbook_entries h ON h.handbook_id = p.handbook_id '
        'JOIN handbook_display d ON d.handbook_id = p.handbook_id '
        'WHERE m.evolution_group_id IN ($placeholders) '
        'ORDER BY m.source_order, p.pet_id',
        groupIds,
      );
      final edgeRows = database.select(
        'SELECT evolution_group_id, from_pet_id, to_pet_id, method_code, '
        'level_requirement, condition_text FROM evolution_edges '
        'WHERE evolution_group_id IN ($placeholders) '
        'ORDER BY evolution_group_id, ordinal',
        groupIds,
      );
      return EvolutionGraph(
        nodes: nodeRows.map((row) => _petSummary(database, row)).toList(),
        edges: edgeRows
            .map(
              (row) => EvolutionEdge(
                evolutionGroupId: row['evolution_group_id'] as String,
                fromPetId: row['from_pet_id'] as String,
                toPetId: row['to_pet_id'] as String,
                methodCode: row['method_code'] as String? ?? 'source',
                levelRequirement: row['level_requirement'] as int?,
                conditionText: row['condition_text'] as String?,
              ),
            )
            .toList(),
        groupIds: groupIds,
      );
    });
  }

  @override
  Future<CatalogInfo> getCatalogInfo() {
    return _read('load Catalog information', (database) {
      final rows = database.select(
        'SELECT dataset_id, schema_version, data_version, snapshot_id, '
        'adapter_version, builder_version, built_at_utc, coverage_json '
        'FROM catalog_meta WHERE singleton = 1',
      );
      if (rows.length != 1) {
        throw const FormatException('Catalog metadata row is missing.');
      }
      final range = database
          .select(
            'SELECT min(revised_at_utc) AS earliest, '
            'max(revised_at_utc) AS latest FROM source_revisions',
          )
          .first;
      final row = rows.first;
      final coverageJson = jsonDecode(row['coverage_json'] as String);
      if (coverageJson is! Map<String, dynamic> ||
          coverageJson.values.any((value) => value is! bool)) {
        throw const FormatException('Catalog coverage metadata is invalid.');
      }
      return CatalogInfo(
        datasetId: row['dataset_id'] as String,
        schemaVersion: row['schema_version'] as int,
        dataVersion: row['data_version'] as int,
        snapshotId: row['snapshot_id'] as String,
        adapterVersion: row['adapter_version'] as String,
        builderVersion: row['builder_version'] as String,
        builtAtUtc: row['built_at_utc'] as String,
        coverage: coverageJson.map(
          (key, value) => MapEntry(key, value as bool),
        ),
        earliestSourceRevisionUtc: range['earliest'] as String,
        latestSourceRevisionUtc: range['latest'] as String,
      );
    });
  }
}

final class _SqlClause {
  const _SqlClause(this.sql, this.arguments);

  final String sql;
  final List<Object?> arguments;
}

_SqlClause _searchClause(String rawKeyword) {
  final keyword = rawKeyword.trim();
  if (keyword.isEmpty) {
    return const _SqlClause('', <Object?>[]);
  }
  final pattern = '%${_escapeLike(keyword)}%';
  final dexNo = RegExp(r'^\d+$').hasMatch(keyword)
      ? keyword.padLeft(3, '0')
      : null;
  return _SqlClause(
    "AND (p.name LIKE ? ESCAPE '\\' OR p.title LIKE ? ESCAPE '\\' "
    "OR EXISTS(SELECT 1 FROM pet_aliases a WHERE a.pet_id = p.pet_id "
    "AND a.alias LIKE ? ESCAPE '\\') OR (? IS NOT NULL AND h.dex_no = ?))",
    <Object?>[pattern, pattern, pattern, dexNo, dexNo],
  );
}

_SqlClause _typeClause(List<String> typeIds) {
  if (typeIds.isEmpty) {
    return const _SqlClause('', <Object?>[]);
  }
  final placeholders = List.filled(typeIds.length, '?').join(', ');
  return _SqlClause(
    'AND EXISTS(SELECT 1 FROM pet_types filter_types '
    'WHERE filter_types.pet_id = p.pet_id '
    'AND filter_types.type_id IN ($placeholders))',
    List<Object?>.from(typeIds),
  );
}

String _escapeLike(String value) {
  return value
      .replaceAll(r'\', r'\\')
      .replaceAll('%', r'\%')
      .replaceAll('_', r'\_');
}

String _petOrder(PetSort sort) {
  return switch (sort) {
    PetSort.handbook =>
      'h.sort_order IS NULL, h.sort_order, h.handbook_id, p.pet_id',
    PetSort.name => 'p.name, p.pet_id',
    PetSort.attack => 'p.atk IS NULL, p.atk DESC, p.pet_id',
    PetSort.magicAttack => 'p.spa IS NULL, p.spa DESC, p.pet_id',
    PetSort.speed => 'p.spe IS NULL, p.spe DESC, p.pet_id',
  };
}

int _limit(int value) => value.clamp(1, 200);

int _offset(int value) => value < 0 ? 0 : value;

bool? _nullableBool(Object? value) {
  if (value == null) {
    return null;
  }
  return value == 1;
}

bool _petExists(Database database, String petId) {
  return database.select(
    "SELECT 1 FROM pets WHERE pet_id = ? AND status = 'active'",
    <Object?>[petId],
  ).isNotEmpty;
}

bool _skillExists(Database database, String skillId) {
  return database.select(
    "SELECT 1 FROM skills WHERE skill_id = ? AND status = 'active'",
    <Object?>[skillId],
  ).isNotEmpty;
}

PetSummary _petSummary(Database database, Row row) {
  final petId = row['pet_id'] as String;
  final types = database
      .select(
        'SELECT t.name FROM pet_types p '
        'JOIN types t ON t.type_id = p.type_id '
        'WHERE p.pet_id = ? ORDER BY p.slot',
        <Object?>[petId],
      )
      .map((type) => type['name'] as String)
      .toList();
  return PetSummary(
    petId: petId,
    handbookId: row['handbook_id'] as String,
    dexNo: row['dex_no'] as String,
    name: row['name'] as String,
    title: row['title'] as String,
    form: row['form'] as String?,
    types: types,
    illustrationKey: row['illustration_key'] as String?,
    isDefaultForm: row['is_default'] == 1,
  );
}

SkillSummary _skillSummary(Row row) {
  final extra = jsonDecode(row['extra_json'] as String);
  return SkillSummary(
    skillId: row['skill_id'] as String,
    name: row['name'] as String,
    category: row['category'] as String?,
    damageClass: extra is Map<String, dynamic>
        ? extra['damage_class'] as String?
        : null,
    description: row['description'] as String?,
    iconKey: row['icon_key'] as String?,
    element: row['element_raw'] as String?,
    energyValue: row['energy_value'] as num?,
    energyText: row['energy_text'] as String?,
    powerValue: row['power_value'] as num?,
    powerText: row['power_text'] as String?,
    isFeature: row['is_feature'] == 1,
  );
}

({String sql, List<Object?> arguments}) _skillTagCondition(String tag) {
  return switch (tag) {
    '\u5f02\u5e38' => (
      sql:
          'EXISTS(SELECT 1 FROM skill_description_notes n '
          "WHERE n.skill_id = s.skill_id AND n.note_id IN ('1001', '1002', '1004', '1008'))",
      arguments: const <Object?>[],
    ),
    '\u56de\u8840' => (
      sql: "(s.description LIKE ? OR s.description LIKE ?)",
      arguments: const <Object?>[
        '%\u56de\u590d%\u751f\u547d%',
        '%\u5438\u8840%',
      ],
    ),
    '\u56de\u80fd' => (
      sql: 's.description LIKE ?',
      arguments: const <Object?>['%\u56de\u590d%\u80fd\u91cf%'],
    ),
    '\u5e94\u5bf9' => (
      sql:
          'EXISTS(SELECT 1 FROM skill_description_notes n '
          "WHERE n.skill_id = s.skill_id AND n.note_id IN ('1015', '1017'))",
      arguments: const <Object?>[],
    ),
    '\u5370\u8bb0' => _descriptionTag('%\u5370\u8bb0%'),
    '\u9a71\u6563' => _descriptionTag('%\u9a71\u6563%'),
    '\u5148\u624b' => (
      sql: "(s.description LIKE ? AND s.category <> '\u9632\u5fa1')",
      arguments: const <Object?>['%\u5148\u624b%'],
    ),
    '\u79bb\u573a' => (
      sql: '(s.description LIKE ? OR s.description LIKE ? OR s.description LIKE ?)',
      arguments: const <Object?>[
        '%\u79bb\u573a%',
        '%\u8131\u79bb%',
        '%\u8fd4\u573a%',
      ],
    ),
    '\u5929\u6c14' => _descriptionTag('%\u5929\u6c14%'),
    '\u9009\u62e9' => _descriptionTag('%\u9009\u62e9%'),
    '\u5de7\u53d8' => _descriptionTag('%\u5de7\u53d8%'),
    '\u5f3a\u5316' => _descriptionTag('%\u6c38\u4e45%'),
    '\u8fde\u51fb' => _descriptionTag('%\u8fde\u51fb%'),
    '\u840c\u5316' => _descriptionTag('%\u840c\u5316%'),
    '\u5f15\u7535' => _descriptionTag('%\u5f15\u7535%'),
    '\u8fc5\u6377' => _descriptionTag('%\u8fc5\u6377%'),
    '\u4f20\u52a8' => _descriptionTag('%\u4f20\u52a8%'),
    '\u8ff8\u53d1' => _descriptionTag('%\u8ff8\u53d1%'),
    '\u5949\u732e' => _descriptionTag('%\u5949\u732e%'),
    '\u6253\u65ad' => _descriptionTag('%\u6253\u65ad%'),
    _ => (sql: '0 = 1', arguments: const <Object?>[]),
  };
}

({String sql, List<Object?> arguments}) _descriptionTag(String pattern) =>
    (sql: 's.description LIKE ?', arguments: <Object?>[pattern]);

List<SourceReference> _sourceReferences(
  Database database,
  String entityKind,
  String entityId,
) {
  final rows = database.select(
    'SELECT r.source_name, r.revision_id, r.license_id, r.source_url '
    'FROM entity_sources e '
    'JOIN source_revisions r ON r.source_ref = e.source_ref '
    'WHERE e.entity_kind = ? AND e.entity_id = ? '
    'ORDER BY r.source_key, r.revision_id',
    <Object?>[entityKind, entityId],
  );
  return rows
      .map(
        (row) => SourceReference(
          sourceName: row['source_name'] as String,
          revisionId: row['revision_id'] as int,
          licenseId: row['license_id'] as String,
          sourceUrl: row['source_url'] as String,
        ),
      )
      .toList();
}
