import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_button.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'streaks_provider.dart';

/// PRD §13.2 -- E6-02's login/playing streak surfaces. No app-launch/
/// session-start hook exists yet to call [StreaksNotifier.recordLogin]
/// automatically (flagged) -- this screen's [Log in today] button
/// stands in for that moment, plus a debug [Simulate next day] control
/// to demonstrate the shield/injury-pause/reset paths without waiting
/// on real elapsed time.
class StreaksSummaryScreen extends ConsumerStatefulWidget {
  const StreaksSummaryScreen({super.key});

  @override
  ConsumerState<StreaksSummaryScreen> createState() =>
      _StreaksSummaryScreenState();
}

class _StreaksSummaryScreenState extends ConsumerState<StreaksSummaryScreen> {
  int _simulatedDaysAhead = 0;

  DateTime _now() => DateTime.now().add(Duration(days: _simulatedDaysAhead));

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final streaks = ref.watch(streaksProvider);
    final notifier = ref.read(streaksProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Streaks')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(
            'Login streak',
            style: AppTypography.label.copyWith(color: colors.textTertiary),
          ),
          Text(
            key: const ValueKey('loginStreakText'),
            '${streaks.currentLoginStreakDays} day(s)',
            style: AppTypography.display.copyWith(color: colors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Playing streak',
            style: AppTypography.label.copyWith(color: colors.textTertiary),
          ),
          Text(
            key: const ValueKey('playingStreakText'),
            '${streaks.currentPlayingStreakWeeks} week(s)',
            style: AppTypography.display.copyWith(color: colors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Switch(
                key: const ValueKey('injuryModeSwitch'),
                value: streaks.injuryModeActive,
                onChanged: notifier.setInjuryMode,
              ),
              Expanded(
                child: Text(
                  'Injury mode (pauses streaks without breaking them)',
                  style: AppTypography.body.copyWith(color: colors.textPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  key: const ValueKey('logInTodayButton'),
                  variant: AppButtonVariant.primary,
                  label: 'Log in today',
                  fullWidth: true,
                  onPressed: () => notifier.recordLogin(now: _now),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppButton(
                  key: const ValueKey('simulateNextDayButton'),
                  variant: AppButtonVariant.secondary,
                  label: 'Simulate next day',
                  fullWidth: true,
                  onPressed: () => setState(() => _simulatedDaysAhead += 1),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            'Log',
            style: AppTypography.label.copyWith(color: colors.textTertiary),
          ),
          const SizedBox(height: AppSpacing.xs),
          if (streaks.log.isEmpty)
            Text(
              'Nothing logged yet.',
              style: AppTypography.body.copyWith(color: colors.textSecondary),
            )
          else
            for (final entry in streaks.log.reversed)
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.xs / 2,
                ),
                child: Text(
                  entry,
                  style: AppTypography.caption.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
