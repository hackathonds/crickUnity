import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_bottom_sheet.dart';
import '../design_system/components/app_button.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_motion.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'scoring_models.dart';
import 'scoring_provider.dart';

const List<int> _runButtons = [0, 1, 2, 3, 4, 6];

/// DS §7 screen 27 (Live Scoring Console, scorer) -- sub-task 1/4 of
/// E4-04's XL split ("pad / extras / bowler-select / strike-swap"; see
/// scoring_models.dart for the exact scope boundaries of this
/// sub-task). "{Scoreboard 128 pinned} -> current-over beads strip 32
/// -> batter/bowler stat strips -> pad zone bottom 45%: run grid
/// (0*1*2*3*4*6 big 64 targets) ... [WICKET] full-width error-outline
/// 52, [Undo] left 44."
class LiveScoringConsoleScreen extends ConsumerWidget {
  const LiveScoringConsoleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final state = ref.watch(inningsProvider);
    final notifier = ref.read(inningsProvider.notifier);
    final striker = state.currentStriker;
    final strikerStats = state.batters[striker];
    final bowler = state.currentBowlerInnings;
    final odometerDuration = AppMotion.resolveDuration(
      context,
      AppMotionToken.standard,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Live scoring')),
      body: Column(
        children: [
          Container(
            key: const ValueKey('pinnedScoreboard'),
            height: 128,
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            color: colors.surfaceAlt,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  state.battingTeamName,
                  style: AppTypography.subtitle.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    AnimatedSwitcher(
                      key: const ValueKey('scoreOdometer'),
                      duration: odometerDuration,
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.3),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      ),
                      child: Text(
                        '${state.totalRuns}/${state.wicketsLost}',
                        key: ValueKey(
                          '${state.totalRuns}-${state.wicketsLost}',
                        ),
                        style: AppTypography.scoreboard.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                      child: Text(
                        '(${state.completedOvers}.${state.legalBallsThisOver} ov)',
                        style: AppTypography.body.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            key: const ValueKey('overBeadsStrip'),
            height: 32,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                for (final delivery in _currentOverDeliveries(state))
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.xs),
                    child: Container(
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: delivery.isWicket
                            ? colors.error.withValues(alpha: 0.15)
                            : colors.surfaceAlt,
                      ),
                      child: Text(
                        delivery.isWicket ? 'W' : '${delivery.runs}',
                        style: AppTypography.caption.copyWith(
                          color: delivery.isWicket
                              ? colors.error
                              : colors.textPrimary,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  key: const ValueKey('strikerStrip'),
                  '$striker* ${strikerStats?.runs ?? 0} (${strikerStats?.balls ?? 0})',
                  style: AppTypography.body.copyWith(color: colors.textPrimary),
                ),
                Text(
                  key: const ValueKey('bowlerStrip'),
                  '${bowler.name} ${bowler.completedOvers}.${bowler.ballsThisOver}-'
                  '${bowler.runsConceded}-${bowler.wickets}',
                  style: AppTypography.caption.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final runs in _runButtons)
                      SizedBox(
                        width: 64,
                        height: 64,
                        child: ElevatedButton(
                          key: ValueKey('runButton_$runs'),
                          style: ElevatedButton.styleFrom(
                            shape: const CircleBorder(),
                            backgroundColor: colors.surfaceAlt,
                            foregroundColor: colors.textPrimary,
                          ),
                          onPressed: () => notifier.recordRun(runs),
                          child: Text(
                            '$runs',
                            style: AppTypography.stat.copyWith(
                              color: colors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: AppButton(
                    key: const ValueKey('wicketButton'),
                    variant: AppButtonVariant.destructive,
                    label: 'WICKET',
                    fullWidth: true,
                    onPressed: () => _showDismissalSheet(context, state),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    SizedBox(
                      width: 44,
                      height: 44,
                      child: IconButton(
                        key: const ValueKey('undoButton'),
                        icon: const Icon(Icons.undo),
                        onPressed: state.deliveries.isEmpty
                            ? null
                            : notifier.undo,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Delivery> _currentOverDeliveries(InningsState state) {
    final ballsIntoOver = state.legalBallsThisOver;
    final startIndex = state.deliveries.length - ballsIntoOver;
    return state.deliveries.sublist(startIndex < 0 ? 0 : startIndex);
  }

  void _showDismissalSheet(BuildContext context, InningsState state) {
    showAppBottomSheet<void>(
      context: context,
      title: 'Wicket',
      contentBuilder: (context) => _DismissalSheetContent(
        strikerName: state.currentStriker,
        availableBatters: state.battingOrder
            .where(
              (name) =>
                  name != state.currentStriker &&
                  state.batters[name]?.isOut != true,
            )
            .toList(),
      ),
    );
  }
}

class _DismissalSheetContent extends ConsumerStatefulWidget {
  final String strikerName;
  final List<String> availableBatters;

  const _DismissalSheetContent({
    required this.strikerName,
    required this.availableBatters,
  });

  @override
  ConsumerState<_DismissalSheetContent> createState() =>
      _DismissalSheetContentState();
}

class _DismissalSheetContentState
    extends ConsumerState<_DismissalSheetContent> {
  DismissalType? _dismissalType;
  String? _fielderName;
  String? _newBatterName;

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
            '${widget.strikerName} is out',
            style: AppTypography.subtitle.copyWith(color: colors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'How?',
            style: AppTypography.label.copyWith(color: colors.textTertiary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final type in DismissalType.values)
                ChoiceChip(
                  key: ValueKey('dismissalType_${type.name}'),
                  label: Text(dismissalTypeLabels[type]!),
                  selected: _dismissalType == type,
                  onSelected: (_) => setState(() => _dismissalType = type),
                ),
            ],
          ),
          if (_dismissalType == DismissalType.caught ||
              _dismissalType == DismissalType.runOut ||
              _dismissalType == DismissalType.stumped) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              'Fielder',
              style: AppTypography.label.copyWith(color: colors.textTertiary),
            ),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.xs,
              children: [
                for (final name in mockFielderNames())
                  ChoiceChip(
                    key: ValueKey('fielder_$name'),
                    label: Text(name),
                    selected: _fielderName == name,
                    onSelected: (_) => setState(() => _fielderName = name),
                  ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Text(
            'New batter',
            style: AppTypography.label.copyWith(color: colors.textTertiary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final name in widget.availableBatters)
                ChoiceChip(
                  key: ValueKey('newBatter_$name'),
                  label: Text(name),
                  selected: _newBatterName == name,
                  onSelected: (_) => setState(() => _newBatterName = name),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            key: const ValueKey('confirmDismissalButton'),
            variant: AppButtonVariant.primary,
            label: 'Confirm',
            fullWidth: true,
            onPressed: _dismissalType != null && _newBatterName != null
                ? () {
                    ref
                        .read(inningsProvider.notifier)
                        .recordWicket(
                          dismissalType: _dismissalType!,
                          fielderName: _fielderName,
                          newBatterName: _newBatterName!,
                        );
                    Navigator.of(context).pop();
                  }
                : null,
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

/// Mock fielding-side names for the dismissal sheet -- no bowling-team
/// XI hookup exists yet either.
List<String> mockFielderNames() => const [
  'Deepak Sharma',
  'Rahul Deshmukh',
  'Sanjay Gupta',
  'Imran Khan',
];
