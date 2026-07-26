import 'package:cricunity/design_system/theme/app_theme.dart';
import 'package:cricunity/profile/edit_profile_provider.dart';
import 'package:cricunity/profile/edit_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget harness() => ProviderScope(
    child: MaterialApp(
      theme: AppTheme.themes[AppTheme.defaultLight],
      home: const EditProfileScreen(),
    ),
  );

  /// Hosts EditProfileScreen behind a push (rather than as `home:`
  /// directly) so there's a stable, still-mounted widget (the "Open"
  /// button's Scaffold) to read the provider container from *after* the
  /// screen pops -- EditProfileScreen's own Element is gone by then.
  Widget pushableHarness() => ProviderScope(
    child: MaterialApp(
      theme: AppTheme.themes[AppTheme.defaultLight],
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const EditProfileScreen()),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    ),
  );

  testWidgets('the Save button is hidden until the form is dirty', (
    tester,
  ) async {
    await tester.pumpWidget(harness());

    expect(find.byKey(const ValueKey('editProfileSaveButton')), findsNothing);

    await tester.enterText(
      find.byKey(const ValueKey('editProfileCityField')),
      'Mumbai',
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('editProfileSaveButton')), findsOneWidget);
  });

  testWidgets('shows the name-change budget helper text', (tester) async {
    await tester.pumpWidget(harness());

    expect(
      find.text('2 of 2 name changes remaining this year'),
      findsOneWidget,
    );
  });

  testWidgets('Save commits the edit and pops the screen', (tester) async {
    await tester.pumpWidget(pushableHarness());
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('editProfileCityField')),
      'Mumbai',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('editProfileSaveButton')));
    await tester.pumpAndSettle();

    expect(find.byType(EditProfileScreen), findsNothing);
    final context = tester.element(find.text('Open'));
    final container = ProviderScope.containerOf(context);
    expect(container.read(editProfileProvider).baseline.city, 'Mumbai');
  });

  testWidgets('leaving with unsaved changes shows the Discard-changes dialog; '
      'Discard reverts and pops', (tester) async {
    await tester.pumpWidget(pushableHarness());
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('editProfileCityField')),
      'Mumbai',
    );
    await tester.pump();

    final navigatorState = tester.state<NavigatorState>(
      find.byType(Navigator).last,
    );
    navigatorState.maybePop();
    await tester.pumpAndSettle();

    expect(find.text('Discard changes?'), findsOneWidget);

    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();

    expect(find.byType(EditProfileScreen), findsNothing);
    final context = tester.element(find.text('Open'));
    final container = ProviderScope.containerOf(context);
    expect(container.read(editProfileProvider).isDirty, isFalse);
  });

  testWidgets('Cancel dismisses the dialog without discarding', (tester) async {
    await tester.pumpWidget(pushableHarness());
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('editProfileCityField')),
      'Mumbai',
    );
    await tester.pump();

    final navigatorState = tester.state<NavigatorState>(
      find.byType(Navigator).last,
    );
    navigatorState.maybePop();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.byType(EditProfileScreen), findsOneWidget);
    final context = tester.element(find.byType(EditProfileScreen));
    final container = ProviderScope.containerOf(context);
    expect(container.read(editProfileProvider).isDirty, isTrue);
  });

  testWidgets('the Titles row shows "None equipped" by default and opens the '
      'picker sheet on tap', (tester) async {
    await tester.pumpWidget(harness());

    expect(find.text('None equipped'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('editProfileTitlesRow')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('titleOption_none')), findsOneWidget);
  });

  testWidgets('equipping a title updates the Titles row without a Save', (
    tester,
  ) async {
    await tester.pumpWidget(harness());

    await tester.tap(find.byKey(const ValueKey('editProfileTitlesRow')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('titleOption_Iron Player')));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(20, 20)); // dismiss the sheet
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byKey(const ValueKey('editProfileTitlesRow')),
        matching: find.text('Iron Player'),
      ),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('editProfileSaveButton')), findsNothing);
  });
}
