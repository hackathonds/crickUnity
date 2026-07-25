import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_text_field.dart';

/// DS §3.19: "Currency fields: right-aligned tnum, symbol fixed,
/// auto-thousand separators." A thin configuration of [AppTextField]
/// rather than a separate field shell — same border/label/validation
/// behavior, just a fixed prefix, right alignment, and digit grouping.
class AppCurrencyField extends StatelessWidget {
  final String label;
  final TextEditingController? controller;
  final String currencySymbol;
  final String? Function(String value)? validator;
  final String? helperText;
  final ValueChanged<String>? onChanged;

  const AppCurrencyField({
    super.key,
    required this.label,
    this.controller,
    this.currencySymbol = '₹',
    this.validator,
    this.helperText,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      label: label,
      controller: controller,
      validator: validator,
      helperText: helperText,
      onChanged: onChanged,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.right,
      prefixText: currencySymbol,
      inputFormatters: [_ThousandsSeparatorFormatter()],
    );
  }
}

/// Strips non-digits and re-inserts `,` every 3 digits from the right as
/// the user types — DS §3.19's "auto-thousand separators."
class _ThousandsSeparatorFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(text: '');
    }

    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      final fromEnd = digits.length - i;
      if (i > 0 && fromEnd % 3 == 0) buffer.write(',');
      buffer.write(digits[i]);
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
