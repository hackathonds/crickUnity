import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design_system/tokens/app_colors.dart';
import '../../design_system/tokens/app_spacing.dart';
import '../../design_system/tokens/app_typography.dart';
import '../../expenses/expense_models.dart';
import '../../expenses/expenses_provider.dart';
import '../../expenses/reminders_provider.dart';
import '../../expenses/settle_up_screen.dart';
import '../../recognition/challenge_models.dart';
import '../../recognition/challenges_provider.dart';
import '../../rewards/luck_layer_screen.dart';
import '../../rewards/luck_provider.dart';
import '../../rewards/marketplace_screen.dart';
import '../../rewards/missions_board_screen.dart';
import '../../rewards/rewards_models.dart' show coinsExpiringWithin;
import '../../rewards/rewards_provider.dart';
import '../../rewards/wallet_screen.dart';
import '../../social/composer_screen.dart' show composerViewerName;

/// PRD §4.4 (Expense Summary): "Net position ... top counterparty,
/// pending count. A: Settle up (pre-filtered), Remind, View all. St:
/// All-settled (green 'All square ✓'); Overdue (red accent + days
/// count); Dispute-open (info banner)."
class ExpenseSummaryBody extends ConsumerWidget {
  const ExpenseSummaryBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final expenses = ref.watch(expensesProvider).expenses;
    final relevant = expenses.where(
      (e) =>
          !e.isDeleted &&
          e.approvalState != ExpenseApprovalState.pendingApproval &&
          e.splitAmong.any((s) => s.name == composerViewerName),
    );
    final net = relevant.fold(
      0,
      (sum, e) => sum + e.netFor(composerViewerName),
    );
    final hasDispute = relevant.any((e) => e.hasActiveDispute);
    final pendingCount = relevant
        .where((e) => e.netFor(composerViewerName) != 0)
        .length;

    if (pendingCount == 0) {
      return Text(
        'All square ✓',
        style: AppTypography.body.copyWith(color: colors.success),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          net >= 0 ? 'You are owed ₹$net' : 'You owe ₹${-net}',
          style: AppTypography.stat.copyWith(
            color: net >= 0 ? colors.success : colors.error,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        Text(
          '$pendingCount pending',
          style: AppTypography.caption.copyWith(color: colors.textSecondary),
        ),
        if (hasDispute)
          Container(
            key: const ValueKey('expenseSummaryDisputeBanner'),
            margin: const EdgeInsets.only(top: AppSpacing.xs),
            padding: const EdgeInsets.all(AppSpacing.xs),
            decoration: BoxDecoration(
              color: colors.surfaceAlt,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'A dispute is open on one of your expenses.',
              style: AppTypography.caption.copyWith(color: colors.textTertiary),
            ),
          ),
        const SizedBox(height: AppSpacing.xs),
        if (net < 0)
          OutlinedButton(
            key: const ValueKey('expenseSummarySettleUpButton'),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    const SettleUpScreen(viewerName: composerViewerName),
              ),
            ),
            child: const Text('Settle up'),
          ),
      ],
    );
  }
}

/// PRD §4.19 (Pending Payments): "Individual dues with payee avatar +
/// context. A: Pay/Settle, Snooze (once per item per 48h), Dispute. V:
/// Payer only. St: Overdue escalation: amber >3d, red >7d (also nudges
/// Trust Score warning tooltip)." Distinct from §4.4's summary --
/// per-item, not net.
class PendingPaymentsBody extends ConsumerWidget {
  const PendingPaymentsBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final now = DateTime.now();
    final unpaid = ref
        .watch(expensesProvider)
        .expenses
        .where(
          (e) =>
              !e.isDeleted &&
              e.approvalState != ExpenseApprovalState.pendingApproval &&
              e.netFor(composerViewerName) < 0 &&
              e.splitAmong.any((s) => s.name == composerViewerName),
        )
        .toList();

    if (unpaid.isEmpty) {
      return Text(
        'Nothing pending.',
        style: AppTypography.body.copyWith(color: colors.textSecondary),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final e in unpaid)
          _PendingPaymentRow(
            expense: e,
            ageDays: now.difference(e.date).inDays,
          ),
      ],
    );
  }
}

class _PendingPaymentRow extends ConsumerWidget {
  final Expense expense;
  final int ageDays;
  const _PendingPaymentRow({required this.expense, required this.ageDays});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final amount = -expense.netFor(composerViewerName);
    final overdueColor = ageDays > 7
        ? colors.error
        : ageDays > 3
        ? colors.coin
        : colors.textSecondary;
    final canSnooze = ref
        .read(remindersProvider.notifier)
        .canSnooze(expense.id);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '₹$amount -- ${expense.title}',
                  style: AppTypography.body.copyWith(color: colors.textPrimary),
                ),
                Text(
                  ageDays > 3
                      ? '${ageDays}d overdue'
                      : reminderCadenceLabel(ageDays),
                  style: AppTypography.caption.copyWith(color: overdueColor),
                ),
              ],
            ),
          ),
          TextButton(
            key: ValueKey('pendingPaymentSettleButton_${expense.id}'),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    const SettleUpScreen(viewerName: composerViewerName),
              ),
            ),
            child: const Text('Pay'),
          ),
          IconButton(
            key: ValueKey('pendingPaymentSnoozeButton_${expense.id}'),
            icon: const Icon(Icons.snooze_outlined, size: 18),
            onPressed: canSnooze
                ? () => ref.read(remindersProvider.notifier).snooze(expense.id)
                : null,
          ),
        ],
      ),
    );
  }
}

/// PRD §4.5 (Coin Balance): "Balance, this week's earnings, next
/// redemption unlock. A: Earn (missions), Redeem (marketplace),
/// History. St: Streak-bonus available (glowing rim); Expiring coins
/// (countdown chip)."
class CoinBalanceBody extends ConsumerWidget {
  const CoinBalanceBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final rewards = ref.watch(rewardsProvider);
    final expiring = coinsExpiringWithin(rewards.coinBatches, 30);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${rewards.coinBalance} coins',
          style: AppTypography.stat.copyWith(
            color: colors.coin,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        if (expiring > 0)
          Text(
            '$expiring expire in 30d',
            style: AppTypography.caption.copyWith(color: colors.coin),
          ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            OutlinedButton(
              key: const ValueKey('coinBalanceEarnButton'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MissionsBoardScreen()),
              ),
              child: const Text('Earn'),
            ),
            const SizedBox(width: AppSpacing.sm),
            OutlinedButton(
              key: const ValueKey('coinBalanceRedeemButton'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MarketplaceScreen()),
              ),
              child: const Text('Redeem'),
            ),
            const SizedBox(width: AppSpacing.sm),
            IconButton(
              key: const ValueKey('coinBalanceHistoryButton'),
              icon: const Icon(Icons.history, size: 18),
              onPressed: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const WalletScreen())),
            ),
          ],
        ),
      ],
    );
  }
}

/// PRD §4.6 (Rewards): "Unclaimed items: scratch cards, spin tokens,
/// level-up chest. A: Claim/Open, View all. V: Only when ≥1 unclaimed
/// (self-hides)." Real reads of luckLayerProvider (scratch/spin) and
/// rewardsProvider's ceremony queue (level-up chest).
class RewardsBody extends ConsumerWidget {
  const RewardsBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final luck = ref.watch(luckLayerProvider);
    final level = ref.watch(rewardsProvider).level;
    final canSpin =
        ref
            .read(luckLayerProvider.notifier)
            .spinBlockReason(viewerLevel: level) ==
        null;
    final ceremonies = ref.watch(rewardsProvider).ceremonyQueue.length;
    final unclaimedCount =
        luck.scratchCardsAvailable + (canSpin ? 1 : 0) + ceremonies;

    if (unclaimedCount == 0) return const SizedBox.shrink();

    return Row(
      children: [
        Expanded(
          child: Text(
            unclaimedCount == 1
                ? '1 reward waiting'
                : '$unclaimedCount rewards waiting',
            style: AppTypography.body.copyWith(color: colors.textPrimary),
          ),
        ),
        OutlinedButton(
          key: const ValueKey('rewardsClaimButton'),
          onPressed: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const LuckLayerScreen())),
          child: const Text('Claim'),
        ),
      ],
    );
  }
}

/// PRD §4.7 (Challenges): "Up to 2 active challenges with progress
/// bars, time left. A: View, Find more, Nudge rival. St: Near-complete
/// (pulsing ≥80%); Completed-unclaimed; Failed (soft grey)."
class ChallengesBody extends ConsumerWidget {
  const ChallengesBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final mine = ref
        .watch(challengesProvider)
        .challenges
        .where((c) => c.participantNamed(composerViewerName) != null)
        .toList();

    if (mine.isEmpty) {
      return Text(
        'No active challenges.',
        style: AppTypography.body.copyWith(color: colors.textSecondary),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [for (final c in mine.take(2)) _ChallengeRow(challenge: c)],
    );
  }
}

class _ChallengeRow extends StatelessWidget {
  final Challenge challenge;
  const _ChallengeRow({required this.challenge});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final mine = challenge.participantNamed(composerViewerName)!;
    final progress = (mine.progress / challenge.target).clamp(0.0, 1.0);
    final daysLeft = challenge.endsAt.difference(DateTime.now()).inDays;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${challenge.title} -- ${mine.progress}/${challenge.target} '
            '${challenge.metricLabel}',
            style: AppTypography.body.copyWith(color: colors.textPrimary),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: colors.surfaceAlt,
              valueColor: AlwaysStoppedAnimation(
                progress >= 0.8 ? colors.coin : colors.primary,
              ),
            ),
          ),
          Text(
            daysLeft > 0 ? '$daysLeft days left' : 'Ending today',
            style: AppTypography.caption.copyWith(color: colors.textTertiary),
          ),
        ],
      ),
    );
  }
}
