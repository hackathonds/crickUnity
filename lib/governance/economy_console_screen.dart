import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../analytics/entity_analytics_screen.dart';
import '../design_system/theme/app_theme.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import '../officials/conduct_report_models.dart';
import '../officials/conduct_report_provider.dart';
import 'economy_changelog_screen.dart';
import 'economy_console_models.dart';
import 'economy_console_provider.dart';

/// PRD §2.17 (Super Admin): "All Admin powers; configure coin economy
/// rates, XP curves, fee policies, feature flags per region; view
/// platform analytics; manage Admin accounts; final appeal authority."
/// Restrictions: "Dual-control for economy changes (second Super Admin
/// co-sign); public changelog for policy changes affecting users'
/// coins/fees." Theme-5 forced, matching E16-11's Admin console --
/// this is squarely admin-tooling too, same DS §7-69 utilitarian intent.
class EconomyConsoleScreen extends StatelessWidget {
  const EconomyConsoleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.themes[AppThemeId.theme5]!,
      child: const _EconomyConsoleBody(),
    );
  }
}

class _EconomyConsoleBody extends ConsumerStatefulWidget {
  const _EconomyConsoleBody();

  @override
  ConsumerState<_EconomyConsoleBody> createState() =>
      _EconomyConsoleBodyState();
}

class _EconomyConsoleBodyState extends ConsumerState<_EconomyConsoleBody> {
  String _actingAs = superAdminNames.first;
  final _newAdminController = TextEditingController();

  @override
  void dispose() {
    _newAdminController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final state = ref.watch(economyConsoleProvider);
    final notifier = ref.read(economyConsoleProvider.notifier);
    final appeals = ref
        .watch(conductReportProvider)
        .reports
        .where((r) => r.status == ConductReportStatus.appealed)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Super Admin console'),
        actions: [
          IconButton(
            key: const ValueKey('publicChangelogButton'),
            icon: const Icon(Icons.article_outlined),
            tooltip: 'Public changelog',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const EconomyChangelogScreen()),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _statusBanner(colors, state, notifier),
          const SizedBox(height: AppSpacing.lg),
          _actingAsPicker(colors),
          const SizedBox(height: AppSpacing.xl),
          _sectionTitle(colors, 'Economy rates'),
          for (final rule in state.earningRules)
            _earningRuleRow(colors, rule, notifier),
          const SizedBox(height: AppSpacing.xl),
          _sectionTitle(colors, 'Fee policies'),
          for (final fee in state.feePolicies) _feeRow(colors, fee, notifier),
          if (state.pendingRateChanges.isNotEmpty ||
              state.pendingFeeChanges.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xl),
            _sectionTitle(colors, 'Pending -- awaiting second co-sign'),
            for (final change in state.pendingRateChanges)
              _pendingRateRow(colors, change, notifier),
            for (final change in state.pendingFeeChanges)
              _pendingFeeRow(colors, change, notifier),
          ],
          const SizedBox(height: AppSpacing.xl),
          _sectionTitle(colors, 'Feature flags per region'),
          for (final flag in state.featureFlags)
            _featureFlagRow(colors, flag, notifier),
          const SizedBox(height: AppSpacing.xl),
          _sectionTitle(colors, 'Admin accounts'),
          for (final admin in state.adminAccounts)
            _adminRow(colors, admin, notifier),
          Row(
            children: [
              Expanded(
                child: TextField(
                  key: const ValueKey('newAdminNameField'),
                  controller: _newAdminController,
                  decoration: const InputDecoration(labelText: 'Add admin'),
                ),
              ),
              IconButton(
                key: const ValueKey('addAdminButton'),
                icon: const Icon(Icons.person_add_outlined),
                onPressed: () {
                  final name = _newAdminController.text.trim();
                  if (name.isEmpty) return;
                  notifier.addAdmin(name);
                  _newAdminController.clear();
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          _sectionTitle(colors, 'Final appeal authority'),
          if (appeals.isEmpty)
            Text(
              'No appeals pending.',
              style: AppTypography.body.copyWith(color: colors.textSecondary),
            )
          else
            for (final report in appeals) _appealRow(colors, report),
          const SizedBox(height: AppSpacing.xl),
          _sectionTitle(colors, 'Platform analytics'),
          OutlinedButton(
            key: const ValueKey('viewPlatformAnalyticsButton'),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const EntityAnalyticsScreen()),
            ),
            child: const Text('Open platform analytics'),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(AppColors colors, String title) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
    child: Text(
      title,
      style: AppTypography.label.copyWith(color: colors.textTertiary),
    ),
  );

  Widget _statusBanner(
    AppColors colors,
    EconomyConsoleState state,
    EconomyConsoleNotifier notifier,
  ) {
    final bannerColor = switch (state.statusLevel) {
      PlatformStatusLevel.operational => colors.success,
      PlatformStatusLevel.degraded => colors.coin,
      PlatformStatusLevel.maintenance => colors.textTertiary,
    };
    return Container(
      key: const ValueKey('platformStatusBanner'),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: bannerColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: bannerColor.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.circle, size: 10, color: bannerColor),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              state.statusMessage.isEmpty
                  ? platformStatusLabels[state.statusLevel]!
                  : state.statusMessage,
              style: AppTypography.body.copyWith(color: colors.textPrimary),
            ),
          ),
          IconButton(
            key: const ValueKey('editStatusBannerButton'),
            icon: const Icon(Icons.edit_outlined, size: 18),
            onPressed: () => _showStatusEditor(state, notifier),
          ),
        ],
      ),
    );
  }

  void _showStatusEditor(
    EconomyConsoleState state,
    EconomyConsoleNotifier notifier,
  ) {
    var level = state.statusLevel;
    final controller = TextEditingController(text: state.statusMessage);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            top: AppSpacing.lg,
            bottom:
                MediaQuery.of(sheetContext).viewInsets.bottom + AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: AppSpacing.sm,
                children: [
                  for (final l in PlatformStatusLevel.values)
                    ChoiceChip(
                      key: ValueKey('statusLevelChip_${l.name}'),
                      label: Text(platformStatusLabels[l]!),
                      selected: level == l,
                      onSelected: (_) => setSheetState(() => level = l),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                key: const ValueKey('statusMessageField'),
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Message (optional)',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                key: const ValueKey('saveStatusBannerButton'),
                onPressed: () {
                  notifier.setStatusBanner(level, controller.text.trim());
                  Navigator.of(sheetContext).pop();
                },
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actingAsPicker(AppColors colors) {
    return Row(
      children: [
        Text(
          'Acting as: ',
          style: AppTypography.caption.copyWith(color: colors.textTertiary),
        ),
        Wrap(
          spacing: AppSpacing.sm,
          children: [
            for (final name in superAdminNames)
              ChoiceChip(
                key: ValueKey('actingAsChip_$name'),
                label: Text(name),
                selected: _actingAs == name,
                onSelected: (_) => setState(() => _actingAs = name),
              ),
          ],
        ),
      ],
    );
  }

  Widget _earningRuleRow(
    AppColors colors,
    EarningRule rule,
    EconomyConsoleNotifier notifier,
  ) {
    return ListTile(
      key: ValueKey('earningRuleRow_${rule.action}'),
      contentPadding: EdgeInsets.zero,
      title: Text(rule.action, style: AppTypography.body),
      subtitle: Text(
        '${rule.coins} coins / ${rule.xp} XP'
        '${rule.note.isNotEmpty ? ' -- ${rule.note}' : ''}',
        style: AppTypography.caption.copyWith(
          color: colors.textTertiary,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
      trailing: IconButton(
        key: ValueKey('proposeRateChangeButton_${rule.action}'),
        icon: const Icon(Icons.edit_outlined, size: 18),
        onPressed: () => _showRatePropose(rule, notifier),
      ),
    );
  }

  void _showRatePropose(EarningRule rule, EconomyConsoleNotifier notifier) {
    final coinsController = TextEditingController(text: '${rule.coins}');
    final xpController = TextEditingController(text: '${rule.xp}');
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          top: AppSpacing.lg,
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom + AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Propose new rate -- ${rule.action}', style: AppTypography.h2),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              key: const ValueKey('proposeCoinsField'),
              controller: coinsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Coins'),
            ),
            TextField(
              key: const ValueKey('proposeXpField'),
              controller: xpController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'XP'),
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton(
              key: const ValueKey('submitRateProposalButton'),
              onPressed: () {
                notifier.proposeRateChange(
                  ruleAction: rule.action,
                  proposedCoins:
                      int.tryParse(coinsController.text) ?? rule.coins,
                  proposedXp: int.tryParse(xpController.text) ?? rule.xp,
                  proposedBy: _actingAs,
                );
                Navigator.of(sheetContext).pop();
              },
              child: const Text('Propose (awaits co-sign)'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _feeRow(
    AppColors colors,
    FeePolicy fee,
    EconomyConsoleNotifier notifier,
  ) {
    return ListTile(
      key: ValueKey('feeRow_${fee.name}'),
      contentPadding: EdgeInsets.zero,
      title: Text(fee.name, style: AppTypography.body),
      subtitle: Text(
        '${fee.percent}%',
        style: AppTypography.caption.copyWith(
          color: colors.textTertiary,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
      trailing: IconButton(
        key: ValueKey('proposeFeeChangeButton_${fee.name}'),
        icon: const Icon(Icons.edit_outlined, size: 18),
        onPressed: () => _showFeePropose(fee, notifier),
      ),
    );
  }

  void _showFeePropose(FeePolicy fee, EconomyConsoleNotifier notifier) {
    final percentController = TextEditingController(text: '${fee.percent}');
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          top: AppSpacing.lg,
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom + AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Propose new fee -- ${fee.name}', style: AppTypography.h2),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              key: const ValueKey('proposeFeePercentField'),
              controller: percentController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: 'Percent'),
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton(
              key: const ValueKey('submitFeeProposalButton'),
              onPressed: () {
                notifier.proposeFeeChange(
                  feeName: fee.name,
                  proposedPercent:
                      double.tryParse(percentController.text) ?? fee.percent,
                  proposedBy: _actingAs,
                );
                Navigator.of(sheetContext).pop();
              },
              child: const Text('Propose (awaits co-sign)'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pendingRateRow(
    AppColors colors,
    PendingRateChange change,
    EconomyConsoleNotifier notifier,
  ) {
    return Container(
      key: ValueKey('pendingRateRow_${change.id}'),
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: colors.surfaceAlt,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${change.ruleAction}: ${change.currentCoins}->${change.proposedCoins} coins, '
              '${change.currentXp}->${change.proposedXp} XP\n'
              'Proposed by ${change.proposedBy}',
              style: AppTypography.caption.copyWith(color: colors.textPrimary),
            ),
          ),
          TextButton(
            key: ValueKey('coSignRateButton_${change.id}'),
            onPressed: () {
              final ok = notifier.coSignRateChange(
                change.id,
                coSignerName: _actingAs,
              );
              if (!ok) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'A different Super Admin must co-sign this change.',
                    ),
                  ),
                );
              }
            },
            child: const Text('Co-sign & apply'),
          ),
        ],
      ),
    );
  }

  Widget _pendingFeeRow(
    AppColors colors,
    PendingFeeChange change,
    EconomyConsoleNotifier notifier,
  ) {
    return Container(
      key: ValueKey('pendingFeeRow_${change.id}'),
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: colors.surfaceAlt,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${change.feeName}: ${change.currentPercent}%->${change.proposedPercent}%\n'
              'Proposed by ${change.proposedBy}',
              style: AppTypography.caption.copyWith(color: colors.textPrimary),
            ),
          ),
          TextButton(
            key: ValueKey('coSignFeeButton_${change.id}'),
            onPressed: () {
              final ok = notifier.coSignFeeChange(
                change.id,
                coSignerName: _actingAs,
              );
              if (!ok) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'A different Super Admin must co-sign this change.',
                    ),
                  ),
                );
              }
            },
            child: const Text('Co-sign & apply'),
          ),
        ],
      ),
    );
  }

  Widget _featureFlagRow(
    AppColors colors,
    FeatureFlag flag,
    EconomyConsoleNotifier notifier,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(flag.label, style: AppTypography.body),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              for (final region in platformRegions)
                FilterChip(
                  key: ValueKey('featureFlagChip_${flag.key}_$region'),
                  label: Text(region),
                  selected: flag.enabledRegions.contains(region),
                  onSelected: (_) =>
                      notifier.toggleFeatureFlagRegion(flag.key, region),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _adminRow(
    AppColors colors,
    String admin,
    EconomyConsoleNotifier notifier,
  ) {
    return ListTile(
      key: ValueKey('adminRow_$admin'),
      contentPadding: EdgeInsets.zero,
      title: Text(admin, style: AppTypography.body),
      trailing: IconButton(
        key: ValueKey('removeAdminButton_$admin'),
        icon: const Icon(Icons.close, size: 18),
        onPressed: () => notifier.removeAdmin(admin),
      ),
    );
  }

  Widget _appealRow(AppColors colors, ConductReport report) {
    return Container(
      key: ValueKey('appealRow_${report.id}'),
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: colors.surfaceAlt,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${report.reportedPlayerName} -- ${conductIncidentTypeLabels[report.incidentType]}',
            style: AppTypography.body.copyWith(color: colors.textPrimary),
          ),
          if (report.appealText != null)
            Text(
              report.appealText!,
              style: AppTypography.caption.copyWith(
                color: colors.textSecondary,
              ),
            ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              OutlinedButton(
                key: ValueKey('upholdAppealButton_${report.id}'),
                onPressed: () => ref
                    .read(conductReportProvider.notifier)
                    .resolveAppeal(report.id, upheld: true),
                child: const Text('Uphold appeal'),
              ),
              const SizedBox(width: AppSpacing.sm),
              OutlinedButton(
                key: ValueKey('rejectAppealButton_${report.id}'),
                onPressed: () => ref
                    .read(conductReportProvider.notifier)
                    .resolveAppeal(report.id, upheld: false),
                child: const Text('Reject appeal'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
