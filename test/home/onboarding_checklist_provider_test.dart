import 'package:cricunity/home/onboarding_checklist_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('starts with nothing complete and shouldShow true', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final state = container.read(onboardingChecklistProvider);

    expect(state.completedCount, 0);
    expect(state.coinsEarned, 0);
    expect(state.shouldShow, isTrue);
  });

  test('completing an item marks it and grants its coins', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(onboardingChecklistProvider.notifier);

    notifier.completeItem(ChecklistItem.joinOrCreateTeam);

    final state = container.read(onboardingChecklistProvider);
    expect(state.completed, contains(ChecklistItem.joinOrCreateTeam));
    expect(
      state.coinsEarned,
      checklistItemCoins[ChecklistItem.joinOrCreateTeam],
    );
  });

  test('completing the same item twice does not double-grant coins', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(onboardingChecklistProvider.notifier);

    notifier.completeItem(ChecklistItem.settleFirstExpense);
    notifier.completeItem(ChecklistItem.settleFirstExpense);

    expect(
      container.read(onboardingChecklistProvider).coinsEarned,
      checklistItemCoins[ChecklistItem.settleFirstExpense],
    );
  });

  test('shouldShow flips false once 2 items are complete', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(onboardingChecklistProvider.notifier);

    notifier.completeItem(ChecklistItem.completeProfile);
    expect(container.read(onboardingChecklistProvider).shouldShow, isTrue);

    notifier.completeItem(ChecklistItem.joinOrCreateTeam);
    expect(container.read(onboardingChecklistProvider).shouldShow, isFalse);
  });

  test('reset returns to the initial state', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(onboardingChecklistProvider.notifier);
    notifier.completeItem(ChecklistItem.completeProfile);
    notifier.completeItem(ChecklistItem.joinOrCreateTeam);

    notifier.reset();

    final state = container.read(onboardingChecklistProvider);
    expect(state.completedCount, 0);
    expect(state.coinsEarned, 0);
    expect(state.shouldShow, isTrue);
  });
}
