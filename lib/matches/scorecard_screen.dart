import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_bottom_sheet.dart';
import '../design_system/components/app_button.dart';
import '../design_system/components/app_text_field.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'scoring_models.dart';
import 'scoring_provider.dart';

const Map<ConfirmerRole, String> _confirmerRoleLabels = {
  ConfirmerRole.composerCaptain: 'Composer captain',
  ConfirmerRole.opponentCaptain: 'Opponent captain',
  ConfirmerRole.scorer: 'Scorer',
};

/// DS §7 screen 29 (Scorecard, final): "Innings accordions (batting
/// table: dismissal text 13 wraps, tnum columns aligned) -> FoW ladder
/// -> confirmation panel (3 avatar-checks: captains+scorer; mine =
/// [Confirm][Dispute]); check engraved stamp animates once on full
/// confirmation." PRD §7.14/§13: both captains + scorer confirm
/// (auto-confirm 48h if unchallenged); confirmed feeds the Match
/// Ripple (PRD Pillar 1) exactly once; a dispute freezes it.
class ScorecardScreen extends ConsumerWidget {
  /// Which of the three confirming parties the viewer is, if any --
  /// null means a spectator with no confirm/dispute action of their own.
  final ConfirmerRole? viewerRole;

  const ScorecardScreen({super.key, this.viewerRole});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final state = ref.watch(inningsProvider);
    final notifier = ref.read(inningsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Scorecard')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          if (state.isDisputed)
            Container(
              key: const ValueKey('disputedBanner'),
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              margin: const EdgeInsets.only(bottom: AppSpacing.lg),
              decoration: BoxDecoration(
                color: colors.error.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                'Frozen -- disputed: ${state.disputeReason}',
                style: AppTypography.body.copyWith(color: colors.error),
              ),
            ),
          if (state.rippleFired) _ConfirmedStamp(rippleLog: state.rippleLog),
          ExpansionTile(
            key: const ValueKey('battingAccordion'),
            title: Text('Batting -- ${state.battingTeamName}'),
            initiallyExpanded: true,
            children: [
              for (final batter in state.batters.values)
                Padding(
                  key: ValueKey('battingRow_${batter.name}'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              batter.name,
                              style: AppTypography.body.copyWith(
                                color: colors.textPrimary,
                              ),
                            ),
                            Text(
                              batter.dismissalText,
                              style: AppTypography.caption.copyWith(
                                color: colors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${batter.runs} (${batter.balls})',
                        style: AppTypography.stat.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          ExpansionTile(
            key: const ValueKey('bowlingAccordion'),
            title: Text('Bowling -- ${state.bowlingTeamName}'),
            children: [
              for (final bowler in state.bowlers.values)
                Padding(
                  key: ValueKey('bowlingRow_${bowler.name}'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          bowler.name,
                          style: AppTypography.body.copyWith(
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        '${bowler.completedOvers}.${bowler.ballsThisOver}-'
                        '${bowler.runsConceded}-${bowler.wickets}',
                        style: AppTypography.stat.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            'Fall of wickets',
            style: AppTypography.label.copyWith(color: colors.textTertiary),
          ),
          const SizedBox(height: AppSpacing.xs),
          for (final fow in state.fallOfWickets)
            Padding(
              key: ValueKey('fowRow_${fow.wicketNumber}'),
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Text(
                '${fow.wicketNumber}-${fow.teamRunsAtFall} '
                '(${fow.batterName}, ${fow.oversAtFall}.'
                '${fow.ballsIntoOverAtFall})',
                style: AppTypography.body.copyWith(color: colors.textPrimary),
              ),
            ),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            'Confirmation',
            style: AppTypography.label.copyWith(color: colors.textTertiary),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final role in ConfirmerRole.values)
            _ConfirmationRow(
              role: role,
              confirmed: switch (role) {
                ConfirmerRole.composerCaptain =>
                  state.composerCaptainConfirmedScorecard,
                ConfirmerRole.opponentCaptain =>
                  state.opponentCaptainConfirmedScorecard,
                ConfirmerRole.scorer => state.scorerConfirmedScorecard,
              },
              isMine: role == viewerRole,
              disabled: state.isDisputed || state.rippleFired,
              onConfirm: () => notifier.confirmScorecard(role),
              onDispute: () => _showDisputeSheet(context),
            ),
          if (!state.isDisputed && !state.isFullyConfirmed) ...[
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              key: const ValueKey('debugForceAutoConfirmButton'),
              variant: AppButtonVariant.tertiary,
              label: '48h auto-confirm (debug: simulate elapsed time)',
              fullWidth: true,
              onPressed: () => notifier.checkAutoConfirm(
                now: () => DateTime.now().add(
                  const Duration(
                    hours: InningsState.scorecardAutoConfirmHours + 1,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showDisputeSheet(BuildContext context) {
    showAppBottomSheet<void>(
      context: context,
      title: 'Dispute scorecard',
      contentBuilder: (context) => const _DisputeSheetContent(),
    );
  }
}

class _ConfirmationRow extends StatelessWidget {
  final ConfirmerRole role;
  final bool confirmed;
  final bool isMine;
  final bool disabled;
  final VoidCallback onConfirm;
  final VoidCallback onDispute;

  const _ConfirmationRow({
    required this.role,
    required this.confirmed,
    required this.isMine,
    required this.disabled,
    required this.onConfirm,
    required this.onDispute,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Icon(
            confirmed ? Icons.check_circle : Icons.radio_button_unchecked,
            color: confirmed ? colors.verified : colors.textTertiary,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              _confirmerRoleLabels[role]!,
              style: AppTypography.body.copyWith(color: colors.textPrimary),
            ),
          ),
          if (isMine && !confirmed && !disabled) ...[
            AppButton(
              key: ValueKey('confirmButton_${role.name}'),
              variant: AppButtonVariant.primary,
              label: 'Confirm',
              onPressed: onConfirm,
            ),
            const SizedBox(width: AppSpacing.sm),
            AppButton(
              key: ValueKey('disputeButton_${role.name}'),
              variant: AppButtonVariant.destructive,
              label: 'Dispute',
              onPressed: onDispute,
            ),
          ],
        ],
      ),
    );
  }
}

/// DS: "check engraved stamp animates once on full confirmation."
class _ConfirmedStamp extends StatelessWidget {
  final List<String> rippleLog;

  const _ConfirmedStamp({required this.rippleLog});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Container(
      key: const ValueKey('confirmedStamp'),
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.verified.withValues(alpha: 0.12),
        border: Border.all(color: colors.verified),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 360),
            curve: Curves.easeOutBack,
            builder: (context, value, child) =>
                Transform.scale(scale: value, child: child),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: colors.verified),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Confirmed',
                  style: AppTypography.title.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final entry in rippleLog)
            Text(
              '• $entry',
              style: AppTypography.caption.copyWith(
                color: colors.textSecondary,
              ),
            ),
        ],
      ),
    );
  }
}

class _DisputeSheetContent extends ConsumerStatefulWidget {
  const _DisputeSheetContent();

  @override
  ConsumerState<_DisputeSheetContent> createState() =>
      _DisputeSheetContentState();
}

class _DisputeSheetContentState extends ConsumerState<_DisputeSheetContent> {
  final _reasonController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Disputing freezes rewards and settlement until resolved. '
            'Both captains will be notified.',
            style: AppTypography.caption.copyWith(color: colors.textTertiary),
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            key: const ValueKey('disputeReasonField'),
            label: 'Reason',
            controller: _reasonController,
          ),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              _error!,
              key: const ValueKey('disputeReasonError'),
              style: AppTypography.caption.copyWith(color: colors.error),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            key: const ValueKey('submitDisputeButton'),
            variant: AppButtonVariant.destructive,
            label: 'Submit dispute',
            fullWidth: true,
            onPressed: () {
              final reason = _reasonController.text.trim();
              if (reason.isEmpty) {
                setState(() => _error = 'Explain what needs correcting.');
                return;
              }
              ref.read(inningsProvider.notifier).disputeScorecard(reason);
              Navigator.of(context).pop();
            },
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}
