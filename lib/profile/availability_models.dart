/// PRD §5.16: "Availability master toggle (Available / Busy until {date}
/// / Injured — injured pauses streak penalties)."
enum AvailabilityStatus { available, busy, injured }

class AvailabilityState {
  final AvailabilityStatus status;

  /// Only meaningful when [status] is [AvailabilityStatus.busy].
  final DateTime? busyUntil;

  const AvailabilityState({
    this.status = AvailabilityStatus.available,
    this.busyUntil,
  });
}
