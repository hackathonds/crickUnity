import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_button.dart';
import '../design_system/icons/app_icon.dart';
import '../design_system/icons/app_icon_id.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_radius.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'permissions_provider.dart';

/// DS §11.3 Permissions primer: "one card per permission (location/
/// notifications) with concrete benefit copy and [Allow]/[Later]; denial
/// writes the §6 fallback states."
///
/// PRD §4.11 gives location's exact denial copy ("Enable location to find
/// cricket around you.") -- that's what [NearbyMatchesPreviewCard] shows.
/// Notifications' benefit copy has no PRD-cited wording, so it's
/// representative copy satisfying "concrete benefit copy," not a business
/// rule.
class PermissionsPrimerScreen extends ConsumerWidget {
  final VoidCallback onContinue;

  const PermissionsPrimerScreen({super.key, required this.onContinue});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final state = ref.watch(permissionsProvider);
    final notifier = ref.read(permissionsProvider.notifier);
    final bothDecided =
        state.location != PermissionStatus.undetermined &&
        state.notifications != PermissionStatus.undetermined;

    return Scaffold(
      appBar: AppBar(title: const Text('Stay in the loop')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PermissionCard(
              key: const ValueKey('permissionCardLocation'),
              keyPrefix: 'location',
              icon: AppIconId.pitch,
              title: 'Location',
              benefit: 'See matches and grounds happening near you.',
              status: state.location,
              onAllow: () => notifier.setLocation(PermissionStatus.granted),
              onLater: () => notifier.setLocation(PermissionStatus.denied),
            ),
            const SizedBox(height: AppSpacing.lg),
            _PermissionCard(
              key: const ValueKey('permissionCardNotifications'),
              keyPrefix: 'notifications',
              icon: AppIconId.remindBell,
              title: 'Notifications',
              benefit:
                  'Get alerted when your match starts or your team needs '
                  'you.',
              status: state.notifications,
              onAllow: () =>
                  notifier.setNotifications(PermissionStatus.granted),
              onLater: () => notifier.setNotifications(PermissionStatus.denied),
            ),
            const Spacer(),
            AppButton(
              key: const ValueKey('permissionsPrimerContinue'),
              variant: AppButtonVariant.primary,
              label: 'Continue',
              fullWidth: true,
              onPressed: bothDecided ? onContinue : null,
            ),
            if (!bothDecided) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Choose Allow or Later for both to continue.',
                style: AppTypography.caption.copyWith(
                  color: colors.textTertiary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PermissionCard extends StatelessWidget {
  final String keyPrefix;
  final AppIconId icon;
  final String title;
  final String benefit;
  final PermissionStatus status;
  final VoidCallback onAllow;
  final VoidCallback onLater;

  const _PermissionCard({
    super.key,
    required this.keyPrefix,
    required this.icon,
    required this.title,
    required this.benefit,
    required this.status,
    required this.onAllow,
    required this.onLater,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final decided = status != PermissionStatus.undetermined;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.border),
        borderRadius: AppRadius.mdRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppIcon(id: icon, semanticLabel: title, color: colors.primary),
              const SizedBox(width: AppSpacing.sm),
              Text(
                title,
                style: AppTypography.title.copyWith(color: colors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            benefit,
            style: AppTypography.body.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          if (decided)
            Text(
              status == PermissionStatus.granted ? 'Allowed' : 'Not now',
              key: ValueKey('permissionCardDecidedLabel_$keyPrefix'),
              style: AppTypography.label.copyWith(
                color: status == PermissionStatus.granted
                    ? colors.primary
                    : colors.textTertiary,
              ),
            )
          else
            Row(
              children: [
                AppButton(
                  key: ValueKey('permissionCardAllow_$keyPrefix'),
                  variant: AppButtonVariant.primary,
                  label: 'Allow',
                  onPressed: onAllow,
                ),
                const SizedBox(width: AppSpacing.sm),
                AppButton(
                  key: ValueKey('permissionCardLater_$keyPrefix'),
                  variant: AppButtonVariant.tertiary,
                  label: 'Later',
                  onPressed: onLater,
                ),
              ],
            ),
        ],
      ),
    );
  }
}
