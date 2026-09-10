class ActivityTimelineEntry {
  const ActivityTimelineEntry({
    required this.activityId,
    required this.seriesId,
    required this.name,
    required this.summary,
    required this.description,
    required this.category,
    required this.kindLabel,
    required this.pageTitle,
    required this.masked,
    required this.startAt,
    required this.endAt,
    required this.iconPath,
  });

  final String activityId;
  final String seriesId;
  final String name;
  final String? summary;
  final String? description;
  final String category;
  final String kindLabel;
  final String? pageTitle;
  final bool masked;
  final DateTime? startAt;
  final DateTime? endAt;
  final String? iconPath;
}

class ActivityTimelineCatalog {
  const ActivityTimelineCatalog({
    required this.categoryOrder,
    required this.categoryLabels,
    required this.entries,
  });

  final List<String> categoryOrder;
  final Map<String, String> categoryLabels;
  final List<ActivityTimelineEntry> entries;
}

abstract interface class ActivityTimelineRepository {
  Future<ActivityTimelineCatalog> load();
}

class FashionVariant {
  const FashionVariant({
    required this.gender,
    required this.genderLabel,
    required this.name,
    required this.description,
    required this.acquisition,
    required this.itemCount,
    required this.imagePath,
  });

  final String gender;
  final String genderLabel;
  final String name;
  final String? description;
  final List<String> acquisition;
  final int itemCount;
  final String imagePath;
}

class FashionEntry {
  const FashionEntry({
    required this.outfitId,
    required this.name,
    required this.pageTitle,
    required this.description,
    required this.gradeName,
    required this.quality,
    required this.seriesId,
    required this.variants,
  });

  final String outfitId;
  final String name;
  final String pageTitle;
  final String? description;
  final String gradeName;
  final int quality;
  final int seriesId;
  final List<FashionVariant> variants;

  FashionVariant variantFor(String gender) => variants.firstWhere(
    (variant) => variant.gender == gender,
    orElse: () => variants.first,
  );
}

class FashionCatalog {
  const FashionCatalog({required this.genderOrder, required this.entries});

  final List<String> genderOrder;
  final List<FashionEntry> entries;
}

abstract interface class FashionCatalogRepository {
  Future<FashionCatalog> load();
}
