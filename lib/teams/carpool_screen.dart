import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_button.dart';
import '../design_system/components/app_dialog.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'carpool_models.dart';
import 'carpool_provider.dart';

/// DS §7 screen 18 (Carpool): "Carpool cards show seats pips (● ● ○),
/// Join → confirm."
class CarpoolScreen extends ConsumerWidget {
  final String viewerName;

  const CarpoolScreen({super.key, required this.viewerName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(carpoolProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Carpool')),
      body: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: state.rides.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, index) =>
            _RideCard(ride: state.rides[index], viewerName: viewerName),
      ),
    );
  }
}

class _RideCard extends ConsumerWidget {
  final CarpoolRide ride;
  final String viewerName;

  const _RideCard({required this.ride, required this.viewerName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final notifier = ref.read(carpoolProvider.notifier);
    final joined = ride.riders.contains(viewerName);

    return Container(
      key: ValueKey('rideCard_${ride.id}'),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${ride.driverName} -> ${ride.destination}',
            style: AppTypography.subtitle.copyWith(color: colors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            key: ValueKey('seatPips_${ride.id}'),
            children: [
              for (var i = 0; i < ride.seatCapacity; i++)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.xs),
                  child: Icon(
                    i < ride.seatsFilled ? Icons.circle : Icons.circle_outlined,
                    size: 14,
                    color: i < ride.seatsFilled
                        ? colors.primary
                        : colors.textTertiary,
                  ),
                ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '${ride.seatsFilled}/${ride.seatCapacity} seats',
                style: AppTypography.caption.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '₹${ride.fuelSplitSuggestion} suggested per rider',
            style: AppTypography.caption.copyWith(color: colors.textTertiary),
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            key: ValueKey('joinRideButton_${ride.id}'),
            variant: joined
                ? AppButtonVariant.secondary
                : AppButtonVariant.primary,
            label: joined ? 'Leave' : 'Join',
            onPressed: (joined || !ride.isFull)
                ? () async {
                    if (joined) {
                      notifier.leaveRide(ride.id, viewerName);
                      return;
                    }
                    final confirmed = await showAppConfirmDialog(
                      context: context,
                      title: 'Join this ride?',
                      body:
                          "You'll be riding with ${ride.driverName} to "
                          '${ride.destination}.',
                      confirmLabel: 'Join',
                    );
                    if (confirmed == true) {
                      notifier.joinRide(ride.id, viewerName);
                    }
                  }
                : null,
          ),
        ],
      ),
    );
  }
}
