import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:roco_handbook/catalog_app.dart';
import 'package:roco_handbook/data/catalog/catalog_installer.dart';
import 'package:roco_handbook/data/catalog/catalog_update_source.dart';
import 'package:roco_handbook/data/catalog/remote_catalog_manifest.dart';
import 'package:roco_handbook/data/catalog/sqlite_catalog_repository.dart';
import 'package:roco_handbook/data/user/sqlite_user_repository.dart';
import 'package:roco_handbook/data/user/user_database_migrator.dart';
import 'package:roco_handbook/domain/catalog_models.dart';
import 'package:roco_handbook/domain/catalog_repository.dart';
import 'package:roco_handbook/domain/user_models.dart';
import 'package:roco_handbook/domain/user_repository.dart';
import 'package:roco_handbook/features/catalog/catalog_home_page.dart';
import 'package:roco_handbook/features/personal/my_library_page.dart';
import 'package:roco_handbook/features/personal/personal_controls.dart';
import 'package:roco_handbook/features/pets/pet_catalog_page.dart';
import 'package:roco_handbook/l10n/app_strings.dart';
import 'package:roco_handbook/widgets/catalog_asset_image.dart';

void main() {
  late SqliteCatalogRepository repository;
  late CatalogSession session;
  late Directory temporary;
  late SqliteUserRepository userRepository;

  setUp(() async {
    repository = SqliteCatalogRepository(
      File('assets/catalog/catalog.db').absolute.path,
      backgroundQueries: false,
    );
    temporary = await Directory.systemTemp.createTemp('roco-flow-test-');
    final userOpen = await UserDatabaseMigrator(
      temporary.path,
      backgroundWork: false,
    ).prepare(await File('../schemas/user_v1.sql').readAsString());
    userRepository = SqliteUserRepository(
      userOpen.databasePath,
      backgroundQueries: false,
      noteIdGenerator: () => 'note_widget',
      utcNow: () => '2026-09-09T12:00:00Z',
    );
    session = CatalogSession(
      repository: repository,
      info: await repository.getCatalogInfo(),
      attribution: 'Offline test attribution',
      installed: false,
      userRepository: userRepository,
      userDatabaseCreated: true,
      userSchemaVersion: 1,
    );
  });

  tearDown(() async {
    await userRepository.close();
    await temporary.delete(recursive: true);
    PaintingBinding.instance.imageCache
      ..clear()
      ..clearLiveImages();
  });

  testWidgets(
    'creature detail sections, skill filters, and evolution navigate',
    (tester) async {
      await _setPhoneSurface(tester);
      await tester.pumpWidget(
        MaterialApp(home: CatalogHomePage(session: session)),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const ValueKey('pet-search')), '武斗酷猫');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('pet-result-pet_000595')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('pet-result-pet_000595')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('pet-detail-pet_000595')),
        findsOneWidget,
      );
      expect(find.text('#004'), findsOneWidget);
      final nameBounds = tester.getRect(find.text('武斗酷猫'));
      final typeBounds = tester.getRect(
        find.byKey(const ValueKey('pet-detail-type-草系')),
      );
      expect(typeBounds.left, greaterThan(nameBounds.right));
      expect(typeBounds.center.dy, closeTo(nameBounds.center.dy, 8));
      expect(find.text('Lord form'), findsOneWidget);
      expect(
        find.ancestor(
          of: find.byKey(const ValueKey('pet-detail-type-草系')),
          matching: find.byType(Chip),
        ),
        findsNothing,
      );
      expect(find.text('Displayed form'), findsNothing);
      expect(
        find.byKey(const ValueKey('form-selector-pet_000595')),
        findsNothing,
      );
      final headerBounds = tester.getRect(find.byType(Card).first);
      final dotBounds = tester.getRect(
        find.byKey(const ValueKey('section-dot-basic-information')),
      );
      expect(headerBounds.right, closeTo(414, 0.1));
      expect(dotBounds.left, lessThan(headerBounds.right));
      for (final section in <String>[
        'basic-information',
        'feature',
        'base-stats',
        'skills',
        'evolution',
        'type-relationships',
        'library',
        'source',
      ]) {
        expect(find.byKey(ValueKey('section-dot-$section')), findsOneWidget);
      }
      expect(
        tester.getTopLeft(find.text('Basic information')).dy,
        lessThan(tester.getTopLeft(find.text('Feature')).dy),
      );
      expect(
        tester.getTopLeft(find.text('Feature')).dy,
        lessThan(tester.getTopLeft(find.text('Base stats')).dy),
      );
      expect(
        tester.getTopLeft(find.text('Base stats')).dy,
        lessThan(tester.getTopLeft(find.text('Skills')).dy),
      );
      expect(
        tester.getTopLeft(find.text('Skills')).dy,
        lessThan(tester.getTopLeft(find.text('Evolution')).dy),
      );

      await tester.tap(find.byKey(const ValueKey('section-dot-evolution')));
      await tester.pumpAndSettle();
      expect(
        tester
            .getSize(find.byKey(const ValueKey('section-dot-mark-evolution')))
            .width,
        12,
      );
      final baseBranch = find.byKey(
        const ValueKey('evolution-edge-pet_000007-pet_000595'),
      );
      expect(baseBranch, findsOneWidget);
      await tester.tap(baseBranch);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('pet-detail-pet_000007')),
        findsOneWidget,
      );
      expect(find.text('#004'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Feature'),
        300,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pumpAndSettle();
      final classFact = tester.getRect(
        find.byKey(const ValueKey('basic-fact-Class')),
      );
      final stageFact = tester.getRect(
        find.byKey(const ValueKey('basic-fact-Stage')),
      );
      expect(classFact.width, closeTo(stageFact.width, 0.1));
      expect(stageFact.left, greaterThan(classFact.right));
      expect(find.text('Third stage'), findsOneWidget);
      final lordEvolution = find.byKey(
        const ValueKey('basic-fact-Lord evolution'),
      );
      expect(
        find.descendant(of: lordEvolution, matching: find.text('No')),
        findsOneWidget,
      );
      expect(find.text('氧循环'), findsOneWidget);
      expect(find.text('使用草系技能后，回复10%生命。'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Skills'),
        300,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pumpAndSettle();
      expect(find.text('Pet skills'), findsOneWidget);
      expect(find.text('Bloodline effects'), findsOneWidget);
      expect(find.text('Learnable skills'), findsOneWidget);
      expect(find.text('休息回复'), findsOneWidget);
      expect(find.textContaining('Source stage'), findsNothing);
      final nativeSkillCard = find.byKey(
        const ValueKey('pet-skill-skill_000345'),
      );
      expect(nativeSkillCard, findsOneWidget);
      expect(
        find.descendant(of: nativeSkillCard, matching: find.text('Unlock：lv6')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: nativeSkillCard, matching: find.text('3')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: nativeSkillCard, matching: find.text('100')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: nativeSkillCard,
          matching: find.text('对敌方精灵造成魔法伤害。'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: nativeSkillCard,
          matching: find.byType(CatalogAssetImage),
        ),
        findsNWidgets(3),
      );
      final nativeElement = find.byKey(
        const ValueKey('pet-skill-element-skill_000345'),
      );
      expect(nativeElement, findsOneWidget);
      final nativeHeading = find.byKey(
        const ValueKey('pet-skill-heading-skill_000345'),
      );
      expect(
        find.descendant(of: nativeHeading, matching: find.text('棘突')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: nativeHeading, matching: nativeElement),
        findsOneWidget,
      );
      final nativeSkillIcon = find
          .descendant(
            of: nativeSkillCard,
            matching: find.byType(CatalogAssetImage),
          )
          .first;
      expect(
        tester.getRect(nativeSkillIcon).center.dy,
        closeTo(tester.getRect(nativeSkillCard).center.dy, 0.1),
      );
      const categoryAssets = <String, String>{
        'native': 'assets/wiki/v1/ui/sources/bloodline.png',
        'blood': 'assets/wiki/v1/ui/sources/bloodline.png',
        'stone': 'assets/wiki/v1/ui/sources/skill-stone.png',
      };
      for (final category in categoryAssets.keys) {
        final categoryButton = find.byKey(
          ValueKey('pet-skill-category-$category'),
        );
        final imageFinder = find.descendant(
          of: categoryButton,
          matching: find.byType(CatalogAssetImage),
        );
        expect(imageFinder, findsOneWidget);
        expect(
          tester.widget<CatalogAssetImage>(imageFinder).assetPath,
          categoryAssets[category],
        );
      }

      await tester.tap(find.byKey(const ValueKey('pet-skill-category-blood')));
      await tester.pumpAndSettle();
      expect(find.text('星星撞击'), findsOneWidget);
      expect(find.text('休息回复'), findsNothing);

      await tester.tap(find.byKey(const ValueKey('pet-skill-category-stone')));
      await tester.pumpAndSettle();
      expect(find.text('毒沼'), findsOneWidget);
      final skillTooltip = tester.widget<Tooltip>(
        find.byKey(const ValueKey('section-tooltip-skills')),
      );
      expect(skillTooltip.message, 'Learnable skills');
      expect(skillTooltip.triggerMode, TooltipTriggerMode.longPress);
      expect(skillTooltip.decoration, isA<ShapeDecoration>());
      expect(
        (skillTooltip.decoration! as ShapeDecoration).shape,
        isA<RoundedRectangleBorder>(),
      );

      await tester.tap(find.byKey(const ValueKey('pet-skill-filter')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('pet-skill-filter-sheet')),
        findsOneWidget,
      );
      expect(find.byType(FilterChip), findsWidgets);
      await tester.tap(find.byKey(const ValueKey('skill-type-filter-物攻')));
      await tester.tap(find.byKey(const ValueKey('skill-element-filter-毒系')));
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();
      expect(find.text('毒沼'), findsOneWidget);
      expect(find.text('瘴气喷射'), findsNothing);
    },
  );

  testWidgets('skill detail labels feature ownership separately', (
    tester,
  ) async {
    await _setPhoneSurface(tester);
    await tester.pumpWidget(
      MaterialApp(home: CatalogHomePage(session: session)),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const ValueKey('pet-search')), '魔力猫');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('pet-result-pet_000007')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('氧循环'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('氧循环'));
    await tester.pumpAndSettle();

    expect(find.text('Creatures with this feature'), findsOneWidget);
    expect(find.text('Feature relationship'), findsWidgets);
    expect(find.text('魔力猫'), findsOneWidget);
  });

  testWidgets(
    'skill handbook uses one toolbar, source filters, and detail cards',
    (tester) async {
      await _setPhoneSurface(tester);
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('zh', 'CN'),
          supportedLocales: AppStrings.supportedLocales,
          localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: CatalogHomePage(session: session),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('\u6280\u80fd').last);
      await tester.pumpAndSettle();
      expect(find.text('\u5168\u90e8'), findsNothing);
      expect(find.text('\u7279\u6027'), findsNothing);
      expect(find.text('\u53ef\u5b66\u4e60'), findsNothing);
      expect(find.text('\u6280\u80fd\u56fe\u9274'), findsOneWidget);
      expect(find.text('\u6280\u80fd\u7b5b\u9009'), findsOneWidget);
      final search = tester.widget<TextField>(
        find.byKey(const ValueKey('skill-search')),
      );
      expect(search.decoration?.labelText, isNull);
      expect(search.decoration?.hintText, '\u6280\u80fd\u67e5\u8be2');
      final handbookRect = tester.getRect(
        find.byKey(const ValueKey('skill-handbook')),
      );
      final filtersRect = tester.getRect(
        find.byKey(const ValueKey('skill-filters')),
      );
      final searchRect = tester.getRect(
        find.byKey(const ValueKey('skill-search')),
      );
      expect(handbookRect.center.dy, closeTo(filtersRect.center.dy, 0.1));
      expect(filtersRect.center.dy, closeTo(searchRect.center.dy, 0.1));
      expect(searchRect.width, greaterThan(filtersRect.width * 1.8));

      await tester.enterText(
        find.byKey(const ValueKey('skill-search')),
        '\u4e00\u62f3',
      );
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      final onePunch = find.byKey(const ValueKey('skill-result-skill_000654'));
      expect(onePunch, findsOneWidget);
      expect(
        find.descendant(of: onePunch, matching: find.text('\u7269\u653b')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: onePunch, matching: find.text('\u8017\u80fd 5')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: onePunch, matching: find.text('\u5a01\u529b 140')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: onePunch,
          matching: find.text(
            '\u5bf9\u654c\u65b9\u7cbe\u7075\u9020\u6210\u7269\u7406\u4f24\u5bb3\u3002',
          ),
        ),
        findsOneWidget,
      );
      final elementIcon = tester.widget<CatalogAssetImage>(
        find.byKey(const ValueKey('skill-result-element-skill_000654')),
      );
      expect(elementIcon.assetPath, 'assets/wiki/v1/ui/types/martial.png');
      expect(
        find.descendant(
          of: onePunch,
          matching: find.byKey(const ValueKey('favorite-skill_000654')),
        ),
        findsNothing,
      );
      await tester.tap(onePunch);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('favorite-skill_000654')),
        findsOneWidget,
      );
      Navigator.of(
        tester.element(find.byKey(const ValueKey('skill-detail-skill_000654'))),
      ).pop();
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('skill-handbook')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('skill-filters')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('skill-catalog-filter-sheet')),
        findsOneWidget,
      );
      expect(find.byType(FilterChip), findsNWidgets(42));
      await tester.tap(
        find.byKey(const ValueKey('skill-catalog-type-filter-\u7269\u653b')),
      );
      await tester.tap(
        find.byKey(const ValueKey('skill-catalog-tag-filter-\u8fde\u51fb')),
      );
      await tester.tap(
        find.byKey(
          const ValueKey('skill-catalog-element-filter-type_8a5435d3dcd0'),
        ),
      );
      await tester.tap(find.text('\u5e94\u7528'));
      await tester.pumpAndSettle();
      expect(find.text('\u8fde\u7eed\u6bd2\u9488'), findsOneWidget);
      expect(find.text('\u6280\u80fd\u7b5b\u9009 (3)'), findsOneWidget);
    },
  );

  testWidgets('supports dark theme and enlarged text without an exception', (
    tester,
  ) async {
    await _setPhoneSurface(tester);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(useMaterial3: true),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: CatalogHomePage(session: session),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Roco World Handbook'), findsOneWidget);
    expect(find.text('Creatures'), findsOneWidget);
    final first = (await repository.searchPets(const PetQuery(limit: 1)))
        .single;
    await tester.tap(find.byKey(ValueKey('pet-result-${first.petId}')));
    await tester.pumpAndSettle();
    expect(find.byKey(ValueKey('pet-detail-${first.petId}')), findsOneWidget);
    expect(tester.takeException(), isNull);
    Navigator.of(
      tester.element(find.byKey(ValueKey('pet-detail-${first.petId}'))),
    ).pop();
    await tester.pumpAndSettle();
    expect(find.text('Skills'), findsOneWidget);
    expect(find.text('My Library'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('check-catalog-update')),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.byKey(const ValueKey('check-catalog-update')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('uses source-grounded Chinese UI and bundled visual assets', (
    tester,
  ) async {
    await _setPhoneSurface(tester);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh', 'CN'),
        supportedLocales: AppStrings.supportedLocales,
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: CatalogHomePage(session: session),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('\u7cbe\u7075'), findsOneWidget);
    expect(find.text('\u6280\u80fd'), findsOneWidget);
    expect(find.text('\u6211\u7684\u6536\u85cf'), findsOneWidget);
    expect(find.byType(CatalogAssetImage), findsWidgets);

    final first = (await repository.searchHandbooks(const PetQuery(limit: 1)))
        .single;
    await tester.tap(find.byKey(ValueKey('pet-result-${first.petId}')));
    await tester.pumpAndSettle();
    expect(find.text('一阶段'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('\u79cd\u65cf\u8d44\u8d28\u603b\u548c'),
      350,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('\u79cd\u65cf\u8d44\u8d28\u603b\u548c'), findsOneWidget);
    expect(find.text('582'), findsOneWidget);
    expect(find.text('\u661f\u5149\u503c\uff1a\n80'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('section-dot-skills')));
    await tester.pumpAndSettle();
    final flashCard = find.byKey(const ValueKey('pet-skill-skill_000430'));
    expect(flashCard, findsOneWidget);
    expect(
      find.descendant(
        of: flashCard,
        matching: find.text('\u89e3\u9501\uff1alv1'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: flashCard,
        matching: find.text(
          '\u5bf9\u654c\u65b9\u7cbe\u7075\u9020\u6210\u9b54\u6cd5\u4f24\u5bb3\u3002',
        ),
      ),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(
      find.text('\u5c5e\u6027\u514b\u5236'),
      350,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('\u5c5e\u6027\u514b\u5236'), findsOneWidget);
    expect(find.text('\u53d7\u5230\u4f24\u5bb3\u589e\u52a0'), findsOneWidget);
  });

  testWidgets('creature catalog uses one control row and full illustrations', (
    tester,
  ) async {
    await _setPhoneSurface(tester);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh', 'CN'),
        supportedLocales: AppStrings.supportedLocales,
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
          body: PetCatalogPage(
            repository: repository,
            userRepository: userRepository,
            datasetId: session.info.datasetId,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('\u5168\u90e8\u5f62\u6001'), findsNothing);
    expect(find.text('\u9ed8\u8ba4\u5f62\u6001'), findsNothing);
    expect(find.text('\u8fea\u83ab'), findsOneWidget);
    expect(find.text('\u5723\u5149\u8fea\u83ab'), findsOneWidget);
    expect(find.text('\uff08\u9996\u9886\u5f62\u6001\uff09'), findsNWidgets(4));
    expect(find.byKey(const ValueKey('pet-dex-pet_000004')), findsOneWidget);
    expect(find.byKey(const ValueKey('pet-dex-pet_000560')), findsOneWidget);
    expect(find.text('NO.001'), findsNWidgets(5));
    expect(find.text('\u5149\u7cfb'), findsNothing);
    final dimoType = tester.widget<CatalogAssetImage>(
      find.byKey(const ValueKey('pet-type-pet_000004-\u5149\u7cfb')),
    );
    expect(dimoType.assetPath, 'assets/wiki/v1/ui/types/light.png');
    final namedForm = tester.widget<Text>(
      find.byKey(const ValueKey('pet-form-pet_000560')),
    );
    expect(namedForm.style?.color, isNotNull);
    expect(namedForm.style?.fontSize, lessThan(16));
    expect(namedForm.maxLines, 1);
    expect(namedForm.softWrap, isFalse);
    expect(
      tester
          .widget<FittedBox>(
            find.byKey(const ValueKey('pet-title-fit-pet_000560')),
          )
          .fit,
      BoxFit.scaleDown,
    );
    expect(
      tester.getRect(find.text('圣光迪莫')).center.dy,
      closeTo(
        tester
            .getRect(find.byKey(const ValueKey('pet-form-pet_000560')))
            .center
            .dy,
        4,
      ),
    );
    expect(find.byKey(const ValueKey('favorite-pet_000004')), findsNothing);

    final searchRect = tester.getRect(find.byKey(const ValueKey('pet-search')));
    final sortRect = tester.getRect(find.byKey(const ValueKey('pet-sort')));
    final typesRect = tester.getRect(find.byKey(const ValueKey('pet-types')));
    expect(searchRect.center.dy, closeTo(sortRect.center.dy, 0.1));
    expect(sortRect.center.dy, closeTo(typesRect.center.dy, 0.1));
    expect(searchRect.width, greaterThan(sortRect.width * 1.8));
    expect(sortRect.width, closeTo(typesRect.width, 0.1));
    expect(sortRect.left, lessThan(typesRect.left));
    expect(typesRect.left, lessThan(searchRect.left));
    final search = tester.widget<TextField>(
      find.byKey(const ValueKey('pet-search')),
    );
    expect(search.decoration?.labelText, isNull);
    expect(search.decoration?.hintText, '\u641c\u7d22\u7cbe\u7075');
    expect(search.decoration?.border, isA<OutlineInputBorder>());

    final dimoCard = find.byKey(const ValueKey('pet-result-pet_000004'));
    final dimoImage = tester.widget<CatalogAssetImage>(
      find
          .descendant(of: dimoCard, matching: find.byType(CatalogAssetImage))
          .first,
    );
    expect(
      dimoImage.assetPath,
      'assets/wiki/v1/pets/illustrations/JL_dimo.png',
    );
    expect(dimoImage.width, 100);
    expect(dimoImage.height, 100);

    await tester.tap(find.byKey(const ValueKey('pet-sort')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('pet-sort-sheet')), findsOneWidget);
    expect(find.byType(ChoiceChip), findsNWidgets(PetSort.values.length));
    await tester.tap(find.byKey(const ValueKey('pet-sort-option-name')));
    await tester.tap(find.text('\u5e94\u7528'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('pet-types')));
    await tester.pumpAndSettle();
    expect(find.byType(FilterChip), findsNWidgets(18));
  });

  testWidgets('creature form subtitles stay complete on one adaptive line', (
    tester,
  ) async {
    await _setPhoneSurface(tester);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh', 'CN'),
        supportedLocales: AppStrings.supportedLocales,
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
          body: PetCatalogPage(
            repository: repository,
            userRepository: userRepository,
            datasetId: session.info.datasetId,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('pet-search')),
      '\u677f\u677f\u58f3',
    );
    await tester.pumpAndSettle();

    final subtitleFinder = find.byKey(const ValueKey('pet-form-pet_000409'));
    expect(subtitleFinder, findsOneWidget);
    final subtitle = tester.widget<Text>(subtitleFinder);
    expect(subtitle.data, '\uff08\u8715\u76ae\u65f6\u7684\u6837\u5b50\uff09');
    expect(subtitle.maxLines, 1);
    expect(subtitle.softWrap, isFalse);
    expect(subtitle.overflow, isNull);
    expect(
      tester
          .widget<FittedBox>(
            find.byKey(const ValueKey('pet-title-fit-pet_000409')),
          )
          .fit,
      BoxFit.scaleDown,
    );
    expect(
      tester.getRect(subtitleFinder).right,
      lessThan(
        tester.getRect(find.byKey(const ValueKey('pet-dex-pet_000409'))).left,
      ),
    );
  });

  testWidgets('localizes every top-level section and Catalog information', (
    tester,
  ) async {
    await _setPhoneSurface(tester);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh', 'CN'),
        supportedLocales: AppStrings.supportedLocales,
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: CatalogHomePage(session: session),
      ),
    );
    await tester.pumpAndSettle();

    final creatureSearch = tester.widget<TextField>(
      find.byKey(const ValueKey('pet-search')),
    );
    expect(creatureSearch.decoration?.hintText, '\u641c\u7d22\u7cbe\u7075');

    await tester.tap(find.byTooltip('\u56fe\u9274\u4fe1\u606f'));
    await tester.pumpAndSettle();
    expect(find.text('\u5173\u4e8e\u56fe\u9274\u6570\u636e'), findsOneWidget);
    expect(find.text('\u6536\u5f55\u8303\u56f4'), findsOneWidget);
    expect(find.text('\u6570\u636e\u6765\u6e90'), findsOneWidget);
    Navigator.of(
      tester.element(find.text('\u5173\u4e8e\u56fe\u9274\u6570\u636e')),
    ).pop();
    await tester.pumpAndSettle();

    await tester.tap(find.text('\u6280\u80fd').last);
    await tester.pumpAndSettle();
    final skillSearch = tester.widget<TextField>(
      find.byKey(const ValueKey('skill-search')),
    );
    expect(skillSearch.decoration?.labelText, isNull);
    expect(skillSearch.decoration?.hintText, '\u6280\u80fd\u67e5\u8be2');
    expect(find.text('\u6280\u80fd\u56fe\u9274'), findsOneWidget);

    await tester.tap(find.text('\u6211\u7684\u6536\u85cf').last);
    await tester.pumpAndSettle();
    expect(find.text('\u6536\u85cf'), findsOneWidget);
    expect(find.text('\u5df2\u6536\u96c6'), findsOneWidget);

    await tester.tap(find.text('\u8bbe\u7f6e').last);
    await tester.pumpAndSettle();
    expect(find.text('\u4e3b\u9898'), findsOneWidget);
    expect(find.text('\u4e2a\u4eba\u6570\u636e'), findsOneWidget);
    expect(find.text('\u56fe\u9274\u66f4\u65b0'), findsOneWidget);
  });

  testWidgets('bootstrap reports that preparation needs no download', (
    tester,
  ) async {
    final completer = Completer<CatalogSession>();
    await tester.pumpWidget(
      CatalogBootstrapApp(bootstrap: () => completer.future),
    );

    expect(find.text('Preparing the offline Catalog...'), findsOneWidget);
    expect(find.text('No download is required.'), findsOneWidget);
    completer.complete(session);
    await tester.pumpAndSettle();
    expect(find.text('Roco World Handbook'), findsOneWidget);
  });

  testWidgets('an older search completion cannot replace a newer result', (
    tester,
  ) async {
    final stale = Completer<List<PetSummary>>();
    final fake = _StaleSearchRepository(stale);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PetCatalogPage(
            repository: fake,
            userRepository: userRepository,
            datasetId: session.info.datasetId,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const ValueKey('pet-search')), 'first');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.enterText(find.byKey(const ValueKey('pet-search')), 'second');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    expect(find.text('Second result'), findsOneWidget);

    stale.complete(<PetSummary>[_summary('stale', 'Stale result')]);
    await tester.pumpAndSettle();
    expect(find.text('Second result'), findsOneWidget);
    expect(find.text('Stale result'), findsNothing);
  });

  testWidgets('favorites a concrete creature and shows it in My Library', (
    tester,
  ) async {
    await _setPhoneSurface(tester);
    await tester.pumpWidget(
      MaterialApp(home: CatalogHomePage(session: session)),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('favorite-pet_000004')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('pet-result-pet_000004')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('favorite-pet_000004')));
    await tester.pumpAndSettle();
    expect(
      await userRepository.isFavorite(
        const ObjectRef(
          datasetId: 'roco-world-zh-cn',
          objectType: UserObjectType.pet,
          objectId: 'pet_000004',
          nameSnapshot: '迪莫',
        ),
      ),
      isTrue,
    );

    Navigator.of(
      tester.element(find.byKey(const ValueKey('pet-detail-pet_000004'))),
    ).pop();
    await tester.pumpAndSettle();
    await tester.tap(find.text('My Library'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('saved-pet:pet_000004')), findsOneWidget);
    expect(
      (await userRepository.listFavorites()).single.object.nameSnapshot,
      '迪莫',
    );
  });

  testWidgets('saves a handbook collection mark and a creature note', (
    tester,
  ) async {
    await _setPhoneSurface(tester);
    final first = (await repository.searchHandbooks(const PetQuery(limit: 1)))
        .single;
    await tester.pumpWidget(
      MaterialApp(home: CatalogHomePage(session: session)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(ValueKey('pet-result-${first.petId}')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('My library'),
      400,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('collected-control')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(ValueKey('note-editor-pet:${first.petId}')),
      'My offline creature note',
    );
    await tester.ensureVisible(find.byKey(const ValueKey('save-note')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('save-note')));
    await tester.pumpAndSettle();

    expect(
      await userRepository.isCollected(
        session.info.datasetId,
        first.handbookId,
      ),
      isTrue,
    );
    final notes = await userRepository.getNotes(
      ObjectRef(
        datasetId: session.info.datasetId,
        objectType: UserObjectType.pet,
        objectId: first.petId,
        nameSnapshot: first.name,
      ),
    );
    expect(notes.single.content, 'My offline creature note');
  });

  testWidgets('a failed note save retains the editor draft', (tester) async {
    await _setPhoneSurface(tester);
    const object = ObjectRef(
      datasetId: 'roco-world-zh-cn',
      objectType: UserObjectType.pet,
      objectId: 'pet_000007',
      nameSnapshot: 'Creature snapshot',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            children: const <Widget>[
              PersonalNotesSection(
                repository: _FailingNoteRepository(),
                object: object,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('note-editor-pet:pet_000007')),
      'Draft remains after failure',
    );
    await tester.tap(find.byKey(const ValueKey('save-note')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Draft remains after failure'), findsOneWidget);
  });

  testWidgets('missing Catalog items keep their snapshot and notes', (
    tester,
  ) async {
    await _setPhoneSurface(tester);
    const object = ObjectRef(
      datasetId: 'roco-world-zh-cn',
      objectType: UserObjectType.pet,
      objectId: 'pet_missing',
      nameSnapshot: 'Retained creature',
    );
    await userRepository.setFavorite(object, true);
    await userRepository.saveNote(
      const NoteDraft(object: object, content: 'Retained personal note'),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: MyLibraryPage(
          catalogRepository: const _MissingCatalogRepository(),
          userRepository: userRepository,
          datasetId: object.datasetId,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('saved-pet:pet_missing')));
    await tester.pumpAndSettle();
    expect(find.text('Retained creature'), findsOneWidget);
    expect(find.text('Currently unavailable in this Catalog.'), findsOneWidget);
    expect(find.text('Retained personal note'), findsOneWidget);
  });

  testWidgets('bundled Catalog recovery requires explicit confirmation', (
    tester,
  ) async {
    await _setPhoneSurface(tester);
    var restoreCalls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: CatalogHomePage(
          session: session,
          onRestoreBundledCatalog: () async {
            restoreCalls += 1;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('restore-bundled-catalog')),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.byKey(const ValueKey('restore-bundled-catalog')));
    await tester.pumpAndSettle();

    expect(find.text('Restore bundled Catalog?'), findsOneWidget);
    expect(
      find.textContaining('Favorites, collection marks, and notes are kept.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(restoreCalls, 0);

    await tester.tap(find.byKey(const ValueKey('restore-bundled-catalog')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('confirm-catalog-restore')));
    await tester.pumpAndSettle();
    expect(restoreCalls, 1);
    expect(find.text('Bundled Catalog restored.'), findsOneWidget);
  });

  testWidgets('Catalog update checks are explicit and report current state', (
    tester,
  ) async {
    await _setPhoneSurface(tester);
    var checkCalls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: CatalogHomePage(
          session: session,
          onCheckCatalogUpdate: (_) async {
            checkCalls += 1;
            return const CatalogUpdateCurrent();
          },
          onInstallCatalogUpdate: (_, _, _) async {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(checkCalls, 0);
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('check-catalog-update')),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    expect(
      find.textContaining('does not check, download, or install'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('check-catalog-update')));
    await tester.pumpAndSettle();

    expect(checkCalls, 1);
    expect(find.text('Catalog is up to date.'), findsOneWidget);
  });

  testWidgets(
    'Catalog download shows size and cancellation keeps current data',
    (tester) async {
      await _setPhoneSurface(tester);
      final candidate = _updateCandidate();
      await tester.pumpWidget(
        MaterialApp(
          home: CatalogHomePage(
            session: session,
            onCheckCatalogUpdate: (_) async =>
                CatalogUpdateAvailable(candidate),
            onInstallCatalogUpdate: (_, cancellation, onProgress) {
              final stopped = Completer<void>();
              onProgress(
                CatalogUpdateProgress(
                  phase: CatalogUpdatePhase.downloading,
                  receivedBytes: 1024 * 1024,
                  totalBytes: candidate.manifest.package.archiveBytes,
                ),
              );
              cancellation.addListener(
                () => stopped.completeError(
                  const CatalogUpdateException(
                    'cancelled',
                    'The Catalog update was cancelled.',
                  ),
                ),
              );
              return stopped.future;
            },
            onRestoreBundledCatalog: () async {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('check-catalog-update')),
        300,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.byKey(const ValueKey('check-catalog-update')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Download Catalog data 2?'), findsOneWidget);
      expect(find.textContaining('Download 5.0 MiB'), findsOneWidget);
      expect(
        find.textContaining('Favorites, collection marks, and notes are kept.'),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('confirm-catalog-download')));
      await tester.pump();
      expect(find.text('Downloading 1.0 MiB of 5.0 MiB...'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const ValueKey('restore-bundled-catalog')),
            )
            .onPressed,
        isNull,
      );

      await tester.tap(find.byKey(const ValueKey('cancel-catalog-update')));
      await tester.pumpAndSettle();
      expect(
        find.text('Catalog update cancelled. Current Catalog unchanged.'),
        findsOneWidget,
      );
      expect(find.text('Data v1'), findsOneWidget);
    },
  );

  testWidgets(
    'verification cannot be cancelled and activates the new Catalog',
    (tester) async {
      await _setPhoneSurface(tester);
      final candidate = _updateCandidate();
      final installation = Completer<void>();
      final updated = _sessionWithDataVersion(session, 2);
      await tester.pumpWidget(
        CatalogBootstrapApp(
          bootstrap: () async => session,
          checkForCatalogUpdate: (_, _) async =>
              CatalogUpdateAvailable(candidate),
          installCatalogUpdate:
              (current, selected, cancellation, onProgress) async {
                expect(current, same(session));
                expect(selected, same(candidate));
                onProgress(
                  CatalogUpdateProgress(
                    phase: CatalogUpdatePhase.verifyingAndInstalling,
                    receivedBytes: candidate.manifest.package.archiveBytes,
                    totalBytes: candidate.manifest.package.archiveBytes,
                  ),
                );
                await installation.future;
                return updated;
              },
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('check-catalog-update')),
        300,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.byKey(const ValueKey('check-catalog-update')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.byKey(const ValueKey('confirm-catalog-download')));
      await tester.pump();

      expect(find.text('Verifying and installing...'), findsOneWidget);
      expect(find.byKey(const ValueKey('cancel-catalog-update')), findsNothing);

      installation.complete();
      await tester.pumpAndSettle();
      expect(find.text('Data v2'), findsOneWidget);
      expect(find.text('Catalog data 2 installed.'), findsOneWidget);
    },
  );

  testWidgets('a failed Catalog download remains explicitly retryable', (
    tester,
  ) async {
    await _setPhoneSurface(tester);
    final candidate = _updateCandidate();
    var checkCalls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: CatalogHomePage(
          session: session,
          onCheckCatalogUpdate: (_) async {
            checkCalls += 1;
            return CatalogUpdateAvailable(candidate);
          },
          onInstallCatalogUpdate: (_, _, _) async {
            throw const CatalogUpdateException(
              'network',
              'The Catalog update request failed.',
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('check-catalog-update')),
      300,
      scrollable: find.byType(Scrollable).last,
    );

    await tester.tap(find.byKey(const ValueKey('check-catalog-update')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byKey(const ValueKey('confirm-catalog-download')));
    await tester.pumpAndSettle();
    expect(
      find.text('Catalog update failed (network). Current Catalog unchanged.'),
      findsOneWidget,
    );
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const ValueKey('check-catalog-update')),
          )
          .onPressed,
      isNotNull,
    );

    await tester.tap(find.byKey(const ValueKey('check-catalog-update')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(checkCalls, 2);
    expect(find.text('Download Catalog data 2?'), findsOneWidget);
  });

  testWidgets('settings exposes the locked App version and licenses', (
    tester,
  ) async {
    await _setPhoneSurface(tester);
    await tester.pumpWidget(
      MaterialApp(home: CatalogHomePage(session: session)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('open-source-licenses')),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();

    expect(find.text('1.1.0 (2)'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('open-source-licenses')));
    await tester.pumpAndSettle();

    expect(find.text('Licenses'), findsOneWidget);
    expect(find.text('Roco World Handbook'), findsOneWidget);
    expect(
      find.text('Independent, non-commercial, and unofficial.'),
      findsOneWidget,
    );
  });
}

Future<void> _setPhoneSurface(WidgetTester tester) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(430, 932);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
}

PetSummary _summary(String id, String name) {
  return PetSummary(
    petId: id,
    handbookId: 'handbook-$id',
    dexNo: '001',
    name: name,
    title: name,
    types: const <String>[],
    isDefaultForm: true,
  );
}

CatalogUpdateCandidate _updateCandidate() {
  final package = RemoteCatalogPackage(
    url: Uri.parse(
      'https://github.com/godwhere/roco-handbook/releases/download/'
      'catalog-data-v2/catalog-v2.zip',
    ),
    archiveBytes: 5 * 1024 * 1024,
    archiveSha256: '0' * 64,
  );
  final manifest = VerifiedRemoteCatalogManifest(
    keyId: 'widget-test-key',
    protocolVersion: 1,
    minimumProtocolVersion: 1,
    datasetId: 'roco-world-zh-cn',
    catalogSchemaVersion: 1,
    dataVersion: 2,
    releaseSequence: 2,
    minimumAppVersion: '1.0.0',
    publishedAtUtc: DateTime.utc(2026, 9, 10),
    snapshotId: 'snapshot-widget-test-v2',
    coverage: const <String, bool>{
      'pets': true,
      'skills': true,
      'evolutions': true,
      'topic_rewards': true,
      'skill_stone_topics': true,
      'description_note_definitions': true,
    },
    package: package,
    signedPayloadBytes: Uint8List(0),
  );
  return CatalogUpdateCandidate(envelopeText: '{}', manifest: manifest);
}

CatalogSession _sessionWithDataVersion(CatalogSession source, int dataVersion) {
  final info = source.info;
  return CatalogSession(
    repository: source.repository,
    info: CatalogInfo(
      datasetId: info.datasetId,
      schemaVersion: info.schemaVersion,
      dataVersion: dataVersion,
      snapshotId: 'snapshot-widget-test-v$dataVersion',
      adapterVersion: info.adapterVersion,
      builderVersion: info.builderVersion,
      builtAtUtc: info.builtAtUtc,
      coverage: info.coverage,
      earliestSourceRevisionUtc: info.earliestSourceRevisionUtc,
      latestSourceRevisionUtc: info.latestSourceRevisionUtc,
    ),
    attribution: source.attribution,
    installed: true,
    userRepository: source.userRepository,
    userDatabaseCreated: source.userDatabaseCreated,
    userSchemaVersion: source.userSchemaVersion,
    catalogOutcome: CatalogOpenOutcome.installedRemote,
  );
}

final class _StaleSearchRepository implements CatalogRepository {
  _StaleSearchRepository(this.stale);

  final Completer<List<PetSummary>> stale;

  @override
  Future<List<PetSummary>> searchHandbooks(PetQuery query) async {
    return const <PetSummary>[];
  }

  @override
  Future<List<PetSummary>> searchPets(PetQuery query) async {
    return switch (query.keyword) {
      'first' => stale.future,
      'second' => <PetSummary>[_summary('second', 'Second result')],
      _ => const <PetSummary>[],
    };
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _MissingCatalogRepository implements CatalogRepository {
  const _MissingCatalogRepository();

  @override
  Future<PetDetail> getPetDetail(String petId) {
    throw CatalogNotFoundException('Creature', petId);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _FailingNoteRepository implements UserRepository {
  const _FailingNoteRepository();

  @override
  Future<List<PersonalNote>> getNotes(ObjectRef object) async {
    return const <PersonalNote>[];
  }

  @override
  Future<String> saveNote(NoteDraft draft) {
    throw const UserDataException('forced_failure', 'Forced test failure.');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
