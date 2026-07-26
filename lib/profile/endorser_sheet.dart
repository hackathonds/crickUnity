import 'package:flutter/material.dart';

import '../design_system/components/app_avatar.dart';
import '../design_system/components/app_bottom_sheet.dart';
import '../design_system/icons/app_icon.dart';
import '../design_system/icons/app_icon_id.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'profile_models.dart';

/// PRD §5.8: "endorser avatars on tap; coach endorsements weighted with a
/// whistle icon."
Future<void> showEndorserSheet({
  required BuildContext context,
  required Endorsement endorsement,
}) {
  return showAppBottomSheet<void>(
    context: context,
    title: endorsement.skill,
    contentBuilder: (context) =>
        _EndorserSheetContent(endorsement: endorsement),
  );
}

class _EndorserSheetContent extends StatelessWidget {
  final Endorsement endorsement;

  const _EndorserSheetContent({required this.endorsement});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final endorser in endorsement.endorsers)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Row(
                children: [
                  AppAvatar(size: AppAvatarSize.sm, name: endorser.name),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      endorser.name,
                      style: AppTypography.body.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                  if (endorser.isCoach)
                    AppIcon(
                      key: const ValueKey('endorserCoachWhistle'),
                      id: AppIconId.whistle,
                      semanticLabel: 'Coach endorsement',
                      color: colors.textTertiary,
                      size: 18,
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
