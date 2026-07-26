import 'package:cricunity/design_system/theme/app_theme.dart';
import 'package:cricunity/onboarding/nearby_matches_preview_card.dart';
import 'package:cricunity/onboarding/permissions_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget harness({List<Override> overrides = const []}) => ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      theme: AppTheme.themes[AppTheme.defaultLight],
      home: const Scaffold(body: NearbyMatchesPreviewCard()),
    ),
  );

  testWidgets(
    'shows the PRD §4.11 enable-prompt when location is not granted',
    (tester) async {
      await tester.pumpWidget(harness());

      expect(
        find.text('Enable location to find cricket around you.'),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('nearbyMatchesContent')), findsNothing);
    },
  );

  testWidgets('shows placeholder match content when location is granted', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container
        .read(permissionsProvider.notifier)
        .setLocation(PermissionStatus.granted);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.themes[AppTheme.defaultLight],
          home: const Scaffold(body: NearbyMatchesPreviewCard()),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('nearbyMatchesContent')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('nearbyMatchesEnablePrompt')),
      findsNothing,
    );
  });

  testWidgets('tapping Enable location grants the permission', (tester) async {
    await tester.pumpWidget(harness());

    await tester.tap(find.byKey(const ValueKey('nearbyMatchesEnableLocation')));
    await tester.pump();

    expect(find.byKey(const ValueKey('nearbyMatchesContent')), findsOneWidget);
  });
}
