import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_button.dart';
import '../design_system/components/app_dropdown_field.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'profile_completeness_meter.dart';
import 'profile_wizard_provider.dart';

/// No geocoding/places API exists in this repo, so "auto-suggest" (DS
/// §11.3) is a small hardcoded city list filtered by the Dropdown-as-sheet
/// field's own built-in search (DS §3.7) -- the same device DOB's Day/
/// Month/Year fields already use for a long option list.
const List<String> mockCities = [
  'Mumbai',
  'Delhi',
  'Bengaluru',
  'Hyderabad',
  'Chennai',
  'Kolkata',
  'Pune',
  'Ahmedabad',
  'Jaipur',
  'Lucknow',
  'Chandigarh',
  'Indore',
  'Nagpur',
  'Surat',
  'Kochi',
];

/// DS §11.3 Profile wizard, step 2: "city (auto-suggest)."
class CityStepScreen extends ConsumerWidget {
  final VoidCallback onContinue;

  const CityStepScreen({super.key, required this.onContinue});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final city = ref.watch(profileWizardProvider.select((s) => s.city));
    final notifier = ref.read(profileWizardProvider.notifier);

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
              "What's your city?",
              style: AppTypography.h2.copyWith(color: colors.textPrimary),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Helps us show you nearby matches and grounds.',
              style: AppTypography.body.copyWith(color: colors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.xxl),
            AppDropdownField<String>(
              key: const ValueKey('cityStepField'),
              label: 'City',
              value: city,
              options: mockCities,
              labelBuilder: (c) => c,
              onChanged: notifier.setCity,
            ),
            const Spacer(),
            AppButton(
              key: const ValueKey('cityStepContinue'),
              variant: AppButtonVariant.primary,
              label: 'Continue',
              fullWidth: true,
              onPressed: onContinue,
            ),
          ],
        ),
      ),
    );
  }
}
