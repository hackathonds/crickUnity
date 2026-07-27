import 'package:flutter_riverpod/flutter_riverpod.dart';

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
}

/// PRD §12.7 -- E7-08's Bookmarks engine.
class SavedNotifier extends Notifier<SavedState> {
  @override
  SavedState build() => const SavedState();

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
