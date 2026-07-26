import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_band_chip.dart';
import '../design_system/components/app_bottom_sheet.dart';
import '../design_system/components/app_button.dart';
import '../design_system/components/app_state_scaffolds.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import '../profile/trust_sportsmanship_models.dart';
import 'join_request_models.dart';
import 'join_requests_provider.dart';

/// PRD §6.4 (Captain/VC view): "requester's card shows stats, Trust
/// band, mutuals; Approve/Deny; deny optionally with canned reasons;
/// auto-expire 14d." Requests past the 14-day window are treated as
/// already expired (filtered out), same as a real backend would stop
/// surfacing them rather than showing a dead "Expired" row.
class JoinRequestsScreen extends ConsumerWidget {
  final DateTime Function() now;

  const JoinRequestsScreen({super.key, this.now = DateTime.now});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(joinRequestsProvider);
    final notifier = ref.read(joinRequestsProvider.notifier);
    final visible = state.pending.where((r) => !r.isExpired(now: now)).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Join requests')),
      body: visible.isEmpty
          ? AppEmptyState(
              message: 'No pending join requests right now.',
              primaryLabel: 'Back',
              onPrimary: () => Navigator.of(context).pop(),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: visible.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.lg),
              itemBuilder: (context, index) => _JoinRequestCard(
                request: visible[index],
                onApprove: () => notifier.approve(visible[index].id),
                onDeny: (reason) =>
                    notifier.deny(visible[index].id, reason: reason),
              ),
            ),
    );
  }
}

class _JoinRequestCard extends StatelessWidget {
  final JoinRequest request;
  final VoidCallback onApprove;
  final ValueChanged<String?> onDeny;

  const _JoinRequestCard({
    required this.request,
    required this.onApprove,
    required this.onDeny,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Container(
      key: ValueKey('joinRequestCard_${request.id}'),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  request.requesterName,
                  style: AppTypography.subtitle.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
              ),
              AppBandChip(
                kind: BandKind.trust,
                label: trustBandLabels[request.trustBand]!,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${request.stats.matches} matches · ${request.stats.runs} runs · '
            '${request.stats.wickets} wickets',
            style: AppTypography.caption.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            request.mutualsCount > 0
                ? '${request.mutualsCount} mutual connections'
                : 'No mutual connections',
            style: AppTypography.caption.copyWith(color: colors.textTertiary),
          ),
          if (request.isRivalInSameTournament) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              key: ValueKey('rivalFlagNotice_${request.id}'),
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: colors.warning.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'This player is on a team competing against you in an '
                'active tournament -- the organizer has been notified.',
                style: AppTypography.caption.copyWith(color: colors.warning),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  key: ValueKey('joinRequestDeny_${request.id}'),
                  variant: AppButtonVariant.secondary,
                  label: 'Deny',
                  onPressed: () => _showDenySheet(context),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppButton(
                  key: ValueKey('joinRequestApprove_${request.id}'),
                  variant: AppButtonVariant.primary,
                  label: 'Approve',
                  onPressed: onApprove,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDenySheet(BuildContext context) {
    showAppBottomSheet<void>(
      context: context,
      title: 'Deny request',
      contentBuilder: (context) => _DenyReasonContent(onDeny: onDeny),
    );
  }
}

class _DenyReasonContent extends StatelessWidget {
  final ValueChanged<String?> onDeny;

  const _DenyReasonContent({required this.onDeny});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    // Plain tappable rows, not ListTile -- AppBottomSheet's own shell is
    // a decorated (colored) box, not a Material, so a ListTile's ink/
    // background effects would be swallowed with a dev-mode assertion.
    Widget row(Key key, String label, Color color, VoidCallback onTap) =>
        GestureDetector(
          key: key,
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Text(
              label,
              style: AppTypography.body.copyWith(color: color),
            ),
          ),
        );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final reason in cannedDenyReasons)
            row(ValueKey('denyReason_$reason'), reason, colors.textPrimary, () {
              Navigator.of(context).pop();
              onDeny(reason);
            }),
          row(
            const ValueKey('denyReasonSkip'),
            'Deny without a reason',
            colors.textSecondary,
            () {
              Navigator.of(context).pop();
              onDeny(null);
            },
          ),
        ],
      ),
    );
  }
}
