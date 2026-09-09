import 'dart:async';
import 'dart:isolate';
import 'dart:math';

import 'package:sqlite3/sqlite3.dart';

import '../../domain/user_models.dart';
import '../../domain/user_repository.dart';

final class SqliteUserRepository implements UserRepository {
  SqliteUserRepository(
    this.databasePath, {
    this.backgroundQueries = true,
    String Function()? noteIdGenerator,
    String Function()? utcNow,
  }) : _noteIdGenerator = noteIdGenerator ?? _newNoteId,
       _utcNow = utcNow ?? _currentUtc;

  final String databasePath;
  final bool backgroundQueries;
  final String Function() _noteIdGenerator;
  final String Function() _utcNow;
  final _changes = StreamController<void>.broadcast();

  @override
  Future<void> setFavorite(ObjectRef object, bool enabled) async {
    _validateObject(object);
    final now = _utcNow();
    await _write('set favorite', (database) {
      if (enabled) {
        database.execute(
          'INSERT INTO favorites('
          'dataset_id, object_type, object_id, name_snapshot, created_at_utc'
          ') VALUES(?, ?, ?, ?, ?) '
          'ON CONFLICT(dataset_id, object_type, object_id) DO UPDATE SET '
          'name_snapshot = excluded.name_snapshot',
          <Object?>[
            object.datasetId,
            object.objectType.storageValue,
            object.objectId,
            object.nameSnapshot,
            now,
          ],
        );
      } else {
        database.execute(
          'DELETE FROM favorites WHERE dataset_id = ? '
          'AND object_type = ? AND object_id = ?',
          <Object?>[
            object.datasetId,
            object.objectType.storageValue,
            object.objectId,
          ],
        );
      }
    });
    _notify();
  }

  @override
  Future<bool> isFavorite(ObjectRef object) {
    _validateObject(object);
    return _read('read favorite', (database) {
      return database.select(
        'SELECT 1 FROM favorites WHERE dataset_id = ? '
        'AND object_type = ? AND object_id = ? LIMIT 1',
        <Object?>[
          object.datasetId,
          object.objectType.storageValue,
          object.objectId,
        ],
      ).isNotEmpty;
    });
  }

  @override
  Future<void> setCollected({
    required String datasetId,
    required String handbookId,
    required String nameSnapshot,
    required bool collected,
  }) async {
    _validateIdentity(datasetId, handbookId, nameSnapshot);
    final now = _utcNow();
    await _write('set collection mark', (database) {
      if (collected) {
        database.execute(
          'INSERT INTO collection_marks('
          'dataset_id, handbook_id, collected, name_snapshot, updated_at_utc'
          ') VALUES(?, ?, 1, ?, ?) '
          'ON CONFLICT(dataset_id, handbook_id) DO UPDATE SET '
          'collected = 1, name_snapshot = excluded.name_snapshot, '
          'updated_at_utc = excluded.updated_at_utc',
          <Object?>[datasetId, handbookId, nameSnapshot, now],
        );
      } else {
        database.execute(
          'DELETE FROM collection_marks '
          'WHERE dataset_id = ? AND handbook_id = ?',
          <Object?>[datasetId, handbookId],
        );
      }
    });
    _notify();
  }

  @override
  Future<bool> isCollected(String datasetId, String handbookId) {
    if (datasetId.isEmpty || handbookId.isEmpty) {
      throw const UserDataException(
        'collection_identity',
        'The collection mark identity is incomplete.',
      );
    }
    return _read('read collection mark', (database) {
      return database.select(
        'SELECT 1 FROM collection_marks WHERE dataset_id = ? '
        'AND handbook_id = ? AND collected = 1 LIMIT 1',
        <Object?>[datasetId, handbookId],
      ).isNotEmpty;
    });
  }

  @override
  Future<String> saveNote(NoteDraft draft) async {
    _validateObject(draft.object);
    final noteId = draft.noteId ?? _noteIdGenerator();
    if (noteId.isEmpty) {
      throw const UserDataException(
        'note_identity',
        'The note identity is incomplete.',
      );
    }
    final now = _utcNow();
    await _write('save note', (database) {
      final existing = database.select(
        'SELECT dataset_id, object_type, object_id, created_at_utc '
        'FROM notes WHERE note_id = ?',
        <Object?>[noteId],
      );
      if (existing.isEmpty) {
        database.execute(
          'INSERT INTO notes('
          'note_id, dataset_id, object_type, object_id, name_snapshot, '
          'content, created_at_utc, updated_at_utc'
          ') VALUES(?, ?, ?, ?, ?, ?, ?, ?)',
          <Object?>[
            noteId,
            draft.object.datasetId,
            draft.object.objectType.storageValue,
            draft.object.objectId,
            draft.object.nameSnapshot,
            draft.content,
            now,
            now,
          ],
        );
        return;
      }
      final row = existing.first;
      if (row['dataset_id'] != draft.object.datasetId ||
          row['object_type'] != draft.object.objectType.storageValue ||
          row['object_id'] != draft.object.objectId) {
        throw const UserDataException(
          'note_identity',
          'A note cannot be reassigned to a different object.',
        );
      }
      database.execute(
        'UPDATE notes SET name_snapshot = ?, content = ?, '
        'updated_at_utc = ? WHERE note_id = ?',
        <Object?>[draft.object.nameSnapshot, draft.content, now, noteId],
      );
    });
    _notify();
    return noteId;
  }

  @override
  Future<void> deleteNote(String noteId) async {
    if (noteId.isEmpty) {
      throw const UserDataException(
        'note_identity',
        'The note identity is incomplete.',
      );
    }
    await _write('delete note', (database) {
      database.execute('DELETE FROM notes WHERE note_id = ?', <Object?>[
        noteId,
      ]);
    });
    _notify();
  }

  @override
  Future<List<PersonalNote>> getNotes(ObjectRef object) {
    _validateObject(object);
    return _read('load notes', (database) {
      return database
          .select(
            'SELECT * FROM notes WHERE dataset_id = ? '
            'AND object_type = ? AND object_id = ? '
            'ORDER BY updated_at_utc DESC, note_id',
            <Object?>[
              object.datasetId,
              object.objectType.storageValue,
              object.objectId,
            ],
          )
          .map(_noteFromRow)
          .toList();
    });
  }

  @override
  Future<List<FavoriteItem>> listFavorites() {
    return _read('load favorites', (database) {
      return database
          .select(
            'SELECT * FROM favorites '
            'ORDER BY created_at_utc DESC, object_type, object_id',
          )
          .map(
            (row) => FavoriteItem(
              object: _objectFromRow(row),
              createdAtUtc: row['created_at_utc'] as String,
            ),
          )
          .toList();
    });
  }

  @override
  Future<List<CollectionMark>> listCollectionMarks(String datasetId) {
    if (datasetId.isEmpty) {
      throw const UserDataException(
        'dataset_identity',
        'The dataset identity is incomplete.',
      );
    }
    return _read('load collection marks', (database) {
      return database
          .select(
            'SELECT * FROM collection_marks '
            'WHERE dataset_id = ? AND collected = 1 '
            'ORDER BY updated_at_utc DESC, handbook_id',
            <Object?>[datasetId],
          )
          .map(
            (row) => CollectionMark(
              datasetId: row['dataset_id'] as String,
              handbookId: row['handbook_id'] as String,
              nameSnapshot: row['name_snapshot'] as String,
              updatedAtUtc: row['updated_at_utc'] as String,
            ),
          )
          .toList();
    });
  }

  @override
  Stream<List<FavoriteItem>> watchFavorites() {
    return _watch(listFavorites);
  }

  @override
  Stream<List<CollectionMark>> watchCollectionMarks(String datasetId) {
    return _watch(() => listCollectionMarks(datasetId));
  }

  @override
  Future<void> close() => _changes.close();

  Future<T> _read<T>(
    String operation,
    T Function(Database database) action,
  ) async {
    try {
      final path = databasePath;
      T execute() {
        final database = sqlite3.open(path, mode: OpenMode.readOnly);
        try {
          database.execute('PRAGMA query_only = ON');
          return action(database);
        } finally {
          database.close();
        }
      }

      return backgroundQueries ? await Isolate.run(execute) : execute();
    } on UserDataException {
      rethrow;
    } on Object catch (error) {
      throw UserDataException(
        'user_read',
        'The personal data operation failed during $operation.',
        error,
      );
    }
  }

  Future<T> _write<T>(
    String operation,
    T Function(Database database) action,
  ) async {
    try {
      final path = databasePath;
      T execute() {
        final database = sqlite3.open(path, mode: OpenMode.readWrite);
        try {
          database.execute('BEGIN IMMEDIATE');
          try {
            final result = action(database);
            database.execute('COMMIT');
            return result;
          } on Object {
            database.execute('ROLLBACK');
            rethrow;
          }
        } finally {
          database.close();
        }
      }

      return backgroundQueries ? await Isolate.run(execute) : execute();
    } on UserDataException {
      rethrow;
    } on Object catch (error) {
      throw UserDataException(
        'user_write',
        'The personal data operation failed during $operation.',
        error,
      );
    }
  }

  void _notify() {
    if (!_changes.isClosed) {
      _changes.add(null);
    }
  }

  Stream<List<T>> _watch<T>(Future<List<T>> Function() load) {
    return Stream<List<T>>.multi((controller) {
      var active = true;
      Future<void> emit() async {
        try {
          final values = await load();
          if (active) {
            controller.add(values);
          }
        } on Object catch (error, stackTrace) {
          if (active) {
            controller.addError(error, stackTrace);
          }
        }
      }

      final subscription = _changes.stream.listen((_) => emit());
      controller.onCancel = () {
        active = false;
        return subscription.cancel();
      };
      emit();
    });
  }
}

ObjectRef _objectFromRow(Row row) {
  return ObjectRef(
    datasetId: row['dataset_id'] as String,
    objectType: UserObjectTypeStorage.parse(row['object_type'] as String),
    objectId: row['object_id'] as String,
    nameSnapshot: row['name_snapshot'] as String,
  );
}

PersonalNote _noteFromRow(Row row) {
  return PersonalNote(
    noteId: row['note_id'] as String,
    object: _objectFromRow(row),
    content: row['content'] as String,
    createdAtUtc: row['created_at_utc'] as String,
    updatedAtUtc: row['updated_at_utc'] as String,
  );
}

void _validateObject(ObjectRef object) {
  _validateIdentity(object.datasetId, object.objectId, object.nameSnapshot);
}

void _validateIdentity(String datasetId, String objectId, String nameSnapshot) {
  if (datasetId.isEmpty || objectId.isEmpty || nameSnapshot.isEmpty) {
    throw const UserDataException(
      'object_identity',
      'The saved object identity is incomplete.',
    );
  }
}

String _currentUtc() => DateTime.now().toUtc().toIso8601String();

String _newNoteId() {
  final random = Random.secure();
  final first = random.nextInt(0x7fffffff).toRadixString(16).padLeft(8, '0');
  final second = random.nextInt(0x7fffffff).toRadixString(16).padLeft(8, '0');
  return 'note_${DateTime.now().microsecondsSinceEpoch}_$first$second';
}
