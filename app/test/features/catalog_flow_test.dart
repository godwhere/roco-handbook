import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
  });

  testWidgets('opens an exact special form and switches the complete detail', (
    tester,
  ) async {
    await _setPhoneSurface(tester);
    await tester.pumpWidget(
      MaterialApp(home: CatalogHomePage(session: session)),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const ValueKey('pet-search')), '武斗酷猫');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('pet-result-pet_000595')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('pet-result-pet_000595')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('pet-detail-pet_000595')), findsOneWidget);
    expect(find.text('#004'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('form-selector-pet_000595')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('魔力猫 — Default form').last);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('pet-detail-pet_000007')), findsOneWidget);
    expect(find.text('#004'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Feature'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    expect(find.text('氧循环'), findsOneWidget);
    expect(find.text('Feature relationship'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Learnable skills'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Learnable skills'), findsOneWidget);
  });

  testWidgets('skill detail labels feature ownership separately', (
    tester,
  ) async {
    await _setPhoneSurface(tester);
    await tester.pumpWidget(
      MaterialApp(home: CatalogHomePage(session: session)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Skills'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('skill-search')), '氧循环');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('skill-result-skill_000003')));
    await tester.pumpAndSettle();

    expect(find.text('Creatures with this feature'), findsOneWidget);
    expect(find.text('Feature relationship'), findsWidgets);
    expect(find.text('魔力猫'), findsOneWidget);
  });

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

    expect(find.text('Roco Handbook'), findsOneWidget);
    expect(find.text('Creatures'), findsOneWidget);
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
    expect(find.text('Roco Handbook'), findsOneWidget);
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
            favoriteKeys: const <String>{},
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

    await tester.tap(find.byKey(const ValueKey('favorite-pet_000001')));
    await tester.pumpAndSettle();
    expect(
      await userRepository.isFavorite(
        const ObjectRef(
          datasetId: 'roco-world-zh-cn',
          objectType: UserObjectType.pet,
          objectId: 'pet_000001',
          nameSnapshot: '迪莫',
        ),
      ),
      isTrue,
    );

    await tester.tap(find.text('My Library'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('saved-pet:pet_000001')), findsOneWidget);
    expect(
      (await userRepository.listFavorites()).single.object.nameSnapshot,
      '喵喵',
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
    expect(find.text('Roco Handbook'), findsOneWidget);
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
