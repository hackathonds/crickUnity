import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_button.dart';
import '../design_system/components/app_tag_chip.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'booking_models.dart';
import 'bookings_provider.dart';

/// PRD §10.2: "booking card (QR check-in, directions, reschedule/cancel
/// per policy)." No real QR-rendering package exists in pubspec.yaml --
/// the code string is shown as monospace text inside a bordered square,
/// same "flag the missing package, keep the real data" convention used
/// throughout this session for missing infra (maps, audio, etc.).
class BookingTicketScreen extends ConsumerWidget {
  final String bookingId;

  const BookingTicketScreen({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final booking = ref
        .watch(bookingsProvider)
        .bookings
        .where((b) => b.id == bookingId)
        .firstOrNull;

    if (booking == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Booking')),
        body: const Center(child: Text('Booking not found.')),
      );
    }

    final notifier = ref.read(bookingsProvider.notifier);
    final statusVariant = switch (booking.status) {
      BookingStatus.confirmed ||
      BookingStatus.rescheduled => AppTagChipVariant.success,
      BookingStatus.pendingOwnerAccept => AppTagChipVariant.warning,
      BookingStatus.cancelledByRenter ||
      BookingStatus.cancelledByOwner ||
      BookingStatus.noShow => AppTagChipVariant.error,
      _ => AppTagChipVariant.neutral,
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Booking ticket')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          AppTagChip(
            label: bookingStatusLabels[booking.status]!,
            variant: statusVariant,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(booking.groundName, style: AppTypography.h2),
          Text(
            '${booking.slotStart.day}/${booking.slotStart.month} · '
            '${booking.slotStart.hour.toString().padLeft(2, '0')}:00 · '
            '${bookingPurposeLabels[booking.purpose]} · ${booking.partySize} players',
            style: AppTypography.body.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xl),
          if (booking.isActive) ...[
            Center(
              child: Container(
                key: const ValueKey('qrTicketBox'),
                width: 160,
                height: 160,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  border: Border.all(color: colors.border, width: 2),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Text(
                  booking.qrCode,
                  textAlign: TextAlign.center,
                  style: AppTypography.caption.copyWith(
                    fontFamily: 'monospace',
                    color: colors.textPrimary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    key: const ValueKey('rescheduleBookingButton'),
                    variant: AppButtonVariant.secondary,
                    label: 'Reschedule',
                    fullWidth: true,
                    onPressed: () => notifier.rescheduleBooking(
                      booking.id,
                      booking.slotStart.add(const Duration(days: 1)),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppButton(
                    key: const ValueKey('cancelBookingButton'),
                    variant: AppButtonVariant.destructive,
                    label: 'Cancel',
                    fullWidth: true,
                    onPressed: () =>
                        _confirmCancel(context, notifier, booking.id),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Cancellation policy: cancelling close to the slot may forfeit '
              'the ₹${booking.depositAmount} deposit per ground policy.',
              style: AppTypography.caption.copyWith(color: colors.textTertiary),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Owner console (E9-05) and Caretaker mode (E9-06) are separate '
              'not-yet-built stories -- these debug controls stand in so the '
              'no-show and owner-cancellation policies can be exercised now.',
              style: AppTypography.caption.copyWith(color: colors.textTertiary),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    key: const ValueKey('debugMarkNoShowButton'),
                    variant: AppButtonVariant.tertiary,
                    label: 'Mark no-show (debug)',
                    fullWidth: true,
                    onPressed: booking.noShowEligible(DateTime.now())
                        ? () => notifier.markNoShow(booking.id)
                        : null,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppButton(
                    key: const ValueKey('debugOwnerCancelButton'),
                    variant: AppButtonVariant.tertiary,
                    label: 'Owner-cancel (debug)',
                    fullWidth: true,
                    onPressed: () => notifier.cancelByOwner(booking.id),
                  ),
                ),
              ],
            ),
          ] else
            Text(
              'This booking is no longer active.',
              style: AppTypography.body.copyWith(color: colors.textSecondary),
            ),
        ],
      ),
    );
  }

  void _confirmCancel(
    BuildContext context,
    BookingsNotifier notifier,
    String bookingId,
  ) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel this booking?'),
        content: const Text(
          'The deposit may be forfeited per the ground\'s cancellation policy.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Keep booking'),
          ),
          TextButton(
            onPressed: () {
              notifier.cancelByRenter(bookingId);
              Navigator.of(context).pop();
            },
            child: const Text('Cancel booking'),
          ),
        ],
      ),
    );
  }
}
