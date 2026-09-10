enum PetSort { handbook, name, attack, magicAttack, speed }

enum SkillFilter { all, features, learnable }

class PetQuery {
  const PetQuery({
    this.keyword = '',
    this.typeIds = const <String>[],
    this.sort = PetSort.handbook,
    this.limit = 80,
    this.offset = 0,
  });

  final String keyword;
  final List<String> typeIds;
  final PetSort sort;
  final int limit;
  final int offset;
}

class CatalogType {
  const CatalogType({required this.typeId, required this.name});

  final String typeId;
  final String name;
}

class SkillQuery {
  const SkillQuery({
    this.keyword = '',
    this.filter = SkillFilter.all,
    this.skillTypes = const <String>[],
    this.tags = const <String>[],
    this.typeIds = const <String>[],
    this.limit = 80,
    this.offset = 0,
  });

  final String keyword;
  final SkillFilter filter;
  final List<String> skillTypes;
  final List<String> tags;
  final List<String> typeIds;
  final int limit;
  final int offset;
}

class PetSummary {
  const PetSummary({
    required this.petId,
    required this.handbookId,
    required this.dexNo,
    required this.name,
    required this.title,
    required this.types,
    required this.isDefaultForm,
    this.form,
    this.illustrationKey,
  });

  final String petId;
  final String handbookId;
  final String dexNo;
  final String name;
  final String title;
  final String? form;
  final List<String> types;
  final String? illustrationKey;
  final bool isDefaultForm;
}

class PetDetail {
  const PetDetail({
    required this.summary,
    required this.stats,
    required this.sourceReferences,
    this.className,
    this.description,
    this.illustrationKey,
    this.stage,
    this.heightText,
    this.weightText,
    this.starlight,
    this.reviewGold,
    this.canDoubleRide,
    this.hasShiny,
    this.isLordEvolution,
  });

  final PetSummary summary;
  final String? className;
  final String? description;
  final String? illustrationKey;
  final int? stage;
  final String? heightText;
  final String? weightText;
  final int? starlight;
  final int? reviewGold;
  final bool? canDoubleRide;
  final bool? hasShiny;
  final bool? isLordEvolution;
  final Map<String, int?> stats;
  final List<SourceReference> sourceReferences;

  int? get totalBaseStats {
    const keys = <String>[
      'HP',
      'Attack',
      'Defense',
      'Magic attack',
      'Magic defense',
      'Speed',
    ];
    var total = 0;
    for (final key in keys) {
      final value = stats[key];
      if (value == null) {
        return null;
      }
      total += value;
    }
    return total;
  }
}

class SkillSummary {
  const SkillSummary({
    required this.skillId,
    required this.name,
    required this.isFeature,
    this.category,
    this.damageClass,
    this.description,
    this.iconKey,
    this.element,
    this.energyValue,
    this.energyText,
    this.powerValue,
    this.powerText,
  });

  final String skillId;
  final String name;
  final String? category;
  final String? damageClass;
  final String? description;
  final String? iconKey;
  final String? element;
  final num? energyValue;
  final String? energyText;
  final num? powerValue;
  final String? powerText;
  final bool isFeature;
}

class SkillDetail {
  const SkillDetail({
    required this.summary,
    required this.descriptionNoteIds,
    required this.sourceReferences,
    this.description,
    this.targetText,
  });

  final SkillSummary summary;
  final String? description;
  final String? targetText;
  final List<String> descriptionNoteIds;
  final List<SourceReference> sourceReferences;
}

class LearnableSkill {
  const LearnableSkill({
    required this.skill,
    required this.sourceKind,
    required this.ordinal,
    this.learnLevel,
    this.sourceStage,
    this.bloodRaw,
    this.requirementText,
  });

  final SkillSummary skill;
  final String sourceKind;
  final int ordinal;
  final int? learnLevel;
  final int? sourceStage;
  final String? bloodRaw;
  final String? requirementText;
}

class PetSkillBundle {
  const PetSkillBundle({required this.learnableSkills, this.featureSkill});

  final SkillSummary? featureSkill;
  final List<LearnableSkill> learnableSkills;
}

class SkillUser {
  const SkillUser({
    required this.pet,
    required this.relationshipKind,
    this.learnLevel,
    this.sourceStage,
    this.bloodRaw,
    this.requirementText,
  });

  final PetSummary pet;
  final String relationshipKind;
  final int? learnLevel;
  final int? sourceStage;
  final String? bloodRaw;
  final String? requirementText;
}

class EvolutionEdge {
  const EvolutionEdge({
    required this.evolutionGroupId,
    required this.fromPetId,
    required this.toPetId,
    required this.methodCode,
    this.levelRequirement,
    this.conditionText,
  });

  final String evolutionGroupId;
  final String fromPetId;
  final String toPetId;
  final String methodCode;
  final int? levelRequirement;
  final String? conditionText;
}

class EvolutionGraph {
  const EvolutionGraph({
    required this.nodes,
    required this.edges,
    required this.groupIds,
  });

  final List<PetSummary> nodes;
  final List<EvolutionEdge> edges;
  final List<String> groupIds;
}

class SourceReference {
  const SourceReference({
    required this.sourceName,
    required this.revisionId,
    required this.licenseId,
    required this.sourceUrl,
  });

  final String sourceName;
  final int revisionId;
  final String licenseId;
  final String sourceUrl;
}

class CatalogInfo {
  const CatalogInfo({
    required this.datasetId,
    required this.schemaVersion,
    required this.dataVersion,
    required this.snapshotId,
    required this.adapterVersion,
    required this.builderVersion,
    required this.builtAtUtc,
    required this.coverage,
    required this.earliestSourceRevisionUtc,
    required this.latestSourceRevisionUtc,
  });

  final String datasetId;
  final int schemaVersion;
  final int dataVersion;
  final String snapshotId;
  final String adapterVersion;
  final String builderVersion;
  final String builtAtUtc;
  final Map<String, bool> coverage;
  final String earliestSourceRevisionUtc;
  final String latestSourceRevisionUtc;
}

class CatalogNotFoundException implements Exception {
  CatalogNotFoundException(this.entityKind, this.entityId);

  final String entityKind;
  final String entityId;

  @override
  String toString() => '$entityKind not found: $entityId';
}

class CatalogQueryException implements Exception {
  CatalogQueryException(this.operation, this.cause);

  final String operation;
  final Object cause;

  @override
  String toString() => 'Catalog query failed during $operation: $cause';
}
