import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_button.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'booking_models.dart';
import 'booking_ticket_screen.dart';
import 'bookings_provider.dart';
import 'ground_models.dart';
import 'grounds_provider.dart';

enum _SlotState { available, held, booked }

/// PRD §10.2: "Availability calendar (green/amber-held/red). Flow: pick
/// slot -> party size & purpose (match/practice) -> price quote incl.
/// deposits -> request or instant-book -> confirmation -> booking card."
/// Backlog: "hold 15:00, policy ack, QR ticket."
///
/// No real per-ground slot calendar data model exists (that's a bigger
/// build than this story's line calls for) -- a fixed daily slot grid
/// (6 slots/day across today+tomorrow) stands in, colored green/amber/
/// red from this ground's *actual* bookingsProvider state (not a static
/// mock), so the hold/confirm/expire flow is genuinely exercised.
class BookingFlowScreen extends ConsumerStatefulWidget {
  final String groundId;

  const BookingFlowScreen({super.key, required this.groundId});

  @override
  ConsumerState<BookingFlowScreen> createState() => _BookingFlowScreenState();
}

class _BookingFlowScreenState extends ConsumerState<BookingFlowScreen> {
  DateTime? _selectedSlot;
  int _partySize = 11;
  BookingPurpose _purpose = BookingPurpose.match;
  String? _activeHoldId;

  static List<DateTime> _slotsFor(DateTime day) => [
    for (final hour in [6, 8, 10, 14, 16, 18])
      DateTime(day.year, day.month, day.day, hour),
  ];

  _SlotState _stateFor(DateTime slot, Ground ground, List<Booking> bookings) {
    final overlapping = bookings.where(
      (b) => b.groundId == ground.id && b.slotStart == slot && b.isActive,
    );
    if (overlapping.isNotEmpty) return _SlotState.booked;
    final held = bookings.where(
      (b) =>
          b.groundId == ground.id &&
          b.slotStart == slot &&
          b.status == BookingStatus.held,
    );
    if (held.isNotEmpty) return _SlotState.held;
    return _SlotState.available;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final ground = ref.watch(groundsProvider).groundById(widget.groundId);
    ref.read(bookingsProvider.notifier).expireStaleHolds();
    final bookings = ref.watch(bookingsProvider).bookings;

    if (ground == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Book a slot')),
        body: const Center(child: Text('Ground not found.')),
      );
    }

    if (_activeHoldId != null) {
      final held = bookings.where((b) => b.id == _activeHoldId).firstOrNull;
      if (held != null && held.status == BookingStatus.held) {
        return _HoldScreen(
          booking: held,
          onExpired: () => setState(() => _activeHoldId = null),
        );
      }
    }

    final today = DateTime.now();
    final days = [today, today.add(const Duration(days: 1))];

    return Scaffold(
      appBar: AppBar(title: Text('Book · ${ground.name}')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          for (final day in days) ...[
            Text(
              '${day.day}/${day.month}/${day.year}',
              style: AppTypography.label.copyWith(color: colors.textTertiary),
            ),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final slot in _slotsFor(day))
                  _SlotChip(
                    key: ValueKey('slotChip_${slot.toIso8601String()}'),
                    slot: slot,
                    state: _stateFor(slot, ground, bookings),
                    selected: _selectedSlot == slot,
                    colors: colors,
                    onTap: () => setState(() => _selectedSlot = slot),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          if (_selectedSlot != null) ...[
            const Divider(),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Party size',
              style: AppTypography.label.copyWith(color: colors.textTertiary),
            ),
            Row(
              children: [
                IconButton(
                  key: const ValueKey('partySizeDecrement'),
                  icon: const Icon(Icons.remove),
                  onPressed: () => setState(
                    () => _partySize = (_partySize - 1).clamp(1, 30),
                  ),
                ),
                Text('$_partySize', style: AppTypography.stat),
                IconButton(
                  key: const ValueKey('partySizeIncrement'),
                  icon: const Icon(Icons.add),
                  onPressed: () => setState(
                    () => _partySize = (_partySize + 1).clamp(1, 30),
                  ),
                ),
              ],
            ),
            Text(
              'Purpose',
              style: AppTypography.label.copyWith(color: colors.textTertiary),
            ),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                for (final p in BookingPurpose.values)
                  ChoiceChip(
                    key: ValueKey('purposeChip_${p.name}'),
                    label: Text(bookingPurposeLabels[p]!),
                    selected: _purpose == p,
                    onSelected: (_) => setState(() => _purpose = p),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: colors.surfaceAlt,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: colors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Price quote',
                    style: AppTypography.label.copyWith(
                      color: colors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '₹${ground.pricePerHour} + ₹${(ground.pricePerHour * depositFraction).round()} deposit',
                    style: AppTypography.stat.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              key: const ValueKey('holdSlotButton'),
              variant: AppButtonVariant.primary,
              label: 'Hold slot (15:00)',
              fullWidth: true,
              onPressed: () {
                final booking = ref
                    .read(bookingsProvider.notifier)
                    .holdSlot(
                      ground: ground,
                      slotStart: _selectedSlot!,
                      partySize: _partySize,
                      purpose: _purpose,
                    );
                setState(() => _activeHoldId = booking.id);
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _SlotChip extends StatelessWidget {
  final DateTime slot;
  final _SlotState state;
  final bool selected;
  final AppColors colors;
  final VoidCallback onTap;

  const _SlotChip({
    super.key,
    required this.slot,
    required this.state,
    required this.selected,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = switch (state) {
      _SlotState.available => colors.success,
      _SlotState.held => colors.warning,
      _SlotState.booked => colors.error,
    };
    return GestureDetector(
      onTap: state == _SlotState.available ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: selected ? 0.35 : 0.15),
          borderRadius: BorderRadius.circular(10),
          border: selected ? Border.all(color: color, width: 2) : null,
        ),
        child: Text(
          '${slot.hour.toString().padLeft(2, '0')}:00',
          style: AppTypography.body.copyWith(color: colors.textPrimary),
        ),
      ),
    );
  }
}

/// PRD §10.2's "policy ack" step, shown while the 15:00 hold is live.
class _HoldScreen extends ConsumerStatefulWidget {
  final Booking booking;
  final VoidCallback onExpired;

  const _HoldScreen({required this.booking, required this.onExpired});

  @override
  ConsumerState<_HoldScreen> createState() => _HoldScreenState();
}

class _HoldScreenState extends ConsumerState<_HoldScreen> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // Forces a rebuild every second so the 15:00 hold countdown actually
    // ticks down, same pattern as onboarding/otp_screen.dart's resend timer.
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final booking = ref
        .watch(bookingsProvider)
        .bookings
        .where((b) => b.id == widget.booking.id)
        .firstOrNull;
    if (booking == null || booking.status != BookingStatus.held) {
      return Scaffold(
        appBar: AppBar(title: const Text('Hold expired')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(
              'Your 15:00 hold expired before the booking was confirmed. Pick a slot again.',
              textAlign: TextAlign.center,
              style: AppTypography.body.copyWith(color: colors.textSecondary),
            ),
          ),
        ),
      );
    }

    final remaining = booking.holdRemaining(DateTime.now()) ?? Duration.zero;
    final minutes = remaining.inMinutes.clamp(0, 15);
    final seconds = (remaining.inSeconds % 60).clamp(0, 59);

    return Scaffold(
      appBar: AppBar(title: const Text('Confirm booking')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: colors.warning.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(Icons.timer_outlined, color: colors.warning),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Slot held for ${minutes}m ${seconds}s',
                    style: AppTypography.body.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              '${booking.groundName} · ${booking.slotStart.hour}:00 · '
              '${bookingPurposeLabels[booking.purpose]} · ${booking.partySize} players',
              style: AppTypography.body,
            ),
            Text(
              '₹${booking.priceQuote} + ₹${booking.depositAmount} deposit',
              style: AppTypography.stat.copyWith(color: colors.textPrimary),
            ),
            const SizedBox(height: AppSpacing.lg),
            CheckboxListTile(
              key: const ValueKey('policyAckCheckbox'),
              contentPadding: EdgeInsets.zero,
              value: booking.policyAcknowledged,
              title: const Text(
                'I have read and accept the cancellation policy',
              ),
              onChanged: (_) => ref
                  .read(bookingsProvider.notifier)
                  .acknowledgePolicy(booking.id),
            ),
            const Spacer(),
            AppButton(
              key: const ValueKey('confirmBookingButton'),
              variant: AppButtonVariant.primary,
              label: booking.instantBook ? 'Confirm booking' : 'Send request',
              fullWidth: true,
              onPressed: booking.policyAcknowledged
                  ? () {
                      ref
                          .read(bookingsProvider.notifier)
                          .confirmBooking(booking.id);
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) =>
                              BookingTicketScreen(bookingId: booking.id),
                        ),
                      );
                    }
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
