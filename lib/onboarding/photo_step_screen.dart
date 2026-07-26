import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_button.dart';
import '../design_system/icons/app_icon.dart';
import '../design_system/icons/app_icon_id.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'profile_completeness_meter.dart';
import 'profile_wizard_provider.dart';

/// DS §11.3 Profile wizard, step 1: "photo (camera/library/skip)."
///
/// No image-picker package (e.g. `image_picker`) exists in this repo, so
/// there's no real camera/gallery to open -- "Take photo"/"Choose from
/// library" simulate a photo being set (filling the completeness meter)
/// rather than opening one, flagged as an open PR question.
class PhotoStepScreen extends ConsumerWidget {
  final VoidCallback onContinue;

  const PhotoStepScreen({super.key, required this.onContinue});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final photoSet = ref.watch(profileWizardProvider.select((s) => s.photoSet));
    final notifier = ref.read(profileWizardProvider.notifier);

    void choosePhoto() {
      notifier.setPhotoSet(true);
      onContinue();
    }

    void skip() {
      onContinue();
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Set up your profile')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ProfileCompletenessMeter(),
            const SizedBox(height: AppSpacing.xxl),
            Text(
              'Add a profile photo',
              style: AppTypography.h2.copyWith(color: colors.textPrimary),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Teammates recognize you faster with a photo. You can always '
              'add one later.',
              style: AppTypography.body.copyWith(color: colors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Center(
              child: Container(
                key: const ValueKey('photoStepAvatarPreview'),
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: photoSet ? colors.primary : colors.surfaceAlt,
                ),
                child: photoSet
                    ? AppIcon(
                        id: AppIconId.verifiedCheck,
                        semanticLabel: 'Photo set',
                        color: colors.onPrimary,
                        size: 36,
                      )
                    : AppIcon(
                        id: AppIconId.avatar,
                        semanticLabel: 'No photo set',
                        color: colors.textTertiary,
                        size: 36,
                      ),
              ),
            ),
            const Spacer(),
            AppButton(
              key: const ValueKey('photoStepTakePhoto'),
              variant: AppButtonVariant.primary,
              label: 'Take photo',
              fullWidth: true,
              onPressed: choosePhoto,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              key: const ValueKey('photoStepChooseLibrary'),
              variant: AppButtonVariant.secondary,
              label: 'Choose from library',
              fullWidth: true,
              onPressed: choosePhoto,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              key: const ValueKey('photoStepSkip'),
              variant: AppButtonVariant.tertiary,
              label: 'Skip',
              fullWidth: true,
              onPressed: skip,
            ),
          ],
        ),
      ),
    );
  }
}
