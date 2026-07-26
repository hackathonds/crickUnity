import 'package:cricunity/teams/join_requests_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('starts with the mock pending requests', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final state = container.read(joinRequestsProvider);

    expect(state.pending, isNotEmpty);
    expect(state.approved, isEmpty);
    expect(state.denied, isEmpty);
  });

  test('approve() moves a request from pending to approved', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(joinRequestsProvider.notifier);
    final id = container.read(joinRequestsProvider).pending.first.id;

    notifier.approve(id);

    final state = container.read(joinRequestsProvider);
    expect(state.pending.any((r) => r.id == id), isFalse);
    expect(state.approved.any((r) => r.id == id), isTrue);
  });

  test('deny() with a canned reason moves the request to denied with that '
      'reason', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(joinRequestsProvider.notifier);
    final id = container.read(joinRequestsProvider).pending.first.id;

    notifier.deny(id, reason: 'Squad is full');

    final state = container.read(joinRequestsProvider);
    expect(state.pending.any((r) => r.id == id), isFalse);
    expect(state.denied.single.reason, 'Squad is full');
  });

  test('deny() without a reason still records the denial', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(joinRequestsProvider.notifier);
    final id = container.read(joinRequestsProvider).pending.first.id;

    notifier.deny(id);

    expect(container.read(joinRequestsProvider).denied.single.reason, isNull);
  });
}
