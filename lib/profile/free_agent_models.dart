import '../onboarding/profile_wizard_provider.dart';

/// PRD §2.2 empty state: "New player with 0 matches sees ... CTAs: Find
/// a team / Create a team / Join as a free agent." No day-of-week enum
/// exists anywhere in this codebase yet -- a small local one is defined
/// here rather than reused from elsewhere.
enum Weekday { monday, tuesday, wednesday, thursday, friday, saturday, sunday }

const Map<Weekday, String> weekdayLabels = {
  Weekday.monday: 'Mon',
  Weekday.tuesday: 'Tue',
  Weekday.wednesday: 'Wed',
  Weekday.thursday: 'Thu',
  Weekday.friday: 'Fri',
  Weekday.saturday: 'Sat',
  Weekday.sunday: 'Sun',
};

class FreeAgentProfile {
  final bool isFreeAgent;
  final Set<Weekday> availableDays;
  final Set<PrimaryRole> rolesOffered;

  const FreeAgentProfile({
    this.isFreeAgent = false,
    this.availableDays = const {},
    this.rolesOffered = const {},
  });

  FreeAgentProfile copyWith({
    bool? isFreeAgent,
    Set<Weekday>? availableDays,
    Set<PrimaryRole>? rolesOffered,
  }) {
    return FreeAgentProfile(
      isFreeAgent: isFreeAgent ?? this.isFreeAgent,
      availableDays: availableDays ?? this.availableDays,
      rolesOffered: rolesOffered ?? this.rolesOffered,
    );
  }
}

/// PRD §8.7 (Auction): "Optional player-auction mode: player pool
/// (registered free agents with base price) ... purse math enforced."
/// No Tournament/Auction module exists yet (Epic E8, not built) -- this
/// is a self-contained registration record, not a real integration with
/// an auction room, purse math, or organizer console.
class AuctionPoolRegistration {
  final String tournamentName;
  final int basePriceRupees;
  final DateTime registeredAt;

  const AuctionPoolRegistration({
    required this.tournamentName,
    required this.basePriceRupees,
    required this.registeredAt,
  });
}
