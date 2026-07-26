import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_button.dart';
import '../design_system/components/app_form_step_progress.dart';
import '../design_system/components/app_text_field.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'phone_entry_screen.dart';
import 'registration_flow_provider.dart';

/// DS §11.3 Registration, step 3 (final step for this story -- Guardian
/// gate/Profile wizard/Permissions/Warm-up are E1-02/E1-03, not built yet).
class NameEntryScreen extends ConsumerStatefulWidget {
  final ValueChanged<String> onContinue;

  const NameEntryScreen({super.key, required this.onContinue});

  @override
  ConsumerState<NameEntryScreen> createState() => _NameEntryScreenState();
}

class _NameEntryScreenState extends ConsumerState<NameEntryScreen> {
  final _controller = TextEditingController();
  String _name = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final isValid = _name.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Create your account')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppFormStepProgress(
              stepCount: 3,
              currentStep: 2,
              labels: registrationStepLabels,
            ),
            const SizedBox(height: AppSpacing.xxl),
            Text(
              "What's your name?",
              style: AppTypography.h2.copyWith(color: colors.textPrimary),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              "This is how teammates will see you.",
              style: AppTypography.body.copyWith(color: colors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.xxl),
            AppTextField(
              key: const ValueKey('nameEntryField'),
              label: 'Full name',
              controller: _controller,
              validator: (value) =>
                  value.trim().isEmpty ? 'Enter your name' : null,
              onChanged: (value) => setState(() => _name = value),
            ),
            const Spacer(),
            AppButton(
              key: const ValueKey('nameEntryContinue'),
              variant: AppButtonVariant.primary,
              label: 'Continue',
              fullWidth: true,
              onPressed: isValid
                  ? () {
                      final name = _name.trim();
                      ref.read(registrationFlowProvider.notifier).setName(name);
                      widget.onContinue(name);
                    }
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
