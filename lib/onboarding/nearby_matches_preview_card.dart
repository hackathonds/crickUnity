import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_button.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_radius.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'permissions_provider.dart';

/// E1-03's AC: "denial of location makes Nearby widget show its
/// enable-prompt state" (PRD §4.11: "Requires location permission; else
/// shows 'Enable location to find cricket around you.'").
///
/// The real Home dashboard (and its real Nearby Matches widget, with
/// teams/over/venue distance and Watch live/Directions/Follow actions)
/// doesn't exist yet -- this is a minimal stand-in that reads the same
/// [permissionsProvider] state, built only to make this AC concretely
/// demonstrable, not the full PRD §4.11 feature.
class NearbyMatchesPreviewCard extends ConsumerWidget {
  const NearbyMatchesPreviewCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final location = ref.watch(permissionsProvider.select((s) => s.location));
    final notifier = ref.read(permissionsProvider.notifier);
    final granted = location == PermissionStatus.granted;

    return Container(
      key: const ValueKey('nearbyMatchesPreviewCard'),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.border),
        borderRadius: AppRadius.mdRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nearby matches',
            style: AppTypography.title.copyWith(color: colors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (granted)
            Text(
              '3 matches within 10km (placeholder)',
              key: const ValueKey('nearbyMatchesContent'),
              style: AppTypography.body.copyWith(color: colors.textSecondary),
            )
          else ...[
            Text(
              'Enable location to find cricket around you.',
              key: const ValueKey('nearbyMatchesEnablePrompt'),
              style: AppTypography.body.copyWith(color: colors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              key: const ValueKey('nearbyMatchesEnableLocation'),
              variant: AppButtonVariant.secondary,
              label: 'Enable location',
              onPressed: () => notifier.setLocation(PermissionStatus.granted),
            ),
          ],
        ],
      ),
    );
  }
}
