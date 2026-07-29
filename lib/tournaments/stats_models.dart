/// PRD §8.10-8.12 (Statistics/Awards/Leaderboards): "Tournament stat
/// hub: most runs (Orange list), most wickets (Purple list), best
/// SR/Econ (min qualifications organizer-set), best figures, team
/// stats. Awards page: auto-computed nominees; organizer confirms
/// winners at closing; awards mint to profiles with tournament
/// provenance. Leaderboards live-update; final versions freeze at
/// tournament close."
///
/// No ball-by-ball scoring pipeline ties into tournament fixtures yet
/// (same gap flagged for team-level results in standings_models.dart,
/// E10-04) -- per-player stats are entered directly by the organizer
/// per fixture, same "stand-in for a missing upstream trigger"
/// convention as elsewhere this session.
class PlayerTournamentStat {
  final String id;
  final String tournamentId;
  final String playerName;
  final String teamName;
  final int runs;
  final int ballsFaced;
  final int wickets;
  final int runsConceded;
  final double oversBowled;

  const PlayerTournamentStat({
    required this.id,
    required this.tournamentId,
    required this.playerName,
    required this.teamName,
    this.runs = 0,
    this.ballsFaced = 0,
    this.wickets = 0,
    this.runsConceded = 0,
    this.oversBowled = 0,
  });

  double get strikeRate => ballsFaced == 0 ? 0 : (runs / ballsFaced) * 100;
  double get economy => oversBowled == 0 ? 0 : runsConceded / oversBowled;

  Map<String, dynamic> toJson() => {
    'id': id,
    'tournamentId': tournamentId,
    'playerName': playerName,
    'teamName': teamName,
    'runs': runs,
    'ballsFaced': ballsFaced,
    'wickets': wickets,
    'runsConceded': runsConceded,
    'oversBowled': oversBowled,
  };

  factory PlayerTournamentStat.fromJson(Map<String, dynamic> json) {
    return PlayerTournamentStat(
      id: json['id'] as String,
      tournamentId: json['tournamentId'] as String,
      playerName: json['playerName'] as String,
      teamName: json['teamName'] as String,
      runs: json['runs'] as int? ?? 0,
      ballsFaced: json['ballsFaced'] as int? ?? 0,
      wickets: json['wickets'] as int? ?? 0,
      runsConceded: json['runsConceded'] as int? ?? 0,
      oversBowled: (json['oversBowled'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// PRD: "min qualifications organizer-set" -- no default numbers are
/// given, so these start at 0 (no qualification) until the organizer
/// sets them.
class StatsQualification {
  final int minBallsFacedForStrikeRate;
  final int minOversBowledForEconomy;

  const StatsQualification({
    this.minBallsFacedForStrikeRate = 0,
    this.minOversBowledForEconomy = 0,
  });

  StatsQualification copyWith({
    int? minBallsFacedForStrikeRate,
    int? minOversBowledForEconomy,
  }) {
    return StatsQualification(
      minBallsFacedForStrikeRate:
          minBallsFacedForStrikeRate ?? this.minBallsFacedForStrikeRate,
      minOversBowledForEconomy:
          minOversBowledForEconomy ?? this.minOversBowledForEconomy,
    );
  }

  Map<String, dynamic> toJson() => {
    'minBallsFacedForStrikeRate': minBallsFacedForStrikeRate,
    'minOversBowledForEconomy': minOversBowledForEconomy,
  };

  factory StatsQualification.fromJson(Map<String, dynamic> json) {
    return StatsQualification(
      minBallsFacedForStrikeRate:
          json['minBallsFacedForStrikeRate'] as int? ?? 0,
      minOversBowledForEconomy: json['minOversBowledForEconomy'] as int? ?? 0,
    );
  }
}

enum AwardCategory {
  mostRuns,
  mostWickets,
  bestStrikeRate,
  bestEconomy,
  bestFigures,
  playerOfTheTournament,
}

const Map<AwardCategory, String> awardCategoryLabels = {
  AwardCategory.mostRuns: 'Most runs (Orange list)',
  AwardCategory.mostWickets: 'Most wickets (Purple list)',
  AwardCategory.bestStrikeRate: 'Best strike rate',
  AwardCategory.bestEconomy: 'Best economy',
  AwardCategory.bestFigures: 'Best figures',
  AwardCategory.playerOfTheTournament: 'Player of the Tournament',
};

/// PRD: "awards mint to profiles with tournament provenance." No
/// cross-module wire into the real Achievements/Badge wall
/// (recognition/achievements_provider.dart) exists for tournament
/// awards specifically -- flagged as a future integration; this
/// records the confirmed award with its provenance note, which is the
/// genuine part of this story's line.
class TournamentAward {
  final String id;
  final String tournamentId;
  final AwardCategory category;
  final String nomineeName;
  final bool confirmed;
  final DateTime? confirmedAt;

  const TournamentAward({
    required this.id,
    required this.tournamentId,
    required this.category,
    required this.nomineeName,
    this.confirmed = false,
    this.confirmedAt,
  });

  String get provenance => confirmed
      ? '${awardCategoryLabels[category]} -- confirmed for this tournament'
      : '${awardCategoryLabels[category]} -- nominee, unconfirmed';

  TournamentAward copyWith({bool? confirmed, DateTime? confirmedAt}) {
    return TournamentAward(
      id: id,
      tournamentId: tournamentId,
      category: category,
      nomineeName: nomineeName,
      confirmed: confirmed ?? this.confirmed,
      confirmedAt: confirmedAt ?? this.confirmedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'tournamentId': tournamentId,
    'category': category.name,
    'nomineeName': nomineeName,
    'confirmed': confirmed,
    'confirmedAt': confirmedAt?.toIso8601String(),
  };

  factory TournamentAward.fromJson(Map<String, dynamic> json) {
    return TournamentAward(
      id: json['id'] as String,
      tournamentId: json['tournamentId'] as String,
      category: AwardCategory.values.byName(json['category'] as String),
      nomineeName: json['nomineeName'] as String,
      confirmed: json['confirmed'] as bool? ?? false,
      confirmedAt: json['confirmedAt'] != null
          ? DateTime.parse(json['confirmedAt'] as String)
          : null,
    );
  }
}
