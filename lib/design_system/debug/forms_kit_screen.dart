import 'package:flutter/material.dart';

import '../components/app_currency_field.dart';
import '../components/app_form_step_progress.dart';
import '../components/app_text_field.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';

/// QA tool for E0-07 (sub-task 7/10): [AppTextField], [AppCurrencyField],
/// [AppFormStepProgress].
class FormsKitScreen extends StatefulWidget {
  const FormsKitScreen({super.key});

  @override
  State<FormsKitScreen> createState() => _FormsKitScreenState();
}

class _FormsKitScreenState extends State<FormsKitScreen> {
  int _currentStep = 1;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    Widget label(String text) => Padding(
      padding: const EdgeInsets.only(
        bottom: AppSpacing.sm,
        top: AppSpacing.xxl,
      ),
      child: Text(
        text,
        style: AppTypography.label.copyWith(color: colors.textTertiary),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Forms kit (QA)')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            label('AppTextField — floating label, blur-validated'),
            AppTextField(
              label: 'Team name',
              helperText: 'Visible to opponents when you send a match invite',
              validator: (value) =>
                  value.trim().isEmpty ? 'Team name is required' : null,
            ),
            label('AppCurrencyField — right-aligned, auto thousands'),
            AppCurrencyField(
              label: 'Entry fee',
              validator: (value) => value.isEmpty ? 'Enter an amount' : null,
            ),
            label('AppFormStepProgress'),
            AppFormStepProgress(
              stepCount: 4,
              currentStep: _currentStep,
              labels: const ['Basics', 'Opponent', 'Ground & Time', 'Review'],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                TextButton(
                  onPressed: _currentStep > 0
                      ? () => setState(() => _currentStep--)
                      : null,
                  child: const Text('Back'),
                ),
                TextButton(
                  onPressed: _currentStep < 3
                      ? () => setState(() => _currentStep++)
                      : null,
                  child: const Text('Next'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
