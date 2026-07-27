import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_state_scaffolds.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'ground_models.dart';
import 'grounds_provider.dart';

/// PRD §10.1's Ground Profile fields drive this discovery card. DS
/// gives no unique screen spec beyond "map+list+filters" (backlog); no
/// maps/GIS package exists in pubspec.yaml, so "Map view" reuses the
/// exact same tinted-grid fallback recognition/grounds_heatmap_screen.dart
/// (E8-04) already established for this identical gap, rather than a
/// third ad-hoc workaround.
class GroundsDiscoveryScreen extends ConsumerStatefulWidget {
  const GroundsDiscoveryScreen({super.key});

  @override
  ConsumerState<GroundsDiscoveryScreen> createState() =>
      _GroundsDiscoveryScreenState();
}

class _GroundsDiscoveryScreenState
    extends ConsumerState<GroundsDiscoveryScreen> {
  bool _mapView = false;

  void _showGroundDetail(BuildContext context, Ground ground) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        final colors = Theme.of(context).extension<AppColors>()!;
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(ground.name, style: AppTypography.h2),
              Text(
                ground.address,
                style: AppTypography.caption.copyWith(
                  color: colors.textTertiary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text('₹${ground.pricePerHour}/hour · ${ground.rating}★'),
              Text(
                '${pitchTypeLabels[ground.pitchTypes.first]} · '
                '${boundaryBadgeLabels[ground.boundaryBadge]}',
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Full profile, booking, and reviews are separate stories '
                '(E9-02/E9-03/E9-04) -- not yet built.',
                style: AppTypography.caption.copyWith(
                  color: colors.textTertiary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final state = ref.watch(groundsProvider);
    final notifier = ref.read(groundsProvider.notifier);
    final grounds = state.filtered;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Grounds'),
        actions: [
          IconButton(
            key: const ValueKey('toggleMapViewButton'),
            icon: Icon(_mapView ? Icons.list : Icons.map_outlined),
            tooltip: _mapView ? 'List view' : 'Map view',
            onPressed: () => setState(() => _mapView = !_mapView),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  key: const ValueKey('groundSearchField'),
                  decoration: const InputDecoration(
                    hintText: 'Search grounds',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: notifier.setQuery,
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  children: [
                    for (final facility in Facility.values)
                      FilterChip(
                        key: ValueKey('facilityFilterChip_${facility.name}'),
                        label: Text(facilityLabels[facility]!),
                        selected: state.filter.requiredFacilities.contains(
                          facility,
                        ),
                        onSelected: (_) => notifier.toggleFacility(facility),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.sm,
                  children: [
                    ChoiceChip(
                      label: const Text('Any pitch'),
                      selected: state.filter.pitchType == null,
                      onSelected: (_) => notifier.setPitchType(null),
                    ),
                    for (final type in PitchType.values)
                      ChoiceChip(
                        key: ValueKey('pitchTypeFilterChip_${type.name}'),
                        label: Text(pitchTypeLabels[type]!),
                        selected: state.filter.pitchType == type,
                        onSelected: (_) => notifier.setPitchType(type),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: grounds.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: AppEmptyState(
                      message: 'No grounds match your filters.',
                      primaryLabel: 'Clear filters',
                      onPrimary: notifier.clearFilters,
                    ),
                  )
                : _mapView
                ? _MapViewFallback(
                    grounds: grounds,
                    colors: colors,
                    onTap: (g) => _showGroundDetail(context, g),
                  )
                : ListView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    children: [
                      for (final ground in grounds)
                        _GroundListCard(
                          ground: ground,
                          colors: colors,
                          onTap: () => _showGroundDetail(context, ground),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _GroundListCard extends StatelessWidget {
  final Ground ground;
  final AppColors colors;
  final VoidCallback onTap;

  const _GroundListCard({
    required this.ground,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey('groundCard_${ground.id}'),
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    ground.name,
                    style: AppTypography.subtitle.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                ),
                if (ground.verifiedOwner)
                  Icon(Icons.verified, size: 16, color: colors.verified),
              ],
            ),
            Text(
              '${ground.city} · ${ground.distanceKm.toStringAsFixed(1)} km',
              style: AppTypography.caption.copyWith(color: colors.textTertiary),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '₹${ground.pricePerHour}/hr · ${ground.rating}★ · '
              '${boundaryBadgeLabels[ground.boundaryBadge]}',
              style: AppTypography.body.copyWith(color: colors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.xs,
              children: [
                for (final entry in ground.facilities.entries)
                  if (entry.value != FacilityAvailability.no)
                    Chip(
                      label: Text(
                        facilityLabels[entry.key]! +
                            (entry.value == FacilityAvailability.paid
                                ? ' (paid)'
                                : ''),
                        style: AppTypography.caption,
                      ),
                    ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// No maps/GIS package exists -- a tinted grid fallback, same
/// convention as recognition/grounds_heatmap_screen.dart (E8-04).
class _MapViewFallback extends StatelessWidget {
  final List<Ground> grounds;
  final AppColors colors;
  final ValueChanged<Ground> onTap;

  const _MapViewFallback({
    required this.grounds,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          for (final ground in grounds)
            GestureDetector(
              key: ValueKey('groundMapPin_${ground.id}'),
              onTap: () => onTap(ground),
              child: Container(
                width: 140,
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(
                    alpha: (0.3 + ground.rating / 10).clamp(0.3, 0.9),
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.location_on, color: colors.onPrimary),
                    Text(
                      ground.name,
                      style: AppTypography.body.copyWith(
                        color: colors.onPrimary,
                      ),
                    ),
                    Text(
                      '${ground.distanceKm.toStringAsFixed(1)} km',
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
    );
  }
}
