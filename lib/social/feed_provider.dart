import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'feed_models.dart';

class FeedState {
  final List<FeedPost> posts;

  const FeedState({this.posts = const []});

  FeedState copyWith({List<FeedPost>? posts}) =>
      FeedState(posts: posts ?? this.posts);
}

/// PRD §12.1 -- E7-01's feed engine. Reactions here are a genuine local
/// tap-to-increment (the "reaction bar" DS §7-57 names on every card) --
/// full reaction-picker/comment-thread interaction is E7-03's separate,
/// larger scope.
class FeedNotifier extends Notifier<FeedState> {
  @override
  FeedState build() => FeedState(posts: mockFeedPosts(now: DateTime.now()));

  void toggleReaction(String postId) {
    state = state.copyWith(
      posts: [
        for (final post in state.posts)
          if (post.id == postId)
            post.copyWith(reactionCount: post.reactionCount + 1)
          else
            post,
      ],
    );
  }
}

final feedProvider = NotifierProvider<FeedNotifier, FeedState>(
  FeedNotifier.new,
);
