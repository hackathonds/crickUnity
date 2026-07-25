import 'package:cricunity/design_system/components/app_currency_field.dart';
import 'package:cricunity/design_system/components/app_form_step_progress.dart';
import 'package:cricunity/design_system/components/app_text_field.dart';
import 'package:cricunity/design_system/theme/app_theme.dart';
import 'package:cricunity/design_system/tokens/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget harness(Widget child) => MaterialApp(
    theme: AppTheme.themes[AppTheme.defaultLight],
    home: Scaffold(body: child),
  );

  final colors = AppTheme.themes[AppTheme.defaultLight]!
      .extension<AppColors>()!;

  Color fieldBorderColor(WidgetTester tester) {
    final container = tester.widget<Container>(
      find.byKey(const ValueKey('appTextFieldBox')),
    );
    final decoration = container.decoration as BoxDecoration;
    return decoration.border!.top.color;
  }

  group('AppTextField', () {
    testWidgets('floating label rises on focus', (tester) async {
      await tester.pumpWidget(harness(const AppTextField(label: 'Team name')));

      final beforeAlign = tester.widget<AnimatedAlign>(
        find.byType(AnimatedAlign),
      );
      expect(beforeAlign.alignment, Alignment.centerLeft);

      await tester.tap(find.byKey(const ValueKey('appTextFieldInput')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 160));

      final afterAlign = tester.widget<AnimatedAlign>(
        find.byType(AnimatedAlign),
      );
      expect(afterAlign.alignment, Alignment.topLeft);
    });

    testWidgets('floating label rises when pre-filled with text', (
      tester,
    ) async {
      final controller = TextEditingController(text: 'Titans');
      await tester.pumpWidget(
        harness(AppTextField(label: 'Team name', controller: controller)),
      );

      final align = tester.widget<AnimatedAlign>(find.byType(AnimatedAlign));
      expect(align.alignment, Alignment.topLeft);
    });

    testWidgets('blur with an invalid value shows the error', (tester) async {
      await tester.pumpWidget(
        harness(
          AppTextField(
            label: 'Team name',
            validator: (value) =>
                value.trim().isEmpty ? 'Team name is required' : null,
          ),
        ),
      );

      await tester.tap(find.byKey(const ValueKey('appTextFieldInput')));
      await tester.pump();
      // Move focus away to trigger blur validation.
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();

      expect(find.text('Team name is required'), findsOneWidget);
      expect(fieldBorderColor(tester), colors.error);
    });

    testWidgets('blur with a valid value shows no error', (tester) async {
      await tester.pumpWidget(
        harness(
          AppTextField(
            label: 'Team name',
            validator: (value) =>
                value.trim().isEmpty ? 'Team name is required' : null,
          ),
        ),
      );

      await tester.enterText(
        find.byKey(const ValueKey('appTextFieldInput')),
        'Titans',
      );
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();

      expect(find.text('Team name is required'), findsNothing);
    });

    testWidgets('error text carries a live-region semantic', (tester) async {
      await tester.pumpWidget(
        harness(
          AppTextField(
            label: 'Team name',
            validator: (value) =>
                value.trim().isEmpty ? 'Team name is required' : null,
          ),
        ),
      );

      await tester.tap(find.byKey(const ValueKey('appTextFieldInput')));
      await tester.pump();
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();

      final semantics = tester.getSemantics(
        find
            .ancestor(
              of: find.text('Team name is required'),
              matching: find.byType(Semantics),
            )
            .first,
      );
      expect(semantics.flagsCollection.isLiveRegion, isTrue);
    });
  });

  group('AppCurrencyField', () {
    testWidgets('typing digits inserts thousand separators', (tester) async {
      await tester.pumpWidget(
        harness(const AppCurrencyField(label: 'Entry fee')),
      );

      await tester.enterText(
        find.byKey(const ValueKey('appTextFieldInput')),
        '1234567',
      );
      await tester.pump();

      expect(find.text('12,34,567'), findsNothing);
      expect(find.text('1,234,567'), findsOneWidget);
    });

    testWidgets('the currency symbol renders as a fixed prefix', (
      tester,
    ) async {
      await tester.pumpWidget(
        harness(const AppCurrencyField(label: 'Entry fee')),
      );

      final field = tester.widget<TextField>(
        find.byKey(const ValueKey('appTextFieldInput')),
      );
      expect(field.decoration!.prefixText, '₹');
      expect(field.textAlign, TextAlign.right);
    });
  });

  group('AppFormStepProgress', () {
    testWidgets('fills segments up to and including currentStep', (
      tester,
    ) async {
      await tester.pumpWidget(
        harness(
          AppFormStepProgress(
            stepCount: 4,
            currentStep: 1,
            labels: const ['Basics', 'Opponent', 'Ground & Time', 'Review'],
          ),
        ),
      );

      Color segmentColor(int i) {
        final container = tester.widget<Container>(
          find.byKey(ValueKey('appFormStepProgressSegment$i')),
        );
        return (container.decoration as BoxDecoration).color!;
      }

      expect(segmentColor(0), colors.primary);
      expect(segmentColor(1), colors.primary);
      expect(segmentColor(2), colors.divider);
      expect(segmentColor(3), colors.divider);
    });

    testWidgets('emphasizes only the current step label', (tester) async {
      await tester.pumpWidget(
        harness(
          AppFormStepProgress(
            stepCount: 2,
            currentStep: 1,
            labels: const ['Basics', 'Review'],
          ),
        ),
      );

      final current = tester.widget<Text>(find.text('Review'));
      final other = tester.widget<Text>(find.text('Basics'));
      expect(current.style!.color, colors.textPrimary);
      expect(other.style!.color, colors.textTertiary);
    });
  });
}
