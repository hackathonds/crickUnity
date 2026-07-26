import 'package:cricunity/design_system/theme/app_theme.dart';
import 'package:cricunity/onboarding/guardian_explainer_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders the guardian-requirement copy and calls onContinue', (
    tester,
  ) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.themes[AppTheme.defaultLight],
        home: GuardianExplainerScreen(onContinue: () => tapped = true),
      ),
    );

    expect(
      find.text('A parent or guardian needs to approve your account'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('guardianExplainerContinue')));
    expect(tapped, isTrue);
  });
}
