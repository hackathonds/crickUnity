import 'package:flutter/material.dart';

import '../design_system/components/app_button.dart';
import '../design_system/components/app_state_scaffolds.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';

/// The temporary end of the pre-tab stack built so far (E1-01 + E1-02).
/// PRD §20-A2's "existing account -> login suggest" is handled here as a
/// "welcome back" variant (this app has no separate password-login screen
/// -- OTP verification is the sign-in mechanism for both new and
/// returning users) rather than a second built screen.
///
/// Profile wizard + Permissions + Warm-up (E1-03) is the real next step in
/// this stack once built; this screen is a placeholder for that hand-off,
/// not a guess at their content.
class RegistrationCompleteScreen extends StatelessWidget {
  final bool isExistingAccount;
  final String? name;
  final VoidCallback onDone;

  /// True once a minor's guardian has granted consent (E1-02, PRD §5.20
  /// "Private+"). Never true alongside [isExistingAccount] -- the
  /// existing-account path skips the guardian gate entirely.
  final bool appliedMinorDefaults;

  const RegistrationCompleteScreen({
    super.key,
    required this.isExistingAccount,
    required this.onDone,
    this.name,
    this.appliedMinorDefaults = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final title = isExistingAccount
        ? 'Welcome back!'
        : "You're all set${name != null && name!.isNotEmpty ? ', $name' : ''}!";
    final subtitle = isExistingAccount
        ? 'Looks like you already have an account with this number -- '
              'signing you in.'
        : appliedMinorDefaults
        ? "Your guardian's approved your account. Since you're under 18, "
              "we've set your profile to Private+ by default."
        : 'Profile setup will slot in here next.';

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
                title,
                key: const ValueKey('registrationCompleteTitle'),
                textAlign: TextAlign.center,
                style: AppTypography.h1.copyWith(color: colors.textPrimary),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                subtitle,
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
