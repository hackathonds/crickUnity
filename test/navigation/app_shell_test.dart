import 'package:cricunity/design_system/components/app_button.dart';
import 'package:cricunity/main.dart';
import 'package:cricunity/navigation/app_router.dart';
import 'package:cricunity/navigation/pinned_live_match_provider.dart';
import 'package:cricunity/navigation/push_depth_tracker.dart';
import 'package:cricunity/roles/current_roles_provider.dart';
import 'package:cricunity/roles/user_role.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FixedPinnedLiveMatch extends PinnedLiveMatchNotifier {
  final String? value;
  _FixedPinnedLiveMatch(this.value);

  @override
  String? build() => value;
}

class _FixedRoles extends CurrentRolesNotifier {
  final Set<UserRole> value;
  _FixedRoles(this.value);

  @override
  Set<UserRole> build() => value;
}

void main() {
  testWidgets(
    'all 4 tabs show their placeholder content; FAB is centerDocked',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: CricUnityApp(
            router: createAppRouter(),
            startWithOnboardingComplete: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Home placeholder row 0'), findsOneWidget);
      expect(find.byType(AppFab), findsOneWidget);
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(
        scaffold.floatingActionButtonLocation,
        FloatingActionButtonLocation.centerDocked,
      );

      await tester.tap(find.byKey(const ValueKey('bottomNavItem-Matches')));
      await tester.pumpAndSettle();
      expect(find.text('Matches placeholder row 0'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('bottomNavItem-Community')));
      await tester.pumpAndSettle();
      expect(find.text('Community placeholder row 0'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('bottomNavItem-Profile')));
      await tester.pumpAndSettle();
      expect(find.text('Profile placeholder row 0'), findsOneWidget);
    },
  );

  testWidgets(
    're-tapping the active tab scrolls to top; tapping again while at top refreshes',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: CricUnityApp(
            router: createAppRouter(),
            startWithOnboardingComplete: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.drag(
        find.text('Home placeholder row 0'),
        const Offset(0, -400),
      );
      await tester.pumpAndSettle();

      // First re-tap while scrolled away: scrolls to top, no refresh yet.
      await tester.tap(find.byKey(const ValueKey('bottomNavItem-Home')));
      await tester.pumpAndSettle();
      expect(find.text('Refreshed'), findsNothing);

      // Second re-tap, now already at top: triggers the refresh signal.
      await tester.tap(find.byKey(const ValueKey('bottomNavItem-Home')));
      await tester.pump();
      expect(find.text('Refreshed'), findsOneWidget);
    },
  );

  testWidgets(
    'long-press Matches with no pinned match shows the empty message',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: CricUnityApp(
            router: createAppRouter(),
            startWithOnboardingComplete: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.longPress(
        find.byKey(const ValueKey('bottomNavItem-Matches')),
      );
      await tester.pump();

      expect(find.text('No live match pinned right now.'), findsOneWidget);
    },
  );

  testWidgets('long-press Matches with a pinned match jumps to it', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          pinnedLiveMatchProvider.overrideWith(
            () => _FixedPinnedLiveMatch('Titans vs Strikers'),
          ),
        ],
        child: CricUnityApp(
          router: createAppRouter(),
          startWithOnboardingComplete: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.longPress(find.byKey(const ValueKey('bottomNavItem-Matches')));
    await tester.pumpAndSettle();

    expect(find.text('Live: Titans vs Strikers'), findsOneWidget);
  });

  testWidgets(
    "drawer's Consoles section is empty by default and appears once a console role activates",
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: CricUnityApp(
            router: createAppRouter(),
            startWithOnboardingComplete: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
      scaffoldState.openDrawer();
      await tester.pumpAndSettle();

      expect(find.text('Consoles'), findsNothing);
      expect(find.text('Captain Console'), findsNothing);
    },
  );

  testWidgets('drawer shows Captain Console once the captain role is active', (
    tester,
  ) async {
    // The drawer's content is taller than a default test viewport — same
    // sliver/list lazy-build issue hit in E0-02/E0-03; make the surface
    // tall enough that every section is actually built.
    tester.view.physicalSize = const Size(400, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentRolesProvider.overrideWith(
            () => _FixedRoles({UserRole.captain}),
          ),
        ],
        child: CricUnityApp(
          router: createAppRouter(),
          startWithOnboardingComplete: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
    scaffoldState.openDrawer();
    await tester.pumpAndSettle();

    expect(find.text('Consoles'), findsOneWidget);
    expect(find.text('Captain Console'), findsOneWidget);
  });

  testWidgets('pushing maxPushDepth levels deep from a tab root hits the cap', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: CricUnityApp(
          router: createAppRouter(),
          startWithOnboardingComplete: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    for (var i = 0; i < maxPushDepth; i++) {
      await tester.tap(find.text('Open next'));
      await tester.pumpAndSettle();
    }

    expect(find.text('Open next'), findsNothing);
    expect(find.textContaining('Depth cap reached'), findsOneWidget);
  });
}
