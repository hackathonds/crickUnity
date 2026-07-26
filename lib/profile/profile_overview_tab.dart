import 'package:flutter/material.dart';

import '../design_system/components/app_tag_chip.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'profile_models.dart';

/// DS §7 screen 4-5, Overview tab: "Recent-form string, favorites
/// shelves, endorsement chips."
class ProfileOverviewTab extends StatelessWidget {
  final PlayerProfile profile;

  const ProfileOverviewTab({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    Widget sectionLabel(String text) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        text,
        style: AppTypography.label.copyWith(color: colors.textTertiary),
      ),
    );

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          sectionLabel('Recent form'),
          Row(
            key: const ValueKey('profileRecentFormRow'),
            children: [
              for (final entry in profile.recentForm) ...[
                _RecentFormChip(entry: entry),
                const SizedBox(width: AppSpacing.sm),
              ],
            ],
          ),
          if (profile.favoriteTeams.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xxl),
            sectionLabel('Favorites'),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final favorite in profile.favoriteTeams)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: colors.surfaceAlt,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      favorite.label,
                      style: AppTypography.body.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
              ],
            ),
          ],
          if (profile.endorsements.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xxl),
            sectionLabel('Endorsements'),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final endorsement in profile.endorsements)
                  AppTagChip(
                    label: '${endorsement.label} (${endorsement.count})',
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _RecentFormChip extends StatelessWidget {
  final RecentFormEntry entry;

  const _RecentFormChip({required this.entry});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final underlineColor = switch (entry.result) {
      FormResult.win => colors.success,
      FormResult.loss => colors.error,
      FormResult.other => colors.textTertiary,
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          entry.label,
          style: AppTypography.stat.copyWith(color: colors.textPrimary),
        ),
        const SizedBox(height: AppSpacing.xs),
        Container(width: 24, height: 2, color: underlineColor),
      ],
    );
  }
}
