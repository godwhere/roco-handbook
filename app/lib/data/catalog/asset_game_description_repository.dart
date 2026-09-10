import 'dart:convert';

import 'package:flutter/services.dart';

import '../../domain/game_descriptions.dart';

final class AssetGameDescriptionRepository
    implements GameDescriptionRepository {
  const AssetGameDescriptionRepository({
    this.assetPath = 'assets/wiki/game-descriptions-v1.json',
  });

  final String assetPath;

  @override
  Future<GameDescriptionCatalog> load() async {
    final text = await rootBundle.loadString(assetPath);
    final value = jsonDecode(text);
    if (value is! Map<String, dynamic> ||
        value['contract_version'] != 1 ||
        value['dataset_id'] != 'roco-world-zh-cn') {
      throw const FormatException('Invalid game description contract identity');
    }
    final rawOrder = value['category_order'];
    final rawLabels = value['category_labels'];
    final rawEntries = value['entries'];
    if (rawOrder is! List<dynamic> ||
        rawLabels is! Map<String, dynamic> ||
        rawEntries is! List<dynamic> ||
        rawOrder.any((item) => item is! String)) {
      throw const FormatException('Invalid game description contract shape');
    }
    final order = List<String>.unmodifiable(rawOrder.cast<String>());
    if (order.isEmpty || order.toSet().length != order.length) {
      throw const FormatException('Invalid game description category order');
    }
    final labels = <String, String>{};
    for (final category in order) {
      final label = rawLabels[category];
      if (label is! String || label.isEmpty) {
        throw FormatException('Missing game description category: $category');
      }
      labels[category] = label;
    }
    if (rawLabels.length != labels.length) {
      throw const FormatException('Unexpected game description category');
    }
    final entries = <GameDescriptionEntry>[];
    final seenIds = <String>{};
    final seenNames = <String>{};
    for (final rawEntry in rawEntries) {
      if (rawEntry is! Map<String, dynamic>) {
        throw const FormatException('Invalid game description entry');
      }
      final noteId = rawEntry['note_id'];
      final name = rawEntry['name'];
      final description = rawEntry['description'];
      final category = rawEntry['category'];
      if (noteId is! String ||
          noteId.isEmpty ||
          !seenIds.add(noteId) ||
          name is! String ||
          name.isEmpty ||
          !seenNames.add(name) ||
          description is! String ||
          description.isEmpty ||
          category is! String ||
          !labels.containsKey(category)) {
        throw const FormatException('Invalid game description entry fields');
      }
      entries.add(
        GameDescriptionEntry(
          noteId: noteId,
          name: name,
          description: description,
          category: category,
        ),
      );
    }
    if (entries.isEmpty) {
      throw const FormatException('Game description contract is empty');
    }
    return GameDescriptionCatalog(
      categoryOrder: order,
      categoryLabels: Map<String, String>.unmodifiable(labels),
      entries: List<GameDescriptionEntry>.unmodifiable(entries),
    );
  }
}
