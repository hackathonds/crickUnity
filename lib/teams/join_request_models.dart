import '../profile/trust_sportsmanship_models.dart';

/// PRD §6.4: "Requests (for Request-policy teams): requester's card
/// shows stats, Trust band, mutuals; Captain/VC Approve/Deny; deny
/// optionally with canned reasons; auto-expire 14d."
const int joinRequestExpiryDays = 14;

/// A representative slice of career stats for the request card -- not
/// the full `ProfileHeaderStats` (matches/rating/verified aren't named
/// in this card's spec, just "stats").
class RequesterStatsSummary {
  final int matches;
  final int runs;
  final int wickets;

  const RequesterStatsSummary({
    required this.matches,
    required this.runs,
    required this.wickets,
  });

  Map<String, dynamic> toJson() => {
    'matches': matches,
    'runs': runs,
    'wickets': wickets,
  };

  factory RequesterStatsSummary.fromJson(Map<String, dynamic> json) {
    return RequesterStatsSummary(
      matches: json['matches'] as int,
      runs: json['runs'] as int,
      wickets: json['wickets'] as int,
    );
  }
}

/// PRD §6.4's business rule: "joining a *direct rival in same active
/// tournament* requires organizer visibility flag." No Tournament
/// module exists yet in this codebase (a separate future epic), so
/// there's no real rival/tournament matching to run -- [isRivalInSameTournament]
/// is a plain caller-supplied flag standing in for that check, not a
/// computed one.
class JoinRequest {
  final String id;
  final String requesterName;
  final RequesterStatsSummary stats;
  final TrustBand trustBand;
  final int mutualsCount;
  final DateTime requestedAt;
  final bool isRivalInSameTournament;

  const JoinRequest({
    required this.id,
    required this.requesterName,
    required this.stats,
    required this.trustBand,
    required this.mutualsCount,
    required this.requestedAt,
    this.isRivalInSameTournament = false,
  });

  bool isExpired({DateTime Function() now = DateTime.now}) =>
      now().difference(requestedAt).inDays >= joinRequestExpiryDays;

  Map<String, dynamic> toJson() => {
    'id': id,
    'requesterName': requesterName,
    'stats': stats.toJson(),
    'trustBand': trustBand.name,
    'mutualsCount': mutualsCount,
    'requestedAt': requestedAt.toIso8601String(),
    'isRivalInSameTournament': isRivalInSameTournament,
  };

  factory JoinRequest.fromJson(Map<String, dynamic> json) {
    return JoinRequest(
      id: json['id'] as String,
      requesterName: json['requesterName'] as String,
      stats: RequesterStatsSummary.fromJson(
        json['stats'] as Map<String, dynamic>,
      ),
      trustBand: TrustBand.values.byName(json['trustBand'] as String),
      mutualsCount: json['mutualsCount'] as int,
      requestedAt: DateTime.parse(json['requestedAt'] as String),
      isRivalInSameTournament:
          json['isRivalInSameTournament'] as bool? ?? false,
    );
  }
}

/// PRD: "deny optionally with canned reasons" -- a fixed convenience
/// list, not an exhaustive/enforced set (a free-text reason is still
/// allowed by the deny flow).
const List<String> cannedDenyReasons = [
  'Squad is full',
  'Looking for a different role',
  'Not a good fit right now',
];

/// Mock data for the debug demo and tests -- no backend join-request
/// queue exists yet.
List<JoinRequest> mockJoinRequests({DateTime Function() now = DateTime.now}) {
  final today = now();
  return [
    JoinRequest(
      id: 'jr-1',
      requesterName: 'Vikram Shah',
      stats: const RequesterStatsSummary(matches: 28, runs: 640, wickets: 12),
      trustBand: TrustBand.reliable,
      mutualsCount: 3,
      requestedAt: today.subtract(const Duration(days: 2)),
    ),
    JoinRequest(
      id: 'jr-2',
      requesterName: 'Farhan Ali',
      stats: const RequesterStatsSummary(matches: 5, runs: 90, wickets: 1),
      trustBand: TrustBand.building,
      mutualsCount: 0,
      requestedAt: today.subtract(const Duration(days: 10)),
      isRivalInSameTournament: true,
    ),
  ];
}
