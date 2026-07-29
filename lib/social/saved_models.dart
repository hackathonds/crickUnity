/// PRD §12.7: "Save any post to private collections (folders); saved
/// tab in profile (self-only); 'saved from' context retained."
class SavedCollection {
  final String id;
  final String name;

  const SavedCollection({required this.id, required this.name});

  Map<String, dynamic> toJson() => {'id': id, 'name': name};

  factory SavedCollection.fromJson(Map<String, dynamic> json) {
    return SavedCollection(
      id: json['id'] as String,
      name: json['name'] as String,
    );
  }
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

  Map<String, dynamic> toJson() => {
    'postId': postId,
    'collectionId': collectionId,
    'savedFromContext': savedFromContext,
    'savedAt': savedAt.toIso8601String(),
  };

  factory SavedPost.fromJson(Map<String, dynamic> json) {
    return SavedPost(
      postId: json['postId'] as String,
      collectionId: json['collectionId'] as String,
      savedFromContext: json['savedFromContext'] as String,
      savedAt: DateTime.parse(json['savedAt'] as String),
    );
  }
}

const String defaultSavedCollectionId = 'collection-all';
