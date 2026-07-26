import 'package:cricunity/design_system/components/app_coin_chip.dart';
import 'package:cricunity/design_system/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget harness(Widget child) => MaterialApp(
    theme: AppTheme.themes[AppTheme.defaultLight],
    home: Scaffold(body: Center(child: child)),
  );

  testWidgets('renders the coin icon and balance', (tester) async {
    await tester.pumpWidget(harness(const AppCoinChip(balance: 240)));

    expect(find.text('240'), findsOneWidget);
  });

  testWidgets('tapping fires onTap', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      harness(AppCoinChip(balance: 240, onTap: () => tapped = true)),
    );

    await tester.tap(find.byKey(const ValueKey('appCoinChipBox')));
    expect(tapped, isTrue);
  });

  testWidgets('long-pressing fires onLongPress', (tester) async {
    var longPressed = false;
    await tester.pumpWidget(
      harness(AppCoinChip(balance: 240, onLongPress: () => longPressed = true)),
    );

    await tester.longPress(find.byKey(const ValueKey('appCoinChipBox')));
    expect(longPressed, isTrue);
  });

  testWidgets('no earn float when the balance has not increased', (
    tester,
  ) async {
    await tester.pumpWidget(harness(const AppCoinChip(balance: 240)));

    expect(find.byKey(const ValueKey('appCoinChipEarnFloat')), findsNothing);
  });

  testWidgets('an increase shows the "+N" earn float', (tester) async {
    final key = GlobalKey();
    await tester.pumpWidget(harness(AppCoinChip(key: key, balance: 240)));

    await tester.pumpWidget(harness(AppCoinChip(key: key, balance: 265)));
    await tester.pump();

    expect(find.text('+25'), findsOneWidget);
  });

  testWidgets('the odometer settles on the new balance', (tester) async {
    final key = GlobalKey();
    await tester.pumpWidget(harness(AppCoinChip(key: key, balance: 240)));

    await tester.pumpWidget(harness(AppCoinChip(key: key, balance: 265)));
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.text('265'), findsOneWidget);
  });

  testWidgets('the earn float fades out after 600ms', (tester) async {
    final key = GlobalKey();
    await tester.pumpWidget(harness(AppCoinChip(key: key, balance: 240)));

    await tester.pumpWidget(harness(AppCoinChip(key: key, balance: 265)));
    await tester.pump();
    expect(find.text('+25'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 700));
    expect(find.text('+25'), findsNothing);
  });
}
