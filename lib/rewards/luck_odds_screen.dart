import 'package:flutter/material.dart';

import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'luck_models.dart';

/// PRD §13.4: "odds page publicly viewable (transparency rule)." Plain
/// percentage table -- no auth/role gate, reachable from both the spin
/// wheel and the Luck Layer hub.
class LuckOddsScreen extends StatelessWidget {
  const LuckOddsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final spinTotal = spinSegmentWeights.values.fold(0, (s, w) => s + w);
    final scratchTotal =
        scratchOutcomeCoinsWeight +
        scratchOutcomeVoucherWeight +
        scratchOutcomeBlankWeight;

    return Scaffold(
      appBar: AppBar(title: const Text('Odds')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(
            'Spin wheel',
            style: AppTypography.label.copyWith(color: colors.textTertiary),
          ),
          const SizedBox(height: AppSpacing.xs),
          for (final entry in spinSegmentWeights.entries)
            _OddsRow(
              key: ValueKey('spinOddsRow_${entry.key.name}'),
              label: spinSegmentLabels[entry.key]!,
              percent: entry.value * 100 / spinTotal,
              colors: colors,
            ),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            'Scratch card',
            style: AppTypography.label.copyWith(color: colors.textTertiary),
          ),
          const SizedBox(height: AppSpacing.xs),
          _OddsRow(
            key: const ValueKey('scratchOddsRow_coins'),
            label: 'Coins (10-500, weighted low)',
            percent: scratchOutcomeCoinsWeight * 100 / scratchTotal,
            colors: colors,
          ),
          _OddsRow(
            key: const ValueKey('scratchOddsRow_voucher'),
            label: 'Voucher',
            percent: scratchOutcomeVoucherWeight * 100 / scratchTotal,
            colors: colors,
          ),
          _OddsRow(
            key: const ValueKey('scratchOddsRow_blank'),
            label: 'Better luck next time',
            percent: scratchOutcomeBlankWeight * 100 / scratchTotal,
            colors: colors,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Pity rule: never more than 2 blanks in a row.',
            style: AppTypography.caption.copyWith(color: colors.textTertiary),
          ),
        ],
      ),
    );
  }
}

class _OddsRow extends StatelessWidget {
  final String label;
  final double percent;
  final AppColors colors;

  const _OddsRow({
    super.key,
    required this.label,
    required this.percent,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs / 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTypography.body.copyWith(color: colors.textPrimary),
            ),
          ),
          Text(
            '${percent.toStringAsFixed(0)}%',
            style: AppTypography.stat.copyWith(color: colors.textSecondary),
          ),
        ],
      ),
    );
  }
}
