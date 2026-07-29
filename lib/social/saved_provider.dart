import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../persistence/persisted_notifier.dart';
import 'saved_models.dart';

class SavedState {
  final List<SavedCollection> collections;
  final List<SavedPost> savedPosts;

  const SavedState({
    this.collections = const [
      SavedCollection(id: defaultSavedCollectionId, name: 'All Saved'),
    ],
    this.savedPosts = const [],
  });

  bool isSaved(String postId) => savedPosts.any((s) => s.postId == postId);

  List<SavedPost> inCollection(String collectionId) =>
      savedPosts.where((s) => s.collectionId == collectionId).toList();

  SavedState copyWith({
    List<SavedCollection>? collections,
    List<SavedPost>? savedPosts,
  }) {
    return SavedState(
      collections: collections ?? this.collections,
      savedPosts: savedPosts ?? this.savedPosts,
    );
  }

  Map<String, dynamic> toJson() => {
    'collections': [for (final c in collections) c.toJson()],
    'savedPosts': [for (final s in savedPosts) s.toJson()],
  };

  factory SavedState.fromJson(Map<String, dynamic> json) {
    return SavedState(
      collections: [
        for (final c in json['collections'] as List)
          SavedCollection.fromJson(c as Map<String, dynamic>),
      ],
      savedPosts: [
        for (final s in json['savedPosts'] as List)
          SavedPost.fromJson(s as Map<String, dynamic>),
      ],
    );
  }
}

/// PRD §12.7 -- E7-08's Bookmarks engine.
class SavedNotifier extends PersistedNotifier<SavedState> {
  @override
  String get persistenceKey => 'saved_v1';

  @override
  SavedState seed() => const SavedState();

  @override
  Map<String, dynamic> toJson(SavedState value) => value.toJson();

  @override
  SavedState fromJson(Map<String, dynamic> json) => SavedState.fromJson(json);

  void createCollection(String name) {
    state = state.copyWith(
      collections: [
        ...state.collections,
        SavedCollection(
          id: 'collection-${DateTime.now().microsecondsSinceEpoch}',
          name: name,
        ),
      ],
    );
  }

  void savePost(
    String postId, {
    String collectionId = defaultSavedCollectionId,
    required String savedFromContext,
    DateTime Function() now = DateTime.now,
  }) {
    if (state.isSaved(postId)) return;
    state = state.copyWith(
      savedPosts: [
        ...state.savedPosts,
        SavedPost(
          postId: postId,
          collectionId: collectionId,
          savedFromContext: savedFromContext,
          savedAt: now(),
        ),
      ],
    );
  }

  void unsavePost(String postId) {
    state = state.copyWith(
      savedPosts: state.savedPosts.where((s) => s.postId != postId).toList(),
    );
  }

  void moveToCollection(String postId, String collectionId) {
    state = state.copyWith(
      savedPosts: [
        for (final s in state.savedPosts)
          if (s.postId == postId)
            SavedPost(
              postId: s.postId,
              collectionId: collectionId,
              savedFromContext: s.savedFromContext,
              savedAt: s.savedAt,
            )
          else
            s,
      ],
    );
  }
}

final savedProvider = NotifierProvider<SavedNotifier, SavedState>(
  SavedNotifier.new,
);
