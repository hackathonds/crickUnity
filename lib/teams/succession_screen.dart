import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_button.dart';
import '../design_system/components/app_dialog.dart';
import '../design_system/components/app_text_field.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'succession_models.dart';
import 'succession_provider.dart';

/// PRD §2.3/2.4/2.9 and the team edge cases in §6 (captaincy/ownership
/// succession). No real Match module exists yet, so match-day
/// auto-elevation uses a fixed mock match label rather than a real
/// fixture.
class SuccessionScreen extends ConsumerWidget {
  final String viewerName;
  final DateTime Function() now;

  static const _mockMatchLabel = "Sunday's match vs Central Warriors";

  const SuccessionScreen({
    super.key,
    required this.viewerName,
    this.now = DateTime.now,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final state = ref.watch(successionProvider);
    final notifier = ref.read(successionProvider.notifier);
    final isCaptain = viewerName == state.captainName;
    final isOwner = viewerName == state.ownerName;

    Widget sectionLabel(String text) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        text,
        style: AppTypography.label.copyWith(color: colors.textTertiary),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Captaincy & ownership')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          sectionLabel('Match-day availability'),
          if (isCaptain)
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Mark yourself unavailable for "$_mockMatchLabel"',
                    style: AppTypography.body.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                ),
                Switch(
                  key: const ValueKey('captainUnavailableSwitch'),
                  value: state.unavailableMatchLabel == _mockMatchLabel,
                  onChanged: (value) => value
                      ? notifier.markCaptainUnavailable(
                          _mockMatchLabel,
                          now: now,
                        )
                      : notifier.markCaptainAvailable(),
                ),
              ],
            ),
          if (state.unavailableMatchLabel != null)
            Container(
              key: const ValueKey('elevationBanner'),
              margin: const EdgeInsets.only(top: AppSpacing.sm),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: colors.surfaceAlt,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                'VC ${state.viceCaptainName} has full match-day powers for '
                '"${state.unavailableMatchLabel}."',
                style: AppTypography.body.copyWith(color: colors.textPrimary),
              ),
            ),
          const SizedBox(height: AppSpacing.xxl),
          sectionLabel('Ownership transfer'),
          if (state.pendingOwnershipTransfer == null && isOwner)
            _OwnershipTransferForm(now: now),
          if (state.pendingOwnershipTransfer != null)
            _PendingOwnershipTransferBanner(
              transfer: state.pendingOwnershipTransfer!,
              isOwner: isOwner,
              now: now,
            ),
          if (state.pendingOwnershipTransfer == null && !isOwner)
            Text(
              'No ownership transfer pending.',
              style: AppTypography.body.copyWith(color: colors.textSecondary),
            ),
          const SizedBox(height: AppSpacing.xxl),
          sectionLabel('Inactive-owner petition'),
          if (isCaptain && !isOwner)
            _InactivityPetitionSection(now: now)
          else if (isOwner && state.pendingInactivityPetition != null)
            _OwnerPetitionResponseBanner(
              petition: state.pendingInactivityPetition!,
              now: now,
            )
          else
            Text(
              'Nothing to review.',
              style: AppTypography.body.copyWith(color: colors.textSecondary),
            ),
          const SizedBox(height: AppSpacing.xxl),
          AppButton(
            key: const ValueKey('leaveTeamButton'),
            variant: AppButtonVariant.destructive,
            label: 'Leave team',
            fullWidth: true,
            onPressed: () => _handleLeaveTeam(context, ref, isCaptain, isOwner),
          ),
        ],
      ),
    );
  }

  void _handleLeaveTeam(
    BuildContext context,
    WidgetRef ref,
    bool isCaptain,
    bool isOwner,
  ) {
    final result = ref
        .read(successionProvider.notifier)
        .attemptExitTeam(isCaptain: isCaptain, isOwner: isOwner);
    if (result.blocked) {
      showAppDialog<void>(
        context: context,
        builder: (context) => AppDialogShell(
          colors: Theme.of(context).extension<AppColors>()!,
          title: 'Resolve succession first',
          body: result.error!,
          actions: [
            TextButton(
              key: const ValueKey('exitBlockedDismiss'),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
            ElevatedButton(
              key: const ValueKey('exitBlockedArchiveTeam'),
              onPressed: () {
                ref.read(successionProvider.notifier).archiveTeam();
                Navigator.of(context).pop();
              },
              child: const Text('Archive team'),
            ),
          ],
        ),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.note ?? 'You left the team.')),
    );
  }
}

class _OwnershipTransferForm extends ConsumerStatefulWidget {
  final DateTime Function() now;

  const _OwnershipTransferForm({required this.now});

  @override
  ConsumerState<_OwnershipTransferForm> createState() =>
      _OwnershipTransferFormState();
}

class _OwnershipTransferFormState
    extends ConsumerState<_OwnershipTransferForm> {
  final _newOwnerController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _newOwnerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTextField(
          key: const ValueKey('newOwnerField'),
          label: 'New owner',
          controller: _newOwnerController,
        ),
        if (_error != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            _error!,
            key: const ValueKey('ownershipTransferError'),
            style: AppTypography.caption.copyWith(color: colors.error),
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        AppButton(
          key: const ValueKey('startOwnershipTransferButton'),
          variant: AppButtonVariant.primary,
          label: 'Start ownership transfer',
          fullWidth: true,
          onPressed: () {
            final result = ref
                .read(successionProvider.notifier)
                .initiateOwnershipTransfer(
                  _newOwnerController.text,
                  now: widget.now,
                );
            setState(() => _error = result.error);
          },
        ),
      ],
    );
  }
}

class _PendingOwnershipTransferBanner extends ConsumerWidget {
  final OwnershipTransfer transfer;
  final bool isOwner;
  final DateTime Function() now;

  const _PendingOwnershipTransferBanner({
    required this.transfer,
    required this.isOwner,
    required this.now,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final coolingComplete = transfer.isCoolingComplete(now: now);

    return Container(
      key: const ValueKey('pendingOwnershipTransferBanner'),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Transferring ownership to ${transfer.newOwnerName}. All '
            'members have been notified.',
            style: AppTypography.body.copyWith(color: colors.textPrimary),
          ),
          Text(
            'Cooling period ends ${transfer.coolingEndsAt.day}/'
            '${transfer.coolingEndsAt.month}/${transfer.coolingEndsAt.year}',
            style: AppTypography.caption.copyWith(color: colors.textTertiary),
          ),
          if (isOwner) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    key: const ValueKey('cancelOwnershipTransferButton'),
                    variant: AppButtonVariant.secondary,
                    label: 'Cancel',
                    onPressed: () => ref
                        .read(successionProvider.notifier)
                        .cancelOwnershipTransfer(),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppButton(
                    key: const ValueKey('completeOwnershipTransferButton'),
                    variant: AppButtonVariant.primary,
                    label: 'Complete transfer',
                    onPressed: coolingComplete
                        ? () => ref
                              .read(successionProvider.notifier)
                              .completeOwnershipTransfer(now: now)
                        : null,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _InactivityPetitionSection extends ConsumerWidget {
  final DateTime Function() now;

  const _InactivityPetitionSection({required this.now});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final state = ref.watch(successionProvider);
    final notifier = ref.read(successionProvider.notifier);
    final inactiveDays = now().difference(state.ownerLastActiveAt).inDays;
    final eligible = inactiveDays >= ownerInactivityThresholdDays;

    if (state.pendingInactivityPetition != null) {
      final petition = state.pendingInactivityPetition!;
      return Container(
        key: const ValueKey('pendingInactivityPetitionBanner'),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: colors.surfaceAlt,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          'Petition sent to the owner. Response window ends '
          '${petition.responseDeadline.day}/${petition.responseDeadline.month}/'
          '${petition.responseDeadline.year}.',
          style: AppTypography.body.copyWith(color: colors.textPrimary),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eligible
              ? 'The owner has been inactive $inactiveDays days.'
              : 'The owner has been inactive $inactiveDays of '
                    '$ownerInactivityThresholdDays days needed to petition.',
          style: AppTypography.body.copyWith(color: colors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.sm),
        AppButton(
          key: const ValueKey('petitionInactiveOwnerButton'),
          variant: AppButtonVariant.secondary,
          label: 'Petition for ownership transfer',
          fullWidth: true,
          onPressed: eligible
              ? () => notifier.petitionInactiveOwner(now: now)
              : null,
        ),
      ],
    );
  }
}

class _OwnerPetitionResponseBanner extends ConsumerWidget {
  final InactivityPetition petition;
  final DateTime Function() now;

  const _OwnerPetitionResponseBanner({
    required this.petition,
    required this.now,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Container(
      key: const ValueKey('ownerPetitionResponseBanner'),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.warning.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your captain has petitioned for an ownership transfer due to '
            'inactivity. Respond by '
            '${petition.responseDeadline.day}/${petition.responseDeadline.month}/'
            '${petition.responseDeadline.year}.',
            style: AppTypography.body.copyWith(color: colors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            key: const ValueKey('ownerRespondToPetitionButton'),
            variant: AppButtonVariant.primary,
            label: "I'm still here",
            fullWidth: true,
            onPressed: () => ref
                .read(successionProvider.notifier)
                .ownerRespondToPetition(now: now),
          ),
        ],
      ),
    );
  }
}
