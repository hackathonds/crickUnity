import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_button.dart';
import '../design_system/components/app_form_step_progress.dart';
import '../design_system/components/app_text_field.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'registration_flow_provider.dart';

const List<String> registrationStepLabels = ['Phone', 'Verify', 'Name'];

String? _validatePhone(String value) {
  if (value.length != 10) return 'Enter a 10-digit phone number';
  return null;
}

/// DS §11.3 Registration, step 1: "single-field-per-screen rhythm (phone ->
/// ...)". PRD §20-A2 mentions phone/email as alternatives, but the cited DS
/// behavior spec and this story's own backlog AC only describe a phone+OTP
/// flow -- built phone-only per those more specific sources.
class PhoneEntryScreen extends ConsumerStatefulWidget {
  final ValueChanged<String> onContinue;

  const PhoneEntryScreen({super.key, required this.onContinue});

  @override
  ConsumerState<PhoneEntryScreen> createState() => _PhoneEntryScreenState();
}

class _PhoneEntryScreenState extends ConsumerState<PhoneEntryScreen> {
  final _controller = TextEditingController();
  String _phone = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final isValid = _validatePhone(_phone) == null;

    return Scaffold(
      appBar: AppBar(title: const Text('Create your account')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppFormStepProgress(
              stepCount: 3,
              currentStep: 0,
              labels: registrationStepLabels,
            ),
            const SizedBox(height: AppSpacing.xxl),
            Text(
              "What's your phone number?",
              style: AppTypography.h2.copyWith(color: colors.textPrimary),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              "We'll text you a 6-digit code to verify it.",
              style: AppTypography.body.copyWith(color: colors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.xxl),
            AppTextField(
              key: const ValueKey('phoneEntryField'),
              label: 'Phone number',
              controller: _controller,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              validator: (value) =>
                  value.isEmpty ? null : _validatePhone(value),
              onChanged: (value) => setState(() => _phone = value),
            ),
            const Spacer(),
            AppButton(
              key: const ValueKey('phoneEntryContinue'),
              variant: AppButtonVariant.primary,
              label: 'Continue',
              fullWidth: true,
              onPressed: isValid
                  ? () {
                      ref
                          .read(registrationFlowProvider.notifier)
                          .submitPhone(_phone);
                      widget.onContinue(_phone);
                    }
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
