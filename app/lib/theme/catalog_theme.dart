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
  final displayTextTheme = CatalogTypography.applyDisplayFont(base.textTheme);
  return base.copyWith(
    textTheme: displayTextTheme,
    primaryTextTheme: CatalogTypography.applyDisplayFont(base.primaryTextTheme),
    appBarTheme: AppBarTheme(
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 2,
      surfaceTintColor: colorScheme.surfaceTint,
      backgroundColor: colorScheme.surfaceContainerLow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      titleTextStyle: displayTextTheme.titleLarge?.copyWith(
        color: colorScheme.onSurface,
        fontWeight: FontWeight.w700,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 72,
      elevation: 0,
      backgroundColor: colorScheme.surfaceContainer,
      indicatorColor: colorScheme.secondaryContainer,
      indicatorShape: const StadiumBorder(),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return displayTextTheme.labelMedium?.copyWith(
          color: selected
              ? colorScheme.onSecondaryContainer
              : colorScheme.onSurfaceVariant,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          color: selected
              ? colorScheme.onSecondaryContainer
              : colorScheme.onSurfaceVariant,
          size: selected ? 27 : 24,
        );
      }),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      showDragHandle: true,
      backgroundColor: colorScheme.surfaceContainerLow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
  );
}
