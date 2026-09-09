import 'user_models.dart';

abstract interface class UserRepository {
  Future<void> setFavorite(ObjectRef object, bool enabled);

  Future<bool> isFavorite(ObjectRef object);

  Future<void> setCollected({
    required String datasetId,
    required String handbookId,
    required String nameSnapshot,
    required bool collected,
  });

  Future<bool> isCollected(String datasetId, String handbookId);

  Future<String> saveNote(NoteDraft draft);

  Future<void> deleteNote(String noteId);

  Future<List<PersonalNote>> getNotes(ObjectRef object);

  Future<List<FavoriteItem>> listFavorites();

  Future<List<CollectionMark>> listCollectionMarks(String datasetId);

  Stream<List<FavoriteItem>> watchFavorites();

  Stream<List<CollectionMark>> watchCollectionMarks(String datasetId);

  Future<void> close();
}
