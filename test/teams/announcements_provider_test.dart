import 'package:cricunity/teams/announcements_provider.dart';
import 'package:cricunity/teams/team_member_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('starts with the mock announcements', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(announcementsProvider).announcements, isNotEmpty);
  });

  test('a plain Player cannot post an announcement', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(announcementsProvider.notifier);

    final error = notifier.post(
      body: 'Hello team',
      actorName: 'Ananya Iyer',
      actingRole: TeamMemberRole.player,
      totalMembers: 18,
    );

    expect(error, isNotNull);
  });

  test('an empty body is rejected', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(announcementsProvider.notifier);

    final error = notifier.post(
      body: '   ',
      actorName: 'Arjun Rao',
      actingRole: TeamMemberRole.captain,
      totalMembers: 18,
    );

    expect(error, isNotNull);
  });

  test('Captain/VC/Manager/Owner can post a normal announcement', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(announcementsProvider.notifier);

    for (final role in [
      TeamMemberRole.captain,
      TeamMemberRole.viceCaptain,
      TeamMemberRole.manager,
      TeamMemberRole.owner,
    ]) {
      final error = notifier.post(
        body: 'Announcement from $role',
        actorName: 'Someone',
        actingRole: role,
        totalMembers: 18,
      );
      expect(error, isNull, reason: '$role should be able to post');
    }
  });

  test('AC: only 1 push-priority announcement is allowed every 6 hours', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(announcementsProvider.notifier);
    // Relative to the real clock, not an arbitrary calendar date -- the
    // mock data's own postedAt values (announcement_models.dart) are
    // generated from the real DateTime.now() at provider-build time.
    final fixedNow = DateTime.now().add(const Duration(days: 30));

    final first = notifier.post(
      body: 'First urgent update',
      actorName: 'Arjun Rao',
      actingRole: TeamMemberRole.captain,
      totalMembers: 18,
      isPushPriority: true,
      now: () => fixedNow,
    );
    expect(first, isNull);

    final secondTooSoon = notifier.post(
      body: 'Second urgent update',
      actorName: 'Arjun Rao',
      actingRole: TeamMemberRole.captain,
      totalMembers: 18,
      isPushPriority: true,
      now: () => fixedNow.add(const Duration(hours: 3)),
    );
    expect(secondTooSoon, isNotNull);

    final afterCooldown = notifier.post(
      body: 'Third urgent update',
      actorName: 'Arjun Rao',
      actingRole: TeamMemberRole.captain,
      totalMembers: 18,
      isPushPriority: true,
      now: () => fixedNow.add(const Duration(hours: 7)),
    );
    expect(afterCooldown, isNull);
  });

  test('a non-push-priority announcement is never rate-limited', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(announcementsProvider.notifier);
    final fixedNow = DateTime(2026, 3, 1, 12);

    notifier.post(
      body: 'Normal update 1',
      actorName: 'Arjun Rao',
      actingRole: TeamMemberRole.captain,
      totalMembers: 18,
      now: () => fixedNow,
    );
    final second = notifier.post(
      body: 'Normal update 2',
      actorName: 'Arjun Rao',
      actingRole: TeamMemberRole.captain,
      totalMembers: 18,
      now: () => fixedNow.add(const Duration(minutes: 5)),
    );

    expect(second, isNull);
  });

  test('toggleComments() flips the flag for that announcement only', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(announcementsProvider.notifier);
    final id = container.read(announcementsProvider).announcements.first.id;
    final before = container
        .read(announcementsProvider)
        .announcements
        .first
        .commentsEnabled;

    notifier.toggleComments(id);

    final after = container
        .read(announcementsProvider)
        .announcements
        .firstWhere((a) => a.id == id)
        .commentsEnabled;
    expect(after, isNot(before));
  });

  test('markSeen() adds the member without duplicating', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(announcementsProvider.notifier);
    final id = container.read(announcementsProvider).announcements.first.id;

    notifier.markSeen(id, 'New Member');
    notifier.markSeen(id, 'New Member');

    final seenBy = container
        .read(announcementsProvider)
        .announcements
        .firstWhere((a) => a.id == id)
        .seenBy;
    expect(seenBy.where((n) => n == 'New Member').length, 1);
  });
}
