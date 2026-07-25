import 'package:cricunity/design_system/components/app_arc_ring.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget harness(Widget child) => MaterialApp(
    home: Scaffold(body: Center(child: child)),
  );

  testWidgets('renders at the given size', (tester) async {
    await tester.pumpWidget(
      harness(
        const AppArcRing(
          progress: 0.5,
          size: 44,
          trackColor: Colors.grey,
          fillColor: Colors.blue,
        ),
      ),
    );

    final rect = tester.getRect(find.byType(AppArcRing));
    expect(rect.width, 44);
    expect(rect.height, 44);
  });

  testWidgets('does not throw at progress 0 or 1', (tester) async {
    await tester.pumpWidget(
      harness(
        const AppArcRing(
          progress: 0,
          size: 44,
          trackColor: Colors.grey,
          fillColor: Colors.blue,
        ),
      ),
    );
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(
      harness(
        const AppArcRing(
          progress: 1,
          size: 44,
          trackColor: Colors.grey,
          fillColor: Colors.blue,
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('CustomPaint is present with a painter configured', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(
        const AppArcRing(
          progress: 0.5,
          size: 44,
          trackColor: Colors.grey,
          fillColor: Colors.blue,
        ),
      ),
    );

    final customPaint = tester.widget<CustomPaint>(
      find.descendant(
        of: find.byType(AppArcRing),
        matching: find.byType(CustomPaint),
      ),
    );
    expect(customPaint.painter, isNotNull);
  });
}
