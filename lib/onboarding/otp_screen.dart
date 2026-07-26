import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_form_step_progress.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_radius.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'phone_entry_screen.dart';
import 'registration_flow_provider.dart';

const int otpLength = 6;

/// DS §11.3 Registration, step 2: "OTP 6-cell auto-advance boxes 48, resend
/// countdown 30s, 3 attempts -> cooldown state with support link."
///
/// [onVerified] fires once the (mocked) code is accepted, with whether this
/// phone matched an existing account (PRD §20-A2) -- the caller decides
/// where that leads (skip to completion vs. the Name step), same
/// expose-a-callback boundary as [PhoneEntryScreen]/[WelcomeScreen].
class OtpScreen extends ConsumerStatefulWidget {
  final void Function(bool isExistingAccount) onVerified;
  final VoidCallback onContactSupport;

  /// Clock seam: `Timer` scheduling is virtualized by `tester.pump()` in
  /// widget tests, but `DateTime.now()` is not, so verifying the 30s resend
  /// countdown actually elapsing needs an injectable "now" rather than a
  /// real 30-second-long test.
  final DateTime Function() now;

  const OtpScreen({
    super.key,
    required this.onVerified,
    required this.onContactSupport,
    this.now = DateTime.now,
  });

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  Timer? _ticker;
  String? _errorText;
  int _resetSignal = 0;

  @override
  void initState() {
    super.initState();
    // Forces a rebuild every second so the resend countdown (derived from
    // registrationFlowProvider's codeSentAt) actually ticks down.
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Duration _resendRemaining(DateTime? codeSentAt) {
    if (codeSentAt == null) return Duration.zero;
    final elapsed = widget.now().difference(codeSentAt);
    final remaining = otpResendCooldown - elapsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  void _handleCodeChanged(String code) {
    if (code.length < otpLength) return;

    final result = ref.read(registrationFlowProvider.notifier).submitOtp(code);
    switch (result) {
      case OtpSubmitResult.correct:
        setState(() => _errorText = null);
        widget.onVerified(ref.read(registrationFlowProvider).isExistingAccount);
      case OtpSubmitResult.incorrect:
        setState(() {
          _errorText = 'Incorrect code, try again.';
          _resetSignal++;
        });
      case OtpSubmitResult.cooldown:
        setState(() {
          _errorText = null;
          _resetSignal++;
        });
    }
  }

  void _handleResend() {
    ref.read(registrationFlowProvider.notifier).resendCode();
    setState(() {
      _errorText = null;
      _resetSignal++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final registration = ref.watch(registrationFlowProvider);
    final remaining = _resendRemaining(registration.codeSentAt);
    final canResend = remaining == Duration.zero;

    return Scaffold(
      appBar: AppBar(title: const Text('Create your account')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppFormStepProgress(
              stepCount: 3,
              currentStep: 1,
              labels: registrationStepLabels,
            ),
            const SizedBox(height: AppSpacing.xxl),
            Text(
              'Enter the code',
              style: AppTypography.h2.copyWith(color: colors.textPrimary),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'We sent a 6-digit code to ${registration.phone}. '
              '(Demo code: $demoCorrectOtp)',
              style: AppTypography.body.copyWith(color: colors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.xxl),
            if (registration.inCooldown)
              _CooldownNotice(onContactSupport: widget.onContactSupport)
            else ...[
              _OtpCells(
                key: const ValueKey('otpCells'),
                length: otpLength,
                enabled: !registration.inCooldown,
                resetSignal: _resetSignal,
                onChanged: _handleCodeChanged,
              ),
              if (_errorText != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _errorText!,
                  key: const ValueKey('otpErrorText'),
                  style: AppTypography.caption.copyWith(color: colors.error),
                ),
              ],
              const SizedBox(height: AppSpacing.xxl),
              TextButton(
                key: const ValueKey('otpResendButton'),
                onPressed: canResend ? _handleResend : null,
                child: Text(
                  canResend
                      ? 'Resend code'
                      : 'Resend code in ${remaining.inSeconds}s',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// DS gives no unlock duration for the 3-attempts cooldown (unlike resend's
/// explicit 30s) -- support is the human-in-the-loop escape hatch; a fresh
/// resend (already specified) is the self-service one, so this notice
/// doesn't invent a countdown for a value the spec never gave.
class _CooldownNotice extends StatelessWidget {
  final VoidCallback onContactSupport;

  const _CooldownNotice({required this.onContactSupport});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Container(
      key: const ValueKey('otpCooldownNotice'),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surfaceAlt,
        borderRadius: AppRadius.mdRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Too many incorrect attempts.',
            style: AppTypography.title.copyWith(color: colors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            "Request a new code below, or get help if you're still stuck.",
            style: AppTypography.body.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            key: const ValueKey('otpContactSupportButton'),
            onPressed: onContactSupport,
            child: const Text('Contact support'),
          ),
        ],
      ),
    );
  }
}

class _OtpCells extends StatefulWidget {
  final int length;
  final bool enabled;
  final int resetSignal;
  final ValueChanged<String> onChanged;

  const _OtpCells({
    super.key,
    required this.length,
    required this.enabled,
    required this.resetSignal,
    required this.onChanged,
  });

  @override
  State<_OtpCells> createState() => _OtpCellsState();
}

class _OtpCellsState extends State<_OtpCells> {
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.length, (_) => TextEditingController());
    _focusNodes = List.generate(widget.length, (_) => FocusNode());
  }

  @override
  void didUpdateWidget(covariant _OtpCells oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.resetSignal != oldWidget.resetSignal) {
      for (final controller in _controllers) {
        controller.clear();
      }
      _focusNodes.first.requestFocus();
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _emitChange() {
    widget.onChanged(_controllers.map((c) => c.text).join());
  }

  void _handleChanged(int index, String value) {
    if (value.isNotEmpty && index < widget.length - 1) {
      _focusNodes[index + 1].requestFocus();
    }
    _emitChange();
  }

  KeyEventResult _handleKeyEvent(int index, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[index].text.isEmpty &&
        index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (var i = 0; i < widget.length; i++)
          Focus(
            onKeyEvent: (node, event) => _handleKeyEvent(i, event),
            child: SizedBox(
              key: ValueKey('otpCell$i'),
              width: 48,
              height: 48,
              child: TextField(
                controller: _controllers[i],
                focusNode: _focusNodes[i],
                enabled: widget.enabled,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                maxLength: 1,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: AppTypography.stat.copyWith(color: colors.textPrimary),
                decoration: InputDecoration(
                  counterText: '',
                  contentPadding: EdgeInsets.zero,
                  border: OutlineInputBorder(
                    borderRadius: AppRadius.smRadius,
                    borderSide: BorderSide(color: colors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: AppRadius.smRadius,
                    borderSide: BorderSide(color: colors.primary, width: 1.5),
                  ),
                ),
                onChanged: (value) => _handleChanged(i, value),
              ),
            ),
          ),
      ],
    );
  }
}
