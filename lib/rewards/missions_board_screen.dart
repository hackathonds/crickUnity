import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_button.dart';
import '../design_system/components/app_tag_chip.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'missions_models.dart';
import 'missions_provider.dart';
import 'season_planner_screen.dart';

/// DS §7-54 (Missions Board): "Daily 3 cards (claim states), weekly/
/// monthly tabs, Season Planner link; refresh-token chip."
class MissionsBoardScreen extends ConsumerStatefulWidget {
  const MissionsBoardScreen({super.key});

  @override
  ConsumerState<MissionsBoardScreen> createState() =>
      _MissionsBoardScreenState();
}

class _MissionsBoardScreenState extends ConsumerState<MissionsBoardScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(
    length: MissionTier.values.length,
    vsync: this,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(missionsProvider.notifier).ensureCurrentPeriod();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(missionsProvider); // rebuild on state changes

    return Scaffold(
      appBar: AppBar(
        title: const Text('Missions'),
        actions: [
          IconButton(
            key: const ValueKey('seasonPlannerLinkButton'),
            icon: const Icon(Icons.calendar_month_outlined),
            tooltip: 'Season Planner',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SeasonPlannerScreen()),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            for (final tier in MissionTier.values)
              Tab(text: missionTierLabels[tier]),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          for (final tier in MissionTier.values) _MissionTierTab(tier: tier),
        ],
      ),
    );
  }
}

class _MissionTierTab extends ConsumerWidget {
  final MissionTier tier;

  const _MissionTierTab({required this.tier});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final state = ref.watch(missionsProvider);
    final notifier = ref.read(missionsProvider.notifier);
    final instances = state.instancesFor(tier);
    final tokens = state.refreshTokens[tier] ?? 0;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '${missionTierLabels[tier]} missions',
                style: AppTypography.label.copyWith(color: colors.textTertiary),
              ),
            ),
            AppTagChip(
              key: ValueKey('refreshTokenChip_${tier.name}'),
              label: '$tokens refresh',
              variant: tokens > 0
                  ? AppTagChipVariant.success
                  : AppTagChipVariant.neutral,
            ),
            const SizedBox(width: AppSpacing.xs),
            AppButton(
              key: ValueKey('useRefreshTokenButton_${tier.name}'),
              variant: AppButtonVariant.tertiary,
              label: 'Refresh',
              onPressed: tokens > 0
                  ? () => notifier.useRefreshToken(tier)
                  : null,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final instance in instances)
          Container(
            key: ValueKey('missionCard_${instance.defId}'),
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: colors.surfaceAlt,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  instance.def.title,
                  style: AppTypography.body.copyWith(color: colors.textPrimary),
                ),
                const SizedBox(height: AppSpacing.xs),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (instance.progress / instance.def.target).clamp(
                      0.0,
                      1.0,
                    ),
                    minHeight: 6,
                    backgroundColor: colors.border,
                    color: colors.coin,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${instance.progress}/${instance.def.target} -- '
                        '+${instance.def.coins} coins, +${instance.def.xp} XP',
                        style: AppTypography.caption.copyWith(
                          color: colors.textTertiary,
                        ),
                      ),
                    ),
                    AppButton(
                      key: ValueKey('claimMissionButton_${instance.defId}'),
                      variant:
                          instance.claimState == MissionClaimState.claimable
                          ? AppButtonVariant.primary
                          : AppButtonVariant.tertiary,
                      label: switch (instance.claimState) {
                        MissionClaimState.claimed => 'Claimed',
                        MissionClaimState.claimable => 'Claim',
                        MissionClaimState.inProgress => 'In progress',
                      },
                      onPressed:
                          instance.claimState == MissionClaimState.claimable
                          ? () => notifier.claimMission(tier, instance.defId)
                          : null,
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
}
