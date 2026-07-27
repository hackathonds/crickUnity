import 'package:flutter/material.dart';

import '../../tokens/app_colors.dart';
import '../../tokens/app_radius.dart';
import '../../tokens/app_spacing.dart';
import '../../tokens/app_typography.dart';

class AppRaceEntry {
  final String label;
  final double value;

  const AppRaceEntry({required this.label, required this.value});
}

/// PRD/DS name no "race chart" spec beyond the E13-01 backlog line
/// itself -- flagged judgment call. A true frame-by-frame animated bar
/// race is out of proportion to this app's other chart simplifications
/// this session; this renders the current standings as horizontal bars,
/// longest first, animating width changes as the underlying value
/// updates (AnimatedContainer) so a live race between e.g. two batters'
/// running totals still reads as "racing" without a custom timeline
/// engine.
class AppRaceChart extends StatelessWidget {
  final List<AppRaceEntry> entries;

  const AppRaceChart({super.key, required this.entries});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final sorted = [...entries]..sort((a, b) => b.value.compareTo(a.value));
    final maxValue = sorted.isEmpty
        ? 1.0
        : sorted.first.value.clamp(1, double.infinity);
    final palette = colors.chartCategorical;

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      children: [
        for (var i = 0; i < sorted.length; i++)
          Padding(
            key: ValueKey('raceChartRow_${sorted[i].label}'),
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Row(
              children: [
                SizedBox(
                  width: 88,
                  child: Text(
                    sorted[i].label,
                    style: AppTypography.caption.copyWith(
                      color: colors.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Align(
                        alignment: Alignment.centerLeft,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 240),
                          curve: Curves.easeOut,
                          height: 18,
                          width:
                              constraints.maxWidth *
                              (sorted[i].value / maxValue).clamp(0.0, 1.0),
                          decoration: BoxDecoration(
                            color: palette[i % palette.length],
                            borderRadius: AppRadius.xsRadius,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  sorted[i].value.toStringAsFixed(0),
                  style: AppTypography.body.copyWith(
                    color: colors.textPrimary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
