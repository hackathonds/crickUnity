import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_motion.dart';
import '../design_system/tokens/app_radius.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'profile_wizard_provider.dart';

/// DS §11.3: "completeness meter fills live." A live percentage fill bar,
/// distinct from [AppFormStepProgress]'s discrete per-step segments --
/// this tracks *optional field* completion across all three Profile
/// wizard screens, not navigation position, so it's shown identically on
/// each one and grows as fields are filled in (never as steps are simply
/// visited).
class ProfileCompletenessMeter extends ConsumerWidget {
  const ProfileCompletenessMeter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final completeness = ref.watch(
      profileWizardProvider.select((s) => s.completeness),
    );
    final duration = AppMotion.resolveDuration(
      context,
      AppMotionToken.standard,
    );
    final percent = (completeness * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Profile completeness',
              style: AppTypography.label.copyWith(color: colors.textTertiary),
            ),
            Text(
              '$percent%',
              key: const ValueKey('profileCompletenessPercent'),
              style: AppTypography.label.copyWith(color: colors.textTertiary),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        ClipRRect(
          borderRadius: AppRadius.fullRadius,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Container(
                height: 6,
                color: colors.divider,
                alignment: Alignment.centerLeft,
                child: AnimatedContainer(
                  key: const ValueKey('profileCompletenessFill'),
                  duration: duration,
                  curve: AppMotionCurves.standard,
                  width: constraints.maxWidth * completeness,
                  height: 6,
                  color: colors.primary,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
