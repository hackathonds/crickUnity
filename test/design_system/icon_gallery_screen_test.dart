import 'package:cricunity/design_system/debug/icon_gallery_screen.dart';
import 'package:cricunity/design_system/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const familyLabels = [
    'Navigation',
    'Sports',
    'Status',
    'Rewards',
    'Expense',
    'Social',
  ];

  const sampleIconLabels = ['home', 'ball', 'live', 'coin', 'wallet', 'heart'];

  testWidgets('renders every icon family and a sample icon from each', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(500, 6000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.themes[AppTheme.defaultLight],
        home: const IconGalleryScreen(),
      ),
    );

    for (final label in familyLabels) {
      expect(
        find.text(label),
        findsOneWidget,
        reason: 'missing family: $label',
      );
    }
    for (final label in sampleIconLabels) {
      expect(find.text(label), findsOneWidget, reason: 'missing icon: $label');
    }
  });
}
