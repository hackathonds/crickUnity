import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_bottom_sheet.dart';
import '../design_system/components/app_button.dart';
import '../design_system/components/app_currency_field.dart';
import '../design_system/components/app_tag_chip.dart';
import '../design_system/components/app_text_field.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_money_text.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'expense_models.dart';
import 'expenses_provider.dart';
import 'recurring_series_provider.dart';
import 'reminders_provider.dart';
import 'settle_up_screen.dart';
import 'settlement_models.dart';
import 'settlements_provider.dart';

/// DS §7-50 (Expense Detail): "amount hero -> per-person state list ->
/// proof gallery -> comments thread -> activity log accordion ->
/// actions [Pay/Remind/Dispute]. Frozen-in-dispute banner." PRD §11.7.
///
/// Comments thread is explicitly out of scope here -- the backlog
/// calls out E5-11 ("Expense comments") as its own later story,
/// deliberately made explicit rather than left implied by this one.
/// Proof gallery stays the E5-01 hasProof flag (no real photo capture/
/// storage pipeline exists in this codebase).
class ExpenseDetailScreen extends ConsumerWidget {
  final String expenseId;
  final String viewerName;
  final bool viewerIsCaptain;

  const ExpenseDetailScreen({
    super.key,
    required this.expenseId,
    required this.viewerName,
    required this.viewerIsCaptain,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final expense = ref
        .watch(expensesProvider)
        .expenses
        .firstWhere((e) => e.id == expenseId);
    final notifier = ref.read(expensesProvider.notifier);
    final settlements = ref.watch(settlementsProvider).settlements;

    final participantNames = {
      for (final p in expense.paidBy) p.name,
      for (final s in expense.splitAmong) s.name,
    };
    // PRD §11.7: "edit-locked once any settlement occurs." A settlement
    // isn't tied to one specific expense (E5-04's model nets several at
    // once) -- approximated as "any confirmed settlement involving one
    // of this expense's participants, created after this expense was
    // posted," flagged.
    final isEditLocked = settlements.any(
      (s) =>
          s.status == SettlementStatus.confirmed &&
          s.createdAt.isAfter(expense.date) &&
          (participantNames.contains(s.fromName) ||
              participantNames.contains(s.toName)),
    );

    final activeDisputes = expense.disputes.where((d) => !d.resolved).toList();
    final isParticipant = participantNames.contains(viewerName);
    final viewerHasActiveDispute = activeDisputes.any(
      (d) => d.disputerName == viewerName,
    );
    final isCreator = expense.createdByName == viewerName;

    return Scaffold(
      appBar: AppBar(title: Text(expense.title)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          if (activeDisputes.isNotEmpty)
            Container(
              key: const ValueKey('frozenDisputeBanner'),
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              margin: const EdgeInsets.only(bottom: AppSpacing.lg),
              decoration: BoxDecoration(
                color: colors.error.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Frozen -- disputed',
                    style: AppTypography.subtitle.copyWith(color: colors.error),
                  ),
                  for (final d in activeDisputes)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xs),
                      child: Text(
                        '${d.disputerName}: ${d.reason}',
                        style: AppTypography.body.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          Center(
            child: Column(
              children: [
                AppMoneyText(
                  key: const ValueKey('amountHero'),
                  symbol: currencySymbols[expense.currency]!,
                  amount: '${expense.amount}',
                  numeralStyle: AppTypography.display.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
                if (expense.conversionNote != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    key: const ValueKey('homeCurrencyConversionText'),
                    '≈ ${currencySymbols[homeCurrency]}'
                    '${expense.homeCurrencyAmount} -- ${expense.conversionNote}',
                    style: AppTypography.caption.copyWith(
                      color: colors.textTertiary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            'Per person',
            style: AppTypography.label.copyWith(color: colors.textTertiary),
          ),
          const SizedBox(height: AppSpacing.xs),
          for (final share in expense.splitAmong)
            Padding(
              key: ValueKey('personRow_${share.name}'),
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs / 2),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      share.name,
                      style: AppTypography.body.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    '₹${share.amount}',
                    style: AppTypography.stat.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            'Proof',
            style: AppTypography.label.copyWith(color: colors.textTertiary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Icon(
                expense.hasProof
                    ? Icons.check_circle
                    : Icons.image_not_supported_outlined,
                color: expense.hasProof ? colors.verified : colors.textTertiary,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                expense.hasProof ? 'Proof attached' : 'No proof attached',
                style: AppTypography.body.copyWith(color: colors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),
          ExpansionTile(
            key: const ValueKey('activityLogAccordion'),
            title: Text(
              'Activity log',
              style: AppTypography.label.copyWith(color: colors.textTertiary),
            ),
            children: [
              for (final entry in _activityLog(expense))
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  child: Text(
                    entry,
                    style: AppTypography.caption.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  key: const ValueKey('payButton'),
                  variant: AppButtonVariant.primary,
                  label: 'Pay',
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => SettleUpScreen(
                        viewerName: viewerName,
                        prefilledCounterpartName:
                            expense.createdByName != viewerName
                            ? expense.createdByName
                            : null,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppButton(
                  key: const ValueKey('remindButtonDetail'),
                  variant: AppButtonVariant.secondary,
                  label: 'Remind',
                  onPressed: () => ref
                      .read(remindersProvider.notifier)
                      .sendManualReminder(expenseId, [
                        for (final s in expense.splitAmong)
                          if (s.name != viewerName)
                            '${s.name}: ${reminderCopy(amount: s.amount, contextCaption: expense.title)}',
                      ]),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppButton(
                  key: const ValueKey('disputeButtonDetail'),
                  variant: AppButtonVariant.destructive,
                  label: 'Dispute',
                  onPressed: isParticipant && !viewerHasActiveDispute
                      ? () => _showDisputeSheet(context, ref)
                      : null,
                ),
              ),
            ],
          ),
          if (isCreator && activeDisputes.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xxl),
            Text(
              'Resolve disputes',
              style: AppTypography.label.copyWith(color: colors.textTertiary),
            ),
            const SizedBox(height: AppSpacing.xs),
            for (final d in activeDisputes)
              Container(
                key: ValueKey('resolveDisputeCard_${d.disputerName}'),
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: colors.surfaceAlt,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${d.disputerName}: ${d.reason}',
                      style: AppTypography.body.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                    if (DateTime.now().difference(d.createdAt).inDays >= 7)
                      AppTagChip(
                        label: 'Escalation eligible',
                        variant: AppTagChipVariant.warning,
                      ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            key: ValueKey('amendButton_${d.disputerName}'),
                            variant: AppButtonVariant.secondary,
                            label: 'Amend',
                            onPressed: isEditLocked
                                ? null
                                : () => _showAmendSheet(context, ref, expense),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: AppButton(
                            key: ValueKey(
                              'upholdCreatorButton_${d.disputerName}',
                            ),
                            variant: d.creatorUpheld
                                ? AppButtonVariant.tertiary
                                : AppButtonVariant.secondary,
                            label: d.creatorUpheld
                                ? 'Creator upheld'
                                : 'Uphold (creator)',
                            onPressed: d.creatorUpheld
                                ? null
                                : () => notifier.upholdDispute(
                                    expenseId,
                                    d.disputerName,
                                    asCreator: true,
                                  ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: AppButton(
                            key: ValueKey(
                              'upholdCaptainButton_${d.disputerName}',
                            ),
                            variant: d.captainUpheld
                                ? AppButtonVariant.tertiary
                                : AppButtonVariant.secondary,
                            label: d.captainUpheld
                                ? 'Captain upheld'
                                : 'Uphold (captain)',
                            onPressed: d.captainUpheld
                                ? null
                                : () => notifier.upholdDispute(
                                    expenseId,
                                    d.disputerName,
                                    asCreator: false,
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
          if (viewerHasActiveDispute)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: AppButton(
                key: const ValueKey('escalateButton'),
                variant: AppButtonVariant.tertiary,
                label: 'Escalate to Admin (after 7d)',
                onPressed: () =>
                    notifier.escalateDispute(expenseId, viewerName),
              ),
            ),
          if (isEditLocked)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Text(
                'Edit-locked: a settlement has occurred since this was '
                'posted. Versioned edits requiring every payer\'s consent '
                'aren\'t built yet (flagged).',
                style: AppTypography.caption.copyWith(
                  color: colors.textTertiary,
                ),
              ),
            ),
          if (isCreator || viewerIsCaptain)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.lg),
              child: AppButton(
                key: const ValueKey('deleteExpenseButton'),
                variant: AppButtonVariant.destructive,
                label: 'Delete',
                fullWidth: true,
                onPressed: () {
                  notifier.deleteExpense(expenseId, viewerName);
                  Navigator.of(context).pop();
                },
              ),
            ),
        ],
      ),
    );
  }

  List<String> _activityLog(Expense expense) {
    final entries = <String>['Created by ${expense.createdByName}'];
    for (final d in expense.disputes) {
      entries.add('Disputed by ${d.disputerName}: ${d.reason}');
      if (d.resolution == 'amended') {
        entries.add('Resolved: amended by ${expense.createdByName}');
      } else if (d.resolution == 'upheld') {
        entries.add('Resolved: upheld by creator + captain');
      }
      if (d.escalatedToAdmin) {
        entries.add('Escalated to Admin by ${d.disputerName}');
      }
    }
    return entries;
  }

  void _showDisputeSheet(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showAppBottomSheet<void>(
      context: context,
      title: 'Dispute this expense',
      contentBuilder: (context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppTextField(
              key: const ValueKey('disputeReasonFieldDetail'),
              label: 'Reason',
              controller: controller,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              key: const ValueKey('submitDisputeButtonDetail'),
              variant: AppButtonVariant.destructive,
              label: 'Dispute',
              fullWidth: true,
              onPressed: () {
                final reason = controller.text.trim();
                if (reason.isEmpty) return;
                ref
                    .read(expensesProvider.notifier)
                    .disputeExpense(expenseId, viewerName, reason);
                Navigator.of(context).pop();
              },
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  void _showAmendSheet(BuildContext context, WidgetRef ref, Expense expense) {
    final controller = TextEditingController(text: '${expense.amount}');
    final seriesId = expense.recurrenceSeriesId;
    // DS §11.13: "editing asks 'This one / All future' sheet" -- only
    // relevant when this expense belongs to a recurring series.
    var applyToAllFuture = false;
    showAppBottomSheet<void>(
      context: context,
      title: 'Amend amount',
      contentBuilder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (seriesId != null) ...[
                Wrap(
                  spacing: AppSpacing.xs,
                  children: [
                    ChoiceChip(
                      key: const ValueKey('amendScopeThisOne'),
                      label: const Text('This one'),
                      selected: !applyToAllFuture,
                      onSelected: (_) =>
                          setSheetState(() => applyToAllFuture = false),
                    ),
                    ChoiceChip(
                      key: const ValueKey('amendScopeAllFuture'),
                      label: const Text('All future'),
                      selected: applyToAllFuture,
                      onSelected: (_) =>
                          setSheetState(() => applyToAllFuture = true),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              AppCurrencyField(
                key: const ValueKey('amendAmountField'),
                label: 'Corrected amount',
                controller: controller,
              ),
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                key: const ValueKey('submitAmendButton'),
                variant: AppButtonVariant.primary,
                label: 'Save amendment',
                fullWidth: true,
                onPressed: () {
                  final newAmount = int.tryParse(
                    controller.text.replaceAll(',', ''),
                  );
                  if (newAmount == null || newAmount <= 0) return;
                  ref
                      .read(expensesProvider.notifier)
                      .amendExpense(expenseId, newAmount);
                  if (seriesId != null && applyToAllFuture) {
                    ref
                        .read(recurringSeriesProvider.notifier)
                        .updateSeriesTemplate(seriesId, newAmount);
                  }
                  Navigator.of(context).pop();
                },
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}
