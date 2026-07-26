import 'package:cricunity/teams/create_team_provider.dart';
import 'package:cricunity/teams/team_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CreateTeamState (pure getters)', () {
    test('a name under 3 characters is not long enough', () {
      const state = CreateTeamState(name: 'Ab');
      expect(state.nameLongEnough, isFalse);
    });

    test('a name already used in that city is taken, with suggestions', () {
      const state = CreateTeamState(name: 'Lions CC', city: 'Pune');
      expect(state.nameTaken, isTrue);
      expect(state.nameSuggestions, isNotEmpty);
    });

    test('the same name is not taken in a city with no existing teams', () {
      const state = CreateTeamState(name: 'Lions CC', city: 'Nowhereville');
      expect(state.nameTaken, isFalse);
      expect(state.nameSuggestions, isEmpty);
    });

    test('AC: owning the max teams blocks creating another', () {
      const state = CreateTeamState(ownedTeamCount: maxOwnedTeams);
      expect(state.canCreateAnotherTeam, isFalse);

      const underCap = CreateTeamState(ownedTeamCount: maxOwnedTeams - 1);
      expect(underCap.canCreateAnotherTeam, isTrue);
    });

    test(
      'canCreate requires a valid name, a city, and at least one format',
      () {
        const incomplete = CreateTeamState(name: 'Falcons', city: 'Pune');
        expect(incomplete.canCreate, isFalse);

        const complete = CreateTeamState(
          name: 'Falcons',
          city: 'Nagpur',
          formatFocus: {TeamFormat.t20},
        );
        expect(complete.canCreate, isTrue);
      },
    );
  });

  group('CreateTeamNotifier', () {
    test('toggling a format twice returns to unselected', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(createTeamProvider.notifier);

      notifier.toggleFormat(TeamFormat.t20);
      expect(
        container.read(createTeamProvider).formatFocus,
        contains(TeamFormat.t20),
      );

      notifier.toggleFormat(TeamFormat.t20);
      expect(
        container.read(createTeamProvider).formatFocus,
        isNot(contains(TeamFormat.t20)),
      );
    });

    test('createTeam() returns null when canCreate is false', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(createTeamProvider.notifier);

      expect(notifier.createTeam(), isNull);
    });

    test('createTeam() builds a Team from the wizard state once valid', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(createTeamProvider.notifier);

      notifier.setName('Falcons');
      notifier.setCity('Nagpur');
      notifier.setHomeGround('VCA Stadium');
      notifier.toggleFormat(TeamFormat.t20);
      notifier.setJoinPolicy(TeamJoinPolicy.inviteOnly);

      final team = notifier.createTeam();

      expect(team, isNotNull);
      expect(team!.name, 'Falcons');
      expect(team.city, 'Nagpur');
      expect(team.homeGround, 'VCA Stadium');
      expect(team.formatFocus, contains(TeamFormat.t20));
      expect(team.joinPolicy, TeamJoinPolicy.inviteOnly);
    });

    test('reset() returns to the initial empty state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(createTeamProvider.notifier);
      notifier.setName('Falcons');

      notifier.reset();

      expect(container.read(createTeamProvider).name, isEmpty);
    });
  });
}
