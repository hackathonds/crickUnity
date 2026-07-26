import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_button.dart';
import '../design_system/components/app_text_field.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'guardian_gate_provider.dart';

String? _validatePhone(String value) {
  if (value.length != 10) return 'Enter a 10-digit phone number';
  return null;
}

/// DS §11.3 Guardian gate, step 3: "guardian contact capture."
class GuardianContactScreen extends ConsumerStatefulWidget {
  final VoidCallback onSent;

  const GuardianContactScreen({super.key, required this.onSent});

  @override
  ConsumerState<GuardianContactScreen> createState() =>
      _GuardianContactScreenState();
}

class _GuardianContactScreenState extends ConsumerState<GuardianContactScreen> {
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
            Text(
              "What's your guardian's phone number?",
              style: AppTypography.h2.copyWith(color: colors.textPrimary),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              "We'll text them a link to approve your account.",
              style: AppTypography.body.copyWith(color: colors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.xxl),
            AppTextField(
              key: const ValueKey('guardianContactField'),
              label: "Guardian's phone number",
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
              key: const ValueKey('guardianContactSend'),
              variant: AppButtonVariant.primary,
              label: 'Send request',
              fullWidth: true,
              onPressed: isValid
                  ? () {
                      ref
                          .read(guardianGateProvider.notifier)
                          .sendGuardianRequest(_phone);
                      widget.onSent();
                    }
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
