import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_button.dart';
import '../design_system/components/app_state_scaffolds.dart';
import '../design_system/components/app_tag_chip.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'booking_models.dart';
import 'bookings_provider.dart';

/// DS §11.17: "Caretaker mode (staff sub-account): single-purpose
/// screen: today's bookings list with [Check in] scan button per row +
/// [Mark no-show] (enabled after 30-min grace, reason sheet);
/// intentionally no other navigation." PRD §2.11 restricts caretaker
/// sub-accounts to "check-in/no-show marking only; no pricing/finance" --
/// this screen exposes nothing else, by design (no drawer, no bottom
/// nav, no links into pricing/owner-console screens).
///
/// No camera/QR-scanning package exists in pubspec.yaml (flagged, same
/// convention as booking_ticket_screen.dart's QR display) -- "scan" is
/// a tap that records a real check-in timestamp.
class CaretakerModeScreen extends ConsumerWidget {
  final String groundId;

  const CaretakerModeScreen({super.key, required this.groundId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final notifier = ref.read(bookingsProvider.notifier);
    final now = DateTime.now();
    final todaysBookings =
        ref
            .watch(bookingsProvider.select((s) => s.bookings))
            .where(
              (b) =>
                  b.groundId == groundId &&
                  b.isActive &&
                  b.slotStart.year == now.year &&
                  b.slotStart.month == now.month &&
                  b.slotStart.day == now.day,
            )
            .toList()
          ..sort((a, b) => a.slotStart.compareTo(b.slotStart));

    return Scaffold(
      appBar: AppBar(title: const Text('Caretaker check-in')),
      body: todaysBookings.isEmpty
          ? const AppEmptyState(
              message: 'No bookings scheduled at this ground today.',
              primaryLabel: 'Refresh',
              onPrimary: _noop,
            )
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                for (final booking in todaysBookings)
                  _BookingRow(
                    key: ValueKey('caretakerBookingRow_${booking.id}'),
                    booking: booking,
                    colors: colors,
                    onCheckIn: () => notifier.checkIn(booking.id),
                    onMarkNoShow: () =>
                        _showNoShowReasonSheet(context, ref, booking.id),
                  ),
              ],
            ),
    );
  }

  static void _noop() {}

  void _showNoShowReasonSheet(
    BuildContext context,
    WidgetRef ref,
    String bookingId,
  ) {
    const reasons = [
      'Team never arrived',
      'Wrong slot/date',
      'No contact',
      'Other',
    ];
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Text('Mark no-show -- reason', style: AppTypography.h2),
            ),
            for (final reason in reasons)
              ListTile(
                key: ValueKey('noShowReasonTile_$reason'),
                title: Text(reason),
                onTap: () {
                  ref
                      .read(bookingsProvider.notifier)
                      .markNoShow(bookingId, reason: reason);
                  Navigator.of(context).pop();
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _BookingRow extends StatelessWidget {
  final Booking booking;
  final AppColors colors;
  final VoidCallback onCheckIn;
  final VoidCallback onMarkNoShow;

  const _BookingRow({
    super.key,
    required this.booking,
    required this.colors,
    required this.onCheckIn,
    required this.onMarkNoShow,
  });

  @override
  Widget build(BuildContext context) {
    final noShowEligible = booking.noShowEligible(DateTime.now());
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${booking.slotStart.hour.toString().padLeft(2, '0')}:00 · '
                  '${bookingPurposeLabels[booking.purpose]} · ${booking.partySize} players',
                  style: AppTypography.body.copyWith(color: colors.textPrimary),
                ),
              ),
              if (booking.checkedIn)
                AppTagChip(
                  label: 'Checked in',
                  variant: AppTagChipVariant.success,
                )
              else if (booking.status == BookingStatus.noShow)
                AppTagChip(label: 'No-show', variant: AppTagChipVariant.error),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  key: ValueKey('checkInButton_${booking.id}'),
                  variant: AppButtonVariant.primary,
                  label: 'Check in',
                  fullWidth: true,
                  onPressed:
                      booking.checkedIn ||
                          booking.status != BookingStatus.confirmed
                      ? null
                      : onCheckIn,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppButton(
                  key: ValueKey('markNoShowButton_${booking.id}'),
                  variant: AppButtonVariant.destructive,
                  label: 'Mark no-show',
                  fullWidth: true,
                  onPressed: noShowEligible ? onMarkNoShow : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
