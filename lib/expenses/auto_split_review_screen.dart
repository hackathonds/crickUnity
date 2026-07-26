import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_bottom_sheet.dart';
import '../design_system/components/app_button.dart';
import '../design_system/components/app_segmented_control.dart';
import '../design_system/components/app_text_field.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import '../matches/match_models.dart';
import '../matches/matches_provider.dart';
import '../teams/availability_matrix_models.dart';
import 'auto_split_bundle_models.dart';
import 'auto_split_bundle_provider.dart';
import 'expense_models.dart';

/// PRD §11.4 (Auto Split, "the flagship") + one-sheet captain review:
/// "Captain reviews one summary sheet ('₹3,400 across 12 players =
/// ₹283.33 each; remainder ₹0.04 → payer') and taps Finalize →
/// everyone notified with their exact share + context." AC amendment
/// (backlog): the split-method chooser here must offer the full method
/// list (attendance-based/role-based included), not just equal/custom
/// -- reuses the same [SplitMethod] enum/segmented control as E5-01/
/// E5-02's Add/Edit Expense screen.
class AutoSplitReviewScreen extends ConsumerWidget {
  final String matchId;
  final String viewerName;
  final bool viewerIsCaptain;

  const AutoSplitReviewScreen({
    super.key,
    required this.matchId,
    required this.viewerName,
    required this.viewerIsCaptain,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final match = ref
        .watch(matchesProvider)
        .matches
        .firstWhere((m) => m.id == matchId);
    final bundle = ref.watch(autoSplitBundleProvider).bundlesByMatchId[matchId];
    final notifier = ref.read(autoSplitBundleProvider.notifier);

    if (bundle == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Auto-split bundle')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: AppButton(
              key: const ValueKey('draftBundleButton'),
              variant: AppButtonVariant.primary,
              label: 'Draft expense bundle',
              onPressed: () => notifier.draftBundleForMatch(
                matchId,
                groundFee: 800,
                ballFee: 300,
                officialsFee:
                    match.draft.scorerAssignment != ScorerAssignment.self ||
                        match.draft.umpireNames.isNotEmpty
                    ? 500
                    : 0,
              ),
            ),
          ),
        ),
      );
    }

    // "unavailable players auto-excluded" -- genuinely reads the
    // match's own availability responses (E4-10-era data), not a mock.
    final excludedUnavailable = [
      for (final name in match.squadNames)
        if (match.availabilityResponses[name] == AvailabilityResponse.no) name,
    ];
    final finalSquad = [
      for (final name in match.squadNames)
        if (match.availabilityResponses[name] != AvailabilityResponse.no) name,
    ];
    final allParticipants = {
      ...finalSquad,
      ...bundle.replacementNames,
    }.toList();

    var previewShares = switch (bundle.splitMethod) {
      SplitMethod.shares => weightedSplit(bundle.totalRupees, {
        for (final p in allParticipants) p: 1,
      }),
      _ => equalSplit(bundle.totalRupees, allParticipants),
    };
    if (bundle.mvpExemptEnabled &&
        bundle.mvpName != null &&
        allParticipants.contains(bundle.mvpName)) {
      final mvp = bundle.mvpName!;
      final rest = [
        for (final p in allParticipants)
          if (p != mvp) p,
      ];
      previewShares = [
        ...equalSplit(bundle.totalRupees, rest),
        SplitShare(name: mvp, amount: 0),
      ];
    }
    final remainder =
        bundle.totalRupees - previewShares.fold(0, (s, e) => s + e.amount);

    return Scaffold(
      appBar: AppBar(title: const Text('Auto-split bundle')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(
            'Preset breakdown',
            style: AppTypography.label.copyWith(color: colors.textTertiary),
          ),
          const SizedBox(height: AppSpacing.xs),
          _lineRow(colors, 'Ground fee', bundle.groundFee),
          _lineRow(colors, 'Ball', bundle.ballFee),
          _lineRow(colors, 'Officials', bundle.officialsFee),
          const Divider(),
          _lineRow(colors, 'Total', bundle.totalRupees, bold: true),
          const SizedBox(height: AppSpacing.xxl),
          if (bundle.status == AutoSplitBundleStatus.voided)
            Container(
              key: const ValueKey('voidedBanner'),
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: colors.error.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                'Voided (match ruled fake): ${bundle.voidReason}',
                style: AppTypography.body.copyWith(color: colors.error),
              ),
            )
          else if (bundle.status == AutoSplitBundleStatus.finalized)
            Container(
              key: const ValueKey('finalizedBanner'),
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: colors.verified.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                'Finalized -- everyone notified with their exact share.',
                style: AppTypography.body.copyWith(color: colors.verified),
              ),
            )
          else ...[
            Text(
              'Squad',
              style: AppTypography.label.copyWith(color: colors.textTertiary),
            ),
            const SizedBox(height: AppSpacing.xs),
            for (final name in match.squadNames)
              Padding(
                key: ValueKey('squadRow_$name'),
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.xs / 2,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: AppTypography.body.copyWith(
                          color: colors.textPrimary,
                          decoration: excludedUnavailable.contains(name)
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                    ),
                    if (excludedUnavailable.contains(name))
                      Text(
                        'Excluded (unavailable)',
                        style: AppTypography.caption.copyWith(
                          color: colors.textTertiary,
                        ),
                      ),
                  ],
                ),
              ),
            for (final name in bundle.replacementNames)
              Padding(
                key: ValueKey('replacementRow_$name'),
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.xs / 2,
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
                    Text(
                      'Replacement',
                      style: AppTypography.caption.copyWith(
                        color: colors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            AppButton(
              key: const ValueKey('addReplacementButton'),
              variant: AppButtonVariant.tertiary,
              label: 'Add replacement',
              onPressed: () => _showAddReplacementSheet(context, ref),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Switch(
                  key: const ValueKey('mvpExemptSwitch'),
                  value: bundle.mvpExemptEnabled,
                  onChanged: (v) => notifier.setMvpExempt(
                    matchId,
                    enabled: v,
                    mvpName: bundle.mvpName,
                  ),
                ),
                Expanded(
                  child: Text(
                    'MVP-exempt rule',
                    style: AppTypography.body.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            if (bundle.mvpExemptEnabled)
              Wrap(
                spacing: AppSpacing.xs,
                children: [
                  for (final name in allParticipants)
                    ChoiceChip(
                      key: ValueKey('mvpChip_$name'),
                      label: Text(name),
                      selected: bundle.mvpName == name,
                      onSelected: (_) => notifier.setMvpExempt(
                        matchId,
                        enabled: true,
                        mvpName: name,
                      ),
                    ),
                ],
              ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Split method',
              style: AppTypography.label.copyWith(color: colors.textTertiary),
            ),
            const SizedBox(height: AppSpacing.xs),
            AppSegmentedControl<SplitMethod>(
              key: const ValueKey('bundleSplitMethodControl'),
              options: SplitMethod.values,
              value: bundle.splitMethod,
              onChanged: (v) => notifier.setSplitMethod(matchId, v),
              labelBuilder: (v) => splitMethodLabels[v]!,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Shares (₹${bundle.totalRupees} across ${allParticipants.length} '
              'players)',
              style: AppTypography.label.copyWith(color: colors.textTertiary),
            ),
            const SizedBox(height: AppSpacing.xs),
            for (final share in previewShares)
              Padding(
                key: ValueKey('previewShareRow_${share.name}'),
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.xs / 2,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        share.name,
                        style: AppTypography.body.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      '₹${share.amount}',
                      style: AppTypography.stat.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            if (remainder != 0)
              Text(
                'Remainder ₹$remainder -> payer',
                style: AppTypography.caption.copyWith(
                  color: colors.textTertiary,
                ),
              ),
            const SizedBox(height: AppSpacing.lg),
            if (viewerIsCaptain)
              AppButton(
                key: const ValueKey('finalizeBundleButton'),
                variant: AppButtonVariant.primary,
                label: 'Finalize',
                fullWidth: true,
                onPressed: allParticipants.isEmpty
                    ? null
                    : () => notifier.finalizeBundle(
                        matchId,
                        finalSquad: finalSquad,
                        createdByName: viewerName,
                        createdByIsCaptain: viewerIsCaptain,
                      ),
              ),
          ],
          if (bundle.notificationLog.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xxl),
            Text(
              'Notifications',
              style: AppTypography.label.copyWith(color: colors.textTertiary),
            ),
            const SizedBox(height: AppSpacing.xs),
            for (final entry in bundle.notificationLog)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Text(
                  entry,
                  style: AppTypography.caption.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ),
          ],
          if (viewerIsCaptain &&
              bundle.status == AutoSplitBundleStatus.finalized) ...[
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              key: const ValueKey('voidBundleButton'),
              variant: AppButtonVariant.destructive,
              label: 'Void (match ruled fake)',
              fullWidth: true,
              onPressed: () => _showVoidSheet(context, ref),
            ),
          ],
        ],
      ),
    );
  }

  Widget _lineRow(
    AppColors colors,
    String label,
    int amount, {
    bool bold = false,
  }) {
    final style = bold
        ? AppTypography.subtitle.copyWith(color: colors.textPrimary)
        : AppTypography.body.copyWith(color: colors.textPrimary);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs / 2),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text('₹$amount', style: style),
        ],
      ),
    );
  }

  void _showAddReplacementSheet(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(autoSplitBundleProvider.notifier);
    showAppBottomSheet<void>(
      context: context,
      title: 'Add replacement',
      contentBuilder: (context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final name in mockExpenseParticipants())
              GestureDetector(
                key: ValueKey('replacementOption_$name'),
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  notifier.addReplacement(matchId, name);
                  Navigator.of(context).pop();
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Text(name, style: AppTypography.body),
                ),
              ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  void _showVoidSheet(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    final notifier = ref.read(autoSplitBundleProvider.notifier);
    showAppBottomSheet<void>(
      context: context,
      title: 'Void bundle',
      contentBuilder: (context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppTextField(
              key: const ValueKey('voidReasonField'),
              label: 'Reason',
              controller: controller,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              key: const ValueKey('confirmVoidButton'),
              variant: AppButtonVariant.destructive,
              label: 'Void',
              fullWidth: true,
              onPressed: () {
                notifier.voidBundle(matchId, controller.text.trim());
                Navigator.of(context).pop();
              },
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}
