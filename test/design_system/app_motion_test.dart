import 'package:cricunity/design_system/tokens/app_motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('reduced motion collapses every duration token to 120ms', (
    tester,
  ) async {
    late BuildContext capturedContext;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: Builder(
          builder: (context) {
            capturedContext = context;
            return const SizedBox();
          },
        ),
      ),
    );

    expect(AppMotion.isReduced(capturedContext), isTrue);
    for (final token in AppMotionToken.values) {
      expect(
        AppMotion.resolveDuration(capturedContext, token),
        AppMotionDuration.reduced,
      );
    }
    expect(
      AppMotion.resolveCurve(capturedContext, AppMotionCurves.standard),
      AppMotionCurves.reduced,
    );
  });

  testWidgets(
    'tokens resolve to their normal duration when motion is not reduced',
    (tester) async {
      late BuildContext capturedContext;
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: false),
          child: Builder(
            builder: (context) {
              capturedContext = context;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(AppMotion.isReduced(capturedContext), isFalse);
      expect(
        AppMotion.resolveDuration(capturedContext, AppMotionToken.standard),
        AppMotionDuration.standard,
      );
      expect(
        AppMotion.resolveDuration(capturedContext, AppMotionToken.ceremony),
        AppMotionDuration.ceremony,
      );
    },
  );

  test('duration tokens match DS §2.6', () {
    expect(AppMotionDuration.instant, const Duration(milliseconds: 80));
    expect(AppMotionDuration.fast, const Duration(milliseconds: 160));
    expect(AppMotionDuration.standard, const Duration(milliseconds: 240));
    expect(AppMotionDuration.gentle, const Duration(milliseconds: 360));
    expect(AppMotionDuration.ceremony, const Duration(milliseconds: 900));
    expect(AppMotionDuration.ceremonyMax, const Duration(milliseconds: 1400));
  });
}
