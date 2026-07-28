import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_card.dart';
import '../design_system/components/app_state_scaffolds.dart';
import '../design_system/components/app_tag_chip.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'booking_models.dart';
import 'booking_ticket_screen.dart';
import 'bookings_provider.dart';
import 'grounds_discovery_screen.dart';

/// No dedicated "My Bookings" screen is described anywhere in DS or the
/// backlog beyond being named as a drawer/sitemap destination -- `Booking`
/// itself carries no per-user renter field (bookings_provider.dart's own
/// top-of-file note: "same single-account convention"), so every booking
/// in [bookingsProvider] already is "mine." This aggregates them into
/// cards linking to the real, already-built [BookingTicketScreen], same
/// spirit as My Teams/My Tournaments.
class MyBookingsScreen extends ConsumerWidget {
  const MyBookingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookings = ref.watch(bookingsProvider).bookings.toList()
      ..sort((a, b) => b.slotStart.compareTo(a.slotStart));

    return Scaffold(
      appBar: AppBar(title: const Text('My Bookings')),
      body: bookings.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: AppEmptyState(
                key: const ValueKey('myBookingsEmptyState'),
                message: "You haven't booked a ground yet.",
                primaryLabel: 'Find a ground',
                onPrimary: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const GroundsDiscoveryScreen(),
                  ),
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                for (final booking in bookings)
                  Padding(
                    key: ValueKey('myBookingCard_${booking.id}'),
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: _BookingCard(booking: booking),
                  ),
              ],
            ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final Booking booking;

  const _BookingCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return AppCard(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => BookingTicketScreen(bookingId: booking.id),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            booking.groundName,
            style: AppTypography.title.copyWith(color: colors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            _formatSlot(booking.slotStart),
            style: AppTypography.caption.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              AppTagChip(label: bookingPurposeLabels[booking.purpose]!),
              AppTagChip(label: bookingStatusLabels[booking.status]!),
            ],
          ),
        ],
      ),
    );
  }

  String _formatSlot(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final period = dt.hour < 12 ? 'AM' : 'PM';
    final minute = dt.minute.toString().padLeft(2, '0');
    return '${months[dt.month - 1]} ${dt.day} · $hour12:$minute $period';
  }
}
