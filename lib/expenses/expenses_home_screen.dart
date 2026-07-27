import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_bottom_sheet.dart';
import '../design_system/components/app_button.dart';
import '../design_system/components/app_expense_card.dart';
import '../design_system/components/app_tag_chip.dart';
import '../design_system/components/app_text_field.dart';
import '../design_system/icons/app_icon_id.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_money_text.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import '../matches/matches_provider.dart';
import 'add_edit_expense_screen.dart';
import 'expense_detail_screen.dart';
import 'expense_models.dart';
import 'expenses_provider.dart';
import 'reminders_provider.dart';
import 'settle_up_screen.dart';
import 'settlement_models.dart';
import 'settlements_provider.dart';

enum _ExpensesTab { iOwe, owed, all }

/// DS §7-48 (Expenses Home): "Net header Display ('You're owed ₹450')
/// -> tabs I-owe/Owed/All -> rows §3.2.6 -> {Add} FAB-less: sticky
/// [Add expense]. All-square state: calm tick illustration." The net
/// header here stays a flat viewer-level total across every expense --
/// the "3 payments instead of 7" per-counterparty netting graph lives
/// in [SettleUpScreen] (E5-04), reached via the Settle Up button below.
/// Also surfaces incoming settlement requests awaiting this viewer's
/// confirm/decline (PRD §11.6).
class ExpensesHomeScreen extends ConsumerStatefulWidget {
  final String viewerName;
  final bool viewerIsCaptain;

  const ExpensesHomeScreen({
    super.key,
    required this.viewerName,
    required this.viewerIsCaptain,
  });

  @override
  ConsumerState<ExpensesHomeScreen> createState() => _ExpensesHomeScreenState();
}

class _ExpensesHomeScreenState extends ConsumerState<ExpensesHomeScreen> {
  _ExpensesTab _tab = _ExpensesTab.all;

  String _contextCaption(Expense expense) {
    if (expense.contextMatchId == null) {
      return expenseCategoryLabels[expense.category]!;
    }
    final matches = ref
        .read(matchesProvider)
        .matches
        .where((m) => m.id == expense.contextMatchId);
    if (matches.isEmpty) return expenseCategoryLabels[expense.category]!;
    return 'vs ${matches.first.draft.opponentTeamName}';
  }

  /// PRD §11.10: age chip (per §3.2.5's warning >3d / error >7d
  /// convention) + payer-visible reminder-cadence schedule with Snooze,
  /// or the payee's manual-remind action -- whichever direction this
  /// expense nets for the viewer.
  Widget _reminderRow(AppColors colors, WidgetRef ref, Expense expense) {
    final ageDays = DateTime.now().difference(expense.date).inDays;
    final net = expense.netFor(widget.viewerName);
    final remindersState = ref.watch(remindersProvider);
    final remindersNotifier = ref.read(remindersProvider.notifier);
    final reminderState = remindersState.stateFor(expense.id);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppTagChip(
                key: ValueKey('ageChip_${expense.id}'),
                label: '${ageDays}d',
                variant: ageChipVariant(ageDays),
              ),
              const SizedBox(width: AppSpacing.sm),
              if (net < 0)
                Expanded(
                  child: Text(
                    reminderCadenceLabel(ageDays),
                    style: AppTypography.caption.copyWith(
                      color: colors.textTertiary,
                    ),
                  ),
                ),
              const Spacer(),
              if (net < 0)
                AppButton(
                  key: ValueKey('snoozeButton_${expense.id}'),
                  variant: AppButtonVariant.tertiary,
                  label: remindersNotifier.canSnooze(expense.id)
                      ? 'Snooze'
                      : 'Snoozed',
                  onPressed: remindersNotifier.canSnooze(expense.id)
                      ? () => remindersNotifier.snooze(expense.id)
                      : null,
                ),
              if (net > 0)
                AppButton(
                  key: ValueKey('remindButton_${expense.id}'),
                  variant: AppButtonVariant.tertiary,
                  label: remindersNotifier.canSendManualReminder(expense.id)
                      ? 'Remind'
                      : 'Reminded today',
                  onPressed: remindersNotifier.canSendManualReminder(expense.id)
                      ? () => remindersNotifier.sendManualReminder(expense.id, [
                          for (final share in expense.splitAmong)
                            if (share.name != widget.viewerName)
                              '${share.name}: ${reminderCopy(amount: share.amount, contextCaption: _contextCaption(expense))}',
                        ])
                      : null,
                ),
            ],
          ),
          if (reminderState.log.isNotEmpty)
            Text(
              'Last reminder sent',
              style: AppTypography.caption.copyWith(color: colors.textTertiary),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final expenses = ref.watch(expensesProvider).expenses;
    final notifier = ref.read(expensesProvider.notifier);
    final settlements = ref.watch(settlementsProvider).settlements;
    final settlementsNotifier = ref.read(settlementsProvider.notifier);
    final incomingSettlements = [
      for (final s in settlements)
        if (s.toName == widget.viewerName &&
            s.status == SettlementStatus.pendingConfirmation)
          s,
    ];

    final net = expenses.fold(0, (sum, e) => sum + e.netFor(widget.viewerName));

    final filtered = [
      for (final e in expenses)
        if (_tab == _ExpensesTab.all ||
            (_tab == _ExpensesTab.iOwe && e.netFor(widget.viewerName) < 0) ||
            (_tab == _ExpensesTab.owed && e.netFor(widget.viewerName) > 0))
          e,
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Expenses')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: net == 0
                ? Column(
                    key: const ValueKey('allSquareState'),
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        color: colors.success,
                        size: 40,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'All square',
                        style: AppTypography.h2.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                    ],
                  )
                : Text.rich(
                    key: const ValueKey('netHeader'),
                    TextSpan(
                      style: AppTypography.display.copyWith(
                        color: net > 0 ? colors.success : colors.textPrimary,
                      ),
                      children: [
                        TextSpan(text: net > 0 ? "You're owed " : 'You owe '),
                        WidgetSpan(
                          alignment: PlaceholderAlignment.baseline,
                          baseline: TextBaseline.alphabetic,
                          child: AppMoneyText(
                            symbol: '₹',
                            amount: '${net.abs()}',
                            numeralStyle: AppTypography.display.copyWith(
                              color: net > 0
                                  ? colors.success
                                  : colors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          if (incomingSettlements.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Column(
                key: const ValueKey('pendingSettlementsSection'),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pending settlements',
                    style: AppTypography.label.copyWith(
                      color: colors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  for (final s in incomingSettlements)
                    Container(
                      key: ValueKey('pendingSettlementRow_${s.id}'),
                      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: colors.surfaceAlt,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${s.fromName} says they paid you ₹${s.amount} '
                              '(${settlementMethodLabels[s.method]})',
                              style: AppTypography.body.copyWith(
                                color: colors.textPrimary,
                              ),
                            ),
                          ),
                          AppButton(
                            key: ValueKey('confirmReceiptButton_${s.id}'),
                            variant: AppButtonVariant.secondary,
                            label: 'Confirm',
                            onPressed: () =>
                                settlementsNotifier.confirmSettlement(s.id),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          AppButton(
                            key: ValueKey('declineReceiptButton_${s.id}'),
                            variant: AppButtonVariant.destructive,
                            label: 'Decline',
                            onPressed: () =>
                                _showDeclineSheet(context, ref, s.id),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: AppSpacing.sm),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              children: [
                for (final tab in _ExpensesTab.values)
                  Expanded(
                    child: GestureDetector(
                      key: ValueKey('expensesTab_${tab.name}'),
                      onTap: () => setState(() => _tab = tab),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: _tab == tab
                                  ? colors.primary
                                  : colors.border,
                              width: _tab == tab ? 2 : 1,
                            ),
                          ),
                        ),
                        child: Text(
                          switch (tab) {
                            _ExpensesTab.iOwe => 'I owe',
                            _ExpensesTab.owed => 'Owed',
                            _ExpensesTab.all => 'All',
                          },
                          textAlign: TextAlign.center,
                          style: AppTypography.body.copyWith(
                            color: _tab == tab
                                ? colors.primary
                                : colors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      key: const ValueKey('expensesEmptyState'),
                      'No expenses here yet.',
                      style: AppTypography.body.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  )
                : ListView(
                    key: const ValueKey('expensesList'),
                    children: [
                      for (final expense in filtered)
                        Column(
                          key: ValueKey('expenseRow_${expense.id}'),
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              key: ValueKey('expenseRowTap_${expense.id}'),
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ExpenseDetailScreen(
                                    expenseId: expense.id,
                                    viewerName: widget.viewerName,
                                    viewerIsCaptain: widget.viewerIsCaptain,
                                  ),
                                ),
                              ),
                              child: AppExpenseRow(
                                title: expense.title,
                                contextCaption: _contextCaption(expense),
                                amount: expense.amount,
                                state: expense.hasActiveDispute
                                    ? AppExpenseRowState.disputed
                                    : (expense.settlementStates[widget
                                              .viewerName] ??
                                          AppExpenseRowState.pending),
                                categoryIcon: AppIconId.receipt,
                              ),
                            ),
                            _reminderRow(colors, ref, expense),
                            if (expense.approvalState ==
                                ExpenseApprovalState.pendingApproval)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.lg,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Awaiting approval',
                                        style: AppTypography.caption.copyWith(
                                          color: colors.warning,
                                        ),
                                      ),
                                    ),
                                    if (widget.viewerIsCaptain)
                                      AppButton(
                                        key: ValueKey(
                                          'approveExpenseButton_${expense.id}',
                                        ),
                                        variant: AppButtonVariant.secondary,
                                        label: 'Approve',
                                        onPressed: () =>
                                            notifier.approveExpense(expense.id),
                                      ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                    ],
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Expanded(
                  child: AppButton(
                    key: const ValueKey('settleUpButton'),
                    variant: AppButtonVariant.secondary,
                    label: 'Settle up',
                    fullWidth: true,
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            SettleUpScreen(viewerName: widget.viewerName),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppButton(
                    key: const ValueKey('addExpenseButton'),
                    variant: AppButtonVariant.primary,
                    label: 'Add expense',
                    fullWidth: true,
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AddEditExpenseScreen(
                          viewerName: widget.viewerName,
                          viewerIsCaptain: widget.viewerIsCaptain,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDeclineSheet(
    BuildContext context,
    WidgetRef ref,
    String settlementId,
  ) {
    final controller = TextEditingController();
    showAppBottomSheet<void>(
      context: context,
      title: 'Decline settlement',
      contentBuilder: (context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Declining opens a mini-dispute -- explain why you didn\'t '
              'receive this payment.',
              style: AppTypography.caption,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppTextField(
              key: const ValueKey('declineReasonField'),
              label: 'Reason',
              controller: controller,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              key: const ValueKey('submitDeclineButton'),
              variant: AppButtonVariant.destructive,
              label: 'Decline',
              fullWidth: true,
              onPressed: () {
                final reason = controller.text.trim();
                if (reason.isEmpty) return;
                ref
                    .read(settlementsProvider.notifier)
                    .declineSettlement(settlementId, reason);
                Navigator.of(context).pop();
              },
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}
