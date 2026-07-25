import 'package:cricunity/design_system/debug/type_specimen_screen.dart';
import 'package:cricunity/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app boots with the default light theme applied', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const CricUnityApp());
    await tester.pump();

    expect(find.byType(CricUnityApp), findsOneWidget);
  });

  testWidgets(
    'app-wide text scale is clamped to 135% even if the OS reports more',
    (tester) async {
      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(3.0)),
          child: CricUnityApp(),
        ),
      );
      await tester.pump();

      final context = tester.element(find.byType(TypeSpecimenScreen));
      final effectiveScaler = MediaQuery.of(context).textScaler;
      expect(
        effectiveScaler.scale(100),
        const TextScaler.linear(1.35).scale(100),
      );
    },
  );
}
