import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_state_scaffolds.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'comments_provider.dart';
import 'composer_screen.dart';
import 'feed_provider.dart';
import 'feed_screen.dart';
import 'hashtag_screen.dart';
import 'post_detail_screen.dart';
import 'saved_models.dart';
import 'saved_provider.dart';

/// PRD §12.7: "Saved tab in profile (self-only); 'saved from' context
/// retained." Reuses FeedPostCard (feed_screen.dart) to render saved
/// posts rather than a second card widget.
class SavedScreen extends ConsumerWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final saved = ref.watch(savedProvider);
    final feed = ref.watch(feedProvider);
    final comments = ref.watch(commentsProvider);
    final feedNotifier = ref.read(feedProvider.notifier);
    final now = DateTime.now();

    final entries = saved.inCollection(defaultSavedCollectionId);

    return Scaffold(
      appBar: AppBar(title: const Text('Saved')),
      body: entries.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: AppEmptyState(
                message:
                    'Nothing saved yet -- tap the bookmark icon on '
                    'any post to save it here.',
                primaryLabel: 'Back',
                onPrimary: () => Navigator.of(context).pop(),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                for (final entry in entries)
                  if (feed.postById(entry.postId) case final post?) ...[
                    Text(
                      'Saved from ${entry.savedFromContext}',
                      style: AppTypography.caption.copyWith(
                        color: colors.textTertiary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    FeedPostCard(
                      key: ValueKey('savedPostCard_${post.id}'),
                      post: post,
                      resharedPost: post.resharedPostId == null
                          ? null
                          : feed.postById(post.resharedPostId!),
                      commentCount: comments.totalCountFor(post.id),
                      now: now,
                      colors: colors,
                      onReact: (reaction) =>
                          feedNotifier.setReaction(post.id, reaction),
                      onWhy: () {},
                      onEditHistory: () {},
                      onVote: (index) => feedNotifier.votePoll(post.id, index),
                      onEdit: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ComposerScreen(editingPost: post),
                        ),
                      ),
                      onDelete: () => feedNotifier.deletePost(post.id),
                      onShare: () {},
                      onOpenComments: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => PostDetailScreen(postId: post.id),
                        ),
                      ),
                      onMentionTap: (_) {},
                      onHashtagTap: (tag) => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => HashtagScreen(hashtag: tag),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
              ],
            ),
    );
  }
}
