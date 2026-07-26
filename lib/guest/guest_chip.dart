import 'package:flutter/material.dart';

import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_radius.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';

/// DS §11.2: "Persistent Guest chip in app bar ('Viewing as guest ·
/// Sign up') 32h." Placement (which app bars show it) is each caller's
/// concern -- the real public screens (Live Match view, Public Profile,
/// Discover, ...) don't exist yet.
class AppGuestChip extends StatelessWidget {
  final VoidCallback onSignUp;

  const AppGuestChip({super.key, required this.onSignUp});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return GestureDetector(
      onTap: onSignUp,
      behavior: HitTestBehavior.opaque,
      child: Container(
        key: const ValueKey('appGuestChip'),
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        decoration: BoxDecoration(
          color: colors.surfaceAlt,
          borderRadius: AppRadius.fullRadius,
        ),
        alignment: Alignment.center,
        child: Text(
          'Viewing as guest · Sign up',
          style: AppTypography.label.copyWith(color: colors.textSecondary),
        ),
      ),
    );
  }
}
