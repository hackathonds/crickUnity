import 'package:flutter/material.dart';

import '../components/app_stepper.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';

/// QA tool for E0-07 (sub-task 8/10): [AppStepper].
class StepperScreen extends StatefulWidget {
  const StepperScreen({super.key});

  @override
  State<StepperScreen> createState() => _StepperScreenState();
}

class _StepperScreenState extends State<StepperScreen> {
  int _overs = 10;
  int _players = 11;

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
      appBar: AppBar(title: const Text('Stepper (QA)')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            label('Overs (0-50) — tap the value to type a number'),
            AppStepper(
              value: _overs,
              min: 0,
              max: 50,
              semanticLabel: 'Overs',
              onChanged: (v) => setState(() => _overs = v),
            ),
            label('Players (1-15) — hold +/− to auto-repeat'),
            AppStepper(
              value: _players,
              min: 1,
              max: 15,
              semanticLabel: 'Players',
              onChanged: (v) => setState(() => _players = v),
            ),
          ],
        ),
      ),
    );
  }
}
