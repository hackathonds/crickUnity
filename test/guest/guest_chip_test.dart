import 'package:cricunity/design_system/theme/app_theme.dart';
import 'package:cricunity/guest/guest_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders the DS §11.2 copy and is 32h', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.themes[AppTheme.defaultLight],
        home: Scaffold(body: AppGuestChip(onSignUp: () {})),
      ),
    );

    expect(find.text('Viewing as guest · Sign up'), findsOneWidget);
    final rect = tester.getRect(find.byKey(const ValueKey('appGuestChip')));
    expect(rect.height, 32);
  });

  testWidgets('tapping the chip calls onSignUp', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.themes[AppTheme.defaultLight],
        home: Scaffold(body: AppGuestChip(onSignUp: () => tapped = true)),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('appGuestChip')));

    expect(tapped, isTrue);
  });
}
