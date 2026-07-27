import 'package:flutter/material.dart';

import '../components/app_chart_shell.dart';
import '../components/charts/app_dot_pressure_gauge.dart';
import '../components/charts/app_manhattan_chart.dart';
import '../components/charts/app_race_chart.dart';
import '../components/charts/app_radar_chart.dart';
import '../components/charts/app_tag_coverage_caption.dart';
import '../components/charts/app_wagon_wheel_chart.dart';
import '../components/charts/app_worm_chart.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';

/// QA tool for E13-01 (Chart library completion). PRD/DS name no
/// enumerable list of "all 23 visualizations" -- the backlog line cites
/// "DS §19.2/§3.3"; §3.3 is real (shared shell rules + Manhattan/
/// Worm/Wagon wheel/Radar behavior) but DS has no §19 at all, so §19.2 is
/// a phantom citation (same pattern as this session's earlier phantom
/// Appx C/E/F/G flags). This gallery therefore ships every visualization
/// the backlog line names explicitly (Manhattan, win-prob worm,
/// dot-pressure gauge, race chart, tag-coverage captions) plus DS §3.3's
/// own named types (wagon wheel, radar) -- 7 real, distinctly-painted
/// charts. The remaining count up to "23" is an open question: neither
/// PRD nor DS enumerates the other ~16, so none are guessed here.
class ChartGalleryScreen extends StatefulWidget {
  const ChartGalleryScreen({super.key});

  @override
  State<ChartGalleryScreen> createState() => _ChartGalleryScreenState();
}

class _ChartGalleryScreenState extends State<ChartGalleryScreen> {
  static const _perOver = [
    (8, 0),
    (4, 1),
    (11, 0),
    (6, 0),
    (14, 1),
    (9, 0),
    (2, 2),
    (12, 0),
    (7, 0),
    (10, 1),
  ];

  static const _winProb = [
    50.0,
    54.0,
    58.0,
    49.0,
    62.0,
    70.0,
    65.0,
    78.0,
    88.0,
    96.0,
  ];

  static const _wagonShots = [
    AppWagonShot(sectorIndex: 0, runs: 1),
    AppWagonShot(sectorIndex: 1, runs: 4),
    AppWagonShot(sectorIndex: 1, runs: 1),
    AppWagonShot(sectorIndex: 2, runs: 6),
    AppWagonShot(sectorIndex: 3, runs: 2),
    AppWagonShot(sectorIndex: 4, runs: 0),
    AppWagonShot(sectorIndex: 5, runs: 4),
    AppWagonShot(sectorIndex: 5, runs: 4),
    AppWagonShot(sectorIndex: 6, runs: 1),
    AppWagonShot(sectorIndex: 7, runs: 6),
  ];

  static const _raceEntries = [
    AppRaceEntry(label: 'Priya N.', value: 58),
    AppRaceEntry(label: 'Deepak S.', value: 46),
    AppRaceEntry(label: 'Arjun K.', value: 71),
    AppRaceEntry(label: 'Meera R.', value: 33),
  ];

  int _wormPeriod = 0;
  int? _tappedWagonZone;

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
      appBar: AppBar(title: const Text('Chart gallery (QA)')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            label('Manhattan -- bar per over, wicket dots stacked on top'),
            AppChartShell(
              title: 'Manhattan',
              chart: const AppManhattanChart(perOver: _perOver),
              onScrub: (fraction) {
                final i = (fraction * (_perOver.length - 1)).round();
                final (runs, wkts) = _perOver[i];
                return AppChartScrubValue('Over $i: $runs run(s), $wkts wkt');
              },
              tableViewBuilder: (context) => _table(
                colors,
                headers: const ['Over', 'Runs', 'Wkts'],
                rows: [
                  for (var i = 0; i < _perOver.length; i++)
                    ['$i', '${_perOver[i].$1}', '${_perOver[i].$2}'],
                ],
              ),
            ),
            label('Win-probability worm -- dashed 50% baseline'),
            AppChartShell(
              title: 'Win probability',
              periods: const ['This innings', 'Last 5'],
              selectedPeriodIndex: _wormPeriod,
              onPeriodChanged: (i) => setState(() => _wormPeriod = i),
              chart: AppWormChart(
                values: _winProb,
                referenceLine: 50,
                maxY: 100,
              ),
              onScrub: (fraction) {
                final i = (fraction * (_winProb.length - 1)).round();
                return AppChartScrubValue(
                  'Over $i: ${_winProb[i].toStringAsFixed(0)}%',
                );
              },
              tableViewBuilder: (context) => _table(
                colors,
                headers: const ['Over', 'Win %'],
                rows: [
                  for (var i = 0; i < _winProb.length; i++)
                    ['$i', _winProb[i].toStringAsFixed(0)],
                ],
              ),
            ),
            label('Wagon wheel -- zone-tap filters the ball list below'),
            AppChartShell(
              title: 'Wagon wheel',
              chartHeight: 240,
              legend: [
                AppChartLegendItem(color: colors.secondary, label: 'Four'),
                AppChartLegendItem(color: colors.accent, label: 'Six'),
              ],
              chart: AppWagonWheelChart(
                shots: _wagonShots,
                onZoneTap: (zone) => setState(() => _tappedWagonZone = zone),
              ),
              tableViewBuilder: (context) => _table(
                colors,
                headers: const ['Sector', 'Runs'],
                rows: [
                  for (final s in _wagonShots)
                    ['Zone ${s.sectorIndex}', '${s.runs}'],
                ],
              ),
            ),
            if (_tappedWagonZone != null)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Text(
                  'Balls in zone $_tappedWagonZone: '
                  '${_wagonShots.where((s) => s.sectorIndex == _tappedWagonZone).length}',
                  style: AppTypography.caption.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ),
            const SizedBox(height: AppSpacing.xs),
            AppChartTagCoverageCaption(
              tagged: _wagonShots.length,
              total: _wagonShots.length + 2,
            ),
            label('Radar -- max 6 axes, 12% fill'),
            AppChartShell(
              title: 'Batting profile',
              chartHeight: 240,
              chart: AppRadarChart(
                axes: const {
                  'Power': 0.8,
                  'Timing': 0.65,
                  'Placement': 0.7,
                  'Rotation': 0.5,
                  'Pace-SR': 0.75,
                  'Spin-SR': 0.6,
                },
              ),
              tableViewBuilder: (context) => _table(
                colors,
                headers: const ['Axis', 'Value'],
                rows: const [
                  ['Power', '0.80'],
                  ['Timing', '0.65'],
                  ['Placement', '0.70'],
                  ['Rotation', '0.50'],
                  ['Pace-SR', '0.75'],
                  ['Spin-SR', '0.60'],
                ],
              ),
            ),
            label('Dot-pressure gauge -- semicircular, banded calm/high'),
            AppChartShell(
              title: 'Dot-ball pressure (last over)',
              chartHeight: 140,
              chart: const AppDotPressureGauge(percent: 66),
              tableViewBuilder: (context) => Text(
                '66% dot balls in the last over.',
                style: AppTypography.caption.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ),
            label('Race chart -- horizontal bars, longest first'),
            SizedBox(
              height: 220,
              child: AppChartShell(
                title: 'Run race',
                chartHeight: 180,
                chart: const AppRaceChart(entries: _raceEntries),
                tableViewBuilder: (context) => _table(
                  colors,
                  headers: const ['Player', 'Runs'],
                  rows: [
                    for (final e in _raceEntries)
                      [e.label, e.value.toStringAsFixed(0)],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _table(
    AppColors colors, {
    required List<String> headers,
    required List<List<String>> rows,
  }) {
    return Table(
      key: const ValueKey('chartGalleryDemoTable'),
      children: [
        TableRow(
          children: [
            for (final h in headers)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Text(
                  h,
                  style: AppTypography.caption.copyWith(
                    color: colors.textTertiary,
                  ),
                ),
              ),
          ],
        ),
        for (final row in rows)
          TableRow(
            children: [
              for (final cell in row)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  child: Text(
                    cell,
                    style: AppTypography.caption.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}
