import 'package:cricunity/teams/availability_matrix_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('canNudge is true before any nudge has been sent', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(availabilityMatrixProvider.notifier);

    expect(notifier.canNudge('evt-1'), isTrue);
  });

  test('AC: only 1 nudge is allowed per event every 12 hours', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(availabilityMatrixProvider.notifier);
    final fixedNow = DateTime(2026, 3, 1, 9);

    final first = notifier.nudgePending('evt-1', now: () => fixedNow);
    expect(first, isNull);

    expect(
      notifier.canNudge(
        'evt-1',
        now: () => fixedNow.add(const Duration(hours: 5)),
      ),
      isFalse,
    );
    final tooSoon = notifier.nudgePending(
      'evt-1',
      now: () => fixedNow.add(const Duration(hours: 5)),
    );
    expect(tooSoon, isNotNull);

    expect(
      notifier.canNudge(
        'evt-1',
        now: () => fixedNow.add(const Duration(hours: 13)),
      ),
      isTrue,
    );
    final afterCooldown = notifier.nudgePending(
      'evt-1',
      now: () => fixedNow.add(const Duration(hours: 13)),
    );
    expect(afterCooldown, isNull);
  });

  test('the nudge cooldown is tracked independently per event', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(availabilityMatrixProvider.notifier);
    final fixedNow = DateTime(2026, 3, 1, 9);

    notifier.nudgePending('evt-1', now: () => fixedNow);

    expect(notifier.canNudge('evt-2', now: () => fixedNow), isTrue);
    final result = notifier.nudgePending('evt-2', now: () => fixedNow);
    expect(result, isNull);
  });
}
