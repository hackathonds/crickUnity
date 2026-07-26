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

/// DS §7 screen 27 (Live Scoring Console, scorer) -- all 4 sub-tasks of
/// E4-04's XL split ("pad / extras / bowler-select / strike-swap"; see
/// scoring_models.dart for the exact scope of each). "{Scoreboard 128
/// pinned} -> current-over beads strip 32 -> batter/bowler stat strips
/// -> pad zone bottom 45%: run grid (0*1*2*3*4*6 big 64 targets) ...
/// [WICKET] full-width error-outline 52, [Undo] left 44."
class LiveScoringConsoleScreen extends ConsumerWidget {
  const LiveScoringConsoleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;

    ref.listen<InningsState>(inningsProvider, (previous, next) {
      final overJustEnded =
          previous != null &&
          previous.legalBallsThisOver != 0 &&
          next.legalBallsThisOver == 0 &&
          next.deliveries.isNotEmpty &&
          next.completedOvers < next.totalOversPerSide;
      if (overJustEnded) _showBowlerSelectSheet(context, next);
    });

    final state = ref.watch(inningsProvider);
    final notifier = ref.read(inningsProvider.notifier);
    final striker = state.currentStriker;
    final strikerStats = state.batters[striker];
    final nonStriker = state.currentNonStriker;
    final nonStrikerStats = state.batters[nonStriker];
    final bowler = state.currentBowlerInnings;
    final needsNewBowler = bowler.completedOvers >= state.maxOversPerBowler;
    final isLastBallWicket =
        state.deliveries.isNotEmpty && state.deliveries.last.isWicket;
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
                    const SizedBox(width: AppSpacing.sm),
                    _WicketKeyMomentChip(
                      show: isLastBallWicket,
                      wicketsLost: state.wicketsLost,
                      dismissalLabel: isLastBallWicket
                          ? dismissalTypeLabels[state
                                .deliveries
                                .last
                                .dismissalType]
                          : null,
                    ),
                  ],
                ),
                _WicketUnderlineSweep(
                  show: isLastBallWicket,
                  wicketsLost: state.wicketsLost,
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
                        _beadLabel(delivery),
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
                  key: const ValueKey('nonStrikerStrip'),
                  '$nonStriker ${nonStrikerStats?.runs ?? 0} '
                  '(${nonStrikerStats?.balls ?? 0})',
                  style: AppTypography.caption.copyWith(
                    color: colors.textSecondary,
                  ),
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
          if (needsNewBowler)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              child: Container(
                key: const ValueKey('needsNewBowlerBanner'),
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: colors.warning.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${bowler.name} has bowled the maximum '
                      '${state.maxOversPerBowler} overs -- select the next '
                      'bowler to continue.',
                      style: AppTypography.body.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    AppButton(
                      key: const ValueKey('selectNextBowlerButton'),
                      variant: AppButtonVariant.primary,
                      label: 'Select next bowler',
                      fullWidth: true,
                      onPressed: () => _showBowlerSelectSheet(context, state),
                    ),
                  ],
                ),
              ),
            ),
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
                          onPressed: needsNewBowler
                              ? null
                              : () => notifier.recordRun(runs),
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
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  children: [
                    for (final type in ExtraType.values)
                      AppButton(
                        key: ValueKey('extraButton_${type.name}'),
                        variant: AppButtonVariant.secondary,
                        label: extraTypeShortLabels[type]!,
                        onPressed: needsNewBowler
                            ? null
                            : () => _showExtraSheet(context, type),
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
                    onPressed: needsNewBowler
                        ? null
                        : () => _showDismissalSheet(context, state),
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
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: AppButton(
                        key: const ValueKey('swapStrikeButton'),
                        variant: AppButtonVariant.tertiary,
                        label: 'Swap strike',
                        onPressed: notifier.manualSwapStrike,
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

  /// Every ball (legal or not) since the last completed-over boundary --
  /// illegal balls (wides, rebowled no-balls) still show up as beads
  /// even though they don't advance the over count. Manual swap-strike
  /// markers aren't balls at all and never appear here.
  List<Delivery> _currentOverDeliveries(InningsState state) {
    final target = state.legalBallsThisOver;
    final result = <Delivery>[];
    var legalCounted = 0;
    for (var i = state.deliveries.length - 1; i >= 0; i--) {
      final d = state.deliveries[i];
      if (d.isManualSwap) continue;
      if (d.isLegal) {
        if (legalCounted >= target) break;
        legalCounted++;
      }
      result.insert(0, d);
    }
    return result;
  }

  String _beadLabel(Delivery delivery) {
    if (delivery.isWicket) return 'W';
    final type = delivery.extraType;
    if (type == null) return '${delivery.runs}';
    return delivery.runs > 0
        ? '${extraTypeShortLabels[type]}${delivery.runs}'
        : extraTypeShortLabels[type]!;
  }

  void _showExtraSheet(BuildContext context, ExtraType type) {
    showAppBottomSheet<void>(
      context: context,
      title: extraTypeLabels[type],
      contentBuilder: (context) => _ExtraRunStepperContent(type: type),
    );
  }

  /// AC (DS §1.5): "3 taps for a bowled dismissal" -- WICKET (opens this
  /// sheet), the dismissal type, the new batter; the sheet auto-submits
  /// on that last tap rather than requiring a separate Confirm.
  void _showDismissalSheet(BuildContext context, InningsState state) {
    showAppBottomSheet<void>(
      context: context,
      title: 'Wicket',
      contentBuilder: (context) => _DismissalSheetContent(
        strikerName: state.currentStriker,
        nonStrikerName: state.currentNonStriker,
        availableBatters: state.battingOrder
            .where(
              (name) =>
                  name != state.currentStriker &&
                  name != state.currentNonStriker &&
                  state.batters[name]?.isOut != true,
            )
            .toList(),
      ),
    );
  }

  /// PRD §7.7: "end-over auto-advance with next-bowler picker (bowler-
  /// overs limits enforced per format rules)." AC: "Given over ends,
  /// Then bowler sheet lists only legal bowlers with overs-left
  /// captions."
  void _showBowlerSelectSheet(BuildContext context, InningsState state) {
    showAppBottomSheet<void>(
      context: context,
      title: 'Next bowler',
      contentBuilder: (context) => _BowlerSelectSheetContent(
        eligibleBowlers: state.eligibleNextBowlers,
        oversLeftFor: (name) =>
            state.maxOversPerBowler -
            (state.bowlers[name]?.completedOvers ?? 0),
      ),
    );
  }
}

bool _dismissalNeedsFielder(DismissalType type) =>
    type == DismissalType.caught ||
    type == DismissalType.runOut ||
    type == DismissalType.stumped;

class _DismissalSheetContent extends ConsumerStatefulWidget {
  final String strikerName;
  final String nonStrikerName;
  final List<String> availableBatters;

  const _DismissalSheetContent({
    required this.strikerName,
    required this.nonStrikerName,
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
  String? _dismissedBatterName;

  /// AC (DS §1.5): submitting happens on the new-batter tap itself --
  /// by construction that's always the last field a dismissal needs, so
  /// there's never a separate Confirm tap.
  void _submit(String newBatterName) {
    ref
        .read(inningsProvider.notifier)
        .recordWicket(
          dismissalType: _dismissalType!,
          fielderName: _fielderName,
          dismissedBatterName: _dismissedBatterName,
          newBatterName: newBatterName,
        );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final type = _dismissalType;
    final needsFielder = type != null && _dismissalNeedsFielder(type);
    final needsRunOutEnd = type == DismissalType.runOut;
    final readyForNewBatter =
        type != null &&
        (!needsFielder || _fielderName != null) &&
        (!needsRunOutEnd || _dismissedBatterName != null);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How out?',
            style: AppTypography.label.copyWith(color: colors.textTertiary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final t in DismissalType.values)
                ChoiceChip(
                  key: ValueKey('dismissalType_${t.name}'),
                  label: Text(dismissalTypeLabels[t]!),
                  selected: _dismissalType == t,
                  onSelected: (_) => setState(() {
                    _dismissalType = t;
                    if (t != DismissalType.runOut) {
                      _dismissedBatterName = widget.strikerName;
                    } else {
                      _dismissedBatterName = null;
                    }
                  }),
                ),
            ],
          ),
          if (needsRunOutEnd) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              'Who was run out?',
              style: AppTypography.label.copyWith(color: colors.textTertiary),
            ),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.xs,
              children: [
                for (final name in [widget.strikerName, widget.nonStrikerName])
                  ChoiceChip(
                    key: ValueKey('runOutEnd_$name'),
                    label: Text(name),
                    selected: _dismissedBatterName == name,
                    onSelected: (_) =>
                        setState(() => _dismissedBatterName = name),
                  ),
              ],
            ),
          ],
          if (needsFielder) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              'Fielder',
              style: AppTypography.label.copyWith(color: colors.textTertiary),
            ),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.xs,
              children: [
                for (final name in mockBowlingRoster())
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
                  selected: false,
                  onSelected: readyForNewBatter ? (_) => _submit(name) : null,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

/// DS §5.13 "Live update" pattern: "wicket = scoreboard underline sweep
/// + key-moment chip springs in." Both are purely derived from whether
/// the *most recent* delivery was a wicket -- no timers -- so they
/// appear the instant a wicket lands and disappear the instant the next
/// ball (or manual swap) is recorded. Keyed by wicketsLost so each new
/// wicket gets a fresh instance and re-animates from scratch rather
/// than reusing a still-settled one. Not a real spring simulation --
/// DS §2.6 reserves spring physics for coin/XP only -- this is a plain
/// scale/fade entrance at the standard 240ms token.
class _WicketKeyMomentChip extends StatelessWidget {
  final bool show;
  final int wicketsLost;
  final String? dismissalLabel;

  const _WicketKeyMomentChip({
    required this.show,
    required this.wicketsLost,
    required this.dismissalLabel,
  });

  @override
  Widget build(BuildContext context) {
    if (!show) return const SizedBox.shrink();
    final colors = Theme.of(context).extension<AppColors>()!;

    return TweenAnimationBuilder<double>(
      key: ValueKey('wicketKeyMoment_$wicketsLost'),
      tween: Tween(begin: 0, end: 1),
      duration: AppMotionDuration.standard,
      curve: Curves.easeOut,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.scale(scale: 0.8 + (0.2 * value), child: child),
      ),
      child: Container(
        key: const ValueKey('keyMomentChip'),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: colors.error.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          dismissalLabel ?? 'OUT',
          style: AppTypography.caption.copyWith(color: colors.error),
        ),
      ),
    );
  }
}

class _WicketUnderlineSweep extends StatelessWidget {
  final bool show;
  final int wicketsLost;

  const _WicketUnderlineSweep({required this.show, required this.wicketsLost});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    if (!show) return const SizedBox(height: 3);

    return TweenAnimationBuilder<double>(
      key: ValueKey('wicketUnderlineSweep_$wicketsLost'),
      tween: Tween(begin: 0, end: 1),
      duration: AppMotionDuration.standard,
      curve: Curves.easeOut,
      builder: (context, value, child) => Align(
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: value,
          child: Container(
            key: const ValueKey('wicketUnderline'),
            height: 3,
            color: colors.error,
          ),
        ),
      ),
    );
  }
}

const List<int> _extraAdditionalRunOptions = [0, 1, 2, 3, 4];

/// DS/PRD: "extras (Wd/Nb/B/Lb with run steppers)." The base
/// wide/no-ball penalty run is applied automatically per the match's
/// sub-rules (Delivery.extra); this stepper only picks any *additional*
/// runs actually run/hit (overthrows, byes taken, etc).
class _ExtraRunStepperContent extends ConsumerWidget {
  final ExtraType type;

  const _ExtraRunStepperContent({required this.type});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            type == ExtraType.bye || type == ExtraType.legBye
                ? 'Runs taken'
                : 'Additional runs run/hit',
            style: AppTypography.label.copyWith(color: colors.textTertiary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            children: [
              for (final n in _extraAdditionalRunOptions)
                ChoiceChip(
                  key: ValueKey('extraRunsOption_${type.name}_$n'),
                  label: Text('$n'),
                  selected: false,
                  onSelected: (_) {
                    ref
                        .read(inningsProvider.notifier)
                        .recordExtra(type, additionalRuns: n);
                    Navigator.of(context).pop();
                  },
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

class _BowlerSelectSheetContent extends ConsumerWidget {
  final List<String> eligibleBowlers;
  final int Function(String name) oversLeftFor;

  const _BowlerSelectSheetContent({
    required this.eligibleBowlers,
    required this.oversLeftFor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final name in eligibleBowlers)
            GestureDetector(
              key: ValueKey('bowlerOption_$name'),
              behavior: HitTestBehavior.opaque,
              onTap: () {
                ref.read(inningsProvider.notifier).selectNextBowler(name);
                Navigator.of(context).pop();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: AppTypography.body.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      '${oversLeftFor(name)} overs left',
                      style: AppTypography.caption.copyWith(
                        color: colors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}
