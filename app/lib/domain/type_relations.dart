class TypeRelationSet {
  const TypeRelationSet({
    required this.typeName,
    required this.strongAgainst,
    required this.resistedBy,
  });

  final String typeName;
  final List<String> strongAgainst;
  final List<String> resistedBy;
}

class IncomingTypeDamage {
  const IncomingTypeDamage({required this.typeName, required this.multiplier});

  final String typeName;
  final double multiplier;
}

class PetTypeRelationships {
  const PetTypeRelationships({required this.outgoing, required this.incoming});

  final List<TypeRelationSet> outgoing;
  final List<IncomingTypeDamage> incoming;
}

abstract interface class TypeRelationRepository {
  Future<PetTypeRelationships> forCreatureTypes(List<String> typeNames);
}
