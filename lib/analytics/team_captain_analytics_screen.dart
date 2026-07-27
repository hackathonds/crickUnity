import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_chart_shell.dart';
import '../design_system/components/app_statistics_card.dart';
import '../design_system/components/app_tag_chip.dart' show AppDeltaDirection;
import '../design_system/components/charts/app_race_chart.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'team_captain_analytics_data.dart';
import 'team_captain_analytics_models.dart';
import 'team_captain_analytics_provider.dart';

/// PRD §19 "Captain Analytics" + "Team Analytics" bullets. See
/// team_captain_analytics_models.dart's top-of-file note for the flagged
/// "§19.4-19.6" citation gap and team_captain_analytics_data.dart's note
/// on why the underlying season is a flagged mock dataset.
class TeamCaptainAnalyticsScreen extends ConsumerStatefulWidget {
  const TeamCaptainAnalyticsScreen({super.key});

  @override
  ConsumerState<TeamCaptainAnalyticsScreen> createState() =>
      _TeamCaptainAnalyticsScreenState();
}

class _TeamCaptainAnalyticsScreenState
    extends ConsumerState<TeamCaptainAnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final matches = ref.watch(teamCaptainMatchesProvider);
    final chemistry = ref.watch(chemistryTrendPercentProvider);
    final captain = computeCaptainSnapshot(matches);
    final team = computeTeamSnapshot(matches, chemistry);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Team & captain analytics'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Captain'),
            Tab(text: 'Team'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _CaptainTab(snapshot: captain),
          _TeamTab(snapshot: team),
        ],
      ),
    );
  }
}

Widget _sectionLabel(AppColors colors, String text) => Padding(
  padding: const EdgeInsets.only(bottom: AppSpacing.sm, top: AppSpacing.xxl),
  child: Text(
    text,
    style: AppTypography.label.copyWith(color: colors.textTertiary),
  ),
);

Widget _raceShell({
  required String title,
  required List<AppRaceEntry> entries,
}) {
  if (entries.isEmpty) return const SizedBox.shrink();
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

Widget _stripCard(
  AppColors colors,
  String text, {
  bool isRecommendation = false,
}) {
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

class _CaptainTab extends StatelessWidget {
  final CaptainAnalyticsSnapshot snapshot;

  const _CaptainTab({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        _sectionLabel(colors, 'Toss decision vs outcome'),
        Row(
          children: [
            for (final decision in TossDecision.values)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.md),
                  child: AppStatisticsCard(
                    eyebrowLabel: tossDecisionLabels[decision]!,
                    value:
                        '${snapshot.tossOutcomes[decision]?.winPercent.toStringAsFixed(0) ?? '0'}%',
                  ),
                ),
              ),
          ],
        ),
        _sectionLabel(colors, 'Bowling-change impact'),
        if (snapshot.bowlingChangeImpact == null)
          Text(
            'No captain-initiated bowling changes recorded yet.',
            style: AppTypography.caption.copyWith(color: colors.textSecondary),
          )
        else
          Row(
            children: [
              Expanded(
                child: AppStatisticsCard(
                  eyebrowLabel: 'Economy before',
                  value: snapshot.bowlingChangeImpact!.avgEconomyBefore
                      .toStringAsFixed(1),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: AppStatisticsCard(
                  eyebrowLabel: 'Economy after',
                  value: snapshot.bowlingChangeImpact!.avgEconomyAfter
                      .toStringAsFixed(1),
                  deltaDirection: snapshot.bowlingChangeImpact!.delta > 0
                      ? AppDeltaDirection.up
                      : AppDeltaDirection.down,
                  deltaValue: snapshot.bowlingChangeImpact!.delta
                      .toStringAsFixed(1),
                ),
              ),
            ],
          ),
        _sectionLabel(colors, 'Selection stability'),
        AppStatisticsCard(
          eyebrowLabel: 'Unchanged XI',
          value:
              '${snapshot.selectionStability.percentUnchanged.toStringAsFixed(0)}%',
        ),
        _sectionLabel(colors, 'Win % by lineup cluster'),
        _raceShell(
          title: 'Win % by squad continuity',
          entries: [
            for (final c in snapshot.lineupClusters)
              AppRaceEntry(label: c.label, value: c.winPercent),
          ],
        ),
        _sectionLabel(colors, 'Availability-response health'),
        AppStatisticsCard(
          eyebrowLabel: 'Responded on time',
          value: '${snapshot.availabilityHealth.percent.toStringAsFixed(0)}%',
        ),
        if (snapshot.insights.isNotEmpty) ...[
          _sectionLabel(colors, 'Insights'),
          for (final i in snapshot.insights) _stripCard(colors, i.text),
        ],
        if (snapshot.recommendations.isNotEmpty) ...[
          _sectionLabel(colors, 'Recommendations'),
          for (final r in snapshot.recommendations)
            _stripCard(colors, r.text, isRecommendation: true),
        ],
      ],
    );
  }
}

class _TeamTab extends StatelessWidget {
  final TeamAnalyticsSnapshot snapshot;

  const _TeamTab({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        _sectionLabel(colors, 'Record'),
        Row(
          children: [
            Expanded(
              child: AppStatisticsCard(
                eyebrowLabel: 'Wins',
                value: '${snapshot.wins}',
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: AppStatisticsCard(
                eyebrowLabel: 'Losses',
                value: '${snapshot.losses}',
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: AppStatisticsCard(
                eyebrowLabel: 'Draws',
                value: '${snapshot.draws}',
              ),
            ),
          ],
        ),
        _sectionLabel(colors, 'Win % batting first vs chasing'),
        Row(
          children: [
            Expanded(
              child: AppStatisticsCard(
                eyebrowLabel: 'Batting first',
                value: '${snapshot.winPercentBattingFirst.toStringAsFixed(0)}%',
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: AppStatisticsCard(
                eyebrowLabel: 'Chasing',
                value: '${snapshot.winPercentChasing.toStringAsFixed(0)}%',
              ),
            ),
          ],
        ),
        _sectionLabel(colors, 'Top run-scorer / wicket-taker'),
        Row(
          children: [
            Expanded(
              child: AppStatisticsCard(
                eyebrowLabel: 'Top scorer',
                value: snapshot.topRunScorer,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: AppStatisticsCard(
                eyebrowLabel: 'Top wicket-taker',
                value: snapshot.topWicketTaker,
              ),
            ),
          ],
        ),
        _sectionLabel(colors, 'Margin distribution'),
        _raceShell(
          title: 'Results by margin bucket',
          entries: [
            for (final b in snapshot.marginDistribution)
              AppRaceEntry(label: b.label, value: b.count.toDouble()),
          ],
        ),
        _sectionLabel(colors, 'Collapse frequency'),
        AppStatisticsCard(
          eyebrowLabel: 'Matches with a collapse',
          value: '${snapshot.collapseFrequency.percent.toStringAsFixed(0)}%',
          onInfoTap: () => showDialog<void>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Collapse frequency'),
              content: const Text(
                'No PRD/DS definition exists for "collapse" -- flagged as '
                '3+ wickets falling within a span of 3 overs.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Got it'),
                ),
              ],
            ),
          ),
        ),
        _sectionLabel(colors, 'Ground-wise record'),
        _raceShell(
          title: 'Wins by ground',
          entries: [
            for (final g in snapshot.groundRecords)
              AppRaceEntry(label: g.groundName, value: g.wins.toDouble()),
          ],
        ),
        _sectionLabel(colors, 'Chemistry trend'),
        AppStatisticsCard(
          eyebrowLabel: 'This season',
          value: snapshot.chemistryTrendPercent >= 0
              ? '+${snapshot.chemistryTrendPercent}%'
              : '${snapshot.chemistryTrendPercent}%',
          deltaDirection: snapshot.chemistryTrendPercent >= 0
              ? AppDeltaDirection.up
              : AppDeltaDirection.down,
        ),
        if (snapshot.insights.isNotEmpty) ...[
          _sectionLabel(colors, 'Insights'),
          for (final i in snapshot.insights) _stripCard(colors, i.text),
        ],
        if (snapshot.recommendations.isNotEmpty) ...[
          _sectionLabel(colors, 'Recommendations'),
          for (final r in snapshot.recommendations)
            _stripCard(colors, r.text, isRecommendation: true),
        ],
      ],
    );
  }
}
