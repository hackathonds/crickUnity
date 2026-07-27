/// PRD §12.7: "Save any post to private collections (folders); saved
/// tab in profile (self-only); 'saved from' context retained."
class SavedCollection {
  final String id;
  final String name;

  const SavedCollection({required this.id, required this.name});
}

class SavedPost {
  final String postId;
  final String collectionId;
  final String savedFromContext;
  final DateTime savedAt;

  const SavedPost({
    required this.postId,
    required this.collectionId,
    required this.savedFromContext,
    required this.savedAt,
  });
}

const String defaultSavedCollectionId = 'collection-all';
