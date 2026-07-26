import 'package:cricunity/design_system/theme/app_theme.dart';
import 'package:cricunity/onboarding/playing_info_step_screen.dart';
import 'package:cricunity/onboarding/profile_wizard_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget harness(VoidCallback onContinue) => ProviderScope(
    child: MaterialApp(
      theme: AppTheme.themes[AppTheme.defaultLight],
      home: PlayingInfoStepScreen(onContinue: onContinue),
    ),
  );

  testWidgets('selecting a role chip stores it; tapping again deselects', (
    tester,
  ) async {
    await tester.pumpWidget(harness(() {}));

    await tester.tap(find.byKey(const ValueKey('playingInfoRole_bowler')));
    await tester.pump();

    var context = tester.element(find.byType(PlayingInfoStepScreen));
    var container = ProviderScope.containerOf(context);
    expect(
      container.read(profileWizardProvider).primaryRole,
      PrimaryRole.bowler,
    );

    await tester.tap(find.byKey(const ValueKey('playingInfoRole_bowler')));
    await tester.pump();

    context = tester.element(find.byType(PlayingInfoStepScreen));
    container = ProviderScope.containerOf(context);
    expect(container.read(profileWizardProvider).primaryRole, isNull);
  });

  testWidgets('selecting a batting-style chip stores it', (tester) async {
    await tester.pumpWidget(harness(() {}));

    final lhbChip = find.byKey(const ValueKey('playingInfoBattingStyle_lhb'));
    await tester.ensureVisible(lhbChip);
    await tester.pumpAndSettle();
    await tester.tap(lhbChip);
    await tester.pump();

    final context = tester.element(find.byType(PlayingInfoStepScreen));
    final container = ProviderScope.containerOf(context);
    expect(
      container.read(profileWizardProvider).battingStyle,
      BattingStyle.lhb,
    );
  });

  testWidgets('Continue is always enabled, even with nothing chosen', (
    tester,
  ) async {
    var continued = false;
    await tester.pumpWidget(harness(() => continued = true));

    await tester.tap(find.byKey(const ValueKey('playingInfoContinue')));
    await tester.pump();

    expect(continued, isTrue);
  });
}
