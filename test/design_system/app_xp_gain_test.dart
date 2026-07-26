import 'dart:async';

import 'package:cricunity/design_system/components/app_avatar.dart';
import 'package:cricunity/design_system/components/app_xp_gain.dart';
import 'package:cricunity/design_system/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget harness(Widget child) => MaterialApp(
    theme: AppTheme.themes[AppTheme.defaultLight],
    home: Scaffold(body: Center(child: child)),
  );

  group('AppAvatarRingSweep', () {
    testWidgets('renders an AppAvatar with the ring visible', (tester) async {
      await tester.pumpWidget(
        harness(
          const AppAvatarRingSweep(
            size: AppAvatarSize.lg,
            name: 'Deepak Sharma',
            fromProgress: 0.2,
            toProgress: 0.6,
          ),
        ),
      );

      expect(find.byType(AppAvatar), findsOneWidget);
      expect(find.byKey(const ValueKey('appAvatarRing')), findsOneWidget);
    });

    testWidgets(
      'the ring progress animates from fromProgress toward toProgress',
      (tester) async {
        await tester.pumpWidget(
          harness(
            const AppAvatarRingSweep(
              size: AppAvatarSize.lg,
              name: 'Deepak Sharma',
              fromProgress: 0.0,
              toProgress: 1.0,
              duration: Duration(milliseconds: 400),
            ),
          ),
        );

        final avatarAtStart = tester.widget<AppAvatar>(find.byType(AppAvatar));
        expect(avatarAtStart.levelProgress, 0.0);

        await tester.pump(const Duration(milliseconds: 400));

        final avatarAtEnd = tester.widget<AppAvatar>(find.byType(AppAvatar));
        expect(avatarAtEnd.levelProgress, 1.0);
      },
    );
  });

  group('showXpGainToast', () {
    testWidgets('shows the "+N XP" toast-chip', (tester) async {
      await tester.pumpWidget(harness(const SizedBox()));
      final context = tester.element(find.byType(SizedBox));

      unawaited(
        showXpGainToast(
          context,
          amount: 50,
          visibleFor: const Duration(milliseconds: 200),
        ),
      );
      await tester.pump();

      expect(find.text('+50 XP'), findsOneWidget);

      // Drain the pending auto-dismiss timer before the test ends.
      await tester.pump(const Duration(milliseconds: 250));
    });

    testWidgets('the toast disappears after the visible duration', (
      tester,
    ) async {
      await tester.pumpWidget(harness(const SizedBox()));
      final context = tester.element(find.byType(SizedBox));

      unawaited(
        showXpGainToast(
          context,
          amount: 50,
          visibleFor: const Duration(milliseconds: 300),
        ),
      );
      await tester.pump();
      expect(find.text('+50 XP'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text('+50 XP'), findsNothing);
    });
  });
}
