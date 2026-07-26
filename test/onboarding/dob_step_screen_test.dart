import 'package:cricunity/design_system/components/app_button.dart';
import 'package:cricunity/design_system/theme/app_theme.dart';
import 'package:cricunity/onboarding/dob_step_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget harness(void Function(bool isMinor) onContinue) => ProviderScope(
    child: MaterialApp(
      theme: AppTheme.themes[AppTheme.defaultLight],
      home: DobStepScreen(onContinue: onContinue),
    ),
  );

  // Every field here has >8 options, so the sheet's search row (DS §3.7)
  // is always present -- used to filter to a single, guaranteed-visible
  // row rather than scrolling a potentially very long list (Year has
  // ~100 entries).
  Future<void> selectDropdown(
    WidgetTester tester,
    Key fieldKey,
    String optionText,
  ) async {
    await tester.tap(find.byKey(fieldKey));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('appTextFieldInput')),
      optionText,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(optionText).last);
    await tester.pumpAndSettle();
  }

  testWidgets('Continue is disabled until day, month, and year are all set', (
    tester,
  ) async {
    await tester.pumpWidget(harness((_) {}));

    var button = tester.widget<AppButton>(
      find.byKey(const ValueKey('dobStepContinue')),
    );
    expect(button.onPressed, isNull);

    await selectDropdown(tester, const ValueKey('dobDayField'), '15');
    await selectDropdown(tester, const ValueKey('dobMonthField'), 'June');

    button = tester.widget<AppButton>(
      find.byKey(const ValueKey('dobStepContinue')),
    );
    expect(button.onPressed, isNull);

    await selectDropdown(tester, const ValueKey('dobYearField'), '2000');

    button = tester.widget<AppButton>(
      find.byKey(const ValueKey('dobStepContinue')),
    );
    expect(button.onPressed, isNotNull);
  });

  testWidgets('a DOB more than 18 years ago reports isMinor: false', (
    tester,
  ) async {
    bool? isMinorResult;
    await tester.pumpWidget(harness((isMinor) => isMinorResult = isMinor));

    await selectDropdown(tester, const ValueKey('dobDayField'), '15');
    await selectDropdown(tester, const ValueKey('dobMonthField'), 'June');
    await selectDropdown(tester, const ValueKey('dobYearField'), '2000');
    await tester.tap(find.byKey(const ValueKey('dobStepContinue')));

    expect(isMinorResult, isFalse);
  });

  testWidgets('a DOB within the last 18 years reports isMinor: true', (
    tester,
  ) async {
    bool? isMinorResult;
    final recentYear = (DateTime.now().year - 5).toString();
    await tester.pumpWidget(harness((isMinor) => isMinorResult = isMinor));

    await selectDropdown(tester, const ValueKey('dobDayField'), '15');
    await selectDropdown(tester, const ValueKey('dobMonthField'), 'June');
    await selectDropdown(tester, const ValueKey('dobYearField'), recentYear);
    await tester.tap(find.byKey(const ValueKey('dobStepContinue')));

    expect(isMinorResult, isTrue);
  });
}
