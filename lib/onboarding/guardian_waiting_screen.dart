import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_state_scaffolds.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'guardian_gate_provider.dart';

/// DS §11.3 Guardian gate, step 4: "'waiting' state screen with resend;
/// app unusable past this point until consent (business rule §17)." The
/// [PopScope] below is what makes "no other screen is reachable" (this
/// story's AC) a structural guarantee rather than a documentation promise
/// -- the same approach E0-04 used for its push-depth cap.
///
/// [showDebugSimulateApproval] renders an extra "Simulate guardian
/// approval" button not in DS -- there's no backend to receive a real
/// guardian's response (that would arrive from their own device), so this
/// is a QA-only bypass, off by default and never shown by the real flow.
class GuardianWaitingScreen extends ConsumerStatefulWidget {
  final VoidCallback onConsentGranted;
  final bool showDebugSimulateApproval;
  final DateTime Function() now;

  const GuardianWaitingScreen({
    super.key,
    required this.onConsentGranted,
    this.showDebugSimulateApproval = false,
    this.now = DateTime.now,
  });

  @override
  ConsumerState<GuardianWaitingScreen> createState() =>
      _GuardianWaitingScreenState();
}

class _GuardianWaitingScreenState extends ConsumerState<GuardianWaitingScreen> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Duration _resendRemaining(DateTime? requestSentAt) {
    if (requestSentAt == null) return Duration.zero;
    final elapsed = widget.now().difference(requestSentAt);
    final remaining = guardianResendCooldown - elapsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    ref.listen(guardianGateProvider, (previous, next) {
      if (previous?.consentGranted != true && next.consentGranted) {
        widget.onConsentGranted();
      }
    });

    final state = ref.watch(guardianGateProvider);
    final remaining = _resendRemaining(state.consentRequestSentAt);
    final canResend = remaining == Duration.zero;

    return PopScope(
      // Blocks back-navigation only while genuinely pending -- once
      // consent is granted this screen stays in the stack (Complete is
      // pushed on top of it, not swapped in), and "Done"'s popUntil needs
      // to be able to pop back through it.
      canPop: state.consentGranted,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Create your account'),
          automaticallyImplyLeading: false,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppArcIllustration(color: colors.primary),
                const SizedBox(height: AppSpacing.xxl),
                Text(
                  'Waiting for guardian approval',
                  key: const ValueKey('guardianWaitingTitle'),
                  textAlign: TextAlign.center,
                  style: AppTypography.h2.copyWith(color: colors.textPrimary),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  "We've texted ${state.guardianPhone} a link to approve "
                  'your account. This screen updates automatically once '
                  "they've confirmed.",
                  textAlign: TextAlign.center,
                  style: AppTypography.body.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                TextButton(
                  key: const ValueKey('guardianWaitingResendButton'),
                  onPressed: canResend
                      ? () => ref
                            .read(guardianGateProvider.notifier)
                            .resendGuardianRequest()
                      : null,
                  child: Text(
                    canResend
                        ? 'Resend request'
                        : 'Resend request in ${remaining.inSeconds}s',
                  ),
                ),
                if (widget.showDebugSimulateApproval) ...[
                  const SizedBox(height: AppSpacing.lg),
                  TextButton(
                    key: const ValueKey('guardianWaitingSimulateApproval'),
                    onPressed: () =>
                        ref.read(guardianGateProvider.notifier).grantConsent(),
                    child: const Text('Simulate guardian approval (demo)'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
