import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_avatar.dart';
import '../design_system/components/app_bottom_sheet.dart';
import '../design_system/components/app_button.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_money_text.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import '../teams/availability_matrix_models.dart';
import 'match_models.dart';
import 'matches_provider.dart';

/// DS §7 screen 25 (Match Detail, pre-live): "Header mini-scoreboard
/// placeholder (crests/date) -> info rows (ground w/ map snippet,
/// officials, ball) -> availability panel (mine prominent; squad grid
/// for captain) -> expense preview card -> {Directions}+{RSVP} sticky
/// pair. Cancelled: struck header + reason banner + re-RSVP if
/// rescheduled." No maps package or Team Treasury module exists yet --
/// the map snippet and expense preview are honest-gap placeholders, not
/// real integrations.
class MatchDetailScreen extends ConsumerWidget {
  final String matchId;
  final String viewerName;
  final bool isCaptain;

  const MatchDetailScreen({
    super.key,
    required this.matchId,
    required this.viewerName,
    this.isCaptain = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final match = ref
        .watch(matchesProvider)
        .matches
        .firstWhere((m) => m.id == matchId);
    final draft = match.draft;
    final cancelled = match.status == MatchStatus.cancelled;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Match detail'),
        actions: [
          IconButton(
            key: const ValueKey('shareMatchButton'),
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Share',
            onPressed: () => _showShareSheet(context, draft.visibility),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                Text(
                  key: const ValueKey('matchDetailHeader'),
                  '${match.composerTeamName} vs ${draft.opponentTeamName}',
                  style: AppTypography.h2.copyWith(
                    color: colors.textPrimary,
                    decoration: cancelled
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                  ),
                ),
                Text(
                  _formatDateTime(draft.dateTime),
                  style: AppTypography.body.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                if (cancelled) ...[
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    key: const ValueKey('cancelledReasonBanner'),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: colors.error.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      'Cancelled: ${match.cancelledReason}',
                      style: AppTypography.body.copyWith(color: colors.error),
                    ),
                  ),
                ] else ...[
                  if (match.rescheduleReason != null)
                    Container(
                      key: const ValueKey('rescheduledBanner'),
                      margin: const EdgeInsets.only(top: AppSpacing.md),
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: colors.warning.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        'Rescheduled: ${match.rescheduleReason}. Please '
                        're-confirm your availability for the new time.',
                        style: AppTypography.body.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                  const SizedBox(height: AppSpacing.xxl),
                  Row(
                    key: const ValueKey('privacyRow'),
                    children: [
                      Icon(
                        draft.visibility == MatchVisibility.private
                            ? Icons.lock_outline
                            : Icons.public,
                        size: 16,
                        color: colors.textTertiary,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        matchVisibilityLabels[draft.visibility]!,
                        style: AppTypography.caption.copyWith(
                          color: colors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                  if (draft.visibility == MatchVisibility.private) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Private match -- link-holders must be approved '
                      'before they can view it.',
                      style: AppTypography.caption.copyWith(
                        color: colors.textTertiary,
                      ),
                    ),
                    if (isCaptain &&
                        match.pendingViewerRequests.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Access requests',
                        style: AppTypography.label.copyWith(
                          color: colors.textTertiary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      for (final name in match.pendingViewerRequests)
                        Padding(
                          key: ValueKey('viewerRequestRow_$name'),
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.xs,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  name,
                                  style: AppTypography.body.copyWith(
                                    color: colors.textPrimary,
                                  ),
                                ),
                              ),
                              AppButton(
                                key: ValueKey('approveViewer_$name'),
                                variant: AppButtonVariant.secondary,
                                label: 'Approve',
                                onPressed: () => ref
                                    .read(matchesProvider.notifier)
                                    .approveViewerAccess(matchId, name),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              AppButton(
                                key: ValueKey('denyViewer_$name'),
                                variant: AppButtonVariant.destructive,
                                label: 'Deny',
                                onPressed: () => ref
                                    .read(matchesProvider.notifier)
                                    .denyViewerAccess(matchId, name),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ],
                  const SizedBox(height: AppSpacing.xxl),
                  Text(
                    'Ground',
                    style: AppTypography.label.copyWith(
                      color: colors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    draft.groundName,
                    style: AppTypography.body.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    key: const ValueKey('mapSnippetPlaceholder'),
                    height: 96,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border.all(color: colors.border),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.map_outlined, color: colors.textTertiary),
                        Text(
                          'No maps package in this codebase yet',
                          style: AppTypography.caption.copyWith(
                            color: colors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _InfoRow(
                    label: 'Officials',
                    value: scorerAssignmentLabels[draft.scorerAssignment]!,
                  ),
                  _InfoRow(
                    label: 'Ball',
                    value: ballTypeLabels[draft.ballType]!,
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  Text(
                    'Your availability',
                    style: AppTypography.label.copyWith(
                      color: colors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    key: const ValueKey('myAvailabilityStatus'),
                    match.availabilityResponses[viewerName] != null
                        ? '${availabilityResponseGlyphs[match.availabilityResponses[viewerName]]} '
                              '${match.availabilityResponses[viewerName]!.name}'
                        : 'No response yet',
                    style: AppTypography.subtitle.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                  if (isCaptain) ...[
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Squad',
                      style: AppTypography.label.copyWith(
                        color: colors.textTertiary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    for (final name in match.squadNames)
                      Padding(
                        key: ValueKey('squadRow_$name'),
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.xs,
                        ),
                        child: Row(
                          children: [
                            AppAvatar(size: AppAvatarSize.xs, name: name),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                name,
                                style: AppTypography.body.copyWith(
                                  color: colors.textPrimary,
                                ),
                              ),
                            ),
                            Text(
                              match.availabilityResponses[name] != null
                                  ? availabilityResponseGlyphs[match
                                        .availabilityResponses[name]]!
                                  : '—',
                              style: AppTypography.body.copyWith(
                                color: colors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                  const SizedBox(height: AppSpacing.xxl),
                  Text(
                    'Expenses',
                    style: AppTypography.label.copyWith(
                      color: colors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  _ExpensePreviewCard(
                    expensePresetEnabled: draft.expensePresetEnabled,
                  ),
                ],
              ],
            ),
          ),
          if (!cancelled)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  Expanded(
                    child: AppButton(
                      key: const ValueKey('directionsButton'),
                      variant: AppButtonVariant.secondary,
                      label: 'Directions',
                      onPressed: () =>
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'No maps package in this codebase yet',
                              ),
                            ),
                          ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: AppButton(
                      key: const ValueKey('rsvpButton'),
                      variant: AppButtonVariant.primary,
                      label: 'RSVP',
                      onPressed: () => _showRsvpSheet(context, ref),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _showRsvpSheet(BuildContext context, WidgetRef ref) {
    showAppBottomSheet<void>(
      context: context,
      title: 'Your availability',
      contentBuilder: (context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                for (final response in AvailabilityResponse.values)
                  ChoiceChip(
                    key: ValueKey('rsvpChip_${response.name}'),
                    label: Text(
                      '${availabilityResponseGlyphs[response]} ${response.name}',
                    ),
                    selected: false,
                    onSelected: (_) {
                      ref
                          .read(matchesProvider.notifier)
                          .respondAvailability(matchId, viewerName, response);
                      Navigator.of(context).pop();
                    },
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  /// PRD §7.24: "Share sheet: live link, scorecard image, performance
  /// cards per player." No real link/image-generation backend exists
  /// yet -- link copy is a real Clipboard write (same convention as
  /// [PostMatchSummaryScreen]'s Share button); scorecard image and
  /// performance cards are flagged mock rows since no rendering
  /// pipeline exists for either.
  void _showShareSheet(BuildContext context, MatchVisibility visibility) {
    showAppBottomSheet<void>(
      context: context,
      title: 'Share match',
      contentBuilder: (context) =>
          _ShareSheetContent(matchId: matchId, visibility: visibility),
    );
  }

  String _formatDateTime(DateTime dt) =>
      '${dt.day}/${dt.month}/${dt.year} '
      '${dt.hour.toString().padLeft(2, '0')}:'
      '${dt.minute.toString().padLeft(2, '0')}';
}

class _ShareSheetContent extends StatelessWidget {
  final String matchId;
  final MatchVisibility visibility;

  const _ShareSheetContent({required this.matchId, required this.visibility});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (visibility == MatchVisibility.private)
            Text(
              'Private -- anyone opening this link will need your '
              'approval before they can view the match.',
              style: AppTypography.caption.copyWith(color: colors.textTertiary),
            ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            key: const ValueKey('copyMatchLinkButton'),
            variant: AppButtonVariant.primary,
            label: 'Copy live link',
            fullWidth: true,
            onPressed: () {
              Clipboard.setData(
                ClipboardData(text: 'https://cricunity.app/match/$matchId'),
              );
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Link copied')));
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            key: const ValueKey('shareScorecardImageButton'),
            variant: AppButtonVariant.secondary,
            label: 'Share scorecard image',
            fullWidth: true,
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'No image-rendering pipeline in this codebase yet',
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            key: const ValueKey('sharePerformanceCardsButton'),
            variant: AppButtonVariant.secondary,
            label: 'Share performance cards',
            fullWidth: true,
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'No image-rendering pipeline in this codebase yet',
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTypography.body.copyWith(color: colors.textSecondary),
            ),
          ),
          Text(
            value,
            style: AppTypography.body.copyWith(color: colors.textPrimary),
          ),
        ],
      ),
    );
  }
}

/// No Team Treasury/expense module exists yet (PRD §6.14-6.16) -- this
/// is a self-contained mock preview, not a real ledger integration.
class _ExpensePreviewCard extends StatelessWidget {
  final bool expensePresetEnabled;

  const _ExpensePreviewCard({required this.expensePresetEnabled});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    if (!expensePresetEnabled) {
      return Text(
        'No auto-created expenses for this match.',
        style: AppTypography.body.copyWith(color: colors.textSecondary),
      );
    }

    return Container(
      key: const ValueKey('expensePreviewCard'),
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
                  'Ground fee',
                  style: AppTypography.body.copyWith(color: colors.textPrimary),
                ),
              ),
              AppMoneyText(
                symbol: '₹',
                amount: '1,500',
                numeralStyle: AppTypography.moneyMin,
                color: colors.textPrimary,
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Balls',
                  style: AppTypography.body.copyWith(color: colors.textPrimary),
                ),
              ),
              AppMoneyText(
                symbol: '₹',
                amount: '400',
                numeralStyle: AppTypography.moneyMin,
                color: colors.textPrimary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
