import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_timeline.dart';
import '../design_system/icons/app_icon_id.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'profile_timeline_models.dart';
import 'profile_timeline_provider.dart';

const Map<ProfileTimelineEntryType, AppIconId> _timelineEntryIcons = {
  ProfileTimelineEntryType.joinedTeam: AppIconId.people,
  ProfileTimelineEntryType.debut: AppIconId.bat,
  ProfileTimelineEntryType.firstFifty: AppIconId.scorebook,
  ProfileTimelineEntryType.captaincy: AppIconId.shield,
  ProfileTimelineEntryType.championship: AppIconId.trophy,
};

/// PRD §5.19: "Timeline tab = life-in-cricket feed: joined team, debut,
/// first fifty, captaincy, championships — auto-generated, each entry
/// sharable; user can hide individual entries." Reuses [AppTimeline]
/// (DS §3.4) rather than a bespoke list.
class ProfileTimelineTab extends ConsumerWidget {
  const ProfileTimelineTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final allEntries = computeProfileTimelineEntries(ref);
    final hidden = ref.watch(profileTimelineProvider).hiddenEntryIds;
    final visible = allEntries.where((e) => !hidden.contains(e.id)).toList();

    if (visible.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Text(
          'No timeline entries yet.',
          style: AppTypography.body.copyWith(color: colors.textSecondary),
        ),
      );
    }

    return AppTimeline(
      shrinkWrap: true,
      entries: [
        for (final entry in visible)
          AppTimelineEntry(
            date: entry.date,
            isKeyEvent: true,
            icon: _timelineEntryIcons[entry.type],
            content: _TimelineEntryCard(entry: entry),
          ),
      ],
      dateLabelBuilder: (date) => '${date.day}/${date.month}/${date.year}',
    );
  }
}

class _TimelineEntryCard extends ConsumerWidget {
  final ProfileTimelineEntry entry;
  const _TimelineEntryCard({required this.entry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Container(
      key: ValueKey('timelineEntry_${entry.id}'),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profileTimelineEntryTypeLabels[entry.type]!,
                  style: AppTypography.label.copyWith(
                    color: colors.textTertiary,
                  ),
                ),
                Text(
                  entry.title,
                  style: AppTypography.body.copyWith(color: colors.textPrimary),
                ),
              ],
            ),
          ),
          IconButton(
            key: ValueKey('shareTimelineEntryButton_${entry.id}'),
            icon: const Icon(Icons.share_outlined, size: 18),
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Shared "${entry.title}" (no share plugin wired yet).',
                ),
              ),
            ),
          ),
          IconButton(
            key: ValueKey('hideTimelineEntryButton_${entry.id}'),
            icon: const Icon(Icons.visibility_off_outlined, size: 18),
            onPressed: () =>
                ref.read(profileTimelineProvider.notifier).hide(entry.id),
          ),
        ],
      ),
    );
  }
}
