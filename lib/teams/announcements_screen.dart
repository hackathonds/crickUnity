import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_button.dart';
import '../design_system/components/app_state_scaffolds.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'announcement_composer_sheet.dart';
import 'announcement_models.dart';
import 'announcements_provider.dart';
import 'team_member_models.dart';

const Set<TeamMemberRole> _canPostAnnouncements = {
  TeamMemberRole.captain,
  TeamMemberRole.viceCaptain,
  TeamMemberRole.manager,
  TeamMemberRole.owner,
};

/// DS §7 screen 11: "Announcement pinned card top of Feed with 'Seen
/// 11/15' for author." Push-priority announcements pin above the rest.
class AnnouncementsScreen extends ConsumerWidget {
  final TeamMemberRole actingRole;
  final String actorName;
  final int totalMembers;

  const AnnouncementsScreen({
    super.key,
    required this.actingRole,
    required this.actorName,
    required this.totalMembers,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(announcementsProvider);
    final canPost = _canPostAnnouncements.contains(actingRole);
    final sorted = [...state.announcements]
      ..sort((a, b) {
        if (a.isPushPriority != b.isPushPriority) {
          return a.isPushPriority ? -1 : 1;
        }
        return b.postedAt.compareTo(a.postedAt);
      });

    return Scaffold(
      appBar: AppBar(title: const Text('Announcements')),
      body: sorted.isEmpty
          ? AppEmptyState(
              message: 'No announcements yet.',
              primaryLabel: 'Back',
              onPrimary: () => Navigator.of(context).pop(),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: sorted.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) => _AnnouncementCard(
                announcement: sorted[index],
                isAuthor: sorted[index].authorName == actorName,
              ),
            ),
      // AC-adjacent: only Captain/VC/Manager/Owner can post -- the
      // action is hidden entirely for other viewers, not just disabled
      // (same "hidden not disabled" pattern used for E3-02's team tabs
      // and E3-04's role-picker options).
      floatingActionButton: canPost
          ? FloatingActionButton.extended(
              key: const ValueKey('newAnnouncementButton'),
              onPressed: () => showAnnouncementComposerSheet(
                context: context,
                actingRole: actingRole,
                actorName: actorName,
                totalMembers: totalMembers,
              ),
              icon: const Icon(Icons.campaign),
              label: const Text('New announcement'),
            )
          : null,
    );
  }
}

class _AnnouncementCard extends ConsumerWidget {
  final Announcement announcement;
  final bool isAuthor;

  const _AnnouncementCard({required this.announcement, required this.isAuthor});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Container(
      key: ValueKey('announcementCard_${announcement.id}'),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(
          color: announcement.isPushPriority ? colors.live : colors.border,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  announcement.authorName,
                  style: AppTypography.subtitle.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
              ),
              if (announcement.isPushPriority)
                Text(
                  'Push-priority',
                  style: AppTypography.caption.copyWith(color: colors.live),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            announcement.body,
            style: AppTypography.body.copyWith(color: colors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              // PRD §6.8: "Read-receipts list visible to poster" --
              // structurally never rendered for anyone but the author,
              // same guard pattern as Weaknesses/Trust bands elsewhere.
              if (isAuthor)
                Expanded(
                  child: Text(
                    key: const ValueKey('announcementSeenBy'),
                    'Seen ${announcement.seenBy.length}/'
                    '${announcement.totalMembers}',
                    style: AppTypography.caption.copyWith(
                      color: colors.textTertiary,
                    ),
                  ),
                )
              else
                const Spacer(),
              if (isAuthor)
                AppButton(
                  key: ValueKey(
                    'announcementToggleComments_${announcement.id}',
                  ),
                  variant: AppButtonVariant.tertiary,
                  label: announcement.commentsEnabled
                      ? 'Comments on'
                      : 'Comments off',
                  onPressed: () => ref
                      .read(announcementsProvider.notifier)
                      .toggleComments(announcement.id),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
