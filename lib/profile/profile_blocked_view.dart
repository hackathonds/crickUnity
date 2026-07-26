import 'package:flutter/material.dart';

import '../design_system/icons/app_icon.dart';
import '../design_system/icons/app_icon_id.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';

/// PRD §5 / this story's AC: "blocked users get 'Profile unavailable'."
class ProfileBlockedView extends StatelessWidget {
  const ProfileBlockedView({super.key});

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
              AppIcon(
                id: AppIconId.locked,
                semanticLabel: 'Unavailable',
                color: colors.textTertiary,
                size: 40,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Profile unavailable',
                key: const ValueKey('profileBlockedMessage'),
                style: AppTypography.h2.copyWith(color: colors.textPrimary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
