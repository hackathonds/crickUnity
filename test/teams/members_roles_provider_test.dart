import 'package:cricunity/teams/members_roles_provider.dart';
import 'package:cricunity/teams/team_member_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('changeRole() by Owner updates the roster and writes a log entry', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(membersRolesProvider.notifier);

    final error = notifier.changeRole(
      memberName: 'Farhan Ali',
      newRole: TeamMemberRole.manager,
      actingRole: TeamMemberRole.owner,
      actorName: 'Rohan Verma',
    );

    expect(error, isNull);
    final state = container.read(membersRolesProvider);
    expect(
      state.roster.firstWhere((m) => m.name == 'Farhan Ali').role,
      TeamMemberRole.manager,
    );
    expect(state.log.single.action, 'Changed role to Manager');
    expect(state.log.single.actorName, 'Rohan Verma');
  });

  test('AC: a Vice-Captain cannot appoint another Vice-Captain', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(membersRolesProvider.notifier);

    final error = notifier.changeRole(
      memberName: 'Farhan Ali',
      newRole: TeamMemberRole.viceCaptain,
      actingRole: TeamMemberRole.viceCaptain,
      actorName: 'Priya Nair',
    );

    expect(error, isNotNull);
    expect(
      container
          .read(membersRolesProvider)
          .roster
          .firstWhere((m) => m.name == 'Farhan Ali')
          .role,
      TeamMemberRole.player,
    );
  });

  test('a Vice-Captain cannot demote the Manager', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(membersRolesProvider.notifier);

    final error = notifier.changeRole(
      memberName: 'Kabir Singh', // mock Manager
      newRole: TeamMemberRole.player,
      actingRole: TeamMemberRole.viceCaptain,
      actorName: 'Priya Nair',
    );

    expect(error, isNotNull);
  });

  test('a plain Player cannot change anyone\'s role', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(membersRolesProvider.notifier);

    final error = notifier.changeRole(
      memberName: 'Farhan Ali',
      newRole: TeamMemberRole.manager,
      actingRole: TeamMemberRole.player,
      actorName: 'Ananya Iyer',
    );

    expect(error, isNotNull);
  });

  test('removeMember() requires a non-empty reason', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(membersRolesProvider.notifier);

    final error = notifier.removeMember(
      memberName: 'Farhan Ali',
      actingRole: TeamMemberRole.owner,
      actorName: 'Rohan Verma',
      reason: '',
    );

    expect(error, isNotNull);
    expect(
      container
          .read(membersRolesProvider)
          .roster
          .any((m) => m.name == 'Farhan Ali'),
      isTrue,
    );
  });

  test('removeMember() with a reason removes the member and writes a log entry '
      'with that reason', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(membersRolesProvider.notifier);

    final error = notifier.removeMember(
      memberName: 'Farhan Ali',
      actingRole: TeamMemberRole.owner,
      actorName: 'Rohan Verma',
      reason: 'Inactive for 3 months',
    );

    expect(error, isNull);
    final state = container.read(membersRolesProvider);
    expect(state.roster.any((m) => m.name == 'Farhan Ali'), isFalse);
    expect(state.log.single.reason, 'Inactive for 3 months');
    expect(state.log.single.action, 'Removed from team');
  });

  test('AC: a Vice-Captain cannot remove the Captain', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(membersRolesProvider.notifier);

    final error = notifier.removeMember(
      memberName: 'Arjun Rao', // mock Captain
      actingRole: TeamMemberRole.viceCaptain,
      actorName: 'Priya Nair',
      reason: 'Disagreement',
    );

    expect(error, isNotNull);
    expect(
      container
          .read(membersRolesProvider)
          .roster
          .any((m) => m.name == 'Arjun Rao'),
      isTrue,
    );
  });

  test('a Vice-Captain can still remove a plain Player (only Captain removal '
      'is blocked)', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(membersRolesProvider.notifier);

    final error = notifier.removeMember(
      memberName: 'Farhan Ali',
      actingRole: TeamMemberRole.viceCaptain,
      actorName: 'Priya Nair',
      reason: 'No-show three times',
    );

    expect(error, isNull);
  });

  test('AC (last-admin guard): once the Captain is gone, the sole remaining '
      'Owner cannot be removed either', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(membersRolesProvider.notifier);

    // Mock roster starts with both a Captain and an Owner -- remove
    // the Captain first (still leaves an admin, so it's allowed) to
    // reach the actual "sole admin" state the guard protects.
    final firstRemoval = notifier.removeMember(
      memberName: 'Arjun Rao', // mock Captain
      actingRole: TeamMemberRole.owner,
      actorName: 'Rohan Verma',
      reason: 'Stepping down',
    );
    expect(firstRemoval, isNull);

    final error = notifier.removeMember(
      memberName: 'Rohan Verma', // now the sole Owner
      actingRole: TeamMemberRole.owner,
      actorName: 'Rohan Verma',
      reason: 'Leaving',
    );

    expect(error, isNotNull);
    expect(
      container
          .read(membersRolesProvider)
          .roster
          .any((m) => m.name == 'Rohan Verma'),
      isTrue,
    );
  });
}
