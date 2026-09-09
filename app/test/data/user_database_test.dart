import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:roco_handbook/data/user/sqlite_user_repository.dart';
import 'package:roco_handbook/data/user/user_database_migrator.dart';
import 'package:roco_handbook/domain/user_models.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  late Directory temporary;
  late String schema;

  setUp(() async {
    temporary = await Directory.systemTemp.createTemp('roco-user-test-');
    schema = await File('../schemas/user_v1.sql').readAsString();
  });

  tearDown(() async {
    if (temporary.existsSync()) {
      await temporary.delete(recursive: true);
    }
  });

  test('creates and reuses the normative personal database', () async {
    final migrator = UserDatabaseMigrator(
      temporary.path,
      backgroundWork: false,
    );
    final created = await migrator.prepare(schema);
    final before = FileStat.statSync(created.databasePath);
    final reopened = await migrator.prepare(schema);
    final after = FileStat.statSync(created.databasePath);

    expect(created.created, isTrue);
    expect(reopened.created, isFalse);
    expect(created.schemaVersion, 1);
    expect(after.modified, before.modified);
    final database = sqlite3.open(created.databasePath);
    addTearDown(database.close);
    expect(database.userVersion, 1);
    expect(
      database.select('SELECT schema_version FROM user_meta').single.values,
      contains(1),
    );
    expect(
      database.select('PRAGMA integrity_check').single.values,
      contains('ok'),
    );
  });

  test(
    'rejects an unknown version without deleting or rebuilding it',
    () async {
      final migrator = UserDatabaseMigrator(
        temporary.path,
        backgroundWork: false,
      );
      final created = await migrator.prepare(schema);
      final database = sqlite3.open(created.databasePath);
      database.userVersion = 2;
      database.close();
      final before = File(created.databasePath).readAsBytesSync();

      await expectLater(
        migrator.prepare(schema),
        throwsA(
          isA<UserDataException>().having(
            (error) => error.code,
            'code',
            'user_schema_version',
          ),
        ),
      );

      expect(File(created.databasePath).readAsBytesSync(), before);
    },
  );

  test('failed first creation removes only its staging file', () async {
    final migrator = UserDatabaseMigrator(
      temporary.path,
      backgroundWork: false,
    );

    await expectLater(
      migrator.prepare('CREATE TABLE broken('),
      throwsA(isA<UserDataException>()),
    );

    final userDirectory = Directory('${temporary.path}/user');
    expect(File('${userDirectory.path}/user.db').existsSync(), isFalse);
    expect(userDirectory.listSync(), isEmpty);
  });

  test('favorites and collection marks are explicit and idempotent', () async {
    final repository = await _repository(temporary, schema);
    addTearDown(repository.close);
    const object = ObjectRef(
      datasetId: 'roco-world-zh-cn',
      objectType: UserObjectType.pet,
      objectId: 'pet_000007',
      nameSnapshot: 'Canonical creature',
    );

    await repository.setFavorite(object, true);
    await repository.setFavorite(object, true);
    expect(await repository.isFavorite(object), isTrue);
    expect(await repository.listFavorites(), hasLength(1));

    await repository.setCollected(
      datasetId: object.datasetId,
      handbookId: 'handbook_000004',
      nameSnapshot: object.nameSnapshot,
      collected: true,
    );
    await repository.setCollected(
      datasetId: object.datasetId,
      handbookId: 'handbook_000004',
      nameSnapshot: object.nameSnapshot,
      collected: true,
    );
    expect(
      await repository.listCollectionMarks(object.datasetId),
      hasLength(1),
    );

    await repository.setFavorite(object, false);
    await repository.setFavorite(object, false);
    await repository.setCollected(
      datasetId: object.datasetId,
      handbookId: 'handbook_000004',
      nameSnapshot: object.nameSnapshot,
      collected: false,
    );
    expect(await repository.isFavorite(object), isFalse);
    expect(
      await repository.isCollected(object.datasetId, 'handbook_000004'),
      isFalse,
    );
  });

  test('notes preserve content and cannot be reassigned', () async {
    final repository = await _repository(temporary, schema);
    addTearDown(repository.close);
    const creature = ObjectRef(
      datasetId: 'roco-world-zh-cn',
      objectType: UserObjectType.pet,
      objectId: 'pet_missing',
      nameSnapshot: 'Saved creature name',
    );
    const skill = ObjectRef(
      datasetId: 'roco-world-zh-cn',
      objectType: UserObjectType.skill,
      objectId: 'skill_missing',
      nameSnapshot: 'Saved skill name',
    );

    final noteId = await repository.saveNote(
      const NoteDraft(object: creature, content: 'Offline draft'),
    );
    await repository.saveNote(
      NoteDraft(noteId: noteId, object: creature, content: 'Edited offline'),
    );
    final notes = await repository.getNotes(creature);
    expect(notes, hasLength(1));
    expect(notes.single.content, 'Edited offline');
    expect(notes.single.object.nameSnapshot, creature.nameSnapshot);

    await expectLater(
      repository.saveNote(
        NoteDraft(noteId: noteId, object: skill, content: 'Wrong object'),
      ),
      throwsA(
        isA<UserDataException>().having(
          (error) => error.code,
          'code',
          'note_identity',
        ),
      ),
    );
    expect(
      (await repository.getNotes(creature)).single.content,
      'Edited offline',
    );

    await repository.deleteNote(noteId);
    expect(await repository.getNotes(creature), isEmpty);
  });

  test('missing Catalog objects remain valid personal records', () async {
    final repository = await _repository(temporary, schema);
    addTearDown(repository.close);
    const missing = ObjectRef(
      datasetId: 'roco-world-zh-cn',
      objectType: UserObjectType.pet,
      objectId: 'pet_retired_or_missing',
      nameSnapshot: 'Retained snapshot',
    );

    await repository.setFavorite(missing, true);
    await repository.saveNote(
      const NoteDraft(object: missing, content: 'Keep this note'),
    );

    expect(
      (await repository.listFavorites()).single.object.nameSnapshot,
      'Retained snapshot',
    );
    expect(
      (await repository.getNotes(missing)).single.content,
      'Keep this note',
    );
  });

  test('personal data remains after the repository is reopened', () async {
    final open = await UserDatabaseMigrator(
      temporary.path,
      backgroundWork: false,
    ).prepare(schema);
    const object = ObjectRef(
      datasetId: 'roco-world-zh-cn',
      objectType: UserObjectType.skill,
      objectId: 'skill_000003',
      nameSnapshot: 'Saved skill',
    );
    final first = SqliteUserRepository(
      open.databasePath,
      backgroundQueries: false,
      noteIdGenerator: () => 'note_restart',
      utcNow: () => '2026-09-09T12:00:00Z',
    );
    await first.setFavorite(object, true);
    await first.saveNote(
      const NoteDraft(object: object, content: 'Persistent note'),
    );
    await first.close();

    final second = SqliteUserRepository(
      open.databasePath,
      backgroundQueries: false,
    );
    addTearDown(second.close);
    expect(await second.isFavorite(object), isTrue);
    expect((await second.getNotes(object)).single.content, 'Persistent note');
  });

  test('production reads and writes run through background isolates', () async {
    final open = await UserDatabaseMigrator(
      temporary.path,
      backgroundWork: false,
    ).prepare(schema);
    final repository = SqliteUserRepository(open.databasePath);
    const object = ObjectRef(
      datasetId: 'roco-world-zh-cn',
      objectType: UserObjectType.pet,
      objectId: 'pet_000007',
      nameSnapshot: 'Background creature',
    );

    final emissions = <List<FavoriteItem>>[];
    final subscription = repository.watchFavorites().listen(emissions.add);
    addTearDown(() async {
      await subscription.cancel();
      await repository.close();
    });
    await _waitFor(() => emissions.isNotEmpty);

    await repository.setFavorite(object, true);
    await _waitFor(() => emissions.any((items) => items.length == 1));

    expect(await repository.isFavorite(object), isTrue);
  });

  test('favorite watchers publish committed changes only', () async {
    final repository = await _repository(temporary, schema);
    const object = ObjectRef(
      datasetId: 'roco-world-zh-cn',
      objectType: UserObjectType.skill,
      objectId: 'skill_000003',
      nameSnapshot: 'Canonical skill',
    );
    final emissions = <List<FavoriteItem>>[];
    final subscription = repository.watchFavorites().listen(emissions.add);
    addTearDown(() async {
      await subscription.cancel();
      await repository.close();
    });
    await _waitFor(() => emissions.isNotEmpty);

    await repository.setFavorite(object, true);
    await _waitFor(() => emissions.any((items) => items.length == 1));

    expect(emissions.first, isEmpty);
    expect(emissions.last.single.object.objectId, object.objectId);
  });
}

Future<SqliteUserRepository> _repository(
  Directory temporary,
  String schema,
) async {
  final result = await UserDatabaseMigrator(
    temporary.path,
    backgroundWork: false,
  ).prepare(schema);
  var clock = 0;
  return SqliteUserRepository(
    result.databasePath,
    backgroundQueries: false,
    noteIdGenerator: () => 'note_test',
    utcNow: () => '2026-09-09T12:00:0${clock++}Z',
  );
}

Future<void> _waitFor(bool Function() condition) async {
  for (var attempt = 0; attempt < 50; attempt += 1) {
    if (condition()) {
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  fail('Timed out while waiting for a stream emission.');
}
