import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_card.dart';
import '../design_system/components/app_state_scaffolds.dart';
import '../design_system/components/app_tag_chip.dart';
import '../design_system/icons/app_icon_id.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import '../profile/free_agent_screen.dart';
import 'create_team_flow.dart';
import 'my_teams_models.dart';
import 'my_teams_provider.dart';
import 'team_home_screen.dart';
import 'team_member_models.dart';

/// DS §7.3 screen 10 ("My Teams"): "Cards 96 with role chip + next-event
/// caption; long-press = default/mute/leave; [Create team] empty-CTA."
/// Backlog: "switcher | open / create | team cards with role chips |
/// member | empty: create/join CTAs." Reuses [AppCard]'s own long-press
/// context-menu (E0-07) rather than a second long-press mechanic.
class MyTeamsScreen extends ConsumerWidget {
  const MyTeamsScreen({super.key});

  static const _viewerName = 'Rohan Verma';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memberships = ref.watch(myTeamsProvider);
    final notifier = ref.read(myTeamsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Teams'),
        actions: [
          IconButton(
            key: const ValueKey('createTeamButton'),
            icon: const Icon(Icons.add),
            tooltip: 'Create team',
            onPressed: () => _openCreateTeam(context),
          ),
        ],
      ),
      body: memberships.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: AppEmptyState(
                key: const ValueKey('myTeamsEmptyState'),
                message: "You haven't joined any teams yet.",
                primaryLabel: 'Create team',
                onPrimary: () => _openCreateTeam(context),
                tertiaryLabel: 'Find a team',
                onTertiary: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        const FreeAgentScreen(playerName: _viewerName),
                  ),
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                for (final membership in memberships)
                  Padding(
                    key: ValueKey('myTeamCard_${membership.team.name}'),
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: _TeamCard(
                      membership: membership,
                      onSetDefault: () =>
                          notifier.setDefault(membership.team.name),
                      onToggleMute: () =>
                          notifier.toggleMute(membership.team.name),
                      onLeave: () =>
                          _confirmLeave(context, notifier, membership),
                    ),
                  ),
              ],
            ),
    );
  }

  void _openCreateTeam(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CreateTeamFlow(onTeamCreated: (_) {})),
    );
  }

  Future<void> _confirmLeave(
    BuildContext context,
    MyTeamsNotifier notifier,
    MyTeamMembership membership,
  ) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Leave ${membership.team.name}?'),
        content: const Text(
          "You'll need a new invite or join request to come back.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            key: const ValueKey('confirmLeaveTeamButton'),
            onPressed: () {
              Navigator.of(context).pop();
              notifier.leave(membership.team.name);
            },
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  }
}

class _TeamCard extends StatelessWidget {
  final MyTeamMembership membership;
  final VoidCallback onSetDefault;
  final VoidCallback onToggleMute;
  final VoidCallback onLeave;

  const _TeamCard({
    required this.membership,
    required this.onSetDefault,
    required this.onToggleMute,
    required this.onLeave,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final team = membership.team;

    return AppCard(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => TeamHomeScreen(
            team: team,
            viewerRole: memberRoleToViewerRole(membership.role),
          ),
        ),
      ),
      menuActions: [
        if (!membership.isDefault)
          AppCardMenuAction(
            label: 'Set default team',
            icon: AppIconId.verifiedCheck,
            onTap: onSetDefault,
          ),
        AppCardMenuAction(
          label: membership.isMuted ? 'Unmute' : 'Mute',
          icon: AppIconId.remindBell,
          onTap: onToggleMute,
        ),
        AppCardMenuAction(
          label: 'Leave',
          icon: AppIconId.close,
          isDestructive: true,
          onTap: onLeave,
        ),
      ],
      child: SizedBox(
        height: 96,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          team.name,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.title.copyWith(
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      if (membership.isDefault)
                        Icon(Icons.star, size: 16, color: colors.coin),
                      if (membership.isMuted) ...[
                        const SizedBox(width: AppSpacing.xs),
                        Icon(
                          Icons.notifications_off_outlined,
                          size: 16,
                          color: colors.textTertiary,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: AppSpacing.sm,
                    children: [
                      AppTagChip(label: teamMemberRoleLabels[membership.role]!),
                      AppTagChip(label: team.city),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    membership.nextEventCaption,
                    style: AppTypography.caption.copyWith(
                      color: colors.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
