import 'package:flutter/material.dart';

import '../design_system/components/app_button.dart';
import '../design_system/components/app_text_field.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'team_invite_models.dart';

/// PRD §6.3-6.4 AC: "a player can be in max 10 teams."
const int maxJoinedTeams = 10;

enum InviteDecision { pending, accepted, declined }

/// PRD §6.3: "Invite card shows role offered ... Accept -> joins;
/// Decline (optional reason to captain)." PRD §11's decision-card
/// pattern: "each shows expiry countdown ... expiring <24h flagged."
///
/// No cross-screen shared state is needed here (a single invite decided
/// once), so this is plain widget state rather than a Riverpod provider
/// -- unlike the multi-screen Create Team wizard, which genuinely needs
/// state shared across pushed routes.
class TeamInviteDecisionScreen extends StatefulWidget {
  final TeamInviteOffer offer;

  /// Mock stand-in for "how many teams is this player already a member
  /// of" -- no backend teams-membership service exists yet (same
  /// pattern as CreateTeamProvider.ownedTeamCount).
  final int joinedTeamCount;
  final DateTime Function() now;

  const TeamInviteDecisionScreen({
    super.key,
    required this.offer,
    this.joinedTeamCount = 0,
    this.now = DateTime.now,
  });

  @override
  State<TeamInviteDecisionScreen> createState() =>
      _TeamInviteDecisionScreenState();
}

class _TeamInviteDecisionScreenState extends State<TeamInviteDecisionScreen> {
  InviteDecision _decision = InviteDecision.pending;
  final _reasonController = TextEditingController();

  bool get _canAccept => widget.joinedTeamCount < maxJoinedTeams;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final offer = widget.offer;
    final expiringSoon = offer.expiringSoon(now: widget.now);

    return Scaffold(
      appBar: AppBar(title: const Text('Team invite')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              offer.teamName,
              style: AppTypography.h2.copyWith(color: colors.textPrimary),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Join as: ${offer.roleOffered}',
              style: AppTypography.body.copyWith(color: colors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              key: const ValueKey('teamInviteExpiryCountdown'),
              expiringSoon
                  ? 'Expires soon'
                  : 'Expires ${offer.expiresAt.day}/${offer.expiresAt.month}/'
                        '${offer.expiresAt.year}',
              style: AppTypography.caption.copyWith(
                color: expiringSoon ? colors.error : colors.textTertiary,
              ),
            ),
            if (_decision == InviteDecision.pending) ...[
              if (!_canAccept) ...[
                const SizedBox(height: AppSpacing.lg),
                Container(
                  key: const ValueKey('teamInviteCapReachedBanner'),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: colors.surfaceAlt,
                    border: Border.all(color: colors.error),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    "You're already in $maxJoinedTeams teams -- that's the "
                    'limit. Leave a team to accept this invite.',
                    style: AppTypography.body.copyWith(color: colors.error),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xxl),
              AppTextField(
                key: const ValueKey('teamInviteDeclineReasonField'),
                label: 'Reason for declining (optional)',
                controller: _reasonController,
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      key: const ValueKey('teamInviteDeclineButton'),
                      variant: AppButtonVariant.secondary,
                      label: 'Decline',
                      onPressed: () =>
                          setState(() => _decision = InviteDecision.declined),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: AppButton(
                      key: const ValueKey('teamInviteAcceptButton'),
                      variant: AppButtonVariant.primary,
                      label: 'Accept',
                      onPressed: _canAccept
                          ? () => setState(
                              () => _decision = InviteDecision.accepted,
                            )
                          : null,
                    ),
                  ),
                ],
              ),
            ] else ...[
              const SizedBox(height: AppSpacing.xxl),
              Text(
                _decision == InviteDecision.accepted
                    ? 'You joined ${offer.teamName}.'
                    : "You declined ${offer.teamName}'s invite.",
                key: const ValueKey('teamInviteDecisionOutcome'),
                style: AppTypography.body.copyWith(color: colors.textPrimary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
