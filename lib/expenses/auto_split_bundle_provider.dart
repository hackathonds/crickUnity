import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auto_split_bundle_models.dart';
import 'expense_models.dart';
import 'expenses_provider.dart';

class AutoSplitBundleState {
  final Map<String, AutoSplitBundle> bundlesByMatchId;

  const AutoSplitBundleState({this.bundlesByMatchId = const {}});

  AutoSplitBundleState copyWith({
    Map<String, AutoSplitBundle>? bundlesByMatchId,
  }) {
    return AutoSplitBundleState(
      bundlesByMatchId: bundlesByMatchId ?? this.bundlesByMatchId,
    );
  }
}

/// PRD §11.4 + Appendix A's Auto-Split ACs (E5-03).
class AutoSplitBundleNotifier extends Notifier<AutoSplitBundleState> {
  @override
  AutoSplitBundleState build() => const AutoSplitBundleState();

  /// "Match creation spawns a draft expense bundle from the team's
  /// preset (ground+ball+officials)." No real team-preset configuration
  /// screen exists yet -- fixed mock figures stand in, same convention
  /// as every other missing-backend mock this session. A no-op if a
  /// bundle already exists for this match.
  void draftBundleForMatch(
    String matchId, {
    required int groundFee,
    required int ballFee,
    required int officialsFee,
  }) {
    if (state.bundlesByMatchId.containsKey(matchId)) return;
    state = state.copyWith(
      bundlesByMatchId: {
        ...state.bundlesByMatchId,
        matchId: AutoSplitBundle(
          matchId: matchId,
          groundFee: groundFee,
          ballFee: ballFee,
          officialsFee: officialsFee,
        ),
      },
    );
  }

  void setSplitMethod(String matchId, SplitMethod method) {
    _update(matchId, (b) => b.copyWith(splitMethod: method));
  }

  void setMvpExempt(String matchId, {required bool enabled, String? mvpName}) {
    _update(
      matchId,
      (b) => b.copyWith(
        mvpExemptEnabled: enabled,
        mvpName: mvpName,
        clearMvpName: !enabled,
      ),
    );
  }

  void addReplacement(String matchId, String name) {
    _update(matchId, (b) {
      if (b.replacementNames.contains(name)) return b;
      return b.copyWith(replacementNames: [...b.replacementNames, name]);
    });
  }

  /// AC: "Given a confirmed match with 12 final squad members and preset
  /// expenses totaling ₹3,400, when the captain finalizes, then 12
  /// shares of ₹283.33 are created, remainder ₹0.04 assigns to payer,
  /// and 12 P1 notifications with inline Pay are sent within the same
  /// session." Genuinely creates a real [Expense] via [expensesProvider]
  /// rather than a separate mock ledger.
  void finalizeBundle(
    String matchId, {
    required List<String> finalSquad,
    required String createdByName,
    required bool createdByIsCaptain,
  }) {
    final bundle = state.bundlesByMatchId[matchId];
    if (bundle == null || bundle.status != AutoSplitBundleStatus.draft) return;

    final people = {...finalSquad, ...bundle.replacementNames}.toList();
    var shares = switch (bundle.splitMethod) {
      SplitMethod.shares => weightedSplit(bundle.totalRupees, {
        for (final p in people) p: 1,
      }),
      // Custom/Percentages/Itemized need per-person input this
      // one-sheet review doesn't collect -- Equal stands in rather
      // than fabricating that input, flagged.
      _ => equalSplit(bundle.totalRupees, people),
    };

    // AC: "Given the team's MVP-exempt rule is ON and an MVP exists,
    // then MVP's share = 0 and the difference redistributes equally."
    // Only defined here for the computed (non-manual-input) methods.
    if (bundle.mvpExemptEnabled &&
        bundle.mvpName != null &&
        people.contains(bundle.mvpName)) {
      final mvp = bundle.mvpName!;
      final rest = [
        for (final p in people)
          if (p != mvp) p,
      ];
      shares = [
        ...equalSplit(bundle.totalRupees, rest),
        SplitShare(name: mvp, amount: 0),
      ];
    }

    final expenseId = ref
        .read(expensesProvider.notifier)
        .addExpense(
          title: 'Match expense bundle',
          category: ExpenseCategory.groundFees,
          amount: bundle.totalRupees,
          paidBy: [
            PaidByEntry(name: teamWalletPayerName, amount: bundle.totalRupees),
          ],
          splitMethod: bundle.splitMethod,
          splitAmong: shares,
          contextMatchId: matchId,
          createdByName: createdByName,
          createdByIsCaptain: createdByIsCaptain,
        );

    _update(
      matchId,
      (b) => b.copyWith(
        status: AutoSplitBundleStatus.finalized,
        expenseId: expenseId,
        notificationLog: [
          for (final s in shares)
            'P1: ${s.name} notified -- your share is ₹${s.amount} for '
                'this match (Pay inline)',
        ],
      ),
    );
  }

  /// AC: "Given the match is later ruled fake, then all shares void,
  /// settlements reverse-request, and coins claw back with user
  /// notifications and appeal links." No real settlement/coin ledger or
  /// appeals flow exists yet -- this logs what would happen, same
  /// convention as E4-10's ripple log.
  void voidBundle(String matchId, String reason) {
    _update(
      matchId,
      (b) => b.copyWith(
        status: AutoSplitBundleStatus.voided,
        voidReason: reason,
        notificationLog: [
          ...b.notificationLog,
          'Match ruled fake: all shares voided, settlements '
              'reverse-requested, coins clawed back. Notifications + '
              'appeal links not built yet (flagged).',
        ],
      ),
    );
  }

  void _update(String matchId, AutoSplitBundle Function(AutoSplitBundle) f) {
    final bundle = state.bundlesByMatchId[matchId];
    if (bundle == null) return;
    state = state.copyWith(
      bundlesByMatchId: {...state.bundlesByMatchId, matchId: f(bundle)},
    );
  }
}

final autoSplitBundleProvider =
    NotifierProvider<AutoSplitBundleNotifier, AutoSplitBundleState>(
      AutoSplitBundleNotifier.new,
    );
