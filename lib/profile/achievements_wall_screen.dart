import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../design_system/components/app_avatar.dart';
import '../design_system/components/app_badge_tile.dart';
import '../design_system/components/app_bottom_sheet.dart';
import '../design_system/components/app_segmented_control.dart';
import '../design_system/components/app_state_scaffolds.dart';
import '../design_system/tokens/app_spacing.dart';
import 'achievement_models.dart';

/// PRD §5.6/§18, DS §3.17: the full badge wall reached from a profile's
/// pinned-badge strip ("See all"). Filterable by category (§13.3's 7-item
/// taxonomy); each tile opens the reused [AppBadgeDetailContent] --
/// earned or locked, since DS §3.17 says locked tiles show "criteria on
/// tap" too, not just earned ones.
///
/// `badges` is passed in synchronously (no backend achievements API
/// exists yet, same precedent as `appearance_settings_screen.dart`), so
/// of the 7 canonical states only Default/Empty/Success are real triggers
/// here -- Loading/Error/Offline/Permission-denied have no genuine cause
/// to fire and aren't fabricated. Empty is real: a category filter (or a
/// brand-new player's whole wall) can have zero badges.
class AchievementsWallScreen extends StatefulWidget {
  final List<AchievementBadge> badges;

  const AchievementsWallScreen({super.key, required this.badges});

  @override
  State<AchievementsWallScreen> createState() => _AchievementsWallScreenState();
}

class _AchievementsWallScreenState extends State<AchievementsWallScreen> {
  BadgeCategory? _filter;

  @override
  Widget build(BuildContext context) {
    final filtered = widget.badges
        .where((b) => _filter == null || b.category == _filter)
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Achievements')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSegmentedControl<BadgeCategory?>(
              key: const ValueKey('achievementsCategoryFilter'),
              options: [null, ...BadgeCategory.values],
              value: _filter,
              onChanged: (value) => setState(() => _filter = value),
              labelBuilder: (category) =>
                  category == null ? 'All' : badgeCategoryLabels[category]!,
            ),
            const SizedBox(height: AppSpacing.lg),
            Expanded(
              child: filtered.isEmpty
                  ? AppEmptyState(
                      message: _filter == null
                          ? 'No badges earned yet -- play a verified match '
                                'to start collecting.'
                          : 'No ${badgeCategoryLabels[_filter]!.toLowerCase()} '
                                'badges yet.',
                      primaryLabel: 'View all badges',
                      onPrimary: () => setState(() => _filter = null),
                    )
                  : GridView.builder(
                      key: const ValueKey('achievementsGrid'),
                      // Fixed extent, not fixed column count: a
                      // 3-column split on a wide/tablet viewport would
                      // stretch each cell far beyond the tile's own 88px
                      // art, leaving the tile stranded off-center.
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 112,
                            mainAxisSpacing: AppSpacing.lg,
                            crossAxisSpacing: AppSpacing.sm,
                          ),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final badge = filtered[index];
                        return Center(
                          child: AppBadgeTile(
                            key: ValueKey('achievementBadgeTile_${badge.name}'),
                            name: badge.name,
                            color: badge.color,
                            earned: badge.earned,
                            size: 88,
                            onTap: () => _openDetail(context, badge),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _openDetail(BuildContext context, AchievementBadge badge) {
    showAppBottomSheet<void>(
      context: context,
      title: badge.name,
      contentBuilder: (context) => AppBadgeDetailContent(
        name: badge.name,
        color: badge.color,
        criteria: badge.criteria,
        rarityPercent: badge.rarityPercent,
        earnDateAndProvenance: badge.earnDateAndProvenance ?? 'Not yet earned',
        friendAvatars: [
          for (final friend in badge.friendsWhoHold) ...[
            AppAvatar(size: AppAvatarSize.xs, name: friend),
            const SizedBox(width: AppSpacing.xs),
          ],
        ],
        onShare: badge.earned
            ? () {
                Clipboard.setData(
                  ClipboardData(text: '${badge.name} -- ${badge.criteria}'),
                );
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Badge copied')));
              }
            : null,
      ),
    );
  }
}
