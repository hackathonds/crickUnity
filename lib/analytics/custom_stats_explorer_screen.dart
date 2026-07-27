import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_stepper.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import '../onboarding/profile_wizard_provider.dart' show BattingStyle;
import 'custom_stats_explorer_data.dart';
import 'custom_stats_explorer_models.dart';
import 'custom_stats_explorer_provider.dart';
import 'player_analytics_models.dart'
    show BowlerType, MatchPhase, bowlerTypeLabels, matchPhaseLabels;
import 'player_analytics_provider.dart';

/// DS §7.10 screen 68: "Custom Stats Explorer: query-builder rows
/// (discipline -> filter chips -> qualification stepper) -> results
/// table (sortable, sticky header) -> [Save query][Pin as widget]." See
/// custom_stats_explorer_models.dart's top-of-file note for the
/// wrong-document "PRD §19.9" citation and the small-sample-caption
/// grounding.
class CustomStatsExplorerScreen extends ConsumerStatefulWidget {
  const CustomStatsExplorerScreen({super.key});

  @override
  ConsumerState<CustomStatsExplorerScreen> createState() =>
      _CustomStatsExplorerScreenState();
}

class _CustomStatsExplorerScreenState
    extends ConsumerState<CustomStatsExplorerScreen> {
  StatsDiscipline _discipline = StatsDiscipline.batting;
  StatsQueryFilters _filters = const StatsQueryFilters();
  int _sortColumnIndex = 1;
  bool _sortAscending = false;

  String get _primaryLabel => switch (_discipline) {
    StatsDiscipline.batting => 'Runs',
    StatsDiscipline.bowling => 'Wickets',
    StatsDiscipline.fielding => 'Contributions',
  };

  String get _secondaryLabel => switch (_discipline) {
    StatsDiscipline.batting => 'SR',
    StatsDiscipline.bowling => 'Econ',
    StatsDiscipline.fielding => 'Total',
  };

  String get _sampleLabel => switch (_discipline) {
    StatsDiscipline.batting => 'Balls faced',
    StatsDiscipline.bowling => 'Balls bowled',
    StatsDiscipline.fielding => 'Innings',
  };

  void _onSort(int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
    });
  }

  Future<void> _promptAndSave({required bool asWidget}) async {
    final controller = TextEditingController(
      text: '${statsDisciplineLabels[_discipline]} query',
    );
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(asWidget ? 'Pin as widget' : 'Save query'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (name == null || name.trim().isEmpty || !mounted) return;
    final notifier = ref.read(customStatsExplorerProvider.notifier);
    if (asWidget) {
      notifier.pinAsWidget(name.trim(), _discipline, _filters);
    } else {
      notifier.saveQuery(name.trim(), _discipline, _filters);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(asWidget ? 'Pinned "$name"' : 'Saved "$name"')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final matches = ref.watch(playerAnalyticsMatchesProvider);
    final explorerState = ref.watch(customStatsExplorerProvider);
    var rows = runQuery(matches, _discipline, _filters);

    rows = [...rows];
    rows.sort((a, b) {
      final cmp = switch (_sortColumnIndex) {
        1 => a.primaryValue.compareTo(b.primaryValue),
        2 => a.secondaryValue.compareTo(b.secondaryValue),
        3 => a.sampleSize.compareTo(b.sampleSize),
        _ => a.date.compareTo(b.date),
      };
      return _sortAscending ? cmp : -cmp;
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Custom Stats Explorer')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          if (explorerState.pinnedWidgets.isNotEmpty) ...[
            Text(
              'Pinned widgets',
              style: AppTypography.label.copyWith(color: colors.textTertiary),
            ),
            const SizedBox(height: AppSpacing.sm),
            for (final widget in explorerState.pinnedWidgets)
              _PinnedWidgetCard(
                query: widget,
                onRemove: () => ref
                    .read(customStatsExplorerProvider.notifier)
                    .unpinWidget(widget.id),
              ),
            const SizedBox(height: AppSpacing.lg),
          ],
          Text(
            'Discipline',
            style: AppTypography.label.copyWith(color: colors.textTertiary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              for (final d in StatsDiscipline.values)
                ChoiceChip(
                  key: ValueKey('disciplineChip_${d.name}'),
                  label: Text(statsDisciplineLabels[d]!),
                  selected: _discipline == d,
                  onSelected: (_) => setState(() {
                    _discipline = d;
                    _filters = const StatsQueryFilters();
                  }),
                ),
            ],
          ),
          if (_discipline != StatsDiscipline.fielding) ...[
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Filters',
              style: AppTypography.label.copyWith(color: colors.textTertiary),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                for (final phase in MatchPhase.values)
                  FilterChip(
                    key: ValueKey('phaseFilterChip_${phase.name}'),
                    label: Text(matchPhaseLabels[phase]!),
                    selected: _filters.phase == phase,
                    onSelected: (selected) => setState(() {
                      _filters = _filters.copyWith(
                        phase: selected ? phase : null,
                        clearPhase: !selected,
                      );
                    }),
                  ),
                if (_discipline == StatsDiscipline.batting)
                  for (final type in BowlerType.values)
                    FilterChip(
                      key: ValueKey('bowlerTypeFilterChip_${type.name}'),
                      label: Text(bowlerTypeLabels[type]!),
                      selected: _filters.bowlerType == type,
                      onSelected: (selected) => setState(() {
                        _filters = _filters.copyWith(
                          bowlerType: selected ? type : null,
                          clearBowlerType: !selected,
                        );
                      }),
                    ),
                if (_discipline == StatsDiscipline.bowling)
                  for (final style in BattingStyle.values)
                    FilterChip(
                      key: ValueKey('battingStyleFilterChip_${style.name}'),
                      label: Text(
                        style == BattingStyle.rhb ? 'vs RHB' : 'vs LHB',
                      ),
                      selected: _filters.battingStyle == style,
                      onSelected: (selected) => setState(() {
                        _filters = _filters.copyWith(
                          battingStyle: selected ? style : null,
                          clearBattingStyle: !selected,
                        );
                      }),
                    ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Text(
                'Qualification: min $_sampleLabel',
                style: AppTypography.label.copyWith(color: colors.textTertiary),
              ),
              const Spacer(),
              AppStepper(
                value: _filters.minSample,
                min: 0,
                max: 20,
                semanticLabel: 'Minimum $_sampleLabel',
                onChanged: (v) =>
                    setState(() => _filters = _filters.copyWith(minSample: v)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          if (rows.isEmpty)
            Text(
              'No matches meet this query.',
              style: AppTypography.body.copyWith(color: colors.textSecondary),
            )
          else ...[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                key: const ValueKey('statsExplorerResultsTable'),
                sortColumnIndex: _sortColumnIndex,
                sortAscending: _sortAscending,
                columns: [
                  DataColumn(label: const Text('Match'), onSort: _onSort),
                  DataColumn(
                    label: Text(_primaryLabel),
                    numeric: true,
                    onSort: _onSort,
                  ),
                  DataColumn(
                    label: Text(_secondaryLabel),
                    numeric: true,
                    onSort: _onSort,
                  ),
                  DataColumn(
                    label: Text(_sampleLabel),
                    numeric: true,
                    onSort: _onSort,
                  ),
                ],
                rows: [
                  for (final row in rows)
                    DataRow(
                      key: ValueKey('statsRow_${row.matchLabel}_${row.date}'),
                      cells: [
                        DataCell(Text(row.matchLabel)),
                        DataCell(Text('${row.primaryValue}')),
                        DataCell(Text(row.secondaryValue.toStringAsFixed(1))),
                        DataCell(Text('${row.sampleSize}')),
                      ],
                    ),
                ],
              ),
            ),
            if (rows.length < smallSampleThreshold)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Text(
                  key: const ValueKey('smallSampleCaption'),
                  'Small sample -- only ${rows.length} qualifying '
                  'innings/overs. Interpret with caution.',
                  style: AppTypography.caption.copyWith(
                    color: colors.textTertiary,
                  ),
                ),
              ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _promptAndSave(asWidget: false),
                    child: const Text('Save query'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: FilledButton(
                    onPressed: () => _promptAndSave(asWidget: true),
                    child: const Text('Pin as widget'),
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

class _PinnedWidgetCard extends ConsumerWidget {
  final SavedQuery query;
  final VoidCallback onRemove;

  const _PinnedWidgetCard({required this.query, required this.onRemove});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final matches = ref.watch(playerAnalyticsMatchesProvider);
    final rows = runQuery(matches, query.discipline, query.filters);
    final total = rows.fold(0, (a, r) => a + r.primaryValue);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  query.name,
                  style: AppTypography.body.copyWith(color: colors.textPrimary),
                ),
                Text(
                  '$total across ${rows.length} innings/overs',
                  style: AppTypography.caption.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(icon: const Icon(Icons.close), onPressed: onRemove),
        ],
      ),
    );
  }
}
