import 'package:cricunity/teams/duty_roster_models.dart';
import 'package:cricunity/teams/duty_roster_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AC: claiming an open slot grants Volunteer coins and XP', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(dutyRosterProvider.notifier);

    final result = notifier.claim('duty-2', 'Kabir Singh');

    expect(result.succeeded, isTrue);
    expect(result.coinsGranted, volunteerDutyCoins);
    expect(result.xpGranted, volunteerDutyXp);
    final slot = container
        .read(dutyRosterProvider)
        .slots
        .firstWhere((s) => s.id == 'duty-2');
    expect(slot.claimantName, 'Kabir Singh');
  });

  test('claiming an already-claimed slot is rejected', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(dutyRosterProvider.notifier);

    // Mock duty-1 is already claimed by Priya Nair.
    final result = notifier.claim('duty-1', 'Kabir Singh');

    expect(result.succeeded, isFalse);
    expect(result.coinsGranted, 0);
  });

  test('unclaim() frees the slot back up', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(dutyRosterProvider.notifier);

    notifier.unclaim('duty-1');

    final slot = container
        .read(dutyRosterProvider)
        .slots
        .firstWhere((s) => s.id == 'duty-1');
    expect(slot.claimantName, isNull);
  });
}
