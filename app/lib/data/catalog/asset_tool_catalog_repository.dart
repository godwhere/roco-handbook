import 'dart:convert';

import 'package:flutter/services.dart';

import '../../domain/tool_catalogs.dart';

const _toolAssetRoot = 'assets/wiki/tools/v1';

final class AssetActivityTimelineRepository
    implements ActivityTimelineRepository {
  const AssetActivityTimelineRepository({
    this.assetPath = 'assets/wiki/activity-timeline-v1.json',
  });

  final String assetPath;

  @override
  Future<ActivityTimelineCatalog> load() async {
    final value = jsonDecode(await rootBundle.loadString(assetPath));
    if (value is! Map<String, dynamic> ||
        value['contract_version'] != 1 ||
        value['dataset_id'] != 'roco-world-zh-cn') {
      throw const FormatException('Invalid activity timeline identity');
    }
    final rawOrder = value['category_order'];
    final rawLabels = value['category_labels'];
    final rawEntries = value['entries'];
    if (rawOrder is! List<dynamic> ||
        rawLabels is! Map<String, dynamic> ||
        rawEntries is! List<dynamic> ||
        rawOrder.any((item) => item is! String)) {
      throw const FormatException('Invalid activity timeline shape');
    }
    final order = List<String>.unmodifiable(rawOrder.cast<String>());
    if (order.isEmpty || order.toSet().length != order.length) {
      throw const FormatException('Invalid activity category order');
    }
    final labels = <String, String>{};
    for (final category in order) {
      final label = rawLabels[category];
      if (label is! String || label.isEmpty) {
        throw const FormatException('Invalid activity category label');
      }
      labels[category] = label;
    }
    if (rawLabels.length != labels.length) {
      throw const FormatException('Unexpected activity category label');
    }
    final entries = <ActivityTimelineEntry>[];
    final ids = <String>{};
    for (final raw in rawEntries) {
      if (raw is! Map<String, dynamic>) {
        throw const FormatException('Invalid activity timeline entry');
      }
      final activityId = raw['activity_id'];
      final seriesId = raw['series_id'];
      final name = raw['name'];
      final summary = raw['summary'];
      final description = raw['description'];
      final category = raw['category'];
      final kindLabel = raw['kind_label'];
      final pageTitle = raw['page_title'];
      final masked = raw['masked'];
      final startAt = _optionalDate(raw['start_at']);
      final endAt = _optionalDate(raw['end_at']);
      final iconPath = raw['icon_path'];
      if (activityId is! String ||
          activityId.isEmpty ||
          !ids.add(activityId) ||
          seriesId is! String ||
          seriesId.isEmpty ||
          name is! String ||
          name.isEmpty ||
          (summary != null && summary is! String) ||
          (description != null && description is! String) ||
          category is! String ||
          !labels.containsKey(category) ||
          kindLabel is! String ||
          (pageTitle != null && pageTitle is! String) ||
          masked is! bool ||
          (iconPath != null && iconPath is! String) ||
          (startAt != null && endAt != null && startAt.isAfter(endAt))) {
        throw const FormatException('Invalid activity timeline fields');
      }
      entries.add(
        ActivityTimelineEntry(
          activityId: activityId,
          seriesId: seriesId,
          name: name,
          summary: summary as String?,
          description: description as String?,
          category: category,
          kindLabel: kindLabel,
          pageTitle: pageTitle as String?,
          masked: masked,
          startAt: startAt,
          endAt: endAt,
          iconPath: iconPath == null ? null : '$_toolAssetRoot/$iconPath',
        ),
      );
    }
    if (entries.isEmpty) {
      throw const FormatException('Activity timeline is empty');
    }
    return ActivityTimelineCatalog(
      categoryOrder: order,
      categoryLabels: Map<String, String>.unmodifiable(labels),
      entries: List<ActivityTimelineEntry>.unmodifiable(entries),
    );
  }
}

final class AssetFashionCatalogRepository implements FashionCatalogRepository {
  const AssetFashionCatalogRepository({
    this.assetPath = 'assets/wiki/fashion-catalog-v1.json',
  });

  final String assetPath;

  @override
  Future<FashionCatalog> load() async {
    final value = jsonDecode(await rootBundle.loadString(assetPath));
    if (value is! Map<String, dynamic> ||
        value['contract_version'] != 1 ||
        value['dataset_id'] != 'roco-world-zh-cn') {
      throw const FormatException('Invalid fashion catalog identity');
    }
    final rawGenderOrder = value['gender_order'];
    final rawEntries = value['entries'];
    if (rawGenderOrder is! List<dynamic> ||
        rawEntries is! List<dynamic> ||
        rawGenderOrder.any((item) => item is! String)) {
      throw const FormatException('Invalid fashion catalog shape');
    }
    final genderOrder = List<String>.unmodifiable(
      rawGenderOrder.cast<String>(),
    );
    if (genderOrder.isEmpty ||
        genderOrder.toSet().length != genderOrder.length) {
      throw const FormatException('Invalid fashion gender order');
    }
    final entries = <FashionEntry>[];
    final ids = <String>{};
    for (final raw in rawEntries) {
      if (raw is! Map<String, dynamic>) {
        throw const FormatException('Invalid fashion entry');
      }
      final outfitId = raw['outfit_id'];
      final name = raw['name'];
      final pageTitle = raw['page_title'];
      final description = raw['description'];
      final gradeName = raw['grade_name'];
      final quality = raw['quality'];
      final seriesId = raw['series_id'];
      final rawVariants = raw['variants'];
      if (outfitId is! String ||
          outfitId.isEmpty ||
          !ids.add(outfitId) ||
          name is! String ||
          name.isEmpty ||
          pageTitle is! String ||
          pageTitle.isEmpty ||
          (description != null && description is! String) ||
          gradeName is! String ||
          gradeName.isEmpty ||
          quality is! int ||
          quality <= 0 ||
          seriesId is! int ||
          seriesId <= 0 ||
          rawVariants is! List<dynamic>) {
        throw const FormatException('Invalid fashion entry fields');
      }
      final variants = <FashionVariant>[];
      final genders = <String>{};
      for (final rawVariant in rawVariants) {
        if (rawVariant is! Map<String, dynamic>) {
          throw const FormatException('Invalid fashion variant');
        }
        final gender = rawVariant['gender'];
        final genderLabel = rawVariant['gender_label'];
        final variantName = rawVariant['name'];
        final variantDescription = rawVariant['description'];
        final rawAcquisition = rawVariant['acquisition'];
        final itemCount = rawVariant['item_count'];
        final imagePath = rawVariant['image_path'];
        if (gender is! String ||
            !genderOrder.contains(gender) ||
            !genders.add(gender) ||
            genderLabel is! String ||
            genderLabel.isEmpty ||
            variantName is! String ||
            variantName.isEmpty ||
            (variantDescription != null && variantDescription is! String) ||
            rawAcquisition is! List<dynamic> ||
            rawAcquisition.any((item) => item is! String || item.isEmpty) ||
            itemCount is! int ||
            itemCount <= 0 ||
            imagePath is! String ||
            imagePath.isEmpty) {
          throw const FormatException('Invalid fashion variant fields');
        }
        variants.add(
          FashionVariant(
            gender: gender,
            genderLabel: genderLabel,
            name: variantName,
            description: variantDescription as String?,
            acquisition: List<String>.unmodifiable(
              rawAcquisition.cast<String>(),
            ),
            itemCount: itemCount,
            imagePath: '$_toolAssetRoot/$imagePath',
          ),
        );
      }
      if (genders.length != genderOrder.length) {
        throw const FormatException('Incomplete fashion variants');
      }
      entries.add(
        FashionEntry(
          outfitId: outfitId,
          name: name,
          pageTitle: pageTitle,
          description: description as String?,
          gradeName: gradeName,
          quality: quality,
          seriesId: seriesId,
          variants: List<FashionVariant>.unmodifiable(variants),
        ),
      );
    }
    if (entries.isEmpty) {
      throw const FormatException('Fashion catalog is empty');
    }
    return FashionCatalog(
      genderOrder: genderOrder,
      entries: List<FashionEntry>.unmodifiable(entries),
    );
  }
}

DateTime? _optionalDate(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is! String || value.isEmpty) {
    throw const FormatException('Invalid optional date');
  }
  return DateTime.tryParse(value) ??
      (throw const FormatException('Invalid optional date'));
}
