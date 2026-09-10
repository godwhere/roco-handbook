class GameDescriptionEntry {
  const GameDescriptionEntry({
    required this.noteId,
    required this.name,
    required this.description,
    required this.category,
  });

  final String noteId;
  final String name;
  final String description;
  final String category;
}

class GameDescriptionCatalog {
  const GameDescriptionCatalog({
    required this.categoryOrder,
    required this.categoryLabels,
    required this.entries,
  });

  final List<String> categoryOrder;
  final Map<String, String> categoryLabels;
  final List<GameDescriptionEntry> entries;
}

abstract interface class GameDescriptionRepository {
  Future<GameDescriptionCatalog> load();
}
