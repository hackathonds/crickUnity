import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_arc_ring.dart';
import '../design_system/components/app_avatar.dart';
import '../design_system/components/app_bottom_sheet.dart';
import '../design_system/components/app_reaction_picker.dart';
import '../design_system/components/app_segmented_control.dart';
import '../design_system/components/app_tag_chip.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'comments_provider.dart';
import 'composer_screen.dart';
import 'feed_models.dart';
import 'feed_provider.dart';
import 'hashtag_screen.dart';
import 'post_detail_screen.dart';
import 'recently_deleted_posts_screen.dart';
import 'reels_screen.dart';
import 'rich_text_content.dart';
import 'stories_bar.dart';

enum _FeedMode { forYou, latest }

const Map<_FeedMode, String> _feedModeLabels = {
  _FeedMode.forYou: 'For You',
  _FeedMode.latest: 'Latest',
};

const Map<AttachedObjectType, IconData> _attachedObjectIcons = {
  AttachedObjectType.match: Icons.sports_cricket,
  AttachedObjectType.performance: Icons.bar_chart,
  AttachedObjectType.ground: Icons.stadium,
  AttachedObjectType.tournament: Icons.emoji_events,
  AttachedObjectType.achievement: Icons.military_tech,
};

String _relativeTime(DateTime timestamp, DateTime now) {
  final diff = now.difference(timestamp);
  if (diff.inMinutes < 60) return '${diff.inMinutes}m';
  if (diff.inHours < 24) return '${diff.inHours}h';
  return '${diff.inDays}d';
}

void _showMentionMock(BuildContext context, String name) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text("Would open @$name's profile (not wired)")),
  );
}

void _openHashtag(BuildContext context, String tag) {
  Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => HashtagScreen(hashtag: tag)));
}

void _showShareSheet(BuildContext context, WidgetRef ref, FeedPost post) {
  showAppBottomSheet<void>(
    context: context,
    title: 'Share',
    contentBuilder: (context) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            key: const ValueKey('shareResharePostOption'),
            leading: const Icon(Icons.repeat),
            title: const Text('Reshare to feed'),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ComposerScreen(resharePost: post),
                ),
              );
            },
          ),
          ListTile(
            key: const ValueKey('shareToStoryOption'),
            leading: const Icon(Icons.auto_stories_outlined),
            title: const Text('Share to story'),
            onTap: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Added to your story')),
              );
            },
          ),
          ListTile(
            key: const ValueKey('shareToMessageOption'),
            leading: const Icon(Icons.send_outlined),
            title: const Text('Share via message'),
            onTap: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Sent via message')));
            },
          ),
          ListTile(
            key: const ValueKey('copyExternalLinkOption'),
            leading: const Icon(Icons.link),
            title: const Text('Copy external link'),
            onTap: () {
              Clipboard.setData(
                ClipboardData(text: 'https://cricunity.app/post/${post.id}'),
              );
              Navigator.of(context).pop();
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Link copied')));
            },
          ),
        ],
      );
    },
  );
}

void _showWhyAmISeeingThis(BuildContext context, FeedPost post) {
  final now = DateTime.now();
  showAppBottomSheet<void>(
    context: context,
    title: 'Why am I seeing this?',
    contentBuilder: (context) {
      final colors = Theme.of(context).extension<AppColors>()!;
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
        child: Text(
          whyAmISeeingThis(post, now),
          style: AppTypography.body.copyWith(color: colors.textSecondary),
        ),
      );
    },
  );
}

const Map<AppReactionType, String> _reactionLabels = {
  AppReactionType.clap: '👏 Props',
  AppReactionType.heart: '❤️ Heart',
  AppReactionType.fire: '🔥 Fire',
  AppReactionType.laugh: '😂 Laugh',
  AppReactionType.wow: '😮 Wow',
  AppReactionType.sad: '😢 Sad',
};

void _showReactionBreakdown(BuildContext context, FeedPost post) {
  showAppBottomSheet<void>(
    context: context,
    title: 'Reactions',
    contentBuilder: (context) {
      final colors = Theme.of(context).extension<AppColors>()!;
      if (post.reactions.isEmpty) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.lg),
          child: Text(
            'No reactions yet.',
            style: AppTypography.body.copyWith(color: colors.textSecondary),
          ),
        );
      }
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final entry in post.reactions.entries)
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.xs / 2,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _reactionLabels[entry.key]!,
                        style: AppTypography.body.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      '${entry.value}',
                      style: AppTypography.stat.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
    },
  );
}

void _showEditHistory(BuildContext context, FeedPost post) {
  showAppBottomSheet<void>(
    context: context,
    title: 'Edit history',
    contentBuilder: (context) {
      final colors = Theme.of(context).extension<AppColors>()!;
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final version in post.editHistory)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Text(
                  version,
                  style: AppTypography.caption.copyWith(
                    color: colors.textTertiary,
                  ),
                ),
              ),
            Text(
              post.contentText,
              style: AppTypography.body.copyWith(color: colors.textPrimary),
            ),
          ],
        ),
      );
    },
  );
}

/// DS §7-57 (Feed): "cards: author row -> attached-object rich card
/// (match/performance verified chip) -> media -> reaction bar -> top
/// comment; 'Latest' toggle in header; caught-up interstitial with
/// Arc." PRD §12.1: "Ranking = relationship closeness x cricket
/// relevance x recency ... 'Latest' toggle gives pure-chronological.
/// Inline 'Why am I seeing this?' on every non-followed item."
class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  _FeedMode _mode = _FeedMode.forYou;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final feed = ref.watch(feedProvider);
    final comments = ref.watch(commentsProvider);
    final notifier = ref.read(feedProvider.notifier);
    final now = DateTime.now();

    final sorted = feed.posts.where((p) => p.deletedAt == null).toList();
    if (_mode == _FeedMode.forYou) {
      sorted.sort((a, b) => rankedScore(b, now).compareTo(rankedScore(a, now)));
    } else {
      sorted.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    }

    // DS: "caught-up interstitial with Arc" -- splits posts newer than
    // a mock "last visit" cutoff from the rest, same Arc device reused
    // a 3rd+ time this session (E0-07/E0-08 gamification cards,
    // leaderboard laurel, level-up/badge ceremonies).
    final cutoff = now.subtract(const Duration(hours: 4));
    final newPosts = sorted.where((p) => p.timestamp.isAfter(cutoff)).toList();
    final earlierPosts = sorted
        .where((p) => !p.timestamp.isAfter(cutoff))
        .toList();

    Widget buildCard(FeedPost post) => FeedPostCard(
      key: ValueKey('feedPost_${post.id}'),
      post: post,
      resharedPost: post.resharedPostId == null
          ? null
          : feed.postById(post.resharedPostId!),
      commentCount: comments.totalCountFor(post.id),
      now: now,
      colors: colors,
      onReact: (reaction) => notifier.setReaction(post.id, reaction),
      onWhy: () => _showWhyAmISeeingThis(context, post),
      onEditHistory: () => _showEditHistory(context, post),
      onVote: (index) => notifier.votePoll(post.id, index),
      onEdit: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ComposerScreen(editingPost: post)),
      ),
      onDelete: () => notifier.deletePost(post.id),
      onShare: () => _showShareSheet(context, ref, post),
      onOpenComments: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => PostDetailScreen(postId: post.id)),
      ),
      onMentionTap: (name) => _showMentionMock(context, name),
      onHashtagTap: (tag) => _openHashtag(context, tag),
    );

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        key: const ValueKey('composerFab'),
        onPressed: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const ComposerScreen())),
        child: const Icon(Icons.add),
      ),
      appBar: AppBar(
        title: const Text('Feed'),
        actions: [
          IconButton(
            key: const ValueKey('reelsButton'),
            icon: const Icon(Icons.movie_creation_outlined),
            tooltip: 'Reels',
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const ReelsScreen())),
          ),
          IconButton(
            key: const ValueKey('recentlyDeletedPostsButton'),
            icon: const Icon(Icons.restore_from_trash_outlined),
            tooltip: 'Recently deleted',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const RecentlyDeletedPostsScreen(),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            child: AppSegmentedControl<_FeedMode>(
              key: const ValueKey('feedModeToggle'),
              options: _FeedMode.values,
              value: _mode,
              onChanged: (value) => setState(() => _mode = value),
              labelBuilder: (mode) => _feedModeLabels[mode]!,
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          const StoriesBar(),
          const SizedBox(height: AppSpacing.lg),
          for (final post in newPosts) buildCard(post),
          if (earlierPosts.isNotEmpty) ...[
            Padding(
              key: const ValueKey('caughtUpInterstitial'),
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
              child: Column(
                children: [
                  AppArcRing(
                    progress: 1.0,
                    size: 48,
                    strokeWidth: 3,
                    trackColor: colors.border,
                    fillColor: colors.primary,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    "You're all caught up",
                    style: AppTypography.body.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              'Earlier',
              style: AppTypography.label.copyWith(color: colors.textTertiary),
            ),
            const SizedBox(height: AppSpacing.xs),
            for (final post in earlierPosts) buildCard(post),
          ],
        ],
      ),
    );
  }
}

/// The feed card, reused unchanged by post_detail_screen.dart for the
/// same post at full size.
class FeedPostCard extends StatelessWidget {
  final FeedPost post;
  final FeedPost? resharedPost;
  final int commentCount;
  final DateTime now;
  final AppColors colors;
  final ValueChanged<AppReactionType?> onReact;
  final VoidCallback onWhy;
  final VoidCallback onEditHistory;
  final ValueChanged<int> onVote;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onShare;
  final VoidCallback onOpenComments;
  final ValueChanged<String> onMentionTap;
  final ValueChanged<String> onHashtagTap;

  const FeedPostCard({
    super.key,
    required this.post,
    required this.resharedPost,
    required this.commentCount,
    required this.now,
    required this.colors,
    required this.onReact,
    required this.onWhy,
    required this.onEditHistory,
    required this.onVote,
    required this.onEdit,
    required this.onDelete,
    required this.onShare,
    required this.onOpenComments,
    required this.onMentionTap,
    required this.onHashtagTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppAvatar(size: AppAvatarSize.sm, name: post.authorName),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.authorName,
                      style: AppTypography.subtitle.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                    Text(
                      post.sponsoredLabel ?? _relativeTime(post.timestamp, now),
                      style: AppTypography.caption.copyWith(
                        color: colors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              if (post.isEdited)
                GestureDetector(
                  key: ValueKey('editedLabel_${post.id}'),
                  onTap: onEditHistory,
                  child: Text(
                    'Edited',
                    style: AppTypography.caption.copyWith(
                      color: colors.textTertiary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              if (!post.isFollowed)
                IconButton(
                  key: ValueKey('whyAmISeeingThisButton_${post.id}'),
                  icon: const Icon(Icons.info_outline, size: 18),
                  tooltip: 'Why am I seeing this?',
                  onPressed: onWhy,
                ),
              if (post.authorName == composerViewerName)
                PopupMenuButton<String>(
                  key: ValueKey('feedPostMenuButton_${post.id}'),
                  onSelected: (value) =>
                      value == 'edit' ? onEdit() : onDelete(),
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
            ],
          ),
          if (post.attachedObject != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colors.border),
              ),
              child: Row(
                children: [
                  Icon(
                    _attachedObjectIcons[post.attachedObject!.type],
                    size: 20,
                    color: colors.textSecondary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.attachedObject!.title,
                          style: AppTypography.body.copyWith(
                            color: colors.textPrimary,
                          ),
                        ),
                        Text(
                          post.attachedObject!.subtitle,
                          style: AppTypography.caption.copyWith(
                            color: colors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (post.attachedObject!.verified)
                    const AppTagChip(
                      label: 'Verified',
                      variant: AppTagChipVariant.verified,
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Text.rich(
            TextSpan(
              children: buildRichTextSpans(
                text: post.contentText,
                baseStyle: AppTypography.body.copyWith(
                  color: colors.textPrimary,
                ),
                tokenStyle: AppTypography.body.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w600,
                ),
                onMentionTap: onMentionTap,
                onHashtagTap: onHashtagTap,
              ),
            ),
            style: AppTypography.body.copyWith(color: colors.textPrimary),
          ),
          if (resharedPost != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              key: ValueKey('reshareNestedPost_${post.id}'),
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    resharedPost!.authorName,
                    style: AppTypography.subtitle.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    resharedPost!.contentText,
                    style: AppTypography.caption.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (post.poll != null) ...[
            const SizedBox(height: AppSpacing.sm),
            _PollCard(
              key: ValueKey('feedPoll_${post.id}'),
              poll: post.poll!,
              colors: colors,
              onVote: onVote,
            ),
          ],
          if (post.mediaCount > 0) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Icon(
                  Icons.photo_outlined,
                  size: 16,
                  color: colors.textTertiary,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  '${post.mediaCount} media',
                  style: AppTypography.caption.copyWith(
                    color: colors.textTertiary,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              AppReactionBar(
                key: ValueKey('feedReactionBar_${post.id}'),
                reactionCount: post.totalReactionCount,
                myReaction: post.myReaction,
                onReact: (reaction) =>
                    onReact(post.myReaction == reaction ? null : reaction),
                onCountsTap: () => _showReactionBreakdown(context, post),
                child: Icon(
                  Icons.front_hand_outlined,
                  size: 20,
                  color: post.myReaction != null
                      ? colors.primary
                      : colors.textSecondary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              GestureDetector(
                key: ValueKey('feedCommentsButton_${post.id}'),
                onTap: onOpenComments,
                child: Row(
                  children: [
                    Icon(
                      Icons.mode_comment_outlined,
                      size: 16,
                      color: colors.textSecondary,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      '$commentCount',
                      style: AppTypography.caption.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              IconButton(
                key: ValueKey('feedShareButton_${post.id}'),
                icon: const Icon(Icons.share_outlined, size: 18),
                onPressed: onShare,
              ),
            ],
          ),
          if (post.topCommentText != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${post.topCommentAuthor}: ${post.topCommentText}',
              style: AppTypography.caption.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PollCard extends StatelessWidget {
  final Poll poll;
  final AppColors colors;
  final ValueChanged<int> onVote;

  const _PollCard({
    super.key,
    required this.poll,
    required this.colors,
    required this.onVote,
  });

  @override
  Widget build(BuildContext context) {
    final voted = poll.votedOptionIndex != null;
    final total = poll.totalVotes;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            poll.question,
            style: AppTypography.body.copyWith(color: colors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.xs),
          for (var i = 0; i < poll.options.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: GestureDetector(
                key: ValueKey('pollOptionTap_$i'),
                onTap: voted ? null : () => onVote(i),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            poll.options[i].text,
                            style: AppTypography.caption.copyWith(
                              color: colors.textPrimary,
                            ),
                          ),
                        ),
                        if (voted)
                          Text(
                            total == 0
                                ? '0%'
                                : '${(poll.options[i].votes * 100 / total).round()}%',
                            style: AppTypography.caption.copyWith(
                              color: colors.textTertiary,
                            ),
                          ),
                      ],
                    ),
                    if (voted) ...[
                      const SizedBox(height: 2),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: total == 0 ? 0 : poll.options[i].votes / total,
                          minHeight: 6,
                          backgroundColor: colors.border,
                          color: colors.primary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
