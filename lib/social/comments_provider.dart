import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'comment_models.dart';

class CommentsState {
  final Map<String, List<FeedComment>> commentsByPostId;
  final Map<String, String> pinnedCommentIdByPostId;

  const CommentsState({
    this.commentsByPostId = const {},
    this.pinnedCommentIdByPostId = const {},
  });

  List<FeedComment> commentsFor(String postId) =>
      commentsByPostId[postId] ?? const [];

  int totalCountFor(String postId) {
    var count = 0;
    for (final c in commentsFor(postId)) {
      count += 1 + c.replies.length;
    }
    return count;
  }

  CommentsState copyWith({
    Map<String, List<FeedComment>>? commentsByPostId,
    Map<String, String>? pinnedCommentIdByPostId,
  }) {
    return CommentsState(
      commentsByPostId: commentsByPostId ?? this.commentsByPostId,
      pinnedCommentIdByPostId:
          pinnedCommentIdByPostId ?? this.pinnedCommentIdByPostId,
    );
  }
}

/// PRD §12.6 -- E7-03's comments engine. "Threaded 2 levels" -- a
/// top-level comment's replies are themselves flat (no reply-to-a-reply),
/// matching AppCommentThread/AppCommentData's own 2-level shape (E0-08).
class CommentsNotifier extends Notifier<CommentsState> {
  @override
  CommentsState build() => const CommentsState();

  void addComment(
    String postId,
    String authorName,
    String body, {
    String? replyToId,
    DateTime Function() now = DateTime.now,
  }) {
    final comment = FeedComment(
      id: 'comment-${now().microsecondsSinceEpoch}',
      authorName: authorName,
      body: body,
      timestamp: now(),
    );
    final existing = state.commentsFor(postId);
    List<FeedComment> updated;
    if (replyToId == null) {
      updated = [...existing, comment];
    } else {
      updated = [
        for (final c in existing)
          if (c.id == replyToId)
            c.copyWith(replies: [...c.replies, comment])
          else
            c,
      ];
    }
    state = state.copyWith(
      commentsByPostId: {...state.commentsByPostId, postId: updated},
    );
  }

  void toggleProps(String postId, String commentId) {
    _updateComment(
      postId,
      commentId,
      (c) => c.copyWith(
        hasMyProps: !c.hasMyProps,
        propsCount: c.hasMyProps ? c.propsCount - 1 : c.propsCount + 1,
      ),
    );
  }

  /// "Author can pin 1 comment" -- pinning a new one replaces the prior
  /// pin (the map key naturally holds only one id per post).
  void pinComment(String postId, String commentId) {
    state = state.copyWith(
      pinnedCommentIdByPostId: {
        ...state.pinnedCommentIdByPostId,
        postId: commentId,
      },
    );
  }

  void unpinComment(String postId) {
    final updated = {...state.pinnedCommentIdByPostId}..remove(postId);
    state = state.copyWith(pinnedCommentIdByPostId: updated);
  }

  /// "Delete-on-own-post rights" -- caller (post_detail_screen.dart)
  /// only shows this action when the viewer is the post's author.
  void deleteComment(String postId, String commentId) {
    final existing = state.commentsFor(postId);
    final updated = [
      for (final c in existing)
        if (c.id != commentId)
          c.copyWith(
            replies: c.replies.where((r) => r.id != commentId).toList(),
          ),
    ];
    state = state.copyWith(
      commentsByPostId: {...state.commentsByPostId, postId: updated},
    );
    if (state.pinnedCommentIdByPostId[postId] == commentId) {
      unpinComment(postId);
    }
  }

  void _updateComment(
    String postId,
    String commentId,
    FeedComment Function(FeedComment) transform,
  ) {
    final existing = state.commentsFor(postId);
    final updated = [
      for (final c in existing)
        if (c.id == commentId)
          transform(c)
        else
          c.copyWith(
            replies: [
              for (final r in c.replies)
                if (r.id == commentId) transform(r) else r,
            ],
          ),
    ];
    state = state.copyWith(
      commentsByPostId: {...state.commentsByPostId, postId: updated},
    );
  }
}

final commentsProvider = NotifierProvider<CommentsNotifier, CommentsState>(
  CommentsNotifier.new,
);
