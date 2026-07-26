import 'package:flutter/material.dart';

import '../components/app_chart_shell.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';

/// QA tool for E0-08 (sub-task 12/12): [AppChartShell] -- the shared
/// container/header/gridlines/scrub-tooltip/legend/table-toggle shell (DS
/// §3.3). The bars below are placeholder data for exercising the shell,
/// not one of the 23 real chart visualizations (those are E13-01).
class ChartShellScreen extends StatefulWidget {
  const ChartShellScreen({super.key});

  @override
  State<ChartShellScreen> createState() => _ChartShellScreenState();
}

class _ChartShellScreenState extends State<ChartShellScreen> {
  static const _runsPerOver = [4, 8, 12, 6, 10, 14, 9, 7, 11, 5];

  int _period = 0;

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
      appBar: AppBar(title: const Text('Chart shell (QA)')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            label(
              'Full shell -- period control, scrub tooltip (tap+hold), '
              'legend, table toggle',
            ),
            AppChartShell(
              title: 'Runs per over',
              periods: const ['Match', 'Season'],
              selectedPeriodIndex: _period,
              onPeriodChanged: (i) => setState(() => _period = i),
              legend: const [
                AppChartLegendItem(color: Colors.teal, label: 'This innings'),
              ],
              onScrub: (fraction) {
                final index = (fraction * (_runsPerOver.length - 1)).round();
                return AppChartScrubValue(
                  'Over $index: ${_runsPerOver[index]}',
                );
              },
              chart: _BarPlaceholder(values: _runsPerOver, color: Colors.teal),
              tableViewBuilder: (context) => Table(
                key: const ValueKey('chartShellDemoTable'),
                children: [
                  for (var i = 0; i < _runsPerOver.length; i++)
                    TableRow(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.xs,
                          ),
                          child: Text(
                            'Over $i',
                            style: AppTypography.caption.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.xs,
                          ),
                          child: Text(
                            '${_runsPerOver[i]}',
                            style: AppTypography.caption.copyWith(
                              color: colors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            label('Minimal shell -- no period control, no scrub'),
            AppChartShell(
              title: 'Wagon wheel (placeholder)',
              chart: _BarPlaceholder(
                values: _runsPerOver.reversed.toList(),
                color: colors.primary,
              ),
              tableViewBuilder: (context) => Text(
                'Table view for this chart is a caller concern.',
                style: AppTypography.caption.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Placeholder bar plot -- not a real Manhattan chart (E13-01); exists only
/// so [AppChartShell]'s gridlines/scrub/legend/toggle have something to
/// frame during QA.
class _BarPlaceholder extends StatelessWidget {
  final List<int> values;
  final Color color;

  const _BarPlaceholder({required this.values, required this.color});

  @override
  Widget build(BuildContext context) {
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final value in values)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs / 2,
                ),
                child: FractionallySizedBox(
                  heightFactor: value / maxValue,
                  alignment: Alignment.bottomCenter,
                  child: Container(color: color),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
