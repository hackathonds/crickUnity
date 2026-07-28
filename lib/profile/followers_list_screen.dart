import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_segmented_control.dart';
import '../design_system/components/app_state_scaffolds.dart';
import '../design_system/components/app_tag_chip.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'follower_models.dart';
import 'followers_provider.dart';

enum _FollowTab { followers, following }

const Map<_FollowTab, String> _tabLabels = {
  _FollowTab.followers: 'Followers',
  _FollowTab.following: 'Following',
};

/// DS §64: "Followers/Following lists with mutual chips; restrict/remove
/// via ⋮." PRD §12.8: restrict and remove apply to *followers* (people
/// following the owner); the Following tab (people the owner follows)
/// gets Unfollow instead -- restricting or removing someone you follow
/// isn't a concept the PRD describes.
class FollowersListScreen extends ConsumerStatefulWidget {
  const FollowersListScreen({super.key});

  @override
  ConsumerState<FollowersListScreen> createState() =>
      _FollowersListScreenState();
}

class _FollowersListScreenState extends ConsumerState<FollowersListScreen> {
  _FollowTab _tab = _FollowTab.followers;

  @override
  Widget build(BuildContext context) {
    final graph = ref.watch(followGraphProvider);
    final notifier = ref.read(followGraphProvider.notifier);
    final entries = _tab == _FollowTab.followers
        ? graph.followers
        : graph.following;

    return Scaffold(
      appBar: AppBar(title: const Text('Followers & Following')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSegmentedControl<_FollowTab>(
              key: const ValueKey('followTabSegmentedControl'),
              options: _FollowTab.values,
              value: _tab,
              labelBuilder: (t) => _tabLabels[t]!,
              onChanged: (t) => setState(() => _tab = t),
            ),
            const SizedBox(height: AppSpacing.lg),
            Expanded(
              child: entries.isEmpty
                  ? AppEmptyState(
                      key: ValueKey('followList${_tab.name}Empty'),
                      message: _tab == _FollowTab.followers
                          ? 'No followers yet.'
                          : "You aren't following anyone yet.",
                      primaryLabel: 'Back',
                      onPrimary: () => Navigator.of(context).maybePop(),
                    )
                  : ListView.separated(
                      itemCount: entries.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) {
                        final entry = entries[index];
                        return _FollowRow(
                          key: ValueKey('followRow_${_tab.name}_${entry.name}'),
                          entry: entry,
                          isRestricted:
                              _tab == _FollowTab.followers &&
                              graph.isRestricted(entry.name),
                          onRestrict: _tab == _FollowTab.followers
                              ? () => notifier.toggleRestrict(entry.name)
                              : null,
                          onRemove: _tab == _FollowTab.followers
                              ? () => notifier.removeFollower(entry.name)
                              : null,
                          onUnfollow: _tab == _FollowTab.following
                              ? () => notifier.unfollow(entry.name)
                              : null,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FollowRow extends StatelessWidget {
  final FollowerEntry entry;
  final bool isRestricted;
  final VoidCallback? onRestrict;
  final VoidCallback? onRemove;
  final VoidCallback? onUnfollow;

  const _FollowRow({
    super.key,
    required this.entry,
    required this.isRestricted,
    this.onRestrict,
    this.onRemove,
    this.onUnfollow,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AppSpacing.sm,
              children: [
                Text(
                  entry.name,
                  style: AppTypography.subtitle.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
                if (entry.isMutual)
                  const AppTagChip(
                    label: 'Mutual',
                    variant: AppTagChipVariant.neutral,
                  ),
                // Owner-only signal -- the restricted person never sees
                // this anywhere (PRD's "without knowing" rule).
                if (isRestricted)
                  AppTagChip(
                    key: const ValueKey('restrictedTag'),
                    label: 'Restricted',
                    variant: AppTagChipVariant.warning,
                  ),
              ],
            ),
          ),
          if (onUnfollow != null)
            TextButton(
              key: const ValueKey('unfollowButton'),
              onPressed: onUnfollow,
              child: const Text('Unfollow'),
            )
          else
            PopupMenuButton<String>(
              key: ValueKey('followRowMenu_${entry.name}'),
              onSelected: (value) => switch (value) {
                'restrict' => onRestrict?.call(),
                'remove' => onRemove?.call(),
                _ => null,
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'restrict',
                  child: Text(isRestricted ? 'Unrestrict' : 'Restrict'),
                ),
                const PopupMenuItem(value: 'remove', child: Text('Remove')),
              ],
            ),
        ],
      ),
    );
  }
}
