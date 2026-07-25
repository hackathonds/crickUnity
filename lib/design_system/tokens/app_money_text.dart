import 'package:flutter/widgets.dart';

import 'app_typography.dart';

/// Composes a currency symbol at 70% of the numeral's size, top-aligned
/// against the numeral — DS §2.4 Money role: "Always with currency symbol
/// at 70% size, top-aligned." Top alignment is achieved by giving both
/// texts the same row and aligning the row's cross axis to its start,
/// rather than the default baseline alignment RichText/TextSpan would give
/// two differently-sized inline spans.
class AppMoneyText extends StatelessWidget {
  final String symbol;
  final String amount;
  final TextStyle numeralStyle;
  final Color? color;

  const AppMoneyText({
    super.key,
    required this.symbol,
    required this.amount,
    this.numeralStyle = AppTypography.moneyMax,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedNumeralStyle = color != null
        ? numeralStyle.copyWith(color: color)
        : numeralStyle;
    final symbolStyle = resolvedNumeralStyle.copyWith(
      fontSize: (resolvedNumeralStyle.fontSize ?? 17) * 0.7,
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(symbol, style: symbolStyle),
        Text(amount, style: resolvedNumeralStyle),
      ],
    );
  }
}
