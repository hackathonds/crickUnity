import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_chart_shell.dart';
import '../design_system/components/app_statistics_card.dart';
import '../design_system/components/charts/app_race_chart.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import '../expenses/expenses_provider.dart';
import '../expenses/reports_models.dart' show ReportPeriod, totalSpentFor;
import '../expenses/reports_screen.dart';
import '../grounds/owner_console_screen.dart';
import '../rewards/missions_models.dart';
import '../rewards/missions_provider.dart';
import '../rewards/rewards_models.dart' show coinsExpiringWithin;
import '../rewards/rewards_provider.dart';
import '../social/composer_screen.dart' show composerViewerName;
import '../social/feed_models.dart' show attachedObjectTypeLabels;
import '../social/feed_provider.dart';
import 'attendance_analytics_models.dart';

/// PRD §19 "Ground Analytics"/"Expense Analytics"/"Social Analytics"/
/// "Rewards Analytics (self)"/"Attendance Analytics" bullets. Backlog:
/// "E13-05 Entity analytics (ground/expense/social/rewards/attendance)
/// -- composition of existing cards" -- Ground (§10.6) and Expense
/// (§11.9) analytics already ship in full as the Owner Console
/// (E9/E10) and Expense Reports (E11) screens, so this hub composes
/// (links to) those rather than duplicating their computation, and adds
/// genuinely new lightweight sections for Social/Rewards-self/
/// Attendance, which had no analytics surface anywhere yet.
class EntityAnalyticsScreen extends ConsumerWidget {
  const EntityAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;

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
      appBar: AppBar(title: const Text('Entity analytics')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          sectionLabel('Ground (owner)'),
          _LinkOutCard(
            title: 'Occupancy, revenue, demand curve, review facets',
            buttonLabel: 'Open Ground Owner Console',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    const OwnerConsoleScreen(groundId: 'ground-green-valley'),
              ),
            ),
          ),
          sectionLabel('Expense'),
          const _ExpenseSection(),
          sectionLabel('Social'),
          const _SocialSection(),
          sectionLabel('Rewards (self)'),
          const _RewardsSection(),
          sectionLabel('Attendance'),
          const _AttendanceSection(),
        ],
      ),
    );
  }
}

class _LinkOutCard extends StatelessWidget {
  final String title;
  final String buttonLabel;
  final VoidCallback onTap;

  const _LinkOutCard({
    required this.title,
    required this.buttonLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.body.copyWith(color: colors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton(onPressed: onTap, child: Text(buttonLabel)),
        ],
      ),
    );
  }
}

class _ExpenseSection extends ConsumerWidget {
  const _ExpenseSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expenses = ref.watch(expensesProvider).expenses;
    final monthTotal = totalSpentFor(
      composerViewerName,
      expenses,
      ReportPeriod.thisMonth,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: AppStatisticsCard(
                eyebrowLabel: 'This month',
                value: '₹$monthTotal',
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: AppStatisticsCard(
                eyebrowLabel: 'Tracked expenses',
                value: '${expenses.length}',
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        _LinkOutCard(
          title: 'Monthly/yearly reports, category donut, settlement speed',
          buttonLabel: 'Open Expense Reports',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const ReportsScreen(
                viewerName: composerViewerName,
                viewerIsCaptain: true,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SocialSection extends ConsumerWidget {
  const _SocialSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final posts = ref
        .watch(feedProvider)
        .posts
        .where((p) => p.authorName == composerViewerName && p.deletedAt == null)
        .toList();

    if (posts.isEmpty) {
      return Text(
        'No posts yet -- share something to see engagement analytics.',
        style: AppTypography.body.copyWith(color: colors.textSecondary),
      );
    }

    final engagementByType = <String, int>{};
    for (final post in posts) {
      final label = post.attachedObject == null
          ? 'Text only'
          : attachedObjectTypeLabels[post.attachedObject!.type]!;
      engagementByType[label] =
          (engagementByType[label] ?? 0) +
          post.totalReactionCount +
          post.mediaCount;
    }

    // PRD: "best posting windows." No PRD/DS bucket scheme is given --
    // flagged judgment call: the four dayparts commentary/UX commonly
    // use.
    String daypartFor(int hour) {
      if (hour < 6) return 'Late night';
      if (hour < 12) return 'Morning';
      if (hour < 18) return 'Afternoon';
      return 'Evening';
    }

    final engagementByDaypart = <String, int>{};
    for (final post in posts) {
      final part = daypartFor(post.timestamp.hour);
      engagementByDaypart[part] =
          (engagementByDaypart[part] ?? 0) + post.totalReactionCount;
    }
    final bestDaypart = engagementByDaypart.entries.isEmpty
        ? null
        : engagementByDaypart.entries.reduce(
            (a, b) => a.value >= b.value ? a : b,
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 76 + engagementByType.length * 40.0,
          child: AppChartShell(
            title: 'Reach & engagement by content type',
            chartHeight: engagementByType.length * 40.0,
            chart: AppRaceChart(
              entries: [
                for (final entry in engagementByType.entries)
                  AppRaceEntry(label: entry.key, value: entry.value.toDouble()),
              ],
            ),
            tableViewBuilder: (context) => Column(
              children: [
                for (final entry in engagementByType.entries)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xs,
                    ),
                    child: Row(
                      children: [
                        Expanded(child: Text(entry.key)),
                        Text('${entry.value}'),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (bestDaypart != null) ...[
          const SizedBox(height: AppSpacing.sm),
          AppStatisticsCard(
            eyebrowLabel: 'Best posting window',
            value: bestDaypart.key,
          ),
        ],
      ],
    );
  }
}

class _RewardsSection extends ConsumerWidget {
  const _RewardsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coinBatches = ref.watch(rewardsProvider).coinBatches;
    final earned = coinBatches.fold(0, (a, b) => a + b.amount);
    final spent = coinBatches.fold(0, (a, b) => a + (b.amount - b.remaining));
    final expiringSoon = coinsExpiringWithin(coinBatches, 30);

    final missions = ref.watch(missionsProvider);
    var totalMissions = 0;
    var claimedMissions = 0;
    for (final tier in MissionTier.values) {
      final instances = missions.instancesFor(tier);
      totalMissions += instances.length;
      claimedMissions += instances.where((i) => i.claimed).length;
    }
    final completionRate = totalMissions == 0
        ? 0.0
        : 100 * claimedMissions / totalMissions;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: AppStatisticsCard(
                eyebrowLabel: 'Coins earned',
                value: '$earned',
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: AppStatisticsCard(
                eyebrowLabel: 'Coins spent',
                value: '$spent',
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: AppStatisticsCard(
                eyebrowLabel: 'Expiring in 30d',
                value: '$expiringSoon',
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: AppStatisticsCard(
                eyebrowLabel: 'Mission completion',
                value: '${completionRate.toStringAsFixed(0)}%',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AttendanceSection extends StatelessWidget {
  const _AttendanceSection();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final records = mockAttendance(DateTime.now());
    final individualRate = 100 - noShowRate(records);
    final nearRate = 100 - noShowRateWithinDistance(records, beyond15km: false);
    final farRate = 100 - noShowRateWithinDistance(records, beyond15km: true);
    final byWeekday = noShowRateByWeekday(records);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 76 + byWeekday.length * 40.0,
          child: AppChartShell(
            title: 'No-show % by weekday',
            chartHeight: byWeekday.length * 40.0,
            chart: AppRaceChart(
              entries: [
                for (final entry in byWeekday.entries)
                  AppRaceEntry(
                    label: weekdayLabels[entry.key - 1],
                    value: entry.value,
                  ),
              ],
            ),
            tableViewBuilder: (context) => Column(
              children: [
                for (final entry in byWeekday.entries)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xs,
                    ),
                    child: Row(
                      children: [
                        Expanded(child: Text(weekdayLabels[entry.key - 1])),
                        Text('${entry.value.toStringAsFixed(0)}%'),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: AppStatisticsCard(
                eyebrowLabel: 'Attendance rate',
                value: '${individualRate.toStringAsFixed(0)}%',
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: AppStatisticsCard(
                eyebrowLabel: '≤15 km grounds',
                value: '${nearRate.toStringAsFixed(0)}%',
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: AppStatisticsCard(
                eyebrowLabel: '>15 km grounds',
                value: '${farRate.toStringAsFixed(0)}%',
              ),
            ),
          ],
        ),
        if (farRate < nearRate)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.md),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: colors.surfaceAlt,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(Icons.insights, size: 18, color: colors.textSecondary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'No-shows spike when ground >15 km -- pick closer '
                      'grounds?',
                      style: AppTypography.body.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
