import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_button.dart';
import '../design_system/components/app_tag_chip.dart';
import '../design_system/components/app_text_field.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import '../matches/scoring_provider.dart';
import 'fan_models.dart';
import 'fan_provider.dart';

const List<(String, double)> _mockFanLeaderboard = [
  ('Ananya Iyer', 82.0),
  ('Farah Khan', 71.0),
  ('Rohan Mehta', 64.0),
];

/// PRD §2.14 (Fan role, "had no dedicated story"): "predictions & fan
/// polls on live matches; fan leaderboards (prediction accuracy,
/// superfan streaks); redeem fan-tier coins ... for fan merchandise/
/// coupons."
class FanEngagementScreen extends ConsumerStatefulWidget {
  const FanEngagementScreen({super.key});

  @override
  ConsumerState<FanEngagementScreen> createState() =>
      _FanEngagementScreenState();
}

class _FanEngagementScreenState extends ConsumerState<FanEngagementScreen> {
  String? _predictedWinner;
  final _mvpController = TextEditingController();

  @override
  void dispose() {
    _mvpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final innings = ref.watch(inningsProvider);
    final fan = ref.watch(fanProvider);
    final notifier = ref.read(fanProvider.notifier);
    final matchLabel =
        '${innings.battingTeamName} vs ${innings.bowlingTeamName}';

    final myAccuracy = fan.accuracyPercent;
    final leaderboard = [..._mockFanLeaderboard, ('You', myAccuracy)]
      ..sort((a, b) => b.$2.compareTo(a.$2));

    return Scaffold(
      appBar: AppBar(title: const Text('Fan Engagement')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(
            'Predict: $matchLabel',
            style: AppTypography.subtitle.copyWith(color: colors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              for (final team in [
                innings.battingTeamName,
                innings.bowlingTeamName,
              ])
                ChoiceChip(
                  key: ValueKey('predictWinnerChip_$team'),
                  label: Text(team),
                  selected: _predictedWinner == team,
                  onSelected: (_) => setState(() => _predictedWinner = team),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          AppTextField(
            key: const ValueKey('predictMvpField'),
            label: 'Predicted MVP',
            controller: _mvpController,
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            key: const ValueKey('submitPredictionButton'),
            variant: AppButtonVariant.primary,
            label: 'Submit prediction',
            fullWidth: true,
            onPressed: _predictedWinner == null
                ? null
                : () {
                    notifier.submitPrediction(
                      matchLabel: matchLabel,
                      predictedWinnerTeamName: _predictedWinner!,
                      predictedMvpName: _mvpController.text.trim(),
                    );
                    setState(() {
                      _predictedWinner = null;
                      _mvpController.clear();
                    });
                  },
          ),
          const SizedBox(height: AppSpacing.xxl),
          Row(
            children: [
              Text(
                'Superfan streak: ${fan.superfanStreak}',
                style: AppTypography.body.copyWith(color: colors.textPrimary),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '${myAccuracy.toStringAsFixed(0)}% accuracy',
                style: AppTypography.caption.copyWith(
                  color: colors.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            'Your predictions',
            style: AppTypography.label.copyWith(color: colors.textTertiary),
          ),
          const SizedBox(height: AppSpacing.xs),
          if (fan.predictions.isEmpty)
            Text(
              'No predictions yet.',
              style: AppTypography.body.copyWith(color: colors.textSecondary),
            )
          else
            for (final p in fan.predictions.reversed)
              Container(
                key: ValueKey('predictionRow_${p.id}'),
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: colors.surfaceAlt,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.matchLabel),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Winner: ${p.predictedWinnerTeamName}',
                            style: AppTypography.caption,
                          ),
                        ),
                        _OutcomeChip(status: p.resultStatus),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'MVP: ${p.predictedMvpName}',
                            style: AppTypography.caption,
                          ),
                        ),
                        _OutcomeChip(status: p.mvpStatus),
                      ],
                    ),
                    if (p.resultStatus == PredictionOutcome.pending)
                      AppButton(
                        key: ValueKey('resolveWinnerDebugButton_${p.id}'),
                        variant: AppButtonVariant.tertiary,
                        label: 'Resolve winner as correct (debug)',
                        onPressed: () => notifier.resolveWinnerPredictions(
                          p.matchLabel,
                          p.predictedWinnerTeamName,
                        ),
                      ),
                  ],
                ),
              ),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            'Prediction-accuracy leaderboard',
            style: AppTypography.label.copyWith(color: colors.textTertiary),
          ),
          const SizedBox(height: AppSpacing.xs),
          for (final entry in leaderboard)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs / 2),
              child: Row(
                children: [
                  Expanded(child: Text(entry.$1)),
                  Text('${entry.$2.toStringAsFixed(0)}%'),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _OutcomeChip extends StatelessWidget {
  final PredictionOutcome status;

  const _OutcomeChip({required this.status});

  @override
  Widget build(BuildContext context) {
    return AppTagChip(
      label: switch (status) {
        PredictionOutcome.pending => 'Pending',
        PredictionOutcome.correct => 'Correct',
        PredictionOutcome.incorrect => 'Incorrect',
      },
      variant: switch (status) {
        PredictionOutcome.pending => AppTagChipVariant.neutral,
        PredictionOutcome.correct => AppTagChipVariant.success,
        PredictionOutcome.incorrect => AppTagChipVariant.error,
      },
    );
  }
}
