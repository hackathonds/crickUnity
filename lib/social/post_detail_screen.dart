import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_bottom_sheet.dart';
import '../design_system/components/app_comment_widget.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../moderation/moderation_provider.dart';
import '../moderation/profanity_filter.dart';
import 'comment_models.dart';
import 'comments_provider.dart';
import 'composer_screen.dart';
import 'feed_provider.dart';
import 'feed_screen.dart';
import 'hashtag_screen.dart';

void _showReplySheet(
  BuildContext context,
  WidgetRef ref,
  String postId,
  String replyToId,
) {
  showAppBottomSheet<void>(
    context: context,
    title: 'Reply',
    contentBuilder: (context) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: AppCommentComposer(
        authorName: composerViewerName,
        onSubmit: (body) {
          ref
              .read(commentsProvider.notifier)
              .addComment(
                postId,
                composerViewerName,
                body,
                replyToId: replyToId,
              );
          Navigator.of(context).pop();
        },
      ),
    ),
  );
}

/// DS §3.13/§59 (Post Detail/Comments): reuses the pre-built
/// AppCommentThread/AppCommentComposer components (E0-08) rather than
/// new comment UI, wired to the real commentsProvider state.
class PostDetailScreen extends ConsumerWidget {
  final String postId;

  const PostDetailScreen({super.key, required this.postId});

  AppCommentData _toViewData(
    FeedComment comment,
    Map<AppCommentData, String> idByData, {
    required bool hideOffensive,
  }) {
    final data = AppCommentData(
      authorName: comment.authorName,
      timeAgo: _relativeTime(comment.timestamp),
      body: maskProfanity(comment.body, enabled: hideOffensive),
      propsCount: comment.propsCount,
      replies: [
        for (final r in comment.replies)
          _toViewData(r, idByData, hideOffensive: hideOffensive),
      ],
    );
    idByData[data] = comment.id;
    return data;
  }

  static String _relativeTime(DateTime timestamp) {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final feed = ref.watch(feedProvider);
    final comments = ref.watch(commentsProvider);
    final post = feed.postById(postId);

    if (post == null) {
      return const Scaffold(body: Center(child: Text('Post not found')));
    }

    final hideOffensive = ref.watch(moderationProvider).hideOffensiveComments;
    final isPostAuthor = post.authorName == composerViewerName;
    final threadComments = comments.commentsFor(postId);
    final pinnedId = comments.pinnedCommentIdByPostId[postId];
    final idByData = <AppCommentData, String>{};
    final commentsByAuthorship = <AppCommentData>[
      for (final c in threadComments)
        _toViewData(c, idByData, hideOffensive: hideOffensive),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Post')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                FeedPostCard(
                  post: post,
                  resharedPost: post.resharedPostId == null
                      ? null
                      : feed.postById(post.resharedPostId!),
                  commentCount: comments.totalCountFor(postId),
                  now: DateTime.now(),
                  colors: colors,
                  onReact: (reaction) => ref
                      .read(feedProvider.notifier)
                      .setReaction(postId, reaction),
                  onWhy: () {},
                  onEditHistory: () {},
                  onVote: (index) =>
                      ref.read(feedProvider.notifier).votePoll(postId, index),
                  onEdit: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ComposerScreen(editingPost: post),
                    ),
                  ),
                  onDelete: () {
                    ref.read(feedProvider.notifier).deletePost(postId);
                    Navigator.of(context).pop();
                  },
                  onShare: () {},
                  onOpenComments: () {},
                  onMentionTap: (_) {},
                  onHashtagTap: (tag) => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => HashtagScreen(hashtag: tag),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                if (pinnedId != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Text(
                      '📌 Pinned',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colors.textTertiary,
                      ),
                    ),
                  ),
                AppCommentThread(
                  comments: commentsByAuthorship,
                  onPropsTap: (data) {
                    final id = idByData[data];
                    if (id != null) {
                      ref
                          .read(commentsProvider.notifier)
                          .toggleProps(postId, id);
                    }
                  },
                  onReplyTap: (data) {
                    final id = idByData[data];
                    if (id == null) return;
                    _showReplySheet(context, ref, postId, id);
                  },
                ),
                if (isPostAuthor && threadComments.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.sm,
                    children: [
                      for (final c in threadComments)
                        ActionChip(
                          key: ValueKey('pinCommentChip_${c.id}'),
                          label: Text(
                            pinnedId == c.id ? 'Unpin' : 'Pin: ${c.body}',
                          ),
                          onPressed: () {
                            final notifier = ref.read(
                              commentsProvider.notifier,
                            );
                            if (pinnedId == c.id) {
                              notifier.unpinComment(postId);
                            } else {
                              notifier.pinComment(postId, c.id);
                            }
                          },
                        ),
                      for (final c in threadComments)
                        ActionChip(
                          key: ValueKey('deleteCommentChip_${c.id}'),
                          label: const Text('Delete comment'),
                          onPressed: () => ref
                              .read(commentsProvider.notifier)
                              .deleteComment(postId, c.id),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          AppCommentComposer(
            authorName: composerViewerName,
            onSubmit: (body) => ref
                .read(commentsProvider.notifier)
                .addComment(postId, composerViewerName, body),
          ),
        ],
      ),
    );
  }
}
