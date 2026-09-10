import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roco_handbook/theme/catalog_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('catalog theme separates display, body, and number typography', () {
    final theme = buildCatalogTheme(
      ColorScheme.fromSeed(seedColor: const Color(0xFF146FC7)),
    );

    for (final style in <TextStyle?>[
      theme.textTheme.headlineSmall,
      theme.textTheme.titleLarge,
      theme.textTheme.titleMedium,
      theme.textTheme.labelLarge,
      theme.primaryTextTheme.titleLarge,
    ]) {
      expect(style?.fontFamily, CatalogTypography.displayFamily);
    }
    expect(
      theme.textTheme.bodyLarge?.fontFamily,
      isNot(CatalogTypography.displayFamily),
    );

    final numbers = CatalogTypography.numbers(
      const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
    );
    expect(numbers.fontFamily, CatalogTypography.numberFamily);
    expect(numbers.fontSize, 18);
    expect(numbers.fontWeight, FontWeight.w700);
  });

  test(
    'both frozen Wiki fonts are packaged in the Flutter asset bundle',
    () async {
      final display = await rootBundle.load('assets/fonts/v1/roco-display.ttf');
      final numbers = await rootBundle.load('assets/fonts/v1/roco-numbers.ttf');

      expect(display.lengthInBytes, 4563796);
      expect(numbers.lengthInBytes, 4312);
    },
  );
}
