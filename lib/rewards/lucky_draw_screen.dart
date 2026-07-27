import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_button.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'luck_models.dart';
import 'luck_provider.dart';
import 'rewards_provider.dart';

/// DS §11.14: "Lucky draw: monthly card in Wallet -- tickets earned
/// tnum, prize gallery, entry-count disclosure line, past winners list;
/// draw-day result state." No real cron or other-player ticket pool
/// exists to genuinely run a draw on a real monthly boundary -- a debug
/// control fires runMonthlyDraw() so the draw-day result state is
/// reachable, same convention as every other simulated-time control
/// this session.
class LuckyDrawScreen extends ConsumerWidget {
  const LuckyDrawScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final rewards = ref.watch(rewardsProvider);
    final luck = ref.watch(luckLayerProvider);
    final notifier = ref.read(luckLayerProvider.notifier);
    final claimable = notifier.claimableTickets(rewards);

    return Scaffold(
      appBar: AppBar(title: const Text('Monthly Lucky Draw')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(
            '$claimable',
            key: const ValueKey('claimableTicketsText'),
            style: AppTypography.display.copyWith(color: colors.textPrimary),
          ),
          Text(
            'tickets to claim this month',
            style: AppTypography.caption.copyWith(color: colors.textTertiary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '1 ticket per 500 coins earned (not spent) this month.',
            style: AppTypography.caption.copyWith(color: colors.textTertiary),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            key: const ValueKey('enterLuckyDrawButton'),
            variant: AppButtonVariant.primary,
            label: 'Enter draw',
            fullWidth: true,
            onPressed: claimable > 0
                ? () => notifier.enterLuckyDraw(rewards)
                : null,
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            'Prize',
            style: AppTypography.label.copyWith(color: colors.textTertiary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: colors.surfaceAlt,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(Icons.card_giftcard, color: colors.coin),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  luckyDrawPrize,
                  style: AppTypography.body.copyWith(color: colors.textPrimary),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Past winners',
                style: AppTypography.label.copyWith(color: colors.textTertiary),
              ),
              AppButton(
                key: const ValueKey('runMonthlyDrawDebugButton'),
                variant: AppButtonVariant.tertiary,
                label: 'Run draw (debug)',
                onPressed: () =>
                    notifier.runMonthlyDraw(viewerName: 'Deepak Sharma'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          if (luck.pastDraws.isEmpty)
            Text(
              'No draws run yet.',
              style: AppTypography.body.copyWith(color: colors.textSecondary),
            )
          else
            for (final draw in luck.pastDraws.reversed)
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.xs / 2,
                ),
                child: Text(
                  '${draw.winnerLabel} won -- ${draw.prize} '
                  '(of ${draw.totalEntries} entries)',
                  key: ValueKey('pastDrawEntry_${draw.monthKey}'),
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
