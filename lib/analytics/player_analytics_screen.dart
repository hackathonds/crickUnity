import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_chart_shell.dart';
import '../design_system/components/app_segmented_control.dart';
import '../design_system/components/app_statistics_card.dart';
import '../design_system/components/app_tag_chip.dart' show AppDeltaDirection;
import '../design_system/components/charts/app_race_chart.dart';
import '../design_system/components/charts/app_worm_chart.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import '../onboarding/profile_wizard_provider.dart' show BattingStyle;
import 'player_analytics_data.dart';
import 'player_analytics_models.dart';
import 'player_analytics_provider.dart';

/// PRD §19 (Analytics, "Player Analytics" bullet): full metric
/// dictionary -- batting phase-wise SR, dismissal patterns, vs
/// pace/spin, entry-point analysis; bowling phase economy, lengths
/// proxy via outcome mix, vs LHB/RHB; fielding contributions, form
/// index, fatigue signal, availability-vs-performance correlation --
/// plus the shared analytics-surface elements every surface gets: time
/// filters, compare-to, export share-card, Insights + Recommendations
/// strips. See player_analytics_models.dart's top-of-file note for the
/// flagged "§19.3" citation gap and player_analytics_data.dart's note on
/// why the underlying dataset is a flagged mock career (no persisted
/// cross-match history store exists elsewhere in the app).
class PlayerAnalyticsScreen extends ConsumerStatefulWidget {
  const PlayerAnalyticsScreen({super.key});

  @override
  ConsumerState<PlayerAnalyticsScreen> createState() =>
      _PlayerAnalyticsScreenState();
}

class _PlayerAnalyticsScreenState extends ConsumerState<PlayerAnalyticsScreen> {
  AnalyticsTimeFilter _filter = AnalyticsTimeFilter.season;
  AnalyticsCompareTo _compareTo = AnalyticsCompareTo.teamAvg;

  void _share(PlayerAnalyticsSnapshot snapshot, double avgRuns) {
    final lines = [
      'My CricUnity Player Analytics (${analyticsTimeFilterLabels[_filter]})',
      'Runs/innings: ${avgRuns.toStringAsFixed(1)}',
      for (final i in snapshot.insights) i.text,
    ];
    Clipboard.setData(ClipboardData(text: lines.join('\n')));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Analytics share-card copied')),
    );
  }

  void _showDefinition(String title, String body) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final now = DateTime.now();
    final allMatches = ref.watch(playerAnalyticsMatchesProvider);
    final scoped = matchesInScope(allMatches, _filter, now);
    final snapshot = computeSnapshot(scoped);

    final avgRuns = scoped.isEmpty
        ? 0.0
        : scoped.fold(0, (a, m) => a + m.runsScored) / scoped.length;
    final compareValue = switch (_compareTo) {
      AnalyticsCompareTo.teamAvg =>
        scoped.isEmpty
            ? 0.0
            : scoped.fold(0.0, (a, m) => a + m.teamAvgRuns) / scoped.length,
      AnalyticsCompareTo.cityAvg =>
        scoped.isEmpty
            ? 0.0
            : scoped.fold(0.0, (a, m) => a + m.cityAvgRuns) / scoped.length,
      AnalyticsCompareTo.selfPast => () {
        final past = allMatches.skip(scoped.length).toList();
        return past.isEmpty
            ? 0.0
            : past.fold(0, (a, m) => a + m.runsScored) / past.length;
      }(),
    };

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Player analytics'),
        actions: [
          IconButton(
            key: const ValueKey('playerAnalyticsShareButton'),
            icon: const Icon(Icons.share),
            onPressed: () => _share(snapshot, avgRuns),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          AppSegmentedControl<AnalyticsTimeFilter>(
            options: AnalyticsTimeFilter.values,
            value: _filter,
            onChanged: (v) => setState(() => _filter = v),
            labelBuilder: (v) => analyticsTimeFilterLabels[v]!,
          ),
          const SizedBox(height: AppSpacing.sm),
          AppSegmentedControl<AnalyticsCompareTo>(
            options: AnalyticsCompareTo.values,
            value: _compareTo,
            onChanged: (v) => setState(() => _compareTo = v),
            labelBuilder: (v) => analyticsCompareToLabels[v]!,
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: AppStatisticsCard(
                  key: const ValueKey('statRunsPerInnings'),
                  eyebrowLabel: 'Runs/innings',
                  value: avgRuns.toStringAsFixed(1),
                  deltaDirection: avgRuns >= compareValue
                      ? AppDeltaDirection.up
                      : AppDeltaDirection.down,
                  deltaValue: (avgRuns - compareValue).toStringAsFixed(1),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: AppStatisticsCard(
                  eyebrowLabel: analyticsCompareToLabels[_compareTo]!,
                  value: compareValue.toStringAsFixed(1),
                ),
              ),
            ],
          ),
          if (scoped.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xxl),
              child: Text(
                'No matches in this window yet.',
                style: AppTypography.body.copyWith(color: colors.textSecondary),
              ),
            )
          else ...[
            sectionLabel('Batting -- phase-wise strike rate'),
            _raceShell(
              title: 'Strike rate by phase',
              entries: [
                for (final phase in MatchPhase.values)
                  AppRaceEntry(
                    label: matchPhaseLabels[phase]!,
                    value: snapshot.battingPhaseSplits[phase]?.strikeRate ?? 0,
                  ),
              ],
            ),
            sectionLabel('Dismissal patterns'),
            if (snapshot.dismissalPatterns.isEmpty)
              Text(
                'No dismissals in this window.',
                style: AppTypography.caption.copyWith(
                  color: colors.textSecondary,
                ),
              )
            else
              _raceShell(
                title: 'Dismissal type',
                entries: [
                  for (final entry in snapshot.dismissalPatterns)
                    AppRaceEntry(
                      label: entry.label,
                      value: entry.count.toDouble(),
                    ),
                ],
              ),
            sectionLabel('vs pace / spin'),
            Row(
              children: [
                Expanded(
                  child: AppStatisticsCard(
                    eyebrowLabel: 'SR vs pace',
                    value:
                        (snapshot.vsBowlerType[BowlerType.pace]?.strikeRate ??
                                0)
                            .toStringAsFixed(0),
                    onInfoTap: () => _showDefinition(
                      'vs pace / spin',
                      'No bowler pace/spin classification exists in the '
                          'scorer console yet -- this is a flagged mock split.',
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: AppStatisticsCard(
                    eyebrowLabel: 'SR vs spin',
                    value:
                        (snapshot.vsBowlerType[BowlerType.spin]?.strikeRate ??
                                0)
                            .toStringAsFixed(0),
                  ),
                ),
              ],
            ),
            sectionLabel('Entry-point analysis'),
            _raceShell(
              title: 'Average by batting position',
              entries: [
                for (final e in snapshot.entryPointStats)
                  AppRaceEntry(
                    label: '#${e.battingPosition}',
                    value: e.average,
                  ),
              ],
            ),
            sectionLabel('Bowling -- phase economy'),
            _raceShell(
              title: 'Economy by phase (lower is better)',
              entries: [
                for (final phase in MatchPhase.values)
                  AppRaceEntry(
                    label: matchPhaseLabels[phase]!,
                    value: snapshot.bowlingPhaseEconomy[phase]?.economy ?? 0,
                  ),
              ],
            ),
            sectionLabel('Lengths proxy (bowling outcome mix)'),
            Row(
              children: [
                for (final proxy in DeliveryLengthProxy.values)
                  Expanded(
                    child: AppStatisticsCard(
                      eyebrowLabel: deliveryLengthProxyLabels[proxy]!,
                      value: '${snapshot.lengthsProxyMix[proxy] ?? 0}',
                      onInfoTap: proxy == DeliveryLengthProxy.good
                          ? () => _showDefinition(
                              'Lengths proxy',
                              'No real pitch-map/length data is captured by '
                                  'the scorer console -- this buckets each ball '
                                  'by its scoring outcome (dot/wicket = good, '
                                  '1-3 = short, 4+ = full) as a proxy.',
                            )
                          : null,
                    ),
                  ),
              ],
            ),
            sectionLabel('vs LHB / RHB'),
            Row(
              children: [
                Expanded(
                  child: AppStatisticsCard(
                    eyebrowLabel: 'Econ vs RHB',
                    value:
                        (snapshot.vsBattingStyle[BattingStyle.rhb]?.economy ??
                                0)
                            .toStringAsFixed(1),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: AppStatisticsCard(
                    eyebrowLabel: 'Econ vs LHB',
                    value:
                        (snapshot.vsBattingStyle[BattingStyle.lhb]?.economy ??
                                0)
                            .toStringAsFixed(1),
                  ),
                ),
              ],
            ),
            sectionLabel('Fielding contributions'),
            Row(
              children: [
                Expanded(
                  child: AppStatisticsCard(
                    eyebrowLabel: 'Catches',
                    value: '${snapshot.fielding.catches}',
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: AppStatisticsCard(
                    eyebrowLabel: 'Run-outs',
                    value: '${snapshot.fielding.runOuts}',
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: AppStatisticsCard(
                    eyebrowLabel: 'Stumpings',
                    value: '${snapshot.fielding.stumpings}',
                  ),
                ),
              ],
            ),
            sectionLabel('Form index'),
            AppChartShell(
              title: 'Form index by match',
              chartHeight: 160,
              chart: AppWormChart(
                values: [for (final p in snapshot.formIndexSeries) p.index],
                maxY: snapshot.formIndexSeries.isEmpty
                    ? 100
                    : snapshot.formIndexSeries
                              .map((p) => p.index)
                              .reduce((a, b) => a > b ? a : b) *
                          1.2,
              ),
              onScrub: (fraction) {
                if (snapshot.formIndexSeries.isEmpty) return null;
                final i = (fraction * (snapshot.formIndexSeries.length - 1))
                    .round();
                final p = snapshot.formIndexSeries[i];
                return AppChartScrubValue(
                  '${p.matchLabel}: ${p.index.toStringAsFixed(0)}',
                );
              },
              tableViewBuilder: (context) => Column(
                children: [
                  for (final p in snapshot.formIndexSeries)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.xs,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              p.matchLabel,
                              style: AppTypography.caption.copyWith(
                                color: colors.textSecondary,
                              ),
                            ),
                          ),
                          Text(
                            p.index.toStringAsFixed(0),
                            style: AppTypography.caption.copyWith(
                              color: colors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            sectionLabel('Fatigue signal'),
            AppStatisticsCard(
              eyebrowLabel: 'Games this week',
              value: '${snapshot.fatigue.gamesThisWeek}',
            ),
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(
                snapshot.fatigue.caption,
                style: AppTypography.caption.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ),
            sectionLabel('Availability vs performance'),
            Row(
              children: [
                Expanded(
                  child: AppStatisticsCard(
                    eyebrowLabel: 'Avg runs -- responded early',
                    value: snapshot
                        .availabilityCorrelation
                        .avgRunsWhenRespondedEarly
                        .toStringAsFixed(1),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: AppStatisticsCard(
                    eyebrowLabel: 'Avg runs -- responded late',
                    value: snapshot
                        .availabilityCorrelation
                        .avgRunsWhenRespondedLate
                        .toStringAsFixed(1),
                  ),
                ),
              ],
            ),
            if (snapshot.insights.isNotEmpty) ...[
              sectionLabel('Insights'),
              for (final insight in snapshot.insights)
                _StripCard(text: insight.text, colors: colors),
            ],
            if (snapshot.recommendations.isNotEmpty) ...[
              sectionLabel('Recommendations'),
              for (final rec in snapshot.recommendations)
                _StripCard(
                  text: rec.text,
                  colors: colors,
                  isRecommendation: true,
                ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _raceShell({
    required String title,
    required List<AppRaceEntry> entries,
  }) {
    return SizedBox(
      height: 76 + entries.length * 40.0,
      child: AppChartShell(
        title: title,
        chartHeight: entries.length * 40.0,
        chart: AppRaceChart(entries: entries),
        tableViewBuilder: (context) => Column(
          children: [
            for (final e in entries)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Row(
                  children: [
                    Expanded(child: Text(e.label)),
                    Text(e.value.toStringAsFixed(1)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StripCard extends StatelessWidget {
  final String text;
  final AppColors colors;
  final bool isRecommendation;

  const _StripCard({
    required this.text,
    required this.colors,
    this.isRecommendation = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            isRecommendation ? Icons.lightbulb_outline : Icons.insights,
            size: 18,
            color: colors.textSecondary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: AppTypography.body.copyWith(color: colors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
