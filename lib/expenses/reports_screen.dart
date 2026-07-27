import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_button.dart';
import '../design_system/components/app_segmented_control.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'expense_models.dart';
import 'expenses_provider.dart';
import 'reports_models.dart';
import 'settlement_models.dart';
import 'settlements_provider.dart';

const Map<ReportPeriod, String> _periodLabels = {
  ReportPeriod.thisMonth: 'This month',
  ReportPeriod.thisYear: 'This year',
};

const List<String> _monthNames = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// DS §7-52 (Reports): "period segmented -> donut by category ->
/// trendline -> insight cards -> [Export statement]." PRD §11.9.
class ReportsScreen extends ConsumerStatefulWidget {
  final String viewerName;
  final bool viewerIsCaptain;

  const ReportsScreen({
    super.key,
    required this.viewerName,
    required this.viewerIsCaptain,
  });

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  ReportPeriod _period = ReportPeriod.thisMonth;
  bool _autoStatementEnabled = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final expenses = ref
        .watch(expensesProvider)
        .expenses
        .where((e) => !e.isDeleted)
        .toList();
    final settlements = ref.watch(settlementsProvider).settlements;

    final periodTotal = totalSpentFor(widget.viewerName, expenses, _period);
    final breakdown = categoryBreakdown(expenses, _period);
    final maxCategoryAmount = breakdown.isEmpty
        ? 1
        : breakdown.map((c) => c.amount).reduce((a, b) => a > b ? a : b);
    final trend = monthlyTrend(expenses);
    final counterparty = topCounterparty(widget.viewerName, expenses);
    final settlementSpeed = averageSettlementSpeedDays(settlements);

    final allParticipants = <String>{
      for (final e in expenses) ...[
        for (final p in e.paidBy) p.name,
        for (final s in e.splitAmong) s.name,
      ],
    };
    final teamComparison = teamAverageComparisonPercent(
      widget.viewerName,
      expenses,
      allParticipants,
    );
    final netBalances = netBalancesByPerson(
      expenses,
      settlements,
      allParticipants,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          AppSegmentedControl<ReportPeriod>(
            key: const ValueKey('reportPeriodControl'),
            options: ReportPeriod.values,
            value: _period,
            onChanged: (v) => setState(() => _period = v),
            labelBuilder: (v) => _periodLabels[v]!,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Your spend (${_periodLabels[_period]!.toLowerCase()})',
            style: AppTypography.label.copyWith(color: colors.textTertiary),
          ),
          Text(
            key: const ValueKey('periodTotalText'),
            '₹$periodTotal',
            style: AppTypography.display.copyWith(color: colors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            'By category',
            style: AppTypography.label.copyWith(color: colors.textTertiary),
          ),
          const SizedBox(height: AppSpacing.xs),
          if (breakdown.isEmpty)
            Text(
              'No expenses this period.',
              style: AppTypography.body.copyWith(color: colors.textSecondary),
            )
          else
            for (final c in breakdown)
              Padding(
                key: ValueKey('categoryBar_${c.category.name}'),
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            expenseCategoryLabels[c.category]!,
                            style: AppTypography.body.copyWith(
                              color: colors.textPrimary,
                            ),
                          ),
                        ),
                        Text(
                          '₹${c.amount}',
                          style: AppTypography.stat.copyWith(
                            color: colors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs / 2),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: c.amount / maxCategoryAmount,
                        minHeight: 6,
                        backgroundColor: colors.border,
                        color: colors.primary,
                      ),
                    ),
                  ],
                ),
              ),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            'Trend',
            style: AppTypography.label.copyWith(color: colors.textTertiary),
          ),
          const SizedBox(height: AppSpacing.xs),
          if (trend.isEmpty)
            Text(
              'No history yet.',
              style: AppTypography.body.copyWith(color: colors.textSecondary),
            )
          else
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                for (final t in trend)
                  Text(
                    '${_monthNames[t.month - 1]} ${t.year}: ₹${t.amount}',
                    style: AppTypography.caption.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
              ],
            ),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            'Insights',
            style: AppTypography.label.copyWith(color: colors.textTertiary),
          ),
          const SizedBox(height: AppSpacing.xs),
          if (teamComparison != null)
            _insightCard(
              colors,
              key: 'teamComparisonInsight',
              text: teamComparison <= 0
                  ? 'Your cricket costs are ${teamComparison.abs().round()}% '
                        'below the team average.'
                  : 'Your cricket costs are ${teamComparison.round()}% above '
                        'the team average.',
            ),
          if (counterparty != null)
            _insightCard(
              colors,
              key: 'topCounterpartyInsight',
              text: 'Your top counterparty is $counterparty.',
            ),
          if (settlementSpeed != null)
            _insightCard(
              colors,
              key: 'settlementSpeedInsight',
              text:
                  'Settlements confirm in ${settlementSpeed.toStringAsFixed(1)} '
                  'days on average.',
            ),
          if (widget.viewerIsCaptain)
            _insightCard(
              colors,
              key: 'pendingDuesConcentrationInsight',
              text: pendingDuesConcentration(netBalances),
            ),
          const SizedBox(height: AppSpacing.xxl),
          Row(
            children: [
              Switch(
                key: const ValueKey('autoStatementSwitch'),
                value: _autoStatementEnabled,
                onChanged: (v) => setState(() => _autoStatementEnabled = v),
              ),
              Expanded(
                child: Text(
                  'Monthly auto-statement (no email delivery exists yet)',
                  style: AppTypography.body.copyWith(color: colors.textPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            key: const ValueKey('exportStatementButton'),
            variant: AppButtonVariant.primary,
            label: 'Export statement (CSV)',
            fullWidth: true,
            onPressed: () {
              Clipboard.setData(
                ClipboardData(text: generateCsvStatement(expenses)),
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('CSV statement copied')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _insightCard(
    AppColors colors, {
    required String key,
    required String text,
  }) {
    return Container(
      key: ValueKey(key),
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        text,
        style: AppTypography.body.copyWith(color: colors.textPrimary),
      ),
    );
  }
}
