import 'package:cricunity/design_system/components/app_pending_pill.dart';
import 'package:cricunity/design_system/theme/app_theme.dart';
import 'package:cricunity/offline/queued_action.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  QueuedAction action(QueuedActionStatus status) => QueuedAction(
    id: '1',
    label: 'Test action',
    isMoneyAction: false,
    perform: () async {},
    status: status,
  );

  testWidgets('pending status shows a spinner and no retry action', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.themes[AppTheme.defaultLight],
        home: Scaffold(
          body: AppPendingPill(action: action(QueuedActionStatus.pending)),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Retry'), findsNothing);
  });

  testWidgets('success status shows a check icon', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.themes[AppTheme.defaultLight],
        home: Scaffold(
          body: AppPendingPill(action: action(QueuedActionStatus.success)),
        ),
      ),
    );

    expect(find.byIcon(Icons.check_circle), findsOneWidget);
  });

  testWidgets('error status shows an error icon and a working Retry action', (
    tester,
  ) async {
    var retried = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.themes[AppTheme.defaultLight],
        home: Scaffold(
          body: AppPendingPill(
            action: action(QueuedActionStatus.error),
            onRetry: () => retried = true,
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.error_outline), findsOneWidget);
    await tester.tap(find.text('Retry'));
    expect(retried, isTrue);
  });
}
