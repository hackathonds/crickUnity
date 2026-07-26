import 'package:cricunity/design_system/components/app_button.dart';
import 'package:cricunity/design_system/theme/app_theme.dart';
import 'package:cricunity/teams/carpool_provider.dart';
import 'package:cricunity/teams/carpool_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget harness({required String viewerName}) => ProviderScope(
    child: MaterialApp(
      theme: AppTheme.themes[AppTheme.defaultLight],
      home: CarpoolScreen(viewerName: viewerName),
    ),
  );

  testWidgets('renders seat pips and the fuel-split suggestion', (
    tester,
  ) async {
    await tester.pumpWidget(harness(viewerName: 'Vikram Shah'));

    expect(find.byKey(const ValueKey('seatPips_ride-1')), findsOneWidget);
    expect(find.textContaining('suggested per rider'), findsWidgets);
  });

  testWidgets('AC: joining a ride shows a confirm dialog first', (
    tester,
  ) async {
    await tester.pumpWidget(harness(viewerName: 'Vikram Shah'));

    await tester.tap(find.byKey(const ValueKey('joinRideButton_ride-1')));
    await tester.pumpAndSettle();

    expect(find.text('Join this ride?'), findsOneWidget);

    // Several "Join" texts exist (both ride cards' buttons + the
    // dialog's confirm action) -- the dialog's is added last/on top.
    await tester.tap(find.text('Join').last);
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(CarpoolScreen));
    final container = ProviderScope.containerOf(context);
    expect(
      container
          .read(carpoolProvider)
          .rides
          .firstWhere((r) => r.id == 'ride-1')
          .riders,
      contains('Vikram Shah'),
    );
  });

  testWidgets('AC: a full ride disables the Join button', (tester) async {
    await tester.pumpWidget(harness(viewerName: 'Vikram Shah'));

    final button = tester.widget<AppButton>(
      find.byKey(const ValueKey('joinRideButton_ride-2')),
    );
    expect(button.onPressed, isNull);
  });
}
