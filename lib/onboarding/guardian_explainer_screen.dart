import 'package:flutter/material.dart';

import '../design_system/components/app_button.dart';
import '../design_system/components/app_state_scaffolds.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';

/// DS §11.3 Guardian gate, step 2: "explains guardian requirement plainly."
/// PRD §17 guardian layer: "minors -> guardian link mandatory; guardian
/// sees followers/messages surface, approves media tagging, receives
/// coach notes."
class GuardianExplainerScreen extends StatelessWidget {
  final VoidCallback onContinue;

  const GuardianExplainerScreen({super.key, required this.onContinue});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Scaffold(
      appBar: AppBar(title: const Text('Create your account')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppArcIllustration(color: colors.primary),
            const SizedBox(height: AppSpacing.xxl),
            Text(
              'A parent or guardian needs to approve your account',
              style: AppTypography.h2.copyWith(color: colors.textPrimary),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              "Since you're under 18, we ask a parent or guardian to "
              'confirm before you can use CricUnity. Once they approve:',
              style: AppTypography.body.copyWith(color: colors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.lg),
            _ExplainerRow(
              text: 'Your profile stays private by default.',
              colors: colors,
            ),
            _ExplainerRow(
              text: 'Your guardian can see your followers and messages.',
              colors: colors,
            ),
            _ExplainerRow(
              text:
                  "They'll approve any photo tags and get your coach's "
                  'notes.',
              colors: colors,
            ),
            const Spacer(),
            AppButton(
              key: const ValueKey('guardianExplainerContinue'),
              variant: AppButtonVariant.primary,
              label: 'Continue',
              fullWidth: true,
              onPressed: onContinue,
            ),
          ],
        ),
      ),
    );
  }
}

class _ExplainerRow extends StatelessWidget {
  final String text;
  final AppColors colors;

  const _ExplainerRow({required this.text, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '•  ',
            style: AppTypography.body.copyWith(color: colors.primary),
          ),
          Expanded(
            child: Text(
              text,
              style: AppTypography.body.copyWith(color: colors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
