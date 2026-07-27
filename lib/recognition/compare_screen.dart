import 'package:flutter/material.dart';

import '../design_system/components/app_chart_shell.dart';
import '../design_system/components/app_dropdown_field.dart';
import '../design_system/components/charts/app_radar_chart.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'compare_models.dart';

/// DS §11.15: "Compare tool ... side-by-side columns (avatars top),
/// radar center, stat rows with per-row winner-tint (subtle, never
/// red), format/window filters; blocked states: other's comparison off
/// / private -> explainer."
class CompareScreen extends StatefulWidget {
  const CompareScreen({super.key});

  @override
  State<CompareScreen> createState() => _CompareScreenState();
}

class _CompareScreenState extends State<CompareScreen> {
  String _opponentName = 'Arjun Rao';

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final me = mockComparisonProfiles[compareViewerName]!;
    final opponent = mockComparisonProfiles[_opponentName]!;
    final others = mockComparisonProfiles.keys
        .where((n) => n != compareViewerName)
        .toList();

    final blocked = !opponent.comparisonEnabled || opponent.isPrivate;

    return Scaffold(
      appBar: AppBar(title: const Text('Compare')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppDropdownField<String>(
              key: const ValueKey('compareOpponentDropdown'),
              label: 'Compare with',
              value: _opponentName,
              options: others,
              labelBuilder: (n) => n,
              onChanged: (v) => setState(() => _opponentName = v),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (blocked)
              Expanded(
                child: Center(
                  child: Text(
                    key: const ValueKey('compareBlockedExplainer'),
                    opponent.isPrivate
                        ? "${opponent.name}'s profile is private -- "
                              'comparisons are blocked.'
                        : "${opponent.name} hasn't enabled comparisons.",
                    textAlign: TextAlign.center,
                    style: AppTypography.body.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ),
              )
            else
              Expanded(
                child: ListView(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            me.name,
                            textAlign: TextAlign.center,
                            style: AppTypography.subtitle.copyWith(
                              color: colors.textPrimary,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            opponent.name,
                            textAlign: TextAlign.center,
                            style: AppTypography.subtitle.copyWith(
                              color: colors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppChartShell(
                      title: 'Radar',
                      chartHeight: 240,
                      legend: [
                        AppChartLegendItem(
                          color: colors.primary,
                          label: me.name,
                        ),
                        AppChartLegendItem(
                          color: colors.accent,
                          label: opponent.name,
                        ),
                      ],
                      chart: AppRadarChart(
                        axes: {
                          for (final d in RadarDimension.values)
                            radarDimensionLabels[d]!:
                                (me.radarScores[d] ?? 0) / 100,
                        },
                        comparisonAxes: {
                          for (final d in RadarDimension.values)
                            radarDimensionLabels[d]!:
                                (opponent.radarScores[d] ?? 0) / 100,
                        },
                      ),
                      tableViewBuilder: (context) => Column(
                        children: [
                          for (final dimension in RadarDimension.values)
                            _RadarBarRow(
                              key: ValueKey('radarRow_${dimension.name}'),
                              label: radarDimensionLabels[dimension]!,
                              myValue: me.radarScores[dimension] ?? 0,
                              opponentValue:
                                  opponent.radarScores[dimension] ?? 0,
                              colors: colors,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      'Stats',
                      style: AppTypography.label.copyWith(
                        color: colors.textTertiary,
                      ),
                    ),
                    for (final statName in me.statRows.keys)
                      _StatCompareRow(
                        key: ValueKey('statRow_$statName'),
                        label: statName,
                        myValue: me.statRows[statName] ?? 0,
                        opponentValue: opponent.statRows[statName] ?? 0,
                        colors: colors,
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RadarBarRow extends StatelessWidget {
  final String label;
  final int myValue;
  final int opponentValue;
  final AppColors colors;

  const _RadarBarRow({
    super.key,
    required this.label,
    required this.myValue,
    required this.opponentValue,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.caption.copyWith(color: colors.textTertiary),
          ),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: myValue / 100,
                    minHeight: 8,
                    backgroundColor: colors.border,
                    color: colors.primary,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: opponentValue / 100,
                    minHeight: 8,
                    backgroundColor: colors.border,
                    color: colors.accent,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCompareRow extends StatelessWidget {
  final String label;
  final int myValue;
  final int opponentValue;
  final AppColors colors;

  const _StatCompareRow({
    super.key,
    required this.label,
    required this.myValue,
    required this.opponentValue,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    // DS: "per-row winner-tint (subtle, never red)."
    final iWin = myValue > opponentValue;
    final theyWin = opponentValue > myValue;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$myValue',
              textAlign: TextAlign.center,
              style: AppTypography.stat.copyWith(
                color: iWin ? colors.success : colors.textPrimary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: AppTypography.caption.copyWith(color: colors.textTertiary),
            ),
          ),
          Expanded(
            child: Text(
              '$opponentValue',
              textAlign: TextAlign.center,
              style: AppTypography.stat.copyWith(
                color: theyWin ? colors.success : colors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
