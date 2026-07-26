import 'package:cricunity/design_system/theme/app_theme.dart';
import 'package:cricunity/home/onboarding_checklist_provider.dart';
import 'package:cricunity/home/onboarding_checklist_widget.dart';
import 'package:cricunity/onboarding/profile_wizard_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget harness() => ProviderScope(
    child: MaterialApp(
      theme: AppTheme.themes[AppTheme.defaultLight],
      home: const Scaffold(body: OnboardingChecklistWidget()),
    ),
  );

  testWidgets('renders all 4 items, none done, widget visible', (tester) async {
    await tester.pumpWidget(harness());

    for (final label in checklistItemLabels.values) {
      expect(find.text(label), findsOneWidget);
    }
    expect(
      find.byKey(const ValueKey('onboardingChecklistWidget')),
      findsOneWidget,
    );
  });

  testWidgets(
    'completing "Join a team" marks the item and plays the coin float '
    '(AC)',
    (tester) async {
      await tester.pumpWidget(harness());

      final context = tester.element(find.byType(OnboardingChecklistWidget));
      final container = ProviderScope.containerOf(context);
      container
          .read(onboardingChecklistProvider.notifier)
          .completeItem(ChecklistItem.joinOrCreateTeam);
      await tester.pump();

      // Marked: struck-through label, its row's circle replaced by a
      // checkmark (covered by the coins-earned assertion below), coins
      // credited.
      expect(
        container.read(onboardingChecklistProvider).completed,
        contains(ChecklistItem.joinOrCreateTeam),
      );

      // AppCoinChip's earn-float animation (DS §5 item 7) plays whenever
      // its balance rises -- this is the "coin float animation" this
      // story's AC asks for, reused rather than rebuilt.
      final earnFloat = tester.widget<Text>(
        find.byKey(const ValueKey('appCoinChipEarnFloat')),
      );
      expect(
        earnFloat.data,
        '+${checklistItemCoins[ChecklistItem.joinOrCreateTeam]}',
      );
    },
  );

  testWidgets('hides itself once 2 items are complete', (tester) async {
    await tester.pumpWidget(harness());

    final context = tester.element(find.byType(OnboardingChecklistWidget));
    final container = ProviderScope.containerOf(context);
    container
        .read(onboardingChecklistProvider.notifier)
        .completeItem(ChecklistItem.joinOrCreateTeam);
    await tester.pump();
    expect(
      find.byKey(const ValueKey('onboardingChecklistWidget')),
      findsOneWidget,
    );

    container
        .read(onboardingChecklistProvider.notifier)
        .completeItem(ChecklistItem.playFirstMatch);
    await tester.pump();

    expect(
      find.byKey(const ValueKey('onboardingChecklistWidget')),
      findsNothing,
    );
  });

  testWidgets(
    'a fully-complete profile (E1-03) auto-marks "Complete profile"',
    (tester) async {
      await tester.pumpWidget(harness());
      final context = tester.element(find.byType(OnboardingChecklistWidget));
      final container = ProviderScope.containerOf(context);

      final wizard = container.read(profileWizardProvider.notifier);
      wizard.setPhotoSet(true);
      wizard.setCity('Mumbai');
      wizard.setPrimaryRole(PrimaryRole.batter);
      wizard.setBattingStyle(BattingStyle.rhb);
      await tester.pump();

      expect(
        container.read(onboardingChecklistProvider).completed,
        contains(ChecklistItem.completeProfile),
      );
    },
  );
}
