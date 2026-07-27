import 'package:flutter/material.dart';

import '../design_system/components/app_dropdown_field.dart';
import '../design_system/components/app_leaderboard_row.dart';
import '../design_system/components/app_segmented_control.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'leaderboard_models.dart';

/// DS §63 (Leaderboards Hub): "scope segmented + metric dropdown +
/// window chips; my-row sticky bottom clone; unranked -> qualification
/// progress card." The segmented/dropdown/chips here are this story's
/// data-layer wiring; the row rendering + sticky self-clone is the
/// pre-built AppLeaderboardRow/AppLeaderboardList (E0-08), reused
/// unchanged.
class LeaderboardHubScreen extends StatefulWidget {
  const LeaderboardHubScreen({super.key});

  @override
  State<LeaderboardHubScreen> createState() => _LeaderboardHubScreenState();
}

class _LeaderboardHubScreenState extends State<LeaderboardHubScreen> {
  // PRD: "Friends scope is default."
  LeaderboardScope _scope = LeaderboardScope.friends;
  LeaderboardMetric _metric = LeaderboardMetric.runs;
  LeaderboardWindow _window = LeaderboardWindow.month;
  AgeBand? _ageBand;
  ExperienceBand? _experienceBand;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final allEntries = mockLeaderboard(
      scope: _scope,
      metric: _metric,
      window: _window,
    );
    final filtered = allEntries.where((e) {
      if (_ageBand != null && e.ageBand != _ageBand) return false;
      if (_experienceBand != null && e.experienceBand != _experienceBand) {
        return false;
      }
      return true;
    }).toList();

    final viewerEntry = filtered.firstWhere(
      (e) => e.name == leaderboardViewerName,
      orElse: () => filtered.isEmpty
          ? const LeaderboardEntry(
              name: leaderboardViewerName,
              teamCaption: '',
              metricValue: 0,
              matchesPlayed: 0,
              ageBand: AgeBand.age25to34,
              experienceBand: ExperienceBand.developing,
            )
          : filtered.first,
    );
    final viewerQualifies = viewerEntry.qualifiesFor(_window);
    final ranked = viewerQualifies
        ? filtered
        : filtered.where((e) => e.name != leaderboardViewerName).toList();
    final myIndex = viewerQualifies
        ? ranked.indexWhere((e) => e.name == leaderboardViewerName)
        : null;

    final rows = [
      for (var i = 0; i < ranked.length; i++)
        AppLeaderboardRowData(
          rank: i + 1,
          name: ranked[i].name,
          teamCaption: ranked[i].teamCaption,
          metric: '${ranked[i].metricValue}',
          movement: ranked[i].movement == null
              ? null
              : ranked[i].movement == LeaderboardMovement.up
              ? AppLeaderboardMovement.up
              : AppLeaderboardMovement.down,
          movementValue: ranked[i].movementValue,
        ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Leaderboards')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppSegmentedControl<LeaderboardScope>(
                  key: const ValueKey('leaderboardScopeSelector'),
                  options: LeaderboardScope.values,
                  value: _scope,
                  onChanged: (v) => setState(() => _scope = v),
                  labelBuilder: (s) => leaderboardScopeLabels[s]!,
                ),
                const SizedBox(height: AppSpacing.sm),
                AppDropdownField<LeaderboardMetric>(
                  key: const ValueKey('leaderboardMetricDropdown'),
                  label: 'Metric',
                  value: _metric,
                  options: LeaderboardMetric.values,
                  labelBuilder: (m) => leaderboardMetricLabels[m]!,
                  onChanged: (v) => setState(() => _metric = v),
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  children: [
                    for (final w in LeaderboardWindow.values)
                      ChoiceChip(
                        key: ValueKey('leaderboardWindowChip_${w.name}'),
                        label: Text(leaderboardWindowLabels[w]!),
                        selected: _window == w,
                        onSelected: (_) => setState(() => _window = w),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  children: [
                    FilterChip(
                      label: const Text('All ages'),
                      selected: _ageBand == null,
                      onSelected: (_) => setState(() => _ageBand = null),
                    ),
                    for (final band in AgeBand.values)
                      FilterChip(
                        key: ValueKey('ageBandChip_${band.name}'),
                        label: Text(ageBandLabels[band]!),
                        selected: _ageBand == band,
                        onSelected: (_) => setState(() => _ageBand = band),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.sm,
                  children: [
                    FilterChip(
                      label: const Text('All experience'),
                      selected: _experienceBand == null,
                      onSelected: (_) => setState(() => _experienceBand = null),
                    ),
                    for (final band in ExperienceBand.values)
                      FilterChip(
                        key: ValueKey('experienceBandChip_${band.name}'),
                        label: Text(experienceBandLabels[band]!),
                        selected: _experienceBand == band,
                        onSelected: (_) =>
                            setState(() => _experienceBand = band),
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (!viewerQualifies)
            Container(
              key: const ValueKey('qualificationProgressCard'),
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: colors.surfaceAlt,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "You're unranked for this window",
                    style: AppTypography.body.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${viewerEntry.matchesPlayed} / '
                    '${qualificationMinMatches[_window]} matches played '
                    '-- keep playing to qualify.',
                    style: AppTypography.caption.copyWith(
                      color: colors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: AppLeaderboardList(
              key: const ValueKey('leaderboardList'),
              rows: rows,
              myIndex: myIndex == null || myIndex < 0 ? null : myIndex,
            ),
          ),
        ],
      ),
    );
  }
}
