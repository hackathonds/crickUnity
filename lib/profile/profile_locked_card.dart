import 'package:flutter/material.dart';

import '../design_system/components/app_avatar.dart';
import '../design_system/components/app_button.dart';
import '../design_system/icons/app_icon.dart';
import '../design_system/icons/app_icon_id.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'profile_models.dart';

/// DS §7 screen 4-5: "Privacy-limited view: minimal card + lock explainer
/// + Request Follow." PRD §5.20: "Private ... public sees name, avatar,
/// city, 'Private profile'."
class ProfileLockedCard extends StatelessWidget {
  final PlayerProfile profile;
  final VoidCallback onRequestFollow;

  const ProfileLockedCard({
    super.key,
    required this.profile,
    required this.onRequestFollow,
  });

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
              AppAvatar(
                size: AppAvatarSize.xxl,
                name: profile.name,
                image: profile.avatarImage,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                profile.name,
                style: AppTypography.h2.copyWith(color: colors.textPrimary),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                profile.city,
                style: AppTypography.body.copyWith(color: colors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppIcon(
                    id: AppIconId.locked,
                    semanticLabel: 'Private',
                    color: colors.textTertiary,
                    size: 16,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'Private profile',
                    key: const ValueKey('profileLockedLabel'),
                    style: AppTypography.caption.copyWith(
                      color: colors.textTertiary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xxl),
              AppButton(
                key: const ValueKey('profileLockedRequestFollow'),
                variant: AppButtonVariant.primary,
                label: 'Request Follow',
                onPressed: onRequestFollow,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
