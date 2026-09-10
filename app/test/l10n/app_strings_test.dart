import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roco_handbook/l10n/app_strings.dart';

void main() {
  testWidgets('source-grounded terminology matches the frozen contract', (
    tester,
  ) async {
    final strings = await _loadChineseStrings(tester);
    final config = jsonDecode(
      File('../config/ui_terminology_zh_cn.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final terms = (config['terms'] as Map<String, dynamic>)
        .cast<String, String>();
    final sourcePages = config['source_pages'] as List<dynamic>;

    const uiKeys = <String, String>{
      'base_stats': 'Base stats',
      'category': 'Category',
      'creature': 'Creatures',
      'energy': 'Energy',
      'evolution': 'Evolution',
      'feature': 'Feature',
      'handbook': 'Handbook',
      'health': 'HP',
      'magic_attack': 'Magic attack',
      'magic_defense': 'Magic defense',
      'physical_attack': 'Attack',
      'physical_defense': 'Defense',
      'power': 'Power',
      'skill': 'Skills',
      'speed': 'Speed',
      'total_base_stats': 'Total base stats',
      'type': 'Types',
      'type_effectiveness': 'Type relationships',
      'incoming_damage_increased': 'Incoming damage increased',
      'incoming_damage_reduced': 'Incoming damage reduced',
      'strong_against': 'Strong against',
      'resisted_by': 'Resisted by',
    };

    expect(terms.keys.toSet(), <String>{...uiKeys.keys, 'creature_handbook'});
    for (final entry in uiKeys.entries) {
      expect(
        strings.text(entry.value),
        terms[entry.key],
        reason: 'UI term ${entry.value} must match ${entry.key}',
      );
    }
    expect(
      (sourcePages.first as Map<String, dynamic>)['title'],
      terms['creature_handbook'],
    );
  });

  testWidgets('every literal UI translation key has a Chinese mapping', (
    tester,
  ) async {
    final strings = await _loadChineseStrings(tester);
    final keys = <String>{};
    final literalCall = RegExp(r"\b[A-Za-z_][A-Za-z0-9_]*\.tr\(\s*'([^']+)'");

    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) {
        continue;
      }
      for (final match in literalCall.allMatches(entity.readAsStringSync())) {
        keys.add(match.group(1)!);
      }
    }

    final untranslated = keys.where((key) => strings.text(key) == key).toList()
      ..sort();
    expect(untranslated, isEmpty);
  });

  test('fixed UI copy does not bypass localization', () {
    final files = <File>[
      File('lib/catalog_app.dart'),
      ...Directory('lib/features')
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart')),
    ];
    final directCopyPatterns = <RegExp>[
      RegExp(r"(?:Text|SelectableText)\(\s*'[^'$]+'"),
      RegExp(
        r"(?:labelText|hintText|helperText|errorText|tooltip|semanticsLabel):\s*'[^']+'",
      ),
    ];
    final violations = <String>[];

    for (final file in files) {
      final source = file.readAsStringSync();
      for (final pattern in directCopyPatterns) {
        for (final match in pattern.allMatches(source)) {
          final line =
              '\n'.allMatches(source.substring(0, match.start)).length + 1;
          violations.add('${file.path}:$line');
        }
      }
    }

    expect(violations, isEmpty);
  });
}

Future<AppStrings> _loadChineseStrings(WidgetTester tester) async {
  AppStrings? strings;
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('zh', 'CN'),
      supportedLocales: AppStrings.supportedLocales,
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Builder(
        builder: (context) {
          strings = AppStrings.of(context);
          return const SizedBox.shrink();
        },
      ),
    ),
  );
  return strings!;
}
