import 'package:cricunity/design_system/components/app_button.dart';
import 'package:cricunity/design_system/theme/app_theme.dart';
import 'package:cricunity/teams/create_team_flow.dart';
import 'package:cricunity/teams/create_team_provider.dart';
import 'package:cricunity/teams/team_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// AC: "team limit 5 owned per user" (PRD §6.1) -- seeded via a provider
/// override since the real notifier always starts at 0 owned teams (no
/// backend to have pre-existing state from).
class _MaxedOutNotifier extends CreateTeamNotifier {
  @override
  CreateTeamState build() =>
      const CreateTeamState(ownedTeamCount: maxOwnedTeams);
}

/// Pre-seeds a city with an already-taken team name (per
/// `mockExistingTeamNamesInCity`) so the taken/suggestions path is
/// reachable without threading a city field through the Name step itself.
class _PuneNotifier extends CreateTeamNotifier {
  @override
  CreateTeamState build() => const CreateTeamState(city: 'Pune');
}

void main() {
  Widget harness({
    List<Override> overrides = const [],
    required Widget child,
  }) => ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      theme: AppTheme.themes[AppTheme.defaultLight],
      home: child,
    ),
  );

  VoidCallback? continueOnPressed(WidgetTester tester, String key) =>
      tester.widget<AppButton>(find.byKey(ValueKey(key))).onPressed;

  testWidgets(
    'AC: the 5-owned-team cap shows a clear error and blocks the wizard',
    (tester) async {
      await tester.pumpWidget(
        harness(
          overrides: [createTeamProvider.overrideWith(_MaxedOutNotifier.new)],
          child: CreateTeamFlow(onTeamCreated: (_) {}),
        ),
      );

      expect(
        find.byKey(const ValueKey('teamLimitReachedBanner')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('teamNameField')), findsNothing);
      expect(continueOnPressed(tester, 'teamNameContinue'), isNull);
    },
  );

  testWidgets('a name already taken in the city shows suggestions and blocks '
      'Continue until changed', (tester) async {
    await tester.pumpWidget(
      harness(
        overrides: [createTeamProvider.overrideWith(_PuneNotifier.new)],
        child: CreateTeamFlow(onTeamCreated: (_) {}),
      ),
    );

    await tester.enterText(
      find.byKey(const ValueKey('teamNameField')),
      'Lions CC',
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('teamNameSuggestions')), findsOneWidget);
    expect(continueOnPressed(tester, 'teamNameContinue'), isNull);

    await tester.tap(find.text('Lions CC Pune'));
    await tester.pump();

    expect(continueOnPressed(tester, 'teamNameContinue'), isNotNull);
  });

  testWidgets(
    'walking through every step end-to-end creates the team and reports it '
    'back',
    (tester) async {
      Team? createdTeam;
      await tester.pumpWidget(
        harness(
          child: CreateTeamFlow(onTeamCreated: (team) => createdTeam = team),
        ),
      );

      await tester.enterText(
        find.byKey(const ValueKey('teamNameField')),
        'Falcons',
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('teamNameContinue')));
      await tester.pumpAndSettle();

      // Logo step -- no input required.
      await tester.tap(find.byKey(const ValueKey('teamLogoContinue')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey('teamCityField')),
        'Nagpur',
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('teamCityGroundContinue')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('teamFormatOption_t20')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('teamFormatContinue')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('teamJoinPolicyContinue')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('teamColorsCreateButton')));
      await tester.pumpAndSettle();

      expect(find.textContaining('Falcons is live!'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('teamCreatedDoneButton')));
      await tester.pumpAndSettle();

      expect(createdTeam, isNotNull);
      expect(createdTeam!.name, 'Falcons');
      expect(createdTeam!.city, 'Nagpur');
      expect(createdTeam!.formatFocus, contains(TeamFormat.t20));
    },
  );
}
