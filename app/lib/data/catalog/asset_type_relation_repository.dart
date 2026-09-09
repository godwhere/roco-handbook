import 'dart:convert';

import 'package:flutter/services.dart';

import '../../domain/type_relations.dart';

final class AssetTypeRelationRepository implements TypeRelationRepository {
  const AssetTypeRelationRepository({
    this.assetPath = 'assets/wiki/type-relations-v1.json',
  });

  final String assetPath;

  static _TypeRelationContract? _cached;

  @override
  Future<PetTypeRelationships> forCreatureTypes(List<String> typeNames) async {
    final contract = _cached ??= await _load();
    final resolved = typeNames.map(_shortTypeName).toList(growable: false);
    if (resolved.isEmpty || resolved.length > 2) {
      throw const FormatException('A creature must have one or two types');
    }
    for (final typeName in resolved) {
      if (!contract.relations.containsKey(typeName)) {
        throw FormatException('Unknown creature type: $typeName');
      }
    }
    final outgoing = resolved
        .map(
          (typeName) => TypeRelationSet(
            typeName: typeName,
            strongAgainst: contract.relations[typeName]!.strongAgainst,
            resistedBy: contract.relations[typeName]!.resistedBy,
          ),
        )
        .toList(growable: false);
    final incoming = <IncomingTypeDamage>[];
    for (final attacker in contract.typeOrder.where(
      (typeName) => typeName != '\u65e0\u7cfb\u522b',
    )) {
      var multiplier = 1.0;
      final attack = contract.relations[attacker]!;
      for (final defender in resolved) {
        if (attack.strongAgainst.contains(defender)) {
          multiplier *= 2;
        } else if (attack.resistedBy.contains(defender)) {
          multiplier *= 0.5;
        }
      }
      if (resolved.length == 2 && multiplier >= 4) {
        multiplier = 3;
      }
      if (multiplier != 1) {
        incoming.add(
          IncomingTypeDamage(typeName: attacker, multiplier: multiplier),
        );
      }
    }
    incoming.sort((left, right) {
      final multiplier = right.multiplier.compareTo(left.multiplier);
      if (multiplier != 0) {
        return multiplier;
      }
      return contract.typeOrder
          .indexOf(left.typeName)
          .compareTo(contract.typeOrder.indexOf(right.typeName));
    });
    return PetTypeRelationships(outgoing: outgoing, incoming: incoming);
  }

  Future<_TypeRelationContract> _load() async {
    final text = await rootBundle.loadString(assetPath);
    final value = jsonDecode(text);
    if (value is! Map<String, dynamic> ||
        value['contract_version'] != 1 ||
        value['dataset_id'] != 'roco-world-zh-cn') {
      throw const FormatException('Invalid type relation contract identity');
    }
    final rawOrder = value['type_order'];
    final rawRelations = value['relations'];
    if (rawOrder is! List<dynamic> || rawRelations is! Map<String, dynamic>) {
      throw const FormatException('Invalid type relation contract shape');
    }
    final order = rawOrder.cast<String>();
    final relations = <String, _TypeRelations>{};
    for (final typeName in order) {
      final raw = rawRelations[typeName];
      if (raw is! Map<String, dynamic>) {
        throw FormatException('Missing type relation: $typeName');
      }
      relations[typeName] = _TypeRelations(
        strongAgainst: _stringList(raw['strong_against']),
        resistedBy: _stringList(raw['resisted_by']),
      );
    }
    return _TypeRelationContract(typeOrder: order, relations: relations);
  }
}

String _shortTypeName(String name) =>
    name.endsWith('\u7cfb') ? name.substring(0, name.length - 1) : name;

List<String> _stringList(Object? value) {
  if (value is! List<dynamic> || value.any((item) => item is! String)) {
    throw const FormatException('Type relation value must be a string array');
  }
  return List<String>.unmodifiable(value.cast<String>());
}

final class _TypeRelationContract {
  const _TypeRelationContract({
    required this.typeOrder,
    required this.relations,
  });

  final List<String> typeOrder;
  final Map<String, _TypeRelations> relations;
}

final class _TypeRelations {
  const _TypeRelations({required this.strongAgainst, required this.resistedBy});

  final List<String> strongAgainst;
  final List<String> resistedBy;
}
