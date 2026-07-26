import 'package:cricunity/guest/guest_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('starts as a guest with no auto-prompt spent', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final state = container.read(guestProvider);

    expect(state.isGuest, isTrue);
    expect(state.hasAutoPrompted, isFalse);
  });

  test('consumeAutoPromptBudget allows exactly once per session', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(guestProvider.notifier);

    expect(notifier.consumeAutoPromptBudget(), isTrue);
    expect(container.read(guestProvider).hasAutoPrompted, isTrue);

    expect(notifier.consumeAutoPromptBudget(), isFalse);
  });

  test('becomeRegistered clears isGuest', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(guestProvider.notifier);

    notifier.becomeRegistered();

    expect(container.read(guestProvider).isGuest, isFalse);
  });

  test('reset returns to the initial state', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(guestProvider.notifier);
    notifier.consumeAutoPromptBudget();
    notifier.becomeRegistered();

    notifier.reset();

    final state = container.read(guestProvider);
    expect(state.isGuest, isTrue);
    expect(state.hasAutoPrompted, isFalse);
  });
}
