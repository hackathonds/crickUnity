import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';
import 'app_card.dart';
import 'app_tag_chip.dart';

/// DS §3.2.9 Statistics Card (2-up grid, 96h). "2-up grid" describes how
/// a screen *lays out* several of these (a 2-column grid) — not
/// something this component enforces itself.
class AppStatisticsCard extends StatelessWidget {
  final String eyebrowLabel;
  final String value;
  final AppDeltaDirection? deltaDirection;
  final String? deltaValue;
  final VoidCallback? onTap;
  final VoidCallback? onInfoTap;

  const AppStatisticsCard({
    super.key,
    required this.eyebrowLabel,
    required this.value,
    this.deltaDirection,
    this.deltaValue,
    this.onTap,
    this.onInfoTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return GestureDetector(
      onTap: onTap,
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    eyebrowLabel.toUpperCase(),
                    style: AppTypography.label.copyWith(
                      color: colors.textTertiary,
                    ),
                  ),
                ),
                if (onInfoTap != null)
                  GestureDetector(
                    key: const ValueKey('appStatisticsCardInfoTap'),
                    onTap: onInfoTap,
                    behavior: HitTestBehavior.opaque,
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: Center(
                        child: Text(
                          'ⓘ',
                          style: TextStyle(
                            fontSize: 16,
                            color: colors.textTertiary,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: AppTypography.stat.copyWith(color: colors.textPrimary),
                ),
                if (deltaDirection != null && deltaValue != null) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: AppDeltaChip(
                      value: deltaValue!,
                      direction: deltaDirection!,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
