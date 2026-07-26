import 'package:flutter/material.dart';

import '../design_system/components/app_bottom_sheet.dart';
import '../design_system/components/app_button.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';

/// DS §11.2 Guest mode: "every interactive control a Guest taps triggers
/// the Register sheet (half detent): value line specific to the blocked
/// action ('Create a free profile to follow Rohan'), [Continue with
/// phone] primary, [Not now] tertiary."
///
/// [valueLine] must name the specific blocked action (this story's AC) --
/// callers pass e.g. "Create a free profile to follow Rohan", never a
/// generic "Sign up to continue."
Future<void> showRegisterSheet({
  required BuildContext context,
  required String valueLine,
  required VoidCallback onContinueWithPhone,
}) {
  return showAppBottomSheet<void>(
    context: context,
    contentBuilder: (context) => _RegisterSheetContent(
      valueLine: valueLine,
      onContinueWithPhone: onContinueWithPhone,
    ),
  );
}

class _RegisterSheetContent extends StatelessWidget {
  final String valueLine;
  final VoidCallback onContinueWithPhone;

  const _RegisterSheetContent({
    required this.valueLine,
    required this.onContinueWithPhone,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xxl,
        AppSpacing.md,
        AppSpacing.xxl,
        AppSpacing.xxl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            valueLine,
            key: const ValueKey('registerSheetValueLine'),
            style: AppTypography.h2.copyWith(color: colors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.xxl),
          AppButton(
            key: const ValueKey('registerSheetContinueWithPhone'),
            variant: AppButtonVariant.primary,
            label: 'Continue with phone',
            fullWidth: true,
            onPressed: () {
              Navigator.of(context).pop();
              onContinueWithPhone();
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            key: const ValueKey('registerSheetNotNow'),
            variant: AppButtonVariant.tertiary,
            label: 'Not now',
            fullWidth: true,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
