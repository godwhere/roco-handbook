enum UserObjectType { pet, skill, handbook }

extension UserObjectTypeStorage on UserObjectType {
  String get storageValue => switch (this) {
    UserObjectType.pet => 'pet',
    UserObjectType.skill => 'skill',
    UserObjectType.handbook => 'handbook',
  };

  String get label => switch (this) {
    UserObjectType.pet => 'Creature',
    UserObjectType.skill => 'Skill',
    UserObjectType.handbook => 'Handbook entry',
  };

  static UserObjectType parse(String value) {
    return switch (value) {
      'pet' => UserObjectType.pet,
      'skill' => UserObjectType.skill,
      'handbook' => UserObjectType.handbook,
      _ => throw UserDataException(
        'object_type',
        'The saved object type is not supported.',
      ),
    };
  }
}

final class ObjectRef {
  const ObjectRef({
    required this.datasetId,
    required this.objectType,
    required this.objectId,
    required this.nameSnapshot,
  });

  final String datasetId;
  final UserObjectType objectType;
  final String objectId;
  final String nameSnapshot;

  String get key => '${objectType.storageValue}:$objectId';
}

final class FavoriteItem {
  const FavoriteItem({required this.object, required this.createdAtUtc});

  final ObjectRef object;
  final String createdAtUtc;
}

final class CollectionMark {
  const CollectionMark({
    required this.datasetId,
    required this.handbookId,
    required this.nameSnapshot,
    required this.updatedAtUtc,
  });

  final String datasetId;
  final String handbookId;
  final String nameSnapshot;
  final String updatedAtUtc;
}

final class PersonalNote {
  const PersonalNote({
    required this.noteId,
    required this.object,
    required this.content,
    required this.createdAtUtc,
    required this.updatedAtUtc,
  });

  final String noteId;
  final ObjectRef object;
  final String content;
  final String createdAtUtc;
  final String updatedAtUtc;
}

final class NoteDraft {
  const NoteDraft({required this.object, required this.content, this.noteId});

  final String? noteId;
  final ObjectRef object;
  final String content;
}

final class UserDataException implements Exception {
  const UserDataException(this.code, this.message, [this.cause]);

  final String code;
  final String message;
  final Object? cause;

  @override
  String toString() => '$code: $message';
}
