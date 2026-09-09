import 'dart:io';
import 'dart:isolate';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as paths;
import 'package:sqlite3/sqlite3.dart';

import '../../domain/user_models.dart';

abstract interface class UserSchemaSource {
  Future<String> loadVersionOne();
}

final class AssetUserSchemaSource implements UserSchemaSource {
  const AssetUserSchemaSource();

  @override
  Future<String> loadVersionOne() {
    return rootBundle.loadString('assets/database/user_v1.sql');
  }
}

final class UserDatabaseOpenResult {
  const UserDatabaseOpenResult({
    required this.databasePath,
    required this.schemaVersion,
    required this.created,
  });

  final String databasePath;
  final int schemaVersion;
  final bool created;
}

final class UserDatabaseMigrator {
  const UserDatabaseMigrator(
    this.applicationSupportPath, {
    this.backgroundWork = true,
  });

  static const currentSchemaVersion = 1;

  final String applicationSupportPath;
  final bool backgroundWork;

  Future<UserDatabaseOpenResult> prepare(String versionOneSchema) async {
    final createdAtUtc = DateTime.now().toUtc().toIso8601String();
    UserDatabaseOpenResult execute() => _prepareUserDatabase(
      applicationSupportPath,
      versionOneSchema,
      createdAtUtc,
    );

    return backgroundWork ? Isolate.run(execute) : execute();
  }

  static void validate(String databasePath) {
    Database? database;
    try {
      database = sqlite3.open(databasePath, mode: OpenMode.readWrite);
      _validateDatabase(database);
    } on UserDataException {
      rethrow;
    } on Object catch (error) {
      throw UserDataException(
        'user_database_validation',
        'The personal database could not be validated.',
        error,
      );
    } finally {
      database?.close();
    }
  }
}

UserDatabaseOpenResult _prepareUserDatabase(
  String applicationSupportPath,
  String versionOneSchema,
  String createdAtUtc,
) {
  final directory = Directory(paths.join(applicationSupportPath, 'user'));
  final target = File(paths.join(directory.path, 'user.db'));
  try {
    directory.createSync(recursive: true);
    if (target.existsSync()) {
      UserDatabaseMigrator.validate(target.path);
      return UserDatabaseOpenResult(
        databasePath: target.path,
        schemaVersion: UserDatabaseMigrator.currentSchemaVersion,
        created: false,
      );
    }

    final staging = File(
      paths.join(
        directory.path,
        '.user-v1-$pid-${DateTime.now().microsecondsSinceEpoch}.staging',
      ),
    );
    var ownsStaging = false;
    try {
      ownsStaging = true;
      final database = sqlite3.open(
        staging.path,
        mode: OpenMode.readWriteCreate,
      );
      try {
        database.execute(versionOneSchema);
        database.execute(
          'INSERT INTO user_meta(singleton, schema_version, created_at_utc) '
          'VALUES(1, ?, ?)',
          <Object?>[UserDatabaseMigrator.currentSchemaVersion, createdAtUtc],
        );
      } finally {
        database.close();
      }
      UserDatabaseMigrator.validate(staging.path);
      staging.renameSync(target.path);
      ownsStaging = false;
      UserDatabaseMigrator.validate(target.path);
      return UserDatabaseOpenResult(
        databasePath: target.path,
        schemaVersion: UserDatabaseMigrator.currentSchemaVersion,
        created: true,
      );
    } finally {
      if (ownsStaging && staging.existsSync()) {
        staging.deleteSync();
      }
    }
  } on UserDataException {
    rethrow;
  } on FileSystemException catch (error) {
    throw UserDataException(
      'user_database_file',
      'The personal database file could not be prepared.',
      error,
    );
  } on Object catch (error) {
    throw UserDataException(
      'user_database_create',
      'The personal database could not be created.',
      error,
    );
  }
}

void _validateDatabase(Database database) {
  final version = database.userVersion;
  if (version != UserDatabaseMigrator.currentSchemaVersion) {
    throw UserDataException(
      'user_schema_version',
      'Personal database schema $version is not supported by this App.',
    );
  }
  final tables = database
      .select(
        "SELECT name FROM sqlite_master WHERE type = 'table' "
        "AND name NOT LIKE 'sqlite_%'",
      )
      .map((row) => row['name'] as String)
      .toSet();
  const requiredTables = <String>{
    'user_meta',
    'favorites',
    'collection_marks',
    'notes',
    'settings',
  };
  final indexes = database
      .select(
        "SELECT name FROM sqlite_master WHERE type = 'index' "
        "AND name NOT LIKE 'sqlite_%'",
      )
      .map((row) => row['name'] as String)
      .toSet();
  if (!tables.containsAll(requiredTables) ||
      !indexes.containsAll(<String>{
        'idx_favorites_created',
        'idx_notes_object',
      })) {
    throw const UserDataException(
      'user_database_contract',
      'The personal database is missing required objects.',
    );
  }
  final meta = database.select(
    'SELECT schema_version FROM user_meta WHERE singleton = 1',
  );
  if (meta.length != 1 ||
      meta.first['schema_version'] !=
          UserDatabaseMigrator.currentSchemaVersion) {
    throw const UserDataException(
      'user_database_metadata',
      'The personal database metadata is invalid.',
    );
  }
  for (final table in requiredTables) {
    if (database.select('PRAGMA foreign_key_list($table)').isNotEmpty) {
      throw const UserDataException(
        'user_database_foreign_key',
        'The personal database must not reference another database.',
      );
    }
  }
  final integrity = database.select('PRAGMA integrity_check');
  if (integrity.length != 1 || integrity.first.values.first != 'ok') {
    throw const UserDataException(
      'user_database_integrity',
      'The personal database did not pass its integrity check.',
    );
  }
}
