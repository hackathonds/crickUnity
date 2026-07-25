import 'package:cricunity/design_system/components/app_state_scaffolds.dart';
import 'package:cricunity/design_system/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'Empty renders its message and fires the primary/tertiary callbacks',
    (tester) async {
      var primaryTapped = false;
      var tertiaryTapped = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.themes[AppTheme.defaultLight],
          home: AppEmptyState(
            message: 'No matches yet',
            primaryLabel: 'Find a game',
            onPrimary: () => primaryTapped = true,
            tertiaryLabel: 'Create one',
            onTertiary: () => tertiaryTapped = true,
          ),
        ),
      );

      expect(find.text('No matches yet'), findsOneWidget);
      await tester.tap(find.text('Find a game'));
      expect(primaryTapped, isTrue);
      await tester.tap(find.text('Create one'));
      expect(tertiaryTapped, isTrue);
    },
  );

  testWidgets('Loading renders exactly 6 skeleton rows for the list shape', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.themes[AppTheme.defaultLight],
        home: const AppLoadingState(shape: AppSkeletonShape.list),
      ),
    );
    await tester.pump();

    final skeleton = tester.widget<Column>(
      find.byKey(const ValueKey('appLoadingListSkeleton')),
    );
    expect(skeleton.children, hasLength(6));
  });

  testWidgets('Loading renders one card shape for the card shape', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.themes[AppTheme.defaultLight],
        home: const AppLoadingState(shape: AppSkeletonShape.card),
      ),
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey('appLoadingCardSkeleton')),
      findsOneWidget,
    );
  });

  testWidgets(
    'Error renders the cause + Retry + Report a problem, and fires both callbacks',
    (tester) async {
      var retried = false;
      var reported = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.themes[AppTheme.defaultLight],
          home: AppErrorState(
            message: "Couldn't load matches.",
            onRetry: () => retried = true,
            onReportProblem: () => reported = true,
          ),
        ),
      );

      expect(find.text("Couldn't load matches."), findsOneWidget);
      await tester.tap(find.text('Retry'));
      expect(retried, isTrue);
      await tester.tap(find.text('Report a problem'));
      expect(reported, isTrue);
    },
  );

  testWidgets('Error with isOffline shows the freshness stamp', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.themes[AppTheme.defaultLight],
        home: AppErrorState(
          message: "You're offline.",
          onRetry: () {},
          isOffline: true,
          lastUpdated: DateTime.now().subtract(const Duration(hours: 2)),
        ),
      ),
    );

    expect(find.text('Showing data from 2h ago'), findsOneWidget);
  });

  test('formatFreshnessStamp formats minutes/hours/days', () {
    final now = DateTime(2026, 1, 1, 12, 0);
    expect(
      formatFreshnessStamp(now.subtract(const Duration(seconds: 30)), now: now),
      'Showing data from just now',
    );
    expect(
      formatFreshnessStamp(now.subtract(const Duration(minutes: 5)), now: now),
      'Showing data from 5m ago',
    );
    expect(
      formatFreshnessStamp(now.subtract(const Duration(hours: 2)), now: now),
      'Showing data from 2h ago',
    );
    expect(
      formatFreshnessStamp(now.subtract(const Duration(days: 3)), now: now),
      'Showing data from 3d ago',
    );
  });
}
