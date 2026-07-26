import 'package:cricunity/teams/team_invite_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('generate() creates a 7-day-expiry link', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(teamInviteProvider.notifier);
    final fixedNow = DateTime(2026, 3, 1);

    notifier.generate('Lions CC', now: () => fixedNow);

    final link = container.read(teamInviteProvider).link;
    expect(link, isNotNull);
    expect(link!.revoked, isFalse);
    expect(link.expiresAt, fixedNow.add(const Duration(days: 7)));
    expect(link.isExpired(now: () => fixedNow), isFalse);
  });

  test('revoke() marks the link revoked and expired', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(teamInviteProvider.notifier);
    notifier.generate('Lions CC');

    notifier.revoke();

    final link = container.read(teamInviteProvider).link;
    expect(link!.revoked, isTrue);
    expect(link.isExpired(), isTrue);
  });

  test('revoke() before any link is generated is a no-op', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(teamInviteProvider.notifier);

    notifier.revoke();

    expect(container.read(teamInviteProvider).link, isNull);
  });
}
