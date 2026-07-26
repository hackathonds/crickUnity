import 'package:flutter_riverpod/flutter_riverpod.dart';

/// E1-05 · PRD §4 Home Dashboard edge cases: "Brand-new user sees an
/// onboarding checklist widget (Complete profile -> Join/create team ->
/// Play first match -> Settle first expense; each grants coins) replacing
/// most widgets until 2 items complete."
///
/// Team/Match/Expense features don't exist yet (later epics), so 3 of
/// these 4 items have no real event to react to -- they're completed via
/// a debug/demo toggle for now, same mocked-event pattern as prior
/// stories. "Complete profile" is the one item wired to something real:
/// [ProfileWizardState.completeness] from E1-03.
///
/// Coin amounts: PRD §13.1's earning table gives exact values for two of
/// these four -- "Play a verified match" (20) and "Settle expense <=48h"
/// (5) -- reused here. The other two ("Complete profile", "Join/create
/// team") have no PRD-cited amount; 10 each is a flagged placeholder, not
/// a citation.
enum ChecklistItem {
  completeProfile,
  joinOrCreateTeam,
  playFirstMatch,
  settleFirstExpense,
}

const Map<ChecklistItem, String> checklistItemLabels = {
  ChecklistItem.completeProfile: 'Complete your profile',
  ChecklistItem.joinOrCreateTeam: 'Join or create a team',
  ChecklistItem.playFirstMatch: 'Play your first match',
  ChecklistItem.settleFirstExpense: 'Settle your first expense',
};

const Map<ChecklistItem, int> checklistItemCoins = {
  ChecklistItem.completeProfile: 10,
  ChecklistItem.joinOrCreateTeam: 10,
  ChecklistItem.playFirstMatch: 20,
  ChecklistItem.settleFirstExpense: 5,
};

class OnboardingChecklistState {
  final Set<ChecklistItem> completed;
  final int coinsEarned;

  const OnboardingChecklistState({
    this.completed = const {},
    this.coinsEarned = 0,
  });

  int get completedCount => completed.length;

  /// PRD §4: "replacing most widgets until 2 items complete."
  bool get shouldShow => completedCount < 2;

  OnboardingChecklistState copyWith({
    Set<ChecklistItem>? completed,
    int? coinsEarned,
  }) {
    return OnboardingChecklistState(
      completed: completed ?? this.completed,
      coinsEarned: coinsEarned ?? this.coinsEarned,
    );
  }
}

class OnboardingChecklistNotifier extends Notifier<OnboardingChecklistState> {
  @override
  OnboardingChecklistState build() => const OnboardingChecklistState();

  /// Idempotent: completing an already-completed item doesn't grant coins
  /// twice.
  void completeItem(ChecklistItem item) {
    if (state.completed.contains(item)) return;
    state = state.copyWith(
      completed: {...state.completed, item},
      coinsEarned: state.coinsEarned + checklistItemCoins[item]!,
    );
  }

  void reset() => state = const OnboardingChecklistState();
}

final onboardingChecklistProvider =
    NotifierProvider<OnboardingChecklistNotifier, OnboardingChecklistState>(
      OnboardingChecklistNotifier.new,
    );
