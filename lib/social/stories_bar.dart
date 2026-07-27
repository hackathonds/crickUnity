import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_avatar.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'create_story_screen.dart';
import 'stories_provider.dart';
import 'story_viewer_screen.dart';

/// DS §60 "Stories/Reels standard viewers." A horizontal avatar strip
/// (the same pattern as every major social app's stories row) sits
/// above the feed list; tapping an avatar opens that author's stories
/// in story_viewer_screen.dart.
class StoriesBar extends ConsumerStatefulWidget {
  const StoriesBar({super.key});

  @override
  ConsumerState<StoriesBar> createState() => _StoriesBarState();
}

class _StoriesBarState extends ConsumerState<StoriesBar> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(storiesProvider.notifier).pruneExpiredStories();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final now = DateTime.now();
    final stories = ref
        .watch(storiesProvider)
        .stories
        .where((s) => !s.isExpired(now))
        .toList();

    final authors = <String>[];
    for (final s in stories) {
      if (!authors.contains(s.authorName)) authors.add(s.authorName);
    }

    return SizedBox(
      height: 84,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _StoryAvatarTile(
            key: const ValueKey('createStoryTile'),
            label: 'Your story',
            child: Stack(
              children: [
                const AppAvatar(size: AppAvatarSize.md, name: 'You'),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Icon(
                    Icons.add_circle,
                    color: colors.primary,
                    size: 18,
                  ),
                ),
              ],
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CreateStoryScreen()),
            ),
          ),
          for (final author in authors)
            _StoryAvatarTile(
              key: ValueKey('storyAvatarTile_$author'),
              label: author,
              child: AppAvatar(size: AppAvatarSize.md, name: author),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => StoryViewerScreen(authorName: author),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StoryAvatarTile extends StatelessWidget {
  final String label;
  final Widget child;
  final VoidCallback onTap;

  const _StoryAvatarTile({
    super.key,
    required this.label,
    required this.child,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 64,
        child: Column(
          children: [
            child,
            const SizedBox(height: AppSpacing.xs),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
