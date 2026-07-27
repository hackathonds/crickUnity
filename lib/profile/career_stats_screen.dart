import 'package:flutter/material.dart';

import '../analytics/player_analytics_data.dart' show mockCareerMatches;
import '../design_system/components/app_chart_shell.dart';
import '../design_system/components/charts/app_manhattan_chart.dart';
import '../design_system/components/charts/app_pie_chart.dart';
import '../design_system/components/charts/app_scatter_chart.dart';
import '../design_system/components/charts/app_wagon_wheel_chart.dart';
import '../design_system/components/charts/app_worm_chart.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import '../matches/scoring_models.dart' show WagonSector, wagonSectorLabels;
import '../teams/team_models.dart' show TeamFormat;
import 'career_stats_data.dart';
import 'career_stats_models.dart';
import 'profile_models.dart' show ViewerRelation;

const Map<TeamFormat, String> _formatLabels = {
  TeamFormat.t10: 'T10',
  TeamFormat.t20: 'T20',
  TeamFormat.thirtyOver: '30-over',
  TeamFormat.testStyle: 'Test-style',
};

/// PRD §5.3 (Career Statistics) + §5.7 (Performance Charts). E2-03
/// (depends on E0-08, E13-01) -- profile_screen.dart's Stats tab
/// previously rendered a placeholder noting exactly this dependency;
/// this is that story, now that both are built. Embeddable content (not
/// its own Scaffold) since it renders inside ProfileScreen's TabBarView.
class CareerStatsTabBody extends StatefulWidget {
  final ViewerRelation viewerRelation;

  const CareerStatsTabBody({super.key, required this.viewerRelation});

  @override
  State<CareerStatsTabBody> createState() => _CareerStatsTabBodyState();
}

class _CareerStatsTabBodyState extends State<CareerStatsTabBody> {
  TeamFormat? _format;
  StatVerifiedFilter _verifiedFilter = StatVerifiedFilter.verified;

  void _showSourceList(String title, List<StatSourceEntry> entries) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        final colors = Theme.of(context).extension<AppColors>()!;
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          expand: false,
          builder: (context, controller) => ListView(
            controller: controller,
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Text(
                title,
                style: AppTypography.title.copyWith(color: colors.textPrimary),
              ),
              const SizedBox(height: AppSpacing.md),
              for (final entry in entries)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          entry.matchLabel,
                          style: AppTypography.body.copyWith(
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                      if (entry.isPreApp)
                        Padding(
                          padding: const EdgeInsets.only(right: AppSpacing.sm),
                          child: Text(
                            'Self-reported',
                            style: AppTypography.caption.copyWith(
                              color: colors.textTertiary,
                            ),
                          ),
                        ),
                      Text(
                        entry.detail,
                        style: AppTypography.body.copyWith(
                          color: colors.textSecondary,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final allMatches = mockCareerMatches(DateTime.now());
    final snapshot = computeCareerStats(
      allMatches,
      format: _format,
      verifiedFilter: _verifiedFilter,
    );
    final rankingEligible = allMatches.where((m) => !m.isPreApp).toList();
    final preAppCount = allMatches.length - rankingEligible.length;

    Widget sectionLabel(String text) => Padding(
      padding: const EdgeInsets.only(
        bottom: AppSpacing.sm,
        top: AppSpacing.xxl,
      ),
      child: Text(
        text,
        style: AppTypography.label.copyWith(color: colors.textTertiary),
      ),
    );

    Widget statRow(String label, String value, {VoidCallback? onTap}) {
      return InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.body.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ),
              Text(
                value,
                style: AppTypography.body.copyWith(
                  color: colors.textPrimary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              ChoiceChip(
                key: const ValueKey('formatChip_all'),
                label: const Text('All formats'),
                selected: _format == null,
                onSelected: (_) => setState(() => _format = null),
              ),
              for (final format in TeamFormat.values)
                ChoiceChip(
                  key: ValueKey('formatChip_${format.name}'),
                  label: Text(_formatLabels[format]!),
                  selected: _format == format,
                  onSelected: (_) => setState(() => _format = format),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              for (final filter in StatVerifiedFilter.values)
                ChoiceChip(
                  key: ValueKey('verifiedFilterChip_${filter.name}'),
                  label: Text(statVerifiedFilterLabels[filter]!),
                  selected: _verifiedFilter == filter,
                  onSelected: (_) => setState(() => _verifiedFilter = filter),
                ),
            ],
          ),
          if (preAppCount > 0)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Text(
                '$preAppCount self-reported pre-app ${preAppCount == 1 ? 'entry' : 'entries'} '
                'excluded from these stats and from rankings.',
                style: AppTypography.caption.copyWith(
                  color: colors.textTertiary,
                ),
              ),
            ),
          sectionLabel('Batting'),
          statRow('Matches', '${snapshot.batting.matches}'),
          statRow('Innings', '${snapshot.batting.innings}'),
          statRow(
            'Runs',
            '${snapshot.batting.runs}',
            onTap: () => _showSourceList('Runs', battingSourceList(allMatches)),
          ),
          statRow(
            'HS',
            '${snapshot.batting.highestScore}${snapshot.batting.highestScoreNotOut ? '*' : ''}',
          ),
          statRow('Avg', snapshot.batting.average.toStringAsFixed(1)),
          statRow('SR', snapshot.batting.strikeRate.toStringAsFixed(1)),
          statRow('50s', '${snapshot.batting.fifties}'),
          statRow('100s', '${snapshot.batting.hundreds}'),
          statRow('4s', '${snapshot.batting.fours}'),
          statRow('6s', '${snapshot.batting.sixes}'),
          statRow('Ducks', '${snapshot.batting.ducks}'),
          statRow('Not-outs', '${snapshot.batting.notOuts}'),
          sectionLabel('Bowling'),
          statRow('Overs', snapshot.bowling.overs.toStringAsFixed(1)),
          statRow(
            'Wickets',
            '${snapshot.bowling.wickets}',
            onTap: () =>
                _showSourceList('Wickets', bowlingSourceList(allMatches)),
          ),
          statRow('Best', snapshot.bowling.bestFigures),
          statRow('Avg', snapshot.bowling.average.toStringAsFixed(1)),
          statRow('Econ', snapshot.bowling.economy.toStringAsFixed(2)),
          statRow('SR', snapshot.bowling.strikeRate.toStringAsFixed(1)),
          statRow('3W', '${snapshot.bowling.threeWicketHauls}'),
          statRow('5W', '${snapshot.bowling.fiveWicketHauls}'),
          statRow('Maidens', '${snapshot.bowling.maidens}'),
          statRow('Dots%', snapshot.bowling.dotBallPercent.toStringAsFixed(0)),
          sectionLabel('Fielding'),
          statRow('Catches', '${snapshot.fielding.catches}'),
          statRow('Run-outs', '${snapshot.fielding.runOuts}'),
          statRow('Stumpings', '${snapshot.fielding.stumpings}'),
          sectionLabel('Runs & wickets by match'),
          AppChartShell(
            title: 'Last 10 matches',
            chart: AppManhattanChart(
              perOver: runsWicketsByMatch(rankingEligible),
            ),
            tableViewBuilder: (context) => Text(
              'Table view -- see Custom Stats Explorer for a full sortable list.',
              style: AppTypography.caption.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ),
          sectionLabel('Form curve'),
          AppChartShell(
            title: 'Runs per match',
            chart: AppWormChart(
              values: formCurve(rankingEligible),
              maxY: rankingEligible.isEmpty
                  ? 100
                  : rankingEligible
                            .map((m) => m.runsScored)
                            .reduce((a, b) => a > b ? a : b) *
                        1.2,
            ),
            tableViewBuilder: (context) => Text(
              'Table view -- see Custom Stats Explorer for a full sortable list.',
              style: AppTypography.caption.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ),
          sectionLabel('Dismissal types'),
          AppChartShell(
            chartHeight: 200,
            title: 'Dismissal-type breakdown',
            chart: AppPieChart(slices: dismissalPie(rankingEligible, colors)),
            tableViewBuilder: (context) => Column(
              children: [
                for (final slice in dismissalPie(rankingEligible, colors))
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xs,
                    ),
                    child: Row(
                      children: [
                        Container(width: 8, height: 8, color: slice.color),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(child: Text(slice.label)),
                        Text(slice.value.toStringAsFixed(0)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          if (widget.viewerRelation == ViewerRelation.self ||
              widget.viewerRelation == ViewerRelation.teammate) ...[
            sectionLabel('SR vs Avg per bowling type faced'),
            AppChartShell(
              chartHeight: 200,
              title: 'vs pace / vs spin',
              chart: AppScatterChart(
                points: srAvgScatterByBowlerType(rankingEligible),
                maxX: 200,
                maxY: 80,
                xAxisLabel: 'Strike rate',
                yAxisLabel: 'Average',
              ),
              tableViewBuilder: (context) => Column(
                children: [
                  for (final point in srAvgScatterByBowlerType(rankingEligible))
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.xs,
                      ),
                      child: Row(
                        children: [
                          Expanded(child: Text(point.label)),
                          Text(
                            'SR ${point.x.toStringAsFixed(0)} / '
                            'Avg ${point.y.toStringAsFixed(1)}',
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ] else
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xxl),
              child: Text(
                'Detailed opposition splits are visible to Self + Teammates.',
                style: AppTypography.caption.copyWith(
                  color: colors.textTertiary,
                ),
              ),
            ),
          sectionLabel('Scoring zones'),
          AppChartShell(
            chartHeight: 240,
            title: 'Scoring-zone aggregate (approximated -- see note)',
            chart: AppWagonWheelChart(
              shots: [
                for (final entry in approximateWagonAggregate(
                  rankingEligible,
                ).entries)
                  for (var i = 0; i < entry.value; i++)
                    AppWagonShot(
                      sectorIndex: WagonSector.values.indexOf(entry.key),
                      runs: 4,
                    ),
              ],
            ),
            tableViewBuilder: (context) => Column(
              children: [
                for (final entry in approximateWagonAggregate(
                  rankingEligible,
                ).entries)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xs,
                    ),
                    child: Row(
                      children: [
                        Expanded(child: Text(wagonSectorLabels[entry.key]!)),
                        Text('${entry.value}'),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text(
              'No shot-direction logging exists in this career history -- '
              'zones are approximated from boundary counts, not real wagon '
              'data.',
              style: AppTypography.caption.copyWith(color: colors.textTertiary),
            ),
          ),
        ],
      ),
    );
  }
}
