import 'package:flutter/material.dart';

import '../design_system/components/app_button.dart';
import '../design_system/icons/app_icon.dart';
import '../design_system/icons/app_icon_id.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';

/// PRD §2.1 edge case: "Guest opening a *private* match link sees 'This
/// match is private -- ask the captain for access' with a request-access
/// button that forces registration first."
///
/// Generalized over [objectType]/[ownerRoleLabel] so any future private
/// object (match today; team, tournament, etc. later) can reuse this
/// scaffold rather than each needing its own lock screen. "Forces
/// registration first" is exactly [onRequestAccess] -- what a request
/// actually does once someone has an account (notifying the owner role)
/// has no data model yet, so it's out of scope here.
class PrivateContentLockScreen extends StatelessWidget {
  final String objectType;
  final String ownerRoleLabel;
  final VoidCallback onRequestAccess;

  const PrivateContentLockScreen({
    super.key,
    required this.objectType,
    required this.ownerRoleLabel,
    required this.onRequestAccess,
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
              AppIcon(
                id: AppIconId.locked,
                semanticLabel: 'Private',
                color: colors.textTertiary,
                size: 40,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'This $objectType is private — ask the $ownerRoleLabel for '
                'access',
                key: const ValueKey('privateLockMessage'),
                textAlign: TextAlign.center,
                style: AppTypography.h2.copyWith(color: colors.textPrimary),
              ),
              const SizedBox(height: AppSpacing.xxl),
              AppButton(
                key: const ValueKey('privateLockRequestAccess'),
                variant: AppButtonVariant.primary,
                label: 'Request access',
                onPressed: onRequestAccess,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
