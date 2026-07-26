import 'package:cricunity/teams/availability_matrix_models.dart';
import 'package:cricunity/teams/practice_session_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('canCheckIn is true right at the scheduled time', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(practiceSessionProvider.notifier);
    final scheduledAt = container
        .read(practiceSessionProvider)
        .session
        .scheduledAt;

    expect(notifier.canCheckIn(now: () => scheduledAt), isTrue);
  });

  test('AC: check-in is blocked more than 1 hour before the session', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(practiceSessionProvider.notifier);
    final scheduledAt = container
        .read(practiceSessionProvider)
        .session
        .scheduledAt;

    final result = notifier.checkIn(
      'Priya Nair',
      now: () => scheduledAt.subtract(const Duration(hours: 2)),
    );

    expect(result.succeeded, isFalse);
  });

  test('AC: check-in is blocked more than 1 hour after the session', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(practiceSessionProvider.notifier);
    final scheduledAt = container
        .read(practiceSessionProvider)
        .session
        .scheduledAt;

    final result = notifier.checkIn(
      'Priya Nair',
      now: () => scheduledAt.add(const Duration(hours: 2)),
    );

    expect(result.succeeded, isFalse);
  });

  test('AC: check-in within the ±1h window grants coins and XP', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(practiceSessionProvider.notifier);
    final scheduledAt = container
        .read(practiceSessionProvider)
        .session
        .scheduledAt;

    final result = notifier.checkIn(
      'Priya Nair',
      now: () => scheduledAt.add(const Duration(minutes: 45)),
    );

    expect(result.succeeded, isTrue);
    expect(result.coinsGranted, practiceAttendanceCoins);
    expect(result.xpGranted, practiceAttendanceXp);
    expect(
      container.read(practiceSessionProvider).session.checkedIn,
      contains('Priya Nair'),
    );
  });

  test('checking in twice is rejected the second time', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(practiceSessionProvider.notifier);
    final scheduledAt = container
        .read(practiceSessionProvider)
        .session
        .scheduledAt;

    notifier.checkIn('Priya Nair', now: () => scheduledAt);
    final second = notifier.checkIn('Priya Nair', now: () => scheduledAt);

    expect(second.succeeded, isFalse);
  });

  test('AC: the weekly coin/XP cap is enforced (mock Kabir Singh is '
      'already at the cap)', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(practiceSessionProvider.notifier);
    final scheduledAt = container
        .read(practiceSessionProvider)
        .session
        .scheduledAt;

    final result = notifier.checkIn('Kabir Singh', now: () => scheduledAt);

    expect(result.succeeded, isTrue);
    expect(result.coinsGranted, 0);
    expect(result.xpGranted, 0);
    // Still recorded as attended even though no reward was granted.
    expect(
      container.read(practiceSessionProvider).session.checkedIn,
      contains('Kabir Singh'),
    );
  });

  test('rsvp() records the member\'s response', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(practiceSessionProvider.notifier);

    notifier.rsvp('Farhan Ali', AvailabilityResponse.yes);

    expect(
      container.read(practiceSessionProvider).session.rsvps['Farhan Ali'],
      AvailabilityResponse.yes,
    );
  });

  test('AC: endSession() logs a no-show for a "Yes" RSVP that never checked '
      'in', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(practiceSessionProvider.notifier);

    // Mock: Priya Nair and Kabir Singh RSVP'd yes; neither checks in.
    notifier.endSession();

    final noShows = container
        .read(practiceSessionProvider)
        .session
        .noShows
        .map((r) => r.memberName)
        .toList();
    expect(noShows, containsAll(['Priya Nair', 'Kabir Singh']));
  });

  test('excuseNoShow() marks the record excused with a reason', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(practiceSessionProvider.notifier);
    notifier.endSession();

    notifier.excuseNoShow('Priya Nair', reason: 'Family emergency');

    final record = container
        .read(practiceSessionProvider)
        .session
        .noShows
        .firstWhere((r) => r.memberName == 'Priya Nair');
    expect(record.excused, isTrue);
    expect(record.reason, 'Family emergency');
  });

  test('a member who checked in is never logged as a no-show', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(practiceSessionProvider.notifier);
    final scheduledAt = container
        .read(practiceSessionProvider)
        .session
        .scheduledAt;

    notifier.checkIn('Priya Nair', now: () => scheduledAt);
    notifier.endSession();

    final noShows = container
        .read(practiceSessionProvider)
        .session
        .noShows
        .map((r) => r.memberName)
        .toList();
    expect(noShows, isNot(contains('Priya Nair')));
  });
}
