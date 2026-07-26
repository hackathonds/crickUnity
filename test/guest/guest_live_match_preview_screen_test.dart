import 'package:cricunity/design_system/theme/app_theme.dart';
import 'package:cricunity/guest/guest_live_match_preview_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget harness(VoidCallback onContinueWithPhone) => ProviderScope(
    child: MaterialApp(
      theme: AppTheme.themes[AppTheme.defaultLight],
      home: GuestLiveMatchPreviewScreen(
        onContinueWithPhone: onContinueWithPhone,
      ),
    ),
  );

  testWidgets('shows the persistent Guest chip', (tester) async {
    await tester.pumpWidget(harness(() {}));
    await tester.pumpAndSettle();

    expect(find.text('Viewing as guest · Sign up'), findsOneWidget);
  });

  testWidgets(
    'auto-prompts once on entry, naming the screen context, then never '
    'again this session',
    (tester) async {
      // A single ProviderScope (one "session") hosting a Navigator so the
      // screen can be entered twice without resetting guestProvider's
      // state, unlike two separate pumpWidget calls would.
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.themes[AppTheme.defaultLight],
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => GuestLiveMatchPreviewScreen(
                          onContinueWithPhone: () {},
                        ),
                      ),
                    ),
                    child: const Text('Enter'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Enter'));
      await tester.pumpAndSettle();
      expect(
        find.text('Create a free profile to follow every ball live.'),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('registerSheetNotNow')));
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Enter'));
      await tester.pumpAndSettle();

      expect(
        find.text('Create a free profile to follow every ball live.'),
        findsNothing,
      );
    },
  );

  testWidgets('Follow names the blocked action specifically (AC)', (
    tester,
  ) async {
    await tester.pumpWidget(harness(() {}));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('registerSheetNotNow')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('guestPreviewFollowButton')));
    await tester.pumpAndSettle();

    expect(
      find.text('Create a free profile to follow Titans vs Strikers.'),
      findsOneWidget,
    );
  });

  testWidgets('React and Comment each name their own action (AC)', (
    tester,
  ) async {
    await tester.pumpWidget(harness(() {}));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('registerSheetNotNow')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('guestPreviewReactButton')));
    await tester.pumpAndSettle();
    expect(
      find.text('Create a free profile to react to this match.'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('registerSheetNotNow')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('guestPreviewCommentButton')));
    await tester.pumpAndSettle();
    expect(
      find.text('Create a free profile to comment on this match.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'a tap always re-triggers the sheet even after a dismissal (AC)',
    (tester) async {
      await tester.pumpWidget(harness(() {}));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('registerSheetNotNow')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('guestPreviewFollowButton')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('registerSheetNotNow')));
      await tester.pumpAndSettle();

      // A second tap on the same blocked control still shows the sheet --
      // dismissals only cap the *auto*-prompt, never explicit taps.
      await tester.tap(find.byKey(const ValueKey('guestPreviewFollowButton')));
      await tester.pumpAndSettle();

      expect(
        find.text('Create a free profile to follow Titans vs Strikers.'),
        findsOneWidget,
      );
    },
  );

  testWidgets('opening the private-match demo shows the lock scaffold', (
    tester,
  ) async {
    await tester.pumpWidget(harness(() {}));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('registerSheetNotNow')));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('guestPreviewPrivateMatchLink')),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('This match is private — ask the captain for access'),
      findsOneWidget,
    );
  });

  testWidgets('Continue with phone from the auto-prompt fires the callback', (
    tester,
  ) async {
    var tapped = false;
    await tester.pumpWidget(harness(() => tapped = true));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('registerSheetContinueWithPhone')),
    );
    await tester.pumpAndSettle();

    expect(tapped, isTrue);
  });
}
