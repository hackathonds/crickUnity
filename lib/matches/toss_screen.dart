import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_bottom_sheet.dart';
import '../design_system/components/app_button.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_motion.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'match_models.dart';
import 'matches_provider.dart';

/// DS §7 screen 26 (Toss, captains): "Full-screen coin 160 with 3D flip
/// 1.2s on [Flip] (either captain), result Clash 28, [Record manual]
/// tertiary; result broadcast toast." PRD §7.6's "notifies followers"
/// has no social/follow-notification system to hook into yet -- the
/// in-app toast + timeline entry are what's implemented here.
class TossScreen extends ConsumerStatefulWidget {
  final String matchId;

  const TossScreen({super.key, required this.matchId});

  @override
  ConsumerState<TossScreen> createState() => _TossScreenState();
}

class _TossScreenState extends ConsumerState<TossScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flipController;
  bool _flipping = false;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  Future<void> _flip(MatchRecord match) async {
    setState(() => _flipping = true);
    final duration = AppMotion.isReduced(context)
        ? AppMotionDuration.reduced
        : const Duration(milliseconds: 1200);
    await _flipController.animateTo(1, duration: duration);
    if (!mounted) return;
    final winner = ref.read(matchesProvider.notifier).flipCoin(widget.matchId);
    setState(() => _flipping = false);
    _flipController.value = 0;
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$winner won the toss!')));
  }

  void _chooseDecision(TossDecision decision) {
    ref
        .read(matchesProvider.notifier)
        .chooseTossDecision(widget.matchId, decision);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Toss recorded: chose to '
          '${tossDecisionLabels[decision]!.toLowerCase()}',
        ),
      ),
    );
  }

  void _showManualEntrySheet(MatchRecord match) {
    showAppBottomSheet<void>(
      context: context,
      title: 'Record manual toss',
      contentBuilder: (context) => _ManualTossContent(
        matchId: widget.matchId,
        composerTeamName: match.composerTeamName,
        opponentTeamName: match.draft.opponentTeamName,
        onRecorded: () => ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Toss recorded'))),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final match = ref
        .watch(matchesProvider)
        .matches
        .firstWhere((m) => m.id == widget.matchId);

    return Scaffold(
      appBar: AppBar(title: const Text('Toss')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (match.tossResult != null)
                Text(
                  key: const ValueKey('tossResultText'),
                  '${match.tossResult!.winningTeamName} won the toss, '
                  'chose to '
                  '${tossDecisionLabels[match.tossResult!.decision]!.toLowerCase()}.',
                  textAlign: TextAlign.center,
                  style: AppTypography.h1.copyWith(color: colors.textPrimary),
                )
              else if (match.pendingTossWinner != null) ...[
                Text(
                  '${match.pendingTossWinner} won the toss!',
                  style: AppTypography.h1.copyWith(color: colors.textPrimary),
                ),
                const SizedBox(height: AppSpacing.xxl),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AppButton(
                      key: const ValueKey('chooseBatButton'),
                      variant: AppButtonVariant.primary,
                      label: 'Bat',
                      onPressed: () => _chooseDecision(TossDecision.bat),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    AppButton(
                      key: const ValueKey('chooseBowlButton'),
                      variant: AppButtonVariant.primary,
                      label: 'Bowl',
                      onPressed: () => _chooseDecision(TossDecision.bowl),
                    ),
                  ],
                ),
              ] else ...[
                AnimatedBuilder(
                  animation: _flipController,
                  builder: (context, child) {
                    final angle = _flipController.value * 6 * math.pi;
                    return Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.001)
                        ..rotateY(angle),
                      child: child,
                    );
                  },
                  child: Container(
                    key: const ValueKey('tossCoin'),
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colors.surfaceAlt,
                      border: Border.all(color: colors.primary, width: 3),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                AppButton(
                  key: const ValueKey('flipCoinButton'),
                  variant: AppButtonVariant.primary,
                  label: 'Flip',
                  fullWidth: true,
                  onPressed: _flipping ? null : () => _flip(match),
                ),
                const SizedBox(height: AppSpacing.sm),
                AppButton(
                  key: const ValueKey('recordManualButton'),
                  variant: AppButtonVariant.tertiary,
                  label: 'Record manual',
                  fullWidth: true,
                  onPressed: _flipping
                      ? null
                      : () => _showManualEntrySheet(match),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ManualTossContent extends ConsumerStatefulWidget {
  final String matchId;
  final String composerTeamName;
  final String opponentTeamName;
  final VoidCallback onRecorded;

  const _ManualTossContent({
    required this.matchId,
    required this.composerTeamName,
    required this.opponentTeamName,
    required this.onRecorded,
  });

  @override
  ConsumerState<_ManualTossContent> createState() => _ManualTossContentState();
}

class _ManualTossContentState extends ConsumerState<_ManualTossContent> {
  late String _winningTeam = widget.composerTeamName;
  TossDecision _decision = TossDecision.bat;

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
            'Who won?',
            style: AppTypography.label.copyWith(color: colors.textTertiary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            children: [
              for (final team in [
                widget.composerTeamName,
                widget.opponentTeamName,
              ])
                ChoiceChip(
                  key: ValueKey('manualTossWinner_$team'),
                  label: Text(team),
                  selected: _winningTeam == team,
                  onSelected: (_) => setState(() => _winningTeam = team),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Chose to',
            style: AppTypography.label.copyWith(color: colors.textTertiary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            children: [
              for (final decision in TossDecision.values)
                ChoiceChip(
                  key: ValueKey('manualTossDecision_${decision.name}'),
                  label: Text(tossDecisionLabels[decision]!),
                  selected: _decision == decision,
                  onSelected: (_) => setState(() => _decision = decision),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            key: const ValueKey('submitManualTossButton'),
            variant: AppButtonVariant.primary,
            label: 'Record',
            fullWidth: true,
            onPressed: () {
              ref
                  .read(matchesProvider.notifier)
                  .recordManualToss(
                    widget.matchId,
                    winningTeamName: _winningTeam,
                    decision: _decision,
                  );
              Navigator.of(context).pop();
              widget.onRecorded();
            },
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}
