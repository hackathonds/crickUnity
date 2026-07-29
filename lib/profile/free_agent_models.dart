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

  Map<String, dynamic> toJson() => {
    'isFreeAgent': isFreeAgent,
    'availableDays': [for (final d in availableDays) d.name],
    'rolesOffered': [for (final r in rolesOffered) r.name],
  };

  factory FreeAgentProfile.fromJson(Map<String, dynamic> json) {
    return FreeAgentProfile(
      isFreeAgent: json['isFreeAgent'] as bool? ?? false,
      availableDays: {
        for (final d in json['availableDays'] as List)
          Weekday.values.byName(d as String),
      },
      rolesOffered: {
        for (final r in json['rolesOffered'] as List)
          PrimaryRole.values.byName(r as String),
      },
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

  Map<String, dynamic> toJson() => {
    'tournamentName': tournamentName,
    'basePriceRupees': basePriceRupees,
    'registeredAt': registeredAt.toIso8601String(),
  };

  factory AuctionPoolRegistration.fromJson(Map<String, dynamic> json) {
    return AuctionPoolRegistration(
      tournamentName: json['tournamentName'] as String,
      basePriceRupees: json['basePriceRupees'] as int,
      registeredAt: DateTime.parse(json['registeredAt'] as String),
    );
  }
}
