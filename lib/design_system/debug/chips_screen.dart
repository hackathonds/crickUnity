import 'package:flutter/material.dart';

import '../components/app_tag_chip.dart';
import '../icons/app_icon_id.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';

/// QA tool for E0-07 (sub-task 5/10): the static tag/status chip family
/// ([AppTagChip], [AppDeltaChip]) — distinct from the interactive
/// Chip-action button shown on the Buttons debug screen.
class ChipsScreen extends StatelessWidget {
  const ChipsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    Widget label(String text) => Padding(
      padding: const EdgeInsets.only(
        bottom: AppSpacing.sm,
        top: AppSpacing.xxl,
      ),
      child: Text(
        text,
        style: AppTypography.label.copyWith(color: colors.textTertiary),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Chips (QA)')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            label('AppTagChip — variants'),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: const [
                AppTagChip(label: 'Captain'),
                AppTagChip(
                  label: 'Verified',
                  variant: AppTagChipVariant.verified,
                  icon: AppIconId.verifiedCheck,
                ),
                AppTagChip(
                  label: 'Locked-in',
                  variant: AppTagChipVariant.success,
                ),
                AppTagChip(
                  label: '4d overdue',
                  variant: AppTagChipVariant.warning,
                ),
                AppTagChip(
                  label: '9d overdue',
                  variant: AppTagChipVariant.error,
                ),
              ],
            ),
            label('AppTagChip — with leading icon'),
            const Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                AppTagChip(label: 'T20', icon: AppIconId.trophy),
                AppTagChip(
                  label: 'Sanctioned',
                  variant: AppTagChipVariant.verified,
                  icon: AppIconId.verifiedCheck,
                ),
              ],
            ),
            label('AppDeltaChip — trend direction'),
            const Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                AppDeltaChip(value: '12%', direction: AppDeltaDirection.up),
                AppDeltaChip(value: '3%', direction: AppDeltaDirection.down),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
