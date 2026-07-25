import 'package:cricunity/design_system/components/app_stepper.dart';
import 'package:cricunity/design_system/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget harness(Widget child) => MaterialApp(
    theme: AppTheme.themes[AppTheme.defaultLight],
    home: Scaffold(body: Center(child: child)),
  );

  testWidgets('tapping + increments the value', (tester) async {
    int? changed;
    await tester.pumpWidget(
      harness(
        AppStepper(
          value: 5,
          min: 0,
          max: 10,
          semanticLabel: 'Overs',
          onChanged: (v) => changed = v,
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('appStepperPlus')));
    expect(changed, 6);
  });

  testWidgets('tapping − decrements the value', (tester) async {
    int? changed;
    await tester.pumpWidget(
      harness(
        AppStepper(
          value: 5,
          min: 0,
          max: 10,
          semanticLabel: 'Overs',
          onChanged: (v) => changed = v,
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('appStepperMinus')));
    expect(changed, 4);
  });

  testWidgets('the minus button is disabled at min and does not decrement', (
    tester,
  ) async {
    int? changed;
    await tester.pumpWidget(
      harness(
        AppStepper(
          value: 0,
          min: 0,
          max: 10,
          semanticLabel: 'Overs',
          onChanged: (v) => changed = v,
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('appStepperMinus')));
    expect(changed, isNull);
  });

  testWidgets('the plus button is disabled at max and does not increment', (
    tester,
  ) async {
    int? changed;
    await tester.pumpWidget(
      harness(
        AppStepper(
          value: 10,
          min: 0,
          max: 10,
          semanticLabel: 'Overs',
          onChanged: (v) => changed = v,
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('appStepperPlus')));
    expect(changed, isNull);
  });

  testWidgets('long-pressing + auto-repeats more than once', (tester) async {
    final changes = <int>[];
    await tester.pumpWidget(
      harness(
        AppStepper(
          value: 0,
          min: 0,
          max: 100,
          semanticLabel: 'Overs',
          onChanged: changes.add,
        ),
      ),
    );

    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('appStepperPlus'))),
    );
    // Past the long-press recognition threshold, then well into the
    // repeat schedule (starts at 400ms, accelerating toward an 80ms
    // floor).
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
    await gesture.up();
    await tester.pump();

    expect(changes.length, greaterThan(1));
  });

  testWidgets('tapping the value opens an inline edit field', (tester) async {
    await tester.pumpWidget(
      harness(
        AppStepper(
          value: 5,
          min: 0,
          max: 10,
          semanticLabel: 'Overs',
          onChanged: (_) {},
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('appStepperValue')));
    await tester.pump();

    expect(find.byKey(const ValueKey('appStepperEditField')), findsOneWidget);
  });

  testWidgets('submitting a valid manual entry calls onChanged', (
    tester,
  ) async {
    int? changed;
    await tester.pumpWidget(
      harness(
        AppStepper(
          value: 5,
          min: 0,
          max: 20,
          semanticLabel: 'Overs',
          onChanged: (v) => changed = v,
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('appStepperValue')));
    await tester.pump();
    await tester.enterText(
      find.byKey(const ValueKey('appStepperEditField')),
      '18',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(changed, 18);
    expect(find.byKey(const ValueKey('appStepperEditField')), findsNothing);
  });

  testWidgets(
    'submitting an out-of-range manual entry reverts without calling onChanged',
    (tester) async {
      int? changed;
      await tester.pumpWidget(
        harness(
          AppStepper(
            value: 5,
            min: 0,
            max: 10,
            semanticLabel: 'Overs',
            onChanged: (v) => changed = v,
          ),
        ),
      );

      await tester.tap(find.byKey(const ValueKey('appStepperValue')));
      await tester.pump();
      await tester.enterText(
        find.byKey(const ValueKey('appStepperEditField')),
        '99',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(changed, isNull);
      expect(find.text('5'), findsOneWidget);
    },
  );
}
