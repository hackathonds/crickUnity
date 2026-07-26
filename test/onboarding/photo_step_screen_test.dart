import 'package:cricunity/design_system/theme/app_theme.dart';
import 'package:cricunity/onboarding/profile_wizard_provider.dart';
import 'package:cricunity/onboarding/photo_step_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget harness(VoidCallback onContinue) => ProviderScope(
    child: MaterialApp(
      theme: AppTheme.themes[AppTheme.defaultLight],
      home: PhotoStepScreen(onContinue: onContinue),
    ),
  );

  testWidgets('Take photo marks the photo set and continues', (tester) async {
    var continued = false;
    await tester.pumpWidget(harness(() => continued = true));

    await tester.tap(find.byKey(const ValueKey('photoStepTakePhoto')));
    await tester.pump();

    expect(continued, isTrue);
    final context = tester.element(find.byType(PhotoStepScreen));
    final container = ProviderScope.containerOf(context);
    expect(container.read(profileWizardProvider).photoSet, isTrue);
  });

  testWidgets('Skip continues without marking a photo set', (tester) async {
    var continued = false;
    await tester.pumpWidget(harness(() => continued = true));

    await tester.tap(find.byKey(const ValueKey('photoStepSkip')));
    await tester.pump();

    expect(continued, isTrue);
    final context = tester.element(find.byType(PhotoStepScreen));
    final container = ProviderScope.containerOf(context);
    expect(container.read(profileWizardProvider).photoSet, isFalse);
  });
}
