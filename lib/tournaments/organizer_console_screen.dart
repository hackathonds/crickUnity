import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_button.dart';
import '../design_system/components/app_tag_chip.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'ledger_models.dart';
import 'ledger_provider.dart';
import 'registration_models.dart';
import 'registrations_provider.dart';
import 'tournament_models.dart';
import 'tournaments_provider.dart';

/// PRD §8.13-8.14 (Expenses/Revenue): organizer ledger (inflows/
/// outflows, line-itemized); transparency rule for captains; prize
/// payout tracker with an Organizer-Score-feeding overdue flag. DS
/// §7.5 item 39: "Organizer Console dashboard tiles (registrations,
/// disputes, payouts) -> queues ... wallet ledger banking-style."
///
/// No tournament-level dispute system exists yet (a separate,
/// not-yet-built concept from the Social-module report flow) -- the
/// disputes tile is flagged at 0 rather than fabricated.
class OrganizerConsoleScreen extends ConsumerStatefulWidget {
  const OrganizerConsoleScreen({super.key});

  @override
  ConsumerState<OrganizerConsoleScreen> createState() =>
      _OrganizerConsoleScreenState();
}

class _OrganizerConsoleScreenState
    extends ConsumerState<OrganizerConsoleScreen> {
  String? _selectedTournamentId;
  LedgerCategory _newEntryCategory = LedgerCategory.grounds;
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  bool _confidential = false;
  String? _payoutWinnerRegId;
  final _payoutAmountController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _payoutAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final published = ref
        .watch(tournamentsProvider)
        .tournaments
        .where((t) => t.status == TournamentStatus.published)
        .toList();
    final registrationsState = ref.watch(registrationsProvider);
    final ledgerState = ref.watch(ledgerProvider);
    final ledgerNotifier = ref.read(ledgerProvider.notifier);

    if (_selectedTournamentId == null && published.isNotEmpty) {
      _selectedTournamentId = published.first.id;
    }
    final tournament = published
        .where((t) => t.id == _selectedTournamentId)
        .firstOrNull;

    if (tournament == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Organizer console')),
        body: Center(
          child: Text(
            'No published tournaments yet -- publish one first (E10-01).',
            textAlign: TextAlign.center,
            style: AppTypography.body.copyWith(color: colors.textSecondary),
          ),
        ),
      );
    }

    final registrations = registrationsState.forTournament(tournament.id);
    final approvedTeams = registrations
        .where((r) => r.status == RegistrationStatus.approved)
        .toList();
    final entries = ledgerState.entriesFor(tournament.id);
    final payouts = ledgerState.payoutsFor(tournament.id);
    final pendingPayouts = payouts.where((p) => !p.isConfirmed).length;
    final overduePayouts = payouts
        .where((p) => p.isOverdue(DateTime.now()))
        .toList();

    return Scaffold(
      appBar: AppBar(title: Text('Organizer console · ${tournament.name}')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              for (final t in published)
                ChoiceChip(
                  key: ValueKey('organizerTournamentChip_${t.id}'),
                  label: Text(t.name.isEmpty ? '(unnamed)' : t.name),
                  selected: _selectedTournamentId == t.id,
                  onSelected: (_) =>
                      setState(() => _selectedTournamentId = t.id),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              _DashboardTile(
                label: 'Registrations',
                value: '${registrations.length}',
                colors: colors,
              ),
              const SizedBox(width: AppSpacing.sm),
              _DashboardTile(
                label: 'Disputes',
                value: '0',
                colors: colors,
                footnote: 'not yet built',
              ),
              const SizedBox(width: AppSpacing.sm),
              _DashboardTile(
                label: 'Payouts pending',
                value: '$pendingPayouts',
                colors: colors,
              ),
            ],
          ),
          if (overduePayouts.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: colors.error.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${overduePayouts.length} payout(s) unconfirmed >7d -- flagging Organizer Score.',
                style: AppTypography.caption.copyWith(color: colors.error),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          Text('Ledger (organizer view)', style: AppTypography.h2),
          const SizedBox(height: AppSpacing.sm),
          _LedgerRow(
            label:
                '${ledgerCategoryLabels[LedgerCategory.entryFees]} (from escrow)',
            amount: tournament.escrowedAmount,
            colors: colors,
          ),
          for (final entry in entries)
            _LedgerRow(
              label:
                  '${ledgerCategoryLabels[entry.category]}${entry.note.isEmpty ? '' : ' -- ${entry.note}'}',
              amount: entry.amount,
              colors: colors,
            ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              for (final category in LedgerCategory.values.where(
                (c) => c != LedgerCategory.entryFees,
              ))
                ChoiceChip(
                  key: ValueKey('ledgerCategoryChip_${category.name}'),
                  label: Text(ledgerCategoryLabels[category]!),
                  selected: _newEntryCategory == category,
                  onSelected: (_) =>
                      setState(() => _newEntryCategory = category),
                ),
            ],
          ),
          TextField(
            key: const ValueKey('ledgerAmountField'),
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Amount (₹)'),
          ),
          TextField(
            key: const ValueKey('ledgerNoteField'),
            controller: _noteController,
            decoration: const InputDecoration(labelText: 'Note'),
          ),
          if (_newEntryCategory == LedgerCategory.sponsors)
            CheckboxListTile(
              key: const ValueKey('ledgerConfidentialCheckbox'),
              contentPadding: EdgeInsets.zero,
              title: const Text('Confidential (hide value from captains)'),
              value: _confidential,
              onChanged: (v) => setState(() => _confidential = v ?? false),
            ),
          AppButton(
            key: const ValueKey('addLedgerEntryButton'),
            variant: AppButtonVariant.secondary,
            label: 'Add ledger entry',
            fullWidth: true,
            onPressed: () {
              final amount = int.tryParse(_amountController.text) ?? 0;
              if (amount <= 0) return;
              ledgerNotifier.addEntry(
                tournament.id,
                _newEntryCategory,
                amount,
                _noteController.text.trim(),
                isConfidential: _confidential,
              );
              _amountController.clear();
              _noteController.clear();
              setState(() => _confidential = false);
            },
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Captain-facing transparency summary', style: AppTypography.h2),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Registered captains see this categorized summary -- sponsor '
            'contract values are hidden if marked confidential, but the '
            'prize pool total & payout status are always visible.',
            style: AppTypography.caption.copyWith(color: colors.textTertiary),
          ),
          const SizedBox(height: AppSpacing.sm),
          _TransparencySummary(
            tournament: tournament,
            entries: entries,
            payouts: payouts,
            colors: colors,
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Prize payout tracker', style: AppTypography.h2),
          const SizedBox(height: AppSpacing.sm),
          for (final payout in payouts)
            _PayoutRow(
              key: ValueKey('payoutRow_${payout.id}'),
              tournamentId: tournament.id,
              payout: payout,
              colors: colors,
            ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              for (final team in approvedTeams)
                ChoiceChip(
                  key: ValueKey('payoutWinnerChip_${team.id}'),
                  label: Text(team.teamName),
                  selected: _payoutWinnerRegId == team.id,
                  onSelected: (_) =>
                      setState(() => _payoutWinnerRegId = team.id),
                ),
            ],
          ),
          TextField(
            key: const ValueKey('payoutAmountField'),
            controller: _payoutAmountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Payout amount (₹)'),
          ),
          AppButton(
            key: const ValueKey('awardPayoutButton'),
            variant: AppButtonVariant.primary,
            label: 'Award payout',
            fullWidth: true,
            onPressed: _payoutWinnerRegId == null
                ? null
                : () {
                    final amount =
                        int.tryParse(_payoutAmountController.text) ?? 0;
                    if (amount <= 0) return;
                    final winner = approvedTeams.firstWhere(
                      (t) => t.id == _payoutWinnerRegId,
                    );
                    ledgerNotifier.awardPayout(
                      tournament.id,
                      winner.id,
                      winner.teamName,
                      amount,
                    );
                    _payoutAmountController.clear();
                    setState(() => _payoutWinnerRegId = null);
                  },
          ),
        ],
      ),
    );
  }
}

class _DashboardTile extends StatelessWidget {
  final String label;
  final String value;
  final AppColors colors;
  final String? footnote;

  const _DashboardTile({
    required this.label,
    required this.value,
    required this.colors,
    this.footnote,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: colors.surfaceAlt,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTypography.caption.copyWith(color: colors.textTertiary),
            ),
            Text(
              value,
              style: AppTypography.stat.copyWith(color: colors.textPrimary),
            ),
            if (footnote != null)
              Text(
                footnote!,
                style: AppTypography.caption.copyWith(
                  color: colors.textTertiary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LedgerRow extends StatelessWidget {
  final String label;
  final int amount;
  final AppColors colors;

  const _LedgerRow({
    required this.label,
    required this.amount,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTypography.body.copyWith(color: colors.textSecondary),
            ),
          ),
          Text(
            '₹$amount',
            style: AppTypography.stat.copyWith(
              fontSize: 15,
              height: 20 / 15,
              color: colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _TransparencySummary extends StatelessWidget {
  final Tournament tournament;
  final List<LedgerEntry> entries;
  final List<PrizePayout> payouts;
  final AppColors colors;

  const _TransparencySummary({
    required this.tournament,
    required this.entries,
    required this.payouts,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final prizePoolTotal = entries
        .where((e) => e.category == LedgerCategory.prizes)
        .fold<int>(0, (sum, e) => sum + e.amount);
    final totalsByCategory = <LedgerCategory, int>{};
    for (final entry in entries) {
      totalsByCategory[entry.category] =
          (totalsByCategory[entry.category] ?? 0) + entry.amount;
    }
    final hasConfidentialSponsor = entries.any(
      (e) => e.category == LedgerCategory.sponsors && e.isConfidential,
    );

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LedgerRow(
            label: ledgerCategoryLabels[LedgerCategory.entryFees]!,
            amount: tournament.escrowedAmount,
            colors: colors,
          ),
          for (final category in LedgerCategory.values.where(
            (c) => c != LedgerCategory.entryFees,
          ))
            if (totalsByCategory.containsKey(category))
              category == LedgerCategory.sponsors && hasConfidentialSponsor
                  ? Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.xs,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              ledgerCategoryLabels[category]!,
                              style: AppTypography.body.copyWith(
                                color: colors.textSecondary,
                              ),
                            ),
                          ),
                          Text(
                            'Confidential',
                            style: AppTypography.body.copyWith(
                              color: colors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : _LedgerRow(
                      label: ledgerCategoryLabels[category]!,
                      amount: totalsByCategory[category]!,
                      colors: colors,
                    ),
          const Divider(),
          Text(
            'Prize pool total: ₹$prizePoolTotal',
            style: AppTypography.stat.copyWith(color: colors.textPrimary),
          ),
          Text(
            'Payout status: ${payouts.where((p) => p.isConfirmed).length}/${payouts.length} confirmed',
            style: AppTypography.body.copyWith(color: colors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _PayoutRow extends ConsumerWidget {
  final String tournamentId;
  final PrizePayout payout;
  final AppColors colors;

  const _PayoutRow({
    super.key,
    required this.tournamentId,
    required this.payout,
    required this.colors,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overdue = payout.isOverdue(DateTime.now());
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${payout.winnerTeamName} · ₹${payout.amount}',
                  style: AppTypography.body,
                ),
                AppTagChip(
                  label: payout.isConfirmed
                      ? 'Confirmed'
                      : (overdue
                            ? 'Overdue -- Organizer Score flagged'
                            : 'Awaiting confirmation'),
                  variant: payout.isConfirmed
                      ? AppTagChipVariant.success
                      : (overdue
                            ? AppTagChipVariant.error
                            : AppTagChipVariant.warning),
                ),
              ],
            ),
          ),
          if (!payout.isConfirmed)
            TextButton(
              key: ValueKey('confirmPayoutButton_${payout.id}'),
              onPressed: () => ref
                  .read(ledgerProvider.notifier)
                  .confirmPayoutReceipt(tournamentId, payout.id),
              child: const Text('Confirm receipt (winner)'),
            ),
        ],
      ),
    );
  }
}
