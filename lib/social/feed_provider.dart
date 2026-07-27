import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'feed_models.dart';

const Duration recentlyDeletedPostRetention = Duration(days: 30);

class FeedState {
  final List<FeedPost> posts;
  final PostAudience lastUsedAudience;

  const FeedState({
    this.posts = const [],
    this.lastUsedAudience = PostAudience.public,
  });

  FeedState copyWith({List<FeedPost>? posts, PostAudience? lastUsedAudience}) {
    return FeedState(
      posts: posts ?? this.posts,
      lastUsedAudience: lastUsedAudience ?? this.lastUsedAudience,
    );
  }
}

/// PRD §12.1/§12.2 -- E7-01/E7-02's feed engine. Reactions/edits/
/// deletes/poll votes here are genuine local interactions; the full
/// reaction-picker/comment-thread/share/mention system is E7-03's
/// separate, larger scope.
class FeedNotifier extends Notifier<FeedState> {
  @override
  FeedState build() => FeedState(posts: mockFeedPosts(now: DateTime.now()));

  void toggleReaction(String postId) {
    _updatePost(
      postId,
      (post) => post.copyWith(reactionCount: post.reactionCount + 1),
    );
  }

  /// PRD §12.2: "audience is per-post sticky-default" -- remembers the
  /// last chosen audience so the composer can default to it next time.
  void addPost(FeedPost post) {
    state = state.copyWith(
      posts: [post, ...state.posts],
      lastUsedAudience: post.audience,
    );
  }

  void editPost(
    String postId,
    String newText, {
    DateTime Function() now = DateTime.now,
  }) {
    _updatePost(postId, (post) => post.withEdit(newText, now()));
  }

  void deletePost(String postId, {DateTime Function() now = DateTime.now}) {
    _updatePost(postId, (post) => post.withDeleted(now()));
  }

  void restorePost(String postId) {
    _updatePost(postId, (post) => post.withRestored());
  }

  void votePoll(String postId, int optionIndex) {
    _updatePost(postId, (post) => post.withPollVote(optionIndex));
  }

  /// Permanently prunes soft-deleted posts past the 30-day restore
  /// window -- no real cron exists, called from a debug control /
  /// screen init the same way other stories' expiry sweeps are.
  void pruneExpiredDeletions({DateTime Function() now = DateTime.now}) {
    final n = now();
    final kept = state.posts
        .where(
          (p) =>
              p.deletedAt == null ||
              n.difference(p.deletedAt!) < recentlyDeletedPostRetention,
        )
        .toList();
    if (kept.length != state.posts.length) {
      state = state.copyWith(posts: kept);
    }
  }

  void _updatePost(String postId, FeedPost Function(FeedPost) transform) {
    state = state.copyWith(
      posts: [
        for (final post in state.posts)
          if (post.id == postId) transform(post) else post,
      ],
    );
  }
}

final feedProvider = NotifierProvider<FeedNotifier, FeedState>(
  FeedNotifier.new,
);
