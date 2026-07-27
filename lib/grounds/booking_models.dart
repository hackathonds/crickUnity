/// PRD §10.2 (Booking): "Availability calendar (green/amber-held/red).
/// Flow: pick slot -> party size & purpose (match/practice) -> price
/// quote incl. deposits -> request or instant-book (owner setting) ->
/// confirmation -> booking card (QR check-in, directions, reschedule/
/// cancel per policy)... No-show handling: owner marks no-show (with
/// grace 30 min) -> deposit per policy + team reliability note."
///
/// Backlog line: "hold 15:00, policy ack, QR ticket, reschedule/cancel
/// per policy, no-show grace 30m."
enum BookingPurpose { match, practice }

const Map<BookingPurpose, String> bookingPurposeLabels = {
  BookingPurpose.match: 'Match',
  BookingPurpose.practice: 'Practice',
};

enum BookingStatus {
  held,
  pendingOwnerAccept,
  confirmed,
  rescheduled,
  cancelledByRenter,
  cancelledByOwner,
  noShow,
  completed,
}

const Map<BookingStatus, String> bookingStatusLabels = {
  BookingStatus.held: 'Held',
  BookingStatus.pendingOwnerAccept: 'Pending owner acceptance',
  BookingStatus.confirmed: 'Confirmed',
  BookingStatus.rescheduled: 'Rescheduled',
  BookingStatus.cancelledByRenter: 'Cancelled by you',
  BookingStatus.cancelledByOwner: 'Cancelled by ground',
  BookingStatus.noShow: 'No-show',
  BookingStatus.completed: 'Completed',
};

/// Backlog names the exact hold duration.
const Duration slotHoldDuration = Duration(minutes: 15);

/// PRD §10.2: "grace 30 min."
const Duration noShowGraceDuration = Duration(minutes: 30);

/// PRD §2.11: "< 48h before slot."
const Duration ownerCancellationPenaltyWindow = Duration(hours: 48);

/// PRD names no exact point value for the reliability drop -- a flagged
/// judgment call.
const double reliabilityPenaltyPoints = 10;

/// PRD names no exact deposit percentage -- a flagged judgment call.
const double depositFraction = 0.2;

class Booking {
  final String id;
  final String groundId;
  final String groundName;
  final DateTime slotStart;
  final DateTime slotEnd;
  final int partySize;
  final BookingPurpose purpose;
  final int priceQuote;
  final int depositAmount;
  final bool instantBook;
  final BookingStatus status;
  final DateTime? heldUntil;
  final bool policyAcknowledged;
  final String qrCode;
  final DateTime createdAt;

  const Booking({
    required this.id,
    required this.groundId,
    required this.groundName,
    required this.slotStart,
    required this.slotEnd,
    required this.partySize,
    required this.purpose,
    required this.priceQuote,
    required this.depositAmount,
    this.instantBook = true,
    this.status = BookingStatus.held,
    this.heldUntil,
    this.policyAcknowledged = false,
    required this.qrCode,
    required this.createdAt,
  });

  bool isHoldExpired(DateTime now) =>
      status == BookingStatus.held &&
      heldUntil != null &&
      now.isAfter(heldUntil!);

  Duration? holdRemaining(DateTime now) => heldUntil?.difference(now);

  bool get isActive =>
      status == BookingStatus.confirmed ||
      status == BookingStatus.pendingOwnerAccept ||
      status == BookingStatus.rescheduled;

  bool noShowEligible(DateTime now) =>
      status == BookingStatus.confirmed &&
      now.isAfter(slotStart.add(noShowGraceDuration));

  bool ownerCancellationTriggersPenalty(DateTime now) =>
      slotStart.difference(now) < ownerCancellationPenaltyWindow;

  Booking copyWith({
    DateTime? slotStart,
    DateTime? slotEnd,
    BookingStatus? status,
    DateTime? heldUntil,
    bool clearHeldUntil = false,
    bool? policyAcknowledged,
  }) {
    return Booking(
      id: id,
      groundId: groundId,
      groundName: groundName,
      slotStart: slotStart ?? this.slotStart,
      slotEnd: slotEnd ?? this.slotEnd,
      partySize: partySize,
      purpose: purpose,
      priceQuote: priceQuote,
      depositAmount: depositAmount,
      instantBook: instantBook,
      status: status ?? this.status,
      heldUntil: clearHeldUntil ? null : (heldUntil ?? this.heldUntil),
      policyAcknowledged: policyAcknowledged ?? this.policyAcknowledged,
      qrCode: qrCode,
      createdAt: createdAt,
    );
  }
}
