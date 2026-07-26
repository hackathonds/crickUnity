import 'package:cricunity/design_system/components/app_ball_scrub_strip.dart';
import 'package:cricunity/design_system/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget harness(Widget child) => MaterialApp(
    theme: AppTheme.themes[AppTheme.defaultLight],
    home: Scaffold(
      body: Padding(padding: const EdgeInsets.only(top: 60), child: child),
    ),
  );

  const balls = [
    AppBallScrubStripEntry(
      over: 14,
      ballInOver: 1,
      outcome: AppBallOutcome.dot,
    ),
    AppBallScrubStripEntry(
      over: 14,
      ballInOver: 2,
      outcome: AppBallOutcome.runs,
    ),
    AppBallScrubStripEntry(
      over: 14,
      ballInOver: 3,
      outcome: AppBallOutcome.four,
    ),
    AppBallScrubStripEntry(
      over: 14,
      ballInOver: 4,
      outcome: AppBallOutcome.wicket,
    ),
    AppBallScrubStripEntry(
      over: 14,
      ballInOver: 5,
      outcome: AppBallOutcome.six,
    ),
    AppBallScrubStripEntry(
      over: 14,
      ballInOver: 6,
      outcome: AppBallOutcome.extra,
    ),
  ];

  testWidgets('the readout bubble is absent before any drag', (tester) async {
    await tester.pumpWidget(harness(const AppBallScrubStrip(balls: balls)));

    expect(
      find.byKey(const ValueKey('appBallScrubStripReadout')),
      findsNothing,
    );
  });

  testWidgets('dragging shows the readout bubble with an over.ball reading', (
    tester,
  ) async {
    await tester.pumpWidget(harness(const AppBallScrubStrip(balls: balls)));

    final box = find.byKey(const ValueKey('appBallScrubStripBox'));
    final start = tester.getTopLeft(box) + const Offset(10, 24);
    final gesture = await tester.startGesture(start);
    await gesture.moveBy(const Offset(20, 0));
    await tester.pump();

    expect(
      find.byKey(const ValueKey('appBallScrubStripReadout')),
      findsOneWidget,
    );
    expect(find.textContaining('14.'), findsOneWidget);

    await gesture.up();
  });

  testWidgets('dragging calls onScrub with the ball at that position', (
    tester,
  ) async {
    AppBallScrubStripEntry? scrubbed;
    await tester.pumpWidget(
      harness(AppBallScrubStrip(balls: balls, onScrub: (b) => scrubbed = b)),
    );

    final box = find.byKey(const ValueKey('appBallScrubStripBox'));
    final start = tester.getTopLeft(box) + const Offset(10, 24);
    final gesture = await tester.startGesture(start);
    await gesture.moveBy(const Offset(20, 0));
    await tester.pump();

    expect(scrubbed, isNotNull);
    await gesture.up();
  });

  testWidgets('releasing the drag hides the readout bubble again', (
    tester,
  ) async {
    await tester.pumpWidget(harness(const AppBallScrubStrip(balls: balls)));

    final box = find.byKey(const ValueKey('appBallScrubStripBox'));
    final start = tester.getTopLeft(box) + const Offset(10, 24);
    final gesture = await tester.startGesture(start);
    await gesture.moveBy(const Offset(20, 0));
    await tester.pump();
    expect(
      find.byKey(const ValueKey('appBallScrubStripReadout')),
      findsOneWidget,
    );

    await gesture.up();
    await tester.pump();
    expect(
      find.byKey(const ValueKey('appBallScrubStripReadout')),
      findsNothing,
    );
  });
}
