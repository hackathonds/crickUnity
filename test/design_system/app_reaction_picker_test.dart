import 'dart:math' as math;

import 'package:cricunity/design_system/components/app_reaction_picker.dart';
import 'package:cricunity/design_system/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget harness(Widget child) => MaterialApp(
    theme: AppTheme.themes[AppTheme.defaultLight],
    home: Scaffold(body: Center(child: child)),
  );

  testWidgets('renders the counts pill with the reaction count', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(
        AppReactionBar(
          reactionCount: 12,
          onReact: (_) {},
          child: const Text('Post content'),
        ),
      ),
    );

    expect(find.textContaining('12'), findsOneWidget);
  });

  testWidgets('quick-tap fires onReact with the default clap reaction', (
    tester,
  ) async {
    AppReactionType? reacted;
    await tester.pumpWidget(
      harness(
        AppReactionBar(
          onReact: (type) => reacted = type,
          child: const Text('Post content'),
        ),
      ),
    );

    await tester.tap(find.text('Post content'));
    expect(reacted, AppReactionType.clap);
  });

  testWidgets('quick-tap plays the particle burst once', (tester) async {
    await tester.pumpWidget(
      harness(
        AppReactionBar(onReact: (_) {}, child: const Text('Post content')),
      ),
    );

    expect(find.byKey(const ValueKey('appReactionParticles')), findsNothing);

    await tester.tap(find.text('Post content'));
    // The AnimationController's ticker needs one zero-duration pump to
    // establish its start-time baseline before a duration-pump shows
    // real elapsed progress (the same gotcha as gesture-driven
    // animations needing an extra pump right after the gesture).
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byKey(const ValueKey('appReactionParticles')), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byKey(const ValueKey('appReactionParticles')), findsNothing);
  });

  testWidgets('long-press opens the radial picker with all 6 reactions', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(
        AppReactionBar(onReact: (_) {}, child: const Text('Post content')),
      ),
    );

    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Post content')),
    );
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.byKey(const ValueKey('appReactionPickerFan')), findsOneWidget);
    for (final emoji in ['👏', '❤️', '🔥', '😂', '😮', '😢']) {
      expect(find.text(emoji), findsOneWidget);
    }

    await gesture.up();
  });

  testWidgets('dragging onto a target and releasing commits that reaction', (
    tester,
  ) async {
    AppReactionType? reacted;
    await tester.pumpWidget(
      harness(
        AppReactionBar(
          onReact: (type) => reacted = type,
          child: const Text('Post content'),
        ),
      ),
    );

    final anchor = tester.getCenter(find.text('Post content'));
    final gesture = await tester.startGesture(anchor);
    await tester.pump(const Duration(milliseconds: 600));

    // The heart target sits at fan angle index 1 (-132deg), well
    // within its 48px hit radius from the anchor.
    final angle = -132 * math.pi / 180;
    final targetOffset = Offset(72 * math.cos(angle), 72 * math.sin(angle));
    await gesture.moveTo(anchor + targetOffset);
    await tester.pump();
    await gesture.up();
    await tester.pump();

    expect(reacted, isNotNull);
  });

  testWidgets('releasing outside all targets does not commit a reaction', (
    tester,
  ) async {
    AppReactionType? reacted;
    await tester.pumpWidget(
      harness(
        AppReactionBar(
          onReact: (type) => reacted = type,
          child: const Text('Post content'),
        ),
      ),
    );

    final anchor = tester.getCenter(find.text('Post content'));
    final gesture = await tester.startGesture(anchor);
    await tester.pump(const Duration(milliseconds: 600));
    // Straight down, far from every fan target (all of which sit above
    // the anchor).
    await gesture.moveTo(anchor + const Offset(0, 200));
    await tester.pump();
    await gesture.up();
    await tester.pump();

    expect(reacted, isNull);
  });

  testWidgets('the picker overlay is removed after release', (tester) async {
    await tester.pumpWidget(
      harness(
        AppReactionBar(onReact: (_) {}, child: const Text('Post content')),
      ),
    );

    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Post content')),
    );
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byKey(const ValueKey('appReactionPickerFan')), findsOneWidget);

    await gesture.up();
    await tester.pump();
    expect(find.byKey(const ValueKey('appReactionPickerFan')), findsNothing);
  });

  testWidgets('tapping the counts pill fires onCountsTap', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      harness(
        AppReactionBar(
          onReact: (_) {},
          onCountsTap: () => tapped = true,
          child: const Text('Post content'),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('appReactionCountsPill')));
    expect(tapped, isTrue);
  });
}
