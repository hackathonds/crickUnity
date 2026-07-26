import 'package:cricunity/design_system/theme/app_theme.dart';
import 'package:cricunity/onboarding/guardian_gate_provider.dart';
import 'package:cricunity/onboarding/guardian_waiting_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpHarness(
    WidgetTester tester, {
    required VoidCallback onConsentGranted,
    bool showDebugSimulateApproval = false,
    DateTime Function()? now,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.themes[AppTheme.defaultLight],
          home: _GuardianRequestSeededWaitingScreen(
            onConsentGranted: onConsentGranted,
            showDebugSimulateApproval: showDebugSimulateApproval,
            now: now,
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('shows the waiting copy and no simulate-approval button by '
      'default', (tester) async {
    await pumpHarness(tester, onConsentGranted: () {});

    expect(find.text('Waiting for guardian approval'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('guardianWaitingSimulateApproval')),
      findsNothing,
    );
  });

  testWidgets(
    'the back button cannot pop this screen while consent is pending',
    (tester) async {
      await pumpHarness(tester, onConsentGranted: () {});

      final popScope = tester.widget<PopScope>(find.byType(PopScope));
      expect(popScope.canPop, isFalse);
    },
  );

  testWidgets('resend is disabled with a countdown right after the request '
      'is sent', (tester) async {
    final fixedNow = DateTime.now();
    await pumpHarness(tester, onConsentGranted: () {}, now: () => fixedNow);

    expect(find.textContaining('Resend request in'), findsOneWidget);
    final button = tester.widget<TextButton>(
      find.byKey(const ValueKey('guardianWaitingResendButton')),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('resend becomes enabled once the cooldown elapses', (
    tester,
  ) async {
    var fakeNow = DateTime.now();
    await pumpHarness(tester, onConsentGranted: () {}, now: () => fakeNow);

    fakeNow = fakeNow.add(const Duration(seconds: 31));
    await tester.pump(const Duration(seconds: 31));

    final button = tester.widget<TextButton>(
      find.byKey(const ValueKey('guardianWaitingResendButton')),
    );
    expect(button.onPressed, isNotNull);
    expect(find.text('Resend request'), findsOneWidget);
  });

  testWidgets(
    'granting consent (simulated) calls onConsentGranted and unblocks pop',
    (tester) async {
      var granted = false;
      await pumpHarness(
        tester,
        onConsentGranted: () => granted = true,
        showDebugSimulateApproval: true,
      );

      await tester.tap(
        find.byKey(const ValueKey('guardianWaitingSimulateApproval')),
      );
      await tester.pump();

      expect(granted, isTrue);
      final popScope = tester.widget<PopScope>(find.byType(PopScope));
      expect(popScope.canPop, isTrue);
    },
  );
}

/// Seeds guardianGateProvider with a sent request (as GuardianContactScreen
/// would) before mounting [GuardianWaitingScreen].
class _GuardianRequestSeededWaitingScreen extends ConsumerStatefulWidget {
  final VoidCallback onConsentGranted;
  final bool showDebugSimulateApproval;
  final DateTime Function()? now;

  const _GuardianRequestSeededWaitingScreen({
    required this.onConsentGranted,
    required this.showDebugSimulateApproval,
    this.now,
  });

  @override
  ConsumerState<_GuardianRequestSeededWaitingScreen> createState() =>
      _GuardianRequestSeededWaitingScreenState();
}

class _GuardianRequestSeededWaitingScreenState
    extends ConsumerState<_GuardianRequestSeededWaitingScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref
          .read(guardianGateProvider.notifier)
          .sendGuardianRequest('9000000000'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GuardianWaitingScreen(
      onConsentGranted: widget.onConsentGranted,
      showDebugSimulateApproval: widget.showDebugSimulateApproval,
      now: widget.now ?? DateTime.now,
    );
  }
}
