import 'package:cricunity/design_system/tokens/app_money_text.dart';
import 'package:cricunity/design_system/tokens/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('symbol renders at 70% of the numeral font size, top-aligned', (
    tester,
  ) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: AppMoneyText(symbol: '₹', amount: '450'),
      ),
    );

    final row = tester.widget<Row>(find.byType(Row));
    expect(row.crossAxisAlignment, CrossAxisAlignment.start);

    final texts = tester.widgetList<Text>(find.byType(Text)).toList();
    expect(texts, hasLength(2));
    final symbolStyle = texts[0].style!;
    final numeralStyle = texts[1].style!;
    expect(symbolStyle.fontSize, closeTo(numeralStyle.fontSize! * 0.7, 0.001));
  });

  test('the money numeral style keeps tabular figures', () {
    expect(
      AppTypography.moneyMax.fontFeatures,
      contains(const FontFeature.tabularFigures()),
    );
  });
}
