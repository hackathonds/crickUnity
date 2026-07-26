import 'package:flutter/material.dart';

import '../design_system/components/app_button.dart';
import '../design_system/components/app_state_scaffolds.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';

/// PRD §20-A2's "existing account -> login suggest", handled as a
/// "welcome back" completion (this app has no separate password-login
/// screen -- OTP verification is the sign-in mechanism for both new and
/// returning users) rather than a second built screen.
///
/// Only reached by the existing-account OTP path -- a new registration
/// continues straight from OTP into the Profile wizard (E1-03) instead of
/// stopping here, since a returning user already has a profile and
/// shouldn't redo it.
class RegistrationCompleteScreen extends StatelessWidget {
  final VoidCallback onDone;

  const RegistrationCompleteScreen({super.key, required this.onDone});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppArcIllustration(color: colors.primary),
              const SizedBox(height: AppSpacing.xxl),
              Text(
                'Welcome back!',
                key: const ValueKey('registrationCompleteTitle'),
                textAlign: TextAlign.center,
                style: AppTypography.h1.copyWith(color: colors.textPrimary),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Looks like you already have an account with this number '
                '-- signing you in.',
                textAlign: TextAlign.center,
                style: AppTypography.body.copyWith(color: colors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.xxl),
              AppButton(
                key: const ValueKey('registrationCompleteDone'),
                variant: AppButtonVariant.primary,
                label: 'Done',
                onPressed: onDone,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
