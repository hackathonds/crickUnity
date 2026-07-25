import 'package:cricunity/design_system/components/app_statistics_card.dart';
import 'package:cricunity/design_system/components/app_tag_chip.dart';
import 'package:cricunity/design_system/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget harness(Widget child) => MaterialApp(
    theme: AppTheme.themes[AppTheme.defaultLight],
    home: Scaffold(body: child),
  );

  testWidgets('the eyebrow label renders uppercase', (tester) async {
    await tester.pumpWidget(
      harness(
        const AppStatisticsCard(eyebrowLabel: 'batting average', value: '42.5'),
      ),
    );

    expect(find.text('BATTING AVERAGE'), findsOneWidget);
  });

  testWidgets('renders the value and a delta chip when given', (tester) async {
    await tester.pumpWidget(
      harness(
        const AppStatisticsCard(
          eyebrowLabel: 'Strike rate',
          value: '118',
          deltaDirection: AppDeltaDirection.up,
          deltaValue: '5',
        ),
      ),
    );

    expect(find.text('118'), findsOneWidget);
    expect(find.byType(AppDeltaChip), findsOneWidget);
    expect(find.text('▲'), findsOneWidget);
  });

  testWidgets('no delta chip when direction/value are omitted', (tester) async {
    await tester.pumpWidget(
      harness(
        const AppStatisticsCard(eyebrowLabel: 'Strike rate', value: '118'),
      ),
    );

    expect(find.byType(AppDeltaChip), findsNothing);
  });

  testWidgets('no info glyph when onInfoTap is omitted', (tester) async {
    await tester.pumpWidget(
      harness(
        const AppStatisticsCard(eyebrowLabel: 'Strike rate', value: '118'),
      ),
    );

    expect(
      find.byKey(const ValueKey('appStatisticsCardInfoTap')),
      findsNothing,
    );
  });

  testWidgets('tapping the card fires onTap', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      harness(
        AppStatisticsCard(
          eyebrowLabel: 'Strike rate',
          value: '118',
          onTap: () => tapped = true,
        ),
      ),
    );

    await tester.tap(find.text('118'));
    expect(tapped, isTrue);
  });

  testWidgets('tapping the info glyph fires onInfoTap, not onTap', (
    tester,
  ) async {
    var tapped = false;
    var infoTapped = false;
    await tester.pumpWidget(
      harness(
        AppStatisticsCard(
          eyebrowLabel: 'Strike rate',
          value: '118',
          onTap: () => tapped = true,
          onInfoTap: () => infoTapped = true,
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('appStatisticsCardInfoTap')));

    expect(infoTapped, isTrue);
    expect(tapped, isFalse);
  });
}
