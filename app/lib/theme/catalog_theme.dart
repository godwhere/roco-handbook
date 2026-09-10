import 'package:flutter/material.dart';

abstract final class CatalogTypography {
  static const displayFamily = 'RocoDisplay';
  static const numberFamily = 'RocoNumbers';

  static const _fallbackFamilies = <String>[
    'PingFang SC',
    'Noto Sans CJK SC',
    'Roboto',
  ];

  static TextTheme applyDisplayFont(TextTheme base) {
    TextStyle? display(TextStyle? style) => style?.copyWith(
      fontFamily: displayFamily,
      fontFamilyFallback: _fallbackFamilies,
    );

    return base.copyWith(
      displayLarge: display(base.displayLarge),
      displayMedium: display(base.displayMedium),
      displaySmall: display(base.displaySmall),
      headlineLarge: display(base.headlineLarge),
      headlineMedium: display(base.headlineMedium),
      headlineSmall: display(base.headlineSmall),
      titleLarge: display(base.titleLarge),
      titleMedium: display(base.titleMedium),
      titleSmall: display(base.titleSmall),
      labelLarge: display(base.labelLarge),
      labelMedium: display(base.labelMedium),
      labelSmall: display(base.labelSmall),
    );
  }

  static TextStyle numbers(TextStyle? base) =>
      (base ?? const TextStyle()).copyWith(
        fontFamily: numberFamily,
        fontFamilyFallback: _fallbackFamilies,
        fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
      );
}

ThemeData buildCatalogTheme(ColorScheme colorScheme) {
  final base = ThemeData(
    colorScheme: colorScheme,
    useMaterial3: true,
    inputDecorationTheme: const InputDecorationTheme(filled: true),
    cardTheme: const CardThemeData(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
    ),
  );
  return base.copyWith(
    textTheme: CatalogTypography.applyDisplayFont(base.textTheme),
    primaryTextTheme: CatalogTypography.applyDisplayFont(base.primaryTextTheme),
  );
}
