import 'package:cricunity/design_system/theme/app_theme.dart';
import 'package:cricunity/teams/join_requests_provider.dart';
import 'package:cricunity/teams/join_requests_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Real clock: the provider's mock data (join_request_models.dart) is
  // generated relative to the real DateTime.now() at build time, so
  // these tests use the real clock too rather than an arbitrary fixed
  // date divorced from that generation instant.
  Widget harness({DateTime Function()? now}) => ProviderScope(
    child: MaterialApp(
      theme: AppTheme.themes[AppTheme.defaultLight],
      home: JoinRequestsScreen(now: now ?? DateTime.now),
    ),
  );

  testWidgets('renders pending request cards with stats and Trust band', (
    tester,
  ) async {
    await tester.pumpWidget(harness());

    expect(find.text('Vikram Shah'), findsOneWidget);
    expect(find.textContaining('matches'), findsWidgets);
    expect(find.text('Reliable'), findsOneWidget);
  });

  testWidgets(
    'AC: the rival-in-tournament organizer-flag notice only shows for the '
    'flagged request',
    (tester) async {
      await tester.pumpWidget(harness());

      expect(find.byKey(const ValueKey('rivalFlagNotice_jr-1')), findsNothing);
      expect(
        find.byKey(const ValueKey('rivalFlagNotice_jr-2')),
        findsOneWidget,
      );
    },
  );

  testWidgets('AC: a request past the 14-day window is filtered out', (
    tester,
  ) async {
    // jr-2's mock requestedAt is ~10 days before the real "now" at
    // provider-build time, jr-1's is ~2 days before -- advancing 5 more
    // days crosses the 14-day line for jr-2 (15 total) but not jr-1 (7).
    final buildInstant = DateTime.now();
    await tester.pumpWidget(
      harness(now: () => buildInstant.add(const Duration(days: 5))),
    );

    expect(find.text('Farhan Ali'), findsNothing);
    expect(find.text('Vikram Shah'), findsOneWidget);
  });

  testWidgets('tapping Approve removes the card', (tester) async {
    await tester.pumpWidget(harness());

    await tester.tap(find.byKey(const ValueKey('joinRequestApprove_jr-1')));
    await tester.pumpAndSettle();

    expect(find.text('Vikram Shah'), findsNothing);
  });

  testWidgets(
    'tapping Deny opens the canned-reason sheet; picking one removes the '
    'card and records the reason',
    (tester) async {
      await tester.pumpWidget(harness());

      await tester.tap(find.byKey(const ValueKey('joinRequestDeny_jr-1')));
      await tester.pumpAndSettle();

      expect(find.text('Squad is full'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('denyReason_Squad is full')));
      await tester.pumpAndSettle();

      expect(find.text('Vikram Shah'), findsNothing);

      final context = tester.element(find.byType(JoinRequestsScreen));
      final container = ProviderScope.containerOf(context);
      expect(
        container.read(joinRequestsProvider).denied.single.reason,
        'Squad is full',
      );
    },
  );

  testWidgets('the empty state shows once every request is resolved', (
    tester,
  ) async {
    await tester.pumpWidget(harness());

    await tester.tap(find.byKey(const ValueKey('joinRequestApprove_jr-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('joinRequestDeny_jr-2')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('denyReasonSkip')));
    await tester.pumpAndSettle();

    expect(find.textContaining('No pending join requests'), findsOneWidget);
  });
}
