import 'package:cricunity/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app boots with the default light theme applied', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const CricUnityApp());
    await tester.pump();

    expect(find.byType(CricUnityApp), findsOneWidget);
  });
}
