import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'record_models.dart';
import 'records_provider.dart';

class _VisitedGround {
  final String name;
  final String city;
  final int matchCount;

  const _VisitedGround({
    required this.name,
    required this.city,
    required this.matchCount,
  });
}

/// DS §11.15: "Grounds heatmap: map with visited-ground pins sized by
/// matches, my-city aggregate toggle; pin tap -> my record at that
/// ground card." No maps/GIS package exists in pubspec.yaml -- a tinted
/// grid stands in for a literal geographic map, flagged, same
/// no-new-heavy-dependency-for-one-feature judgment this session has
/// made elsewhere.
class GroundsHeatmapScreen extends ConsumerStatefulWidget {
  const GroundsHeatmapScreen({super.key});

  @override
  ConsumerState<GroundsHeatmapScreen> createState() =>
      _GroundsHeatmapScreenState();
}

class _GroundsHeatmapScreenState extends ConsumerState<GroundsHeatmapScreen> {
  bool _myCityOnly = false;
  String? _selectedGround;

  static const _grounds = [
    _VisitedGround(name: 'Green Valley Ground', city: 'Delhi', matchCount: 14),
    _VisitedGround(name: 'Riverside Oval', city: 'Delhi', matchCount: 6),
    _VisitedGround(name: 'City Stadium', city: 'Mumbai', matchCount: 2),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final myCity = 'Delhi';
    final grounds = _myCityOnly
        ? _grounds.where((g) => g.city == myCity).toList()
        : _grounds;
    final maxCount = _grounds
        .map((g) => g.matchCount)
        .reduce((a, b) => a > b ? a : b);

    final records = ref.watch(recordsProvider).records;
    final selectedRecords = _selectedGround == null
        ? const <Record>[]
        : records
              .where(
                (r) =>
                    r.scope == RecordScope.ground &&
                    r.scopeLabel == _selectedGround,
              )
              .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Grounds heatmap')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          SwitchListTile(
            key: const ValueKey('myCityAggregateToggle'),
            contentPadding: EdgeInsets.zero,
            title: Text('My city only ($myCity)'),
            value: _myCityOnly,
            onChanged: (v) => setState(() => _myCityOnly = v),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final ground in grounds)
                GestureDetector(
                  key: ValueKey('groundTile_${ground.name}'),
                  onTap: () => setState(() => _selectedGround = ground.name),
                  child: Container(
                    width: 140,
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(
                        alpha: (0.2 + 0.6 * ground.matchCount / maxCount).clamp(
                          0.2,
                          0.8,
                        ),
                      ),
                      borderRadius: BorderRadius.circular(10),
                      border: _selectedGround == ground.name
                          ? Border.all(color: colors.primary, width: 2)
                          : null,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ground.name,
                          style: AppTypography.body.copyWith(
                            color: colors.onPrimary,
                          ),
                        ),
                        Text(
                          '${ground.matchCount} matches',
                          style: AppTypography.caption.copyWith(
                            color: colors.onPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          if (_selectedGround != null) ...[
            const SizedBox(height: AppSpacing.xl),
            Text(
              'My record at $_selectedGround',
              style: AppTypography.label.copyWith(color: colors.textTertiary),
            ),
            const SizedBox(height: AppSpacing.xs),
            if (selectedRecords.isEmpty)
              Text(
                'No ground records tracked here yet.',
                style: AppTypography.body.copyWith(color: colors.textSecondary),
              )
            else
              for (final record in selectedRecords)
                Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: colors.surfaceAlt,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    '${recordCategoryLabels[record.category]}: '
                    '${record.isVacant ? "Vacant -- be first!" : "${record.holderName} -- ${record.value}"}',
                    style: AppTypography.body.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                ),
          ],
        ],
      ),
    );
  }
}
