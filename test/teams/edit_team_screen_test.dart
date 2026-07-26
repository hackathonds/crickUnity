import 'package:cricunity/design_system/theme/app_theme.dart';
import 'package:cricunity/teams/edit_team_provider.dart';
import 'package:cricunity/teams/edit_team_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget harness({bool canEditIdentity = true}) => ProviderScope(
    child: MaterialApp(
      theme: AppTheme.themes[AppTheme.defaultLight],
      home: EditTeamScreen(canEditIdentity: canEditIdentity),
    ),
  );

  /// Hosts EditTeamScreen behind a push so there's a stable, still-mounted
  /// widget to read the provider container from after the screen pops --
  /// same pattern as edit_profile_screen_test.dart's pushableHarness().
  Widget pushableHarness({bool canEditIdentity = true}) => ProviderScope(
    child: MaterialApp(
      theme: AppTheme.themes[AppTheme.defaultLight],
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      EditTeamScreen(canEditIdentity: canEditIdentity),
                ),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    ),
  );

  testWidgets(
    'AC: a Manager (canEditIdentity: false) never sees the Name or Colors '
    'fields, only logistics',
    (tester) async {
      await tester.pumpWidget(harness(canEditIdentity: false));

      expect(find.byKey(const ValueKey('editTeamNameField')), findsNothing);
      expect(find.byKey(const ValueKey('editTeamColorSwatches')), findsNothing);
      expect(find.byKey(const ValueKey('editTeamCityField')), findsOneWidget);
      expect(find.byKey(const ValueKey('editTeamGroundField')), findsOneWidget);
    },
  );

  testWidgets('an Owner/Captain sees identity fields too', (tester) async {
    await tester.pumpWidget(harness());

    expect(find.byKey(const ValueKey('editTeamNameField')), findsOneWidget);
    expect(find.byKey(const ValueKey('editTeamColorSwatches')), findsOneWidget);
  });

  testWidgets('the Save button is hidden until the form is dirty', (
    tester,
  ) async {
    await tester.pumpWidget(harness());

    expect(find.byKey(const ValueKey('editTeamSaveButton')), findsNothing);

    await tester.enterText(
      find.byKey(const ValueKey('editTeamCityField')),
      'Mumbai',
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('editTeamSaveButton')), findsOneWidget);
  });

  testWidgets('Save commits the edit and pops the screen', (tester) async {
    await tester.pumpWidget(pushableHarness());
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('editTeamCityField')),
      'Mumbai',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('editTeamSaveButton')));
    await tester.pumpAndSettle();

    expect(find.byType(EditTeamScreen), findsNothing);
    final context = tester.element(find.text('Open'));
    final container = ProviderScope.containerOf(context);
    expect(container.read(editTeamProvider).baseline.city, 'Mumbai');
  });

  testWidgets('leaving with unsaved changes shows the Discard-changes dialog', (
    tester,
  ) async {
    await tester.pumpWidget(pushableHarness());
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('editTeamCityField')),
      'Mumbai',
    );
    await tester.pump();

    final navigatorState = tester.state<NavigatorState>(
      find.byType(Navigator).last,
    );
    navigatorState.maybePop();
    await tester.pumpAndSettle();

    expect(find.text('Discard changes?'), findsOneWidget);
  });

  testWidgets(
    'AC: after saving a name change, the "Formerly known as" chip appears',
    (tester) async {
      await tester.pumpWidget(harness());

      await tester.enterText(
        find.byKey(const ValueKey('editTeamNameField')),
        'New Name CC',
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('editTeamSaveButton')));
      await tester.pumpAndSettle();

      // Screen popped -- reopen to see the post-save state rendered.
      final context = tester.element(find.byType(MaterialApp));
      final container = ProviderScope.containerOf(context);
      expect(container.read(editTeamProvider).formerNameActive(), isTrue);
    },
  );
}
