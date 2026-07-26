import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'availability_models.dart';
import 'availability_provider.dart';

/// DS §11.18: "profile-menu Availability sheet (Available/Busy-until-
/// date-picker/Injured→links 11.16)."
Future<void> showAvailabilitySheet({
  required BuildContext context,
  DateTime Function() now = DateTime.now,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _AvailabilitySheetContent(now: now),
  );
}

class _AvailabilitySheetContent extends ConsumerWidget {
  final DateTime Function() now;

  const _AvailabilitySheetContent({required this.now});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final state = ref.watch(availabilityProvider);
    final notifier = ref.read(availabilityProvider.notifier);

    Widget row({
      required Key key,
      required String label,
      required bool selected,
      required VoidCallback onTap,
    }) => Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        key: key,
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? colors.primary : colors.border,
                    width: 1.5,
                  ),
                ),
                child: selected
                    ? Center(
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colors.primary,
                          ),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                label,
                style: AppTypography.body.copyWith(color: colors.textPrimary),
              ),
            ],
          ),
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Availability',
            style: AppTypography.title.copyWith(color: colors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.lg),
          row(
            key: const ValueKey('availabilityOption_available'),
            label: 'Available',
            selected: state.status == AvailabilityStatus.available,
            onTap: notifier.setAvailable,
          ),
          row(
            key: const ValueKey('availabilityOption_busy'),
            label:
                state.status == AvailabilityStatus.busy &&
                    state.busyUntil != null
                ? 'Busy until ${state.busyUntil!.day}/'
                      '${state.busyUntil!.month}/${state.busyUntil!.year}'
                : 'Busy until...',
            selected: state.status == AvailabilityStatus.busy,
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: now().add(const Duration(days: 1)),
                firstDate: now(),
                lastDate: now().add(const Duration(days: 365)),
              );
              if (picked != null) notifier.setBusyUntil(picked);
            },
          ),
          row(
            key: const ValueKey('availabilityOption_injured'),
            label: 'Injured',
            selected: state.status == AvailabilityStatus.injured,
            onTap: notifier.setInjured,
          ),
          if (state.status == AvailabilityStatus.injured) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              key: const ValueKey('availabilityInjuryLogStub'),
              'Injury details (type, date, notes) are tracked in the '
              'Injury log -- not built yet.',
              style: AppTypography.caption.copyWith(color: colors.textTertiary),
            ),
          ],
        ],
      ),
    );
  }
}
