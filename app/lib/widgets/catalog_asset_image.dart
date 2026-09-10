import 'package:flutter/material.dart';

import '../domain/catalog_models.dart';

const _assetRoot = 'assets/wiki/v2';

String? petIllustrationAsset(String? key) =>
    key == null ? null : '$_assetRoot/pets/illustrations/$key.png';

String? petShinyIllustrationAsset(String? key) =>
    key == null ? null : '$_assetRoot/pets/shiny/${key}_yise.png';

String? skillIconAsset(SkillSummary skill) {
  final key = skill.iconKey;
  if (key == null) {
    return null;
  }
  final prefix = skill.isFeature ? 'Feature' : 'Skill';
  return '$_assetRoot/skills/${prefix}_$key.png';
}

String? typeIconAsset(String typeName) {
  final shortName = typeName.endsWith('\u7cfb')
      ? typeName.substring(0, typeName.length - 1)
      : typeName;
  final file = _typeIconFiles[shortName];
  return file == null ? null : '$_assetRoot/ui/types/$file.png';
}

String? skillCategoryIconAsset(String? category) {
  final file = _skillCategoryFiles[category];
  return file == null ? null : '$_assetRoot/ui/skill-categories/$file.png';
}

String? skillSourceIconAsset(String sourceKind) {
  final file = switch (sourceKind) {
    'native' || 'blood' => 'bloodline',
    'stone' || 'legendary' => 'skill-stone',
    _ => null,
  };
  return file == null ? null : '$_assetRoot/ui/sources/$file.png';
}

const _typeIconFiles = <String, String>{
  '\u666e\u901a': 'normal',
  '\u8349': 'grass',
  '\u706b': 'fire',
  '\u6c34': 'water',
  '\u5149': 'light',
  '\u5730': 'ground',
  '\u51b0': 'ice',
  '\u9f99': 'dragon',
  '\u7535': 'electric',
  '\u6bd2': 'poison',
  '\u866b': 'bug',
  '\u6b66': 'martial',
  '\u7ffc': 'wing',
  '\u840c': 'cute',
  '\u5e7d': 'ghost',
  '\u6076': 'evil',
  '\u673a\u68b0': 'mechanical',
  '\u5e7b': 'illusion',
};

const _skillCategoryFiles = <String, String>{
  '\u7269\u653b': 'physical-attack',
  '\u9b54\u653b': 'magic-attack',
  '\u9632\u5fa1': 'defense',
  '\u72b6\u6001': 'status',
};

class CatalogAssetImage extends StatelessWidget {
  const CatalogAssetImage({
    required this.assetPath,
    required this.semanticLabel,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.fallbackIcon = Icons.image_not_supported_outlined,
    this.borderRadius,
    super.key,
  });

  final String? assetPath;
  final String semanticLabel;
  final double? width;
  final double? height;
  final BoxFit fit;
  final IconData fallbackIcon;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final fallback = SizedBox(
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: borderRadius,
        ),
        child: Center(child: Icon(fallbackIcon)),
      ),
    );
    final content = assetPath == null
        ? fallback
        : Image.asset(
            assetPath!,
            width: width,
            height: height,
            fit: fit,
            excludeFromSemantics: true,
            errorBuilder: (_, _, _) => fallback,
          );
    final clipped = borderRadius == null
        ? content
        : ClipRRect(borderRadius: borderRadius!, child: content);
    return Semantics(label: semanticLabel, image: true, child: clipped);
  }
}

class TypeIconLabel extends StatelessWidget {
  const TypeIconLabel({
    required this.typeName,
    this.compact = false,
    super.key,
  });

  final String typeName;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 18.0 : 22.0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        CatalogAssetImage(
          assetPath: typeIconAsset(typeName),
          semanticLabel: typeName,
          width: size,
          height: size,
          fallbackIcon: Icons.circle_outlined,
          borderRadius: BorderRadius.circular(size / 2),
        ),
        const SizedBox(width: 5),
        Text(typeName),
      ],
    );
  }
}
