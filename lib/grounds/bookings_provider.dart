import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'booking_models.dart';
import 'ground_models.dart';
import 'grounds_provider.dart';

class BookingsState {
  final List<Booking> bookings;

  const BookingsState({this.bookings = const []});

  BookingsState copyWith({List<Booking>? bookings}) =>
      BookingsState(bookings: bookings ?? this.bookings);
}

/// Backlog E9-03 -- Booking flow engine. See booking_models.dart's
/// top-of-file note on the exact hold/grace/penalty windows this cites.
class BookingsNotifier extends Notifier<BookingsState> {
  @override
  BookingsState build() => BookingsState(bookings: _seedBookings());

  /// E9-04 (Reviews) needs a genuinely completed stay to exercise the
  /// verified-booker gate against, and E9-06 (Caretaker mode) needs a
  /// genuine "today, past grace, not checked in" booking to exercise
  /// check-in/no-show against -- two seeded bookings (no per-user
  /// renter field exists on Booking; same single-account convention as
  /// composerViewerName elsewhere) rather than screens that trust an
  /// unchecked flag.
  static List<Booking> _seedBookings() {
    final completedSlotStart = DateTime.now().subtract(
      const Duration(days: 10),
    );
    final todaySlotStart = DateTime.now().subtract(const Duration(hours: 1));
    return [
      Booking(
        id: 'booking-seed-completed',
        groundId: 'ground-green-valley',
        groundName: 'Green Valley Ground',
        slotStart: completedSlotStart,
        slotEnd: completedSlotStart.add(const Duration(hours: 1)),
        partySize: 11,
        purpose: BookingPurpose.match,
        priceQuote: 800,
        depositAmount: 160,
        status: BookingStatus.completed,
        policyAcknowledged: true,
        qrCode: 'QR-ground-green-valley-seed',
        createdAt: completedSlotStart.subtract(const Duration(days: 2)),
      ),
      Booking(
        id: 'booking-seed-today',
        groundId: 'ground-green-valley',
        groundName: 'Green Valley Ground',
        slotStart: todaySlotStart,
        slotEnd: todaySlotStart.add(const Duration(hours: 1)),
        partySize: 9,
        purpose: BookingPurpose.practice,
        priceQuote: 800,
        depositAmount: 160,
        status: BookingStatus.confirmed,
        policyAcknowledged: true,
        qrCode: 'QR-ground-green-valley-today',
        createdAt: todaySlotStart.subtract(const Duration(days: 1)),
      ),
    ];
  }

  /// PRD §10.2 step 1-3: pick slot -> party size & purpose -> price
  /// quote incl. deposits. Slots are treated as 1-hour blocks priced at
  /// the ground's per-hour rate; the deposit fraction is a flagged
  /// judgment call (booking_models.dart's depositFraction).
  Booking holdSlot({
    required Ground ground,
    required DateTime slotStart,
    required int partySize,
    required BookingPurpose purpose,
    DateTime Function() now = DateTime.now,
  }) {
    final booking = Booking(
      id: 'booking-${now().microsecondsSinceEpoch}',
      groundId: ground.id,
      groundName: ground.name,
      slotStart: slotStart,
      slotEnd: slotStart.add(const Duration(hours: 1)),
      partySize: partySize,
      purpose: purpose,
      priceQuote: ground.pricePerHour,
      depositAmount: (ground.pricePerHour * depositFraction).round(),
      // PRD §10.2: "request or instant-book (owner setting)." No owner
      // console exists yet to set this (that's E9-05); seeded grounds
      // default instant-book so this story's flow can be exercised
      // end-to-end, flagged rather than left unreachable.
      instantBook: true,
      status: BookingStatus.held,
      heldUntil: now().add(slotHoldDuration),
      qrCode: 'QR-${ground.id}-${now().millisecondsSinceEpoch}',
      createdAt: now(),
    );
    state = state.copyWith(bookings: [...state.bookings, booking]);
    return booking;
  }

  /// PRD §10.2's "policy ack" step -- explicit acknowledgement of the
  /// cancellation policy before a hold can be confirmed.
  void acknowledgePolicy(String bookingId) {
    _update(bookingId, (b) => b.copyWith(policyAcknowledged: true));
  }

  void confirmBooking(
    String bookingId, {
    DateTime Function() now = DateTime.now,
  }) {
    final booking = state.bookings.where((b) => b.id == bookingId).firstOrNull;
    if (booking == null) return;
    if (!booking.policyAcknowledged || booking.isHoldExpired(now())) return;
    _update(
      bookingId,
      (b) => b.copyWith(
        status: b.instantBook
            ? BookingStatus.confirmed
            : BookingStatus.pendingOwnerAccept,
        clearHeldUntil: true,
      ),
    );
  }

  /// Sweeps holds whose 15:00 window has lapsed without confirmation
  /// back to cancelled, freeing the slot. Called from the booking
  /// screen's build (same "sweep on read" convention as
  /// rewards_provider.dart's sweepExpiredCoins, E6-05).
  void expireStaleHolds({DateTime Function() now = DateTime.now}) {
    final nowValue = now();
    final hasExpired = state.bookings.any((b) => b.isHoldExpired(nowValue));
    if (!hasExpired) return;
    state = state.copyWith(
      bookings: [
        for (final b in state.bookings)
          if (b.isHoldExpired(nowValue))
            b.copyWith(
              status: BookingStatus.cancelledByRenter,
              clearHeldUntil: true,
            )
          else
            b,
      ],
    );
  }

  /// PRD §10.2: "Reschedule: both parties confirm; policy-based fees
  /// shown before confirming." No multi-account system exists to model
  /// a second confirming party (same flagged convention as every other
  /// cross-party flow this session) -- this applies the reschedule
  /// unilaterally from the renter's side.
  void rescheduleBooking(String bookingId, DateTime newSlotStart) {
    _update(
      bookingId,
      (b) => b.copyWith(
        slotStart: newSlotStart,
        slotEnd: newSlotStart.add(const Duration(hours: 1)),
        status: BookingStatus.rescheduled,
      ),
    );
  }

  void cancelByRenter(String bookingId) {
    _update(
      bookingId,
      (b) => b.copyWith(status: BookingStatus.cancelledByRenter),
    );
  }

  /// PRD §2.11: owner-side cancellation < 48h before slot auto-applies
  /// refund + a reliability-score drop on the ground listing.
  void cancelByOwner(
    String bookingId, {
    DateTime Function() now = DateTime.now,
  }) {
    final booking = state.bookings.where((b) => b.id == bookingId).firstOrNull;
    if (booking == null) return;
    final triggersPenalty = booking.ownerCancellationTriggersPenalty(now());
    _update(
      bookingId,
      (b) => b.copyWith(status: BookingStatus.cancelledByOwner),
    );
    if (triggersPenalty) {
      ref
          .read(groundsProvider.notifier)
          .applyReliabilityPenalty(booking.groundId, reliabilityPenaltyPoints);
    }
  }

  /// PRD §10.2: "owner marks no-show (with grace 30 min) -> deposit per
  /// policy + team reliability note." No renter-side reliability/Trust
  /// score model exists for teams in this module yet -- the deposit
  /// forfeiture is applied; the team-reliability note is flagged as a
  /// future cross-module hook (Trust score lives in the Team module).
  void markNoShow(
    String bookingId, {
    String? reason,
    DateTime Function() now = DateTime.now,
  }) {
    final booking = state.bookings.where((b) => b.id == bookingId).firstOrNull;
    if (booking == null || !booking.noShowEligible(now())) return;
    _update(
      bookingId,
      (b) => b.copyWith(status: BookingStatus.noShow, noShowReason: reason),
    );
  }

  /// DS §11.17 Caretaker mode: "[Check in] scan button per row." No
  /// camera/QR package exists (flagged) -- records a real timestamp.
  void checkIn(String bookingId, {DateTime Function() now = DateTime.now}) {
    final booking = state.bookings.where((b) => b.id == bookingId).firstOrNull;
    if (booking == null || !booking.isActive || booking.checkedIn) return;
    _update(bookingId, (b) => b.copyWith(checkedIn: true, checkedInAt: now()));
  }

  List<Booking> todaysBookingsFor(
    String groundId, {
    DateTime Function() now = DateTime.now,
  }) {
    final today = now();
    return state.bookings
        .where(
          (b) =>
              b.groundId == groundId &&
              b.isActive &&
              b.slotStart.year == today.year &&
              b.slotStart.month == today.month &&
              b.slotStart.day == today.day,
        )
        .toList();
  }

  /// Transitions confirmed/rescheduled bookings whose slot has fully
  /// elapsed to completed -- the real state E9-04's verified-booker
  /// gate reads. Same "sweep on read" convention as expireStaleHolds.
  void sweepCompletions({DateTime Function() now = DateTime.now}) {
    final nowValue = now();
    final due = state.bookings.any(
      (b) =>
          (b.status == BookingStatus.confirmed ||
              b.status == BookingStatus.rescheduled) &&
          nowValue.isAfter(b.slotEnd),
    );
    if (!due) return;
    state = state.copyWith(
      bookings: [
        for (final b in state.bookings)
          if ((b.status == BookingStatus.confirmed ||
                  b.status == BookingStatus.rescheduled) &&
              nowValue.isAfter(b.slotEnd))
            b.copyWith(status: BookingStatus.completed)
          else
            b,
      ],
    );
  }

  List<Booking> completedBookingsFor(String groundId) => state.bookings
      .where(
        (b) => b.groundId == groundId && b.status == BookingStatus.completed,
      )
      .toList();

  void _update(String bookingId, Booking Function(Booking) transform) {
    state = state.copyWith(
      bookings: [
        for (final b in state.bookings)
          if (b.id == bookingId) transform(b) else b,
      ],
    );
  }
}

final bookingsProvider = NotifierProvider<BookingsNotifier, BookingsState>(
  BookingsNotifier.new,
);
