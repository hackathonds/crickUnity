import 'tournament_models.dart';

/// PRD §8.2 (Registration): "Team applies with squad list (min/max
/// enforced), pays entry fee into tournament wallet (escrow) -- refund
/// rules displayed upfront (full refund if rejected/cancelled;
/// organizer-set sliding scale for withdrawal). Organizer reviews
/// (squad eligibility flags: duplicate player across two registered
/// teams is auto-flagged and blocked until resolved). Waitlist
/// auto-promotes on dropout."
enum RegistrationStatus { pending, approved, rejected, waitlisted, withdrawn }

const Map<RegistrationStatus, String> registrationStatusLabels = {
  RegistrationStatus.pending: 'Pending review',
  RegistrationStatus.approved: 'Approved',
  RegistrationStatus.rejected: 'Rejected',
  RegistrationStatus.waitlisted: 'Waitlisted',
  RegistrationStatus.withdrawn: 'Withdrawn',
};

/// PRD names no exact sliding scale for a withdrawal refund -- a
/// flagged judgment call: full refund 14+ days out, half refund 7-13
/// days out, no refund inside 7 days.
double withdrawalRefundFraction(DateTime tournamentStart, DateTime now) {
  final daysOut = tournamentStart.difference(now).inDays;
  if (daysOut >= 14) return 1.0;
  if (daysOut >= 7) return 0.5;
  return 0.0;
}

class TeamRegistration {
  final String id;
  final String tournamentId;
  final String teamName;
  final List<String> squad;
  final Set<String> docsChecked;
  final RegistrationStatus status;
  final DateTime createdAt;
  final int? waitlistPosition;

  const TeamRegistration({
    required this.id,
    required this.tournamentId,
    required this.teamName,
    required this.squad,
    this.docsChecked = const {},
    this.status = RegistrationStatus.pending,
    required this.createdAt,
    this.waitlistPosition,
  });

  bool get docsComplete =>
      commonRegistrationDocs.every((doc) => docsChecked.contains(doc));

  TeamRegistration copyWith({
    RegistrationStatus? status,
    int? waitlistPosition,
    bool clearWaitlistPosition = false,
  }) {
    return TeamRegistration(
      id: id,
      tournamentId: tournamentId,
      teamName: teamName,
      squad: squad,
      docsChecked: docsChecked,
      status: status ?? this.status,
      createdAt: createdAt,
      waitlistPosition: clearWaitlistPosition
          ? null
          : (waitlistPosition ?? this.waitlistPosition),
    );
  }
}

/// PRD §8.2: "duplicate player across two registered teams is
/// auto-flagged and blocked until resolved." Only pending/waitlisted/
/// approved registrations count -- a rejected or withdrawn team's
/// squad no longer occupies a slot.
Set<String> duplicatePlayersAcross(List<TeamRegistration> registrations) {
  final counts = <String, int>{};
  for (final r in registrations) {
    if (r.status == RegistrationStatus.rejected ||
        r.status == RegistrationStatus.withdrawn) {
      continue;
    }
    for (final player in r.squad) {
      counts[player] = (counts[player] ?? 0) + 1;
    }
  }
  return {
    for (final entry in counts.entries)
      if (entry.value > 1) entry.key,
  };
}
