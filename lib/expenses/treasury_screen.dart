import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_bottom_sheet.dart';
import '../design_system/components/app_button.dart';
import '../design_system/components/app_currency_field.dart';
import '../design_system/components/app_expense_card.dart';
import '../design_system/components/app_tag_chip.dart';
import '../design_system/components/app_text_field.dart';
import '../design_system/icons/app_icon_id.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_money_text.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'add_edit_expense_screen.dart';
import 'collection_models.dart';
import 'collections_provider.dart';
import 'expense_detail_screen.dart';
import 'expense_models.dart';
import 'expenses_provider.dart';
import 'settlement_models.dart';
import 'settlements_provider.dart';
import 'wallet_payouts_provider.dart';

/// PRD §11.8: "leaving members' unspent earmarked contributions handled
/// per team policy set at wallet creation (refund / donate to team --
/// shown to every contributor upfront)." No wallet-creation flow exists
/// yet to actually set this -- a fixed mock default, shown read-only,
/// same convention as every other missing-configuration-screen mock
/// this session.
const WalletLeavingMemberPolicyChoice mockWalletLeavingPolicy =
    WalletLeavingMemberPolicyChoice.refundToMember;

enum WalletLeavingMemberPolicyChoice { refundToMember, donateToTeam }

const Map<WalletLeavingMemberPolicyChoice, String> _leavingPolicyLabels = {
  WalletLeavingMemberPolicyChoice.refundToMember: 'refunded to the member',
  WalletLeavingMemberPolicyChoice.donateToTeam: 'donated to the team fund',
};

/// DS §16 (Treasury, all-see): "Net wallet Display header ->
/// Collections progress cards (paid-grid avatars) -> ledger list
/// (Expense Rows) -> {Add expense} sticky for Manager/Captain. Dual-
/// approval pending items carry 'Awaiting {name}' chip." PRD §11.5/
/// §11.8.
class TreasuryScreen extends ConsumerWidget {
  final String viewerName;
  final bool viewerIsManagerOrCaptain;

  const TreasuryScreen({
    super.key,
    required this.viewerName,
    required this.viewerIsManagerOrCaptain,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final expenses = ref.watch(expensesProvider).expenses;
    final settlements = ref.watch(settlementsProvider).settlements;
    final collections = ref.watch(collectionsProvider).collections;
    final payouts = ref.watch(walletPayoutsProvider).requests;
    final payoutsNotifier = ref.read(walletPayoutsProvider.notifier);

    final walletNet =
        netBalancesByPerson(expenses, settlements, {
          teamWalletPayerName,
        })[teamWalletPayerName] ??
        0;
    final walletExpenses = [
      for (final e in expenses)
        if (e.paidBy.any((p) => p.name == teamWalletPayerName) ||
            e.splitAmong.any((s) => s.name == teamWalletPayerName))
          e,
    ];
    final pendingPayouts = payouts.where((p) => !p.completed).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Treasury')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text.rich(
            key: const ValueKey('walletNetHeader'),
            TextSpan(
              style: AppTypography.display.copyWith(color: colors.textPrimary),
              children: [
                const TextSpan(text: 'Team wallet: '),
                WidgetSpan(
                  alignment: PlaceholderAlignment.baseline,
                  baseline: TextBaseline.alphabetic,
                  child: AppMoneyText(
                    symbol: '₹',
                    amount: '${walletNet.abs()}',
                    numeralStyle: AppTypography.display.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Leaving members\' unspent contributions are '
            '${_leavingPolicyLabels[mockWalletLeavingPolicy]}.',
            style: AppTypography.caption.copyWith(color: colors.textTertiary),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            'Collections',
            style: AppTypography.label.copyWith(color: colors.textTertiary),
          ),
          const SizedBox(height: AppSpacing.xs),
          for (final c in collections)
            Container(
              key: ValueKey('collectionCard_${c.id}'),
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
                    c.title,
                    style: AppTypography.subtitle.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                  Text(
                    '₹${c.totalCollected} of ₹${c.totalTarget} -- '
                    '${collectionDeadlineLabel(c.deadline)}',
                    style: AppTypography.caption.copyWith(
                      color: colors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      key: ValueKey('collectionProgress_${c.id}'),
                      value: c.progress.clamp(0.0, 1.0),
                      minHeight: 6,
                      backgroundColor: colors.border,
                      color: colors.primary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    children: [
                      for (final name in c.memberNames)
                        Column(
                          key: ValueKey('collectionMember_${c.id}_$name'),
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: c.hasPaidFully(name)
                                  ? colors.success
                                  : colors.border,
                              child: Text(
                                name.substring(0, 1),
                                style: AppTypography.caption.copyWith(
                                  color: colors.surface,
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  if (!c.hasPaidFully(viewerName))
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.sm),
                      child: AppButton(
                        key: ValueKey('contributeButton_${c.id}'),
                        variant: AppButtonVariant.secondary,
                        label: 'Contribute',
                        onPressed: () => _showContributeSheet(context, ref, c),
                      ),
                    ),
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.xxl),
          if (pendingPayouts.isNotEmpty) ...[
            Text(
              'Pending payouts',
              style: AppTypography.label.copyWith(color: colors.textTertiary),
            ),
            const SizedBox(height: AppSpacing.xs),
            for (final p in pendingPayouts)
              Container(
                key: ValueKey('pendingPayoutCard_${p.id}'),
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: colors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${p.purpose} -- ₹${p.amount}',
                      style: AppTypography.body.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    AppTagChip(
                      label: !p.captainApproved
                          ? 'Awaiting Captain'
                          : 'Awaiting Manager/Owner',
                      variant: AppTagChipVariant.warning,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            key: ValueKey('approveCaptainButton_${p.id}'),
                            variant: p.captainApproved
                                ? AppButtonVariant.tertiary
                                : AppButtonVariant.secondary,
                            label: p.captainApproved
                                ? 'Captain approved'
                                : 'Approve (Captain)',
                            onPressed: p.captainApproved
                                ? null
                                : () => payoutsNotifier.approvePayout(
                                    p.id,
                                    asCaptain: true,
                                    createdByName: viewerName,
                                  ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: AppButton(
                            key: ValueKey('approveManagerButton_${p.id}'),
                            variant: p.managerOrOwnerApproved
                                ? AppButtonVariant.tertiary
                                : AppButtonVariant.secondary,
                            label: p.managerOrOwnerApproved
                                ? 'Manager/Owner approved'
                                : 'Approve (Manager/Owner)',
                            onPressed: p.managerOrOwnerApproved
                                ? null
                                : () => payoutsNotifier.approvePayout(
                                    p.id,
                                    asCaptain: false,
                                    createdByName: viewerName,
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            const SizedBox(height: AppSpacing.lg),
          ],
          Text(
            'Ledger',
            style: AppTypography.label.copyWith(color: colors.textTertiary),
          ),
          const SizedBox(height: AppSpacing.xs),
          for (final e in walletExpenses)
            GestureDetector(
              key: ValueKey('treasuryExpenseTap_${e.id}'),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ExpenseDetailScreen(
                    expenseId: e.id,
                    viewerName: viewerName,
                    viewerIsCaptain: viewerIsManagerOrCaptain,
                  ),
                ),
              ),
              child: AppExpenseRow(
                title: e.title,
                contextCaption: expenseCategoryLabels[e.category]!,
                amount: e.amount,
                state:
                    e.settlementStates[viewerName] ??
                    AppExpenseRowState.pending,
                categoryIcon: AppIconId.wallet,
              ),
            ),
          if (viewerIsManagerOrCaptain) ...[
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              key: const ValueKey('requestPayoutButton'),
              variant: AppButtonVariant.secondary,
              label: 'Request payout',
              fullWidth: true,
              onPressed: () => _showRequestPayoutSheet(context, ref),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              key: const ValueKey('treasuryAddExpenseButton'),
              variant: AppButtonVariant.primary,
              label: 'Add expense',
              fullWidth: true,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AddEditExpenseScreen(
                    viewerName: viewerName,
                    viewerIsCaptain: viewerIsManagerOrCaptain,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showContributeSheet(BuildContext context, WidgetRef ref, Collection c) {
    final controller = TextEditingController(
      text: '${c.amountPerMember - (c.contributions[viewerName] ?? 0)}',
    );
    showAppBottomSheet<void>(
      context: context,
      title: 'Contribute',
      contentBuilder: (context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppCurrencyField(
              key: const ValueKey('contributeAmountField'),
              label: 'Amount',
              controller: controller,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              key: const ValueKey('submitContributeButton'),
              variant: AppButtonVariant.primary,
              label: 'Contribute',
              fullWidth: true,
              onPressed: () {
                final amount = int.tryParse(
                  controller.text.replaceAll(',', ''),
                );
                if (amount == null || amount <= 0) return;
                ref
                    .read(collectionsProvider.notifier)
                    .contribute(c.id, viewerName, amount);
                Navigator.of(context).pop();
              },
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  void _showRequestPayoutSheet(BuildContext context, WidgetRef ref) {
    final purposeController = TextEditingController();
    final amountController = TextEditingController();
    showAppBottomSheet<void>(
      context: context,
      title: 'Request payout',
      contentBuilder: (context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(
              key: const ValueKey('payoutPurposeField'),
              label: 'Purpose',
              controller: purposeController,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppCurrencyField(
              key: const ValueKey('payoutAmountField'),
              label: 'Amount',
              controller: amountController,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Above ₹$expenseApprovalThresholdRupees needs both Captain and '
              'Manager/Owner approval before it pays out.',
              style: AppTypography.caption,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              key: const ValueKey('submitPayoutRequestButton'),
              variant: AppButtonVariant.primary,
              label: 'Request',
              fullWidth: true,
              onPressed: () {
                final purpose = purposeController.text.trim();
                final amount = int.tryParse(
                  amountController.text.replaceAll(',', ''),
                );
                if (purpose.isEmpty || amount == null || amount <= 0) return;
                ref
                    .read(walletPayoutsProvider.notifier)
                    .requestPayout(
                      purpose: purpose,
                      amount: amount,
                      createdByName: viewerName,
                    );
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
