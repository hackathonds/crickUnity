import 'package:flutter/material.dart';

import '../design_system/components/app_button.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'endorser_sheet.dart';
import 'profile_models.dart';
import 'style_tag_picker_sheet.dart';

/// DS §7 screen 4-5, Overview tab: "Recent-form string, favorites
/// shelves, endorsement chips." Extended by E2-04 with style tags and a
/// private Weaknesses section.
///
/// PRD §5.8 hard rule: "Weaknesses ... never publicly displayed." This
/// story's AC is "a follower viewing profile can never fetch/see
/// weaknesses surface" -- enforced here structurally: the whole
/// Weaknesses section is only ever *constructed* (not just hidden) when
/// [relation] is [ViewerRelation.self]. PRD also allows "explicitly
/// shared coaches" to see it, but no coach/role-relationship model exists
/// yet to check that against -- self-only until that exists, an
/// intentionally conservative gap, not a guess.
class ProfileOverviewTab extends StatelessWidget {
  final PlayerProfile profile;
  final ViewerRelation relation;
  final ValueChanged<List<String>>? onStyleTagsChanged;

  const ProfileOverviewTab({
    super.key,
    required this.profile,
    required this.relation,
    this.onStyleTagsChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final isSelf = relation == ViewerRelation.self;

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
          if (profile.styleTags.isNotEmpty || isSelf) ...[
            const SizedBox(height: AppSpacing.xxl),
            sectionLabel('Style'),
            Wrap(
              key: const ValueKey('profileStyleTagsRow'),
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final tag in profile.styleTags)
                  AppChipActionButton(label: tag, onPressed: null),
                if (isSelf)
                  AppChipActionButton(
                    key: const ValueKey('profileEditStyleTags'),
                    label: '+ Edit',
                    onPressed: () => showStyleTagPickerSheet(
                      context: context,
                      currentTags: profile.styleTags,
                      onChanged: onStyleTagsChanged ?? (_) {},
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
                  AppChipActionButton(
                    key: ValueKey('profileEndorsement_${endorsement.skill}'),
                    label: '${endorsement.skill} (${endorsement.count})',
                    onPressed: () => showEndorserSheet(
                      context: context,
                      endorsement: endorsement,
                    ),
                  ),
              ],
            ),
          ],
          // Structural guard (see this class's doc comment) -- not a
          // Visibility/Opacity wrapper, the subtree simply never exists
          // for anyone but self.
          if (isSelf && profile.weaknesses.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xxl),
            sectionLabel('Weaknesses (only you can see this)'),
            Column(
              key: const ValueKey('profileWeaknessesSection'),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final weakness in profile.weaknesses)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Text(
                      '${weakness.label} -- ${weakness.suggestedReason}',
                      style: AppTypography.body.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
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
