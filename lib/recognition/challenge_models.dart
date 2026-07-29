/// PRD §13.3/§14: "Challenges: monthly global ('October: 200 runs'),
/// club challenges, friend head-to-head (stake optional: winner takes
/// both entry-coin stakes; capped 50 coins to keep friendly) ...
/// Monthly global (join -> progress bar -> finisher badge), Club
/// Challenges (club-scoped, club leaderboard), Friend Challenges (1:1,
/// same-metric, live head-to-head bar in both homes, trash-talk
/// quick-chat stickers, result card auto-drafted)."
enum ChallengeType { monthlyGlobal, club, friendH2H }

const Map<ChallengeType, String> challengeTypeLabels = {
  ChallengeType.monthlyGlobal: 'Monthly Global',
  ChallengeType.club: 'Club',
  ChallengeType.friendH2H: 'Friend H2H',
};

const int maxChallengeStakeCoins = 50;

/// "trash-talk quick-chat stickers" -- no real sticker asset library
/// exists (same gap flagged in messaging/chat_models.dart's cricket
/// sticker packs), a small mock label set stands in.
const List<String> challengeQuickChatStickers = [
  "Bring it on!",
  'Too easy 😎',
  'Not today!',
  'GG either way',
];

class ChallengeParticipant {
  final String name;
  final int progress;
  final bool claimed;

  const ChallengeParticipant({
    required this.name,
    this.progress = 0,
    this.claimed = false,
  });

  ChallengeParticipant copyWith({int? progress, bool? claimed}) {
    return ChallengeParticipant(
      name: name,
      progress: progress ?? this.progress,
      claimed: claimed ?? this.claimed,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'progress': progress,
    'claimed': claimed,
  };

  factory ChallengeParticipant.fromJson(Map<String, dynamic> json) {
    return ChallengeParticipant(
      name: json['name'] as String,
      progress: json['progress'] as int? ?? 0,
      claimed: json['claimed'] as bool? ?? false,
    );
  }
}

class Challenge {
  final String id;
  final ChallengeType type;
  final String title;
  final String metricLabel;
  final int target;
  final List<ChallengeParticipant> participants;
  final int? stakeCoins;
  final DateTime endsAt;
  final String? lastLeaderName;

  const Challenge({
    required this.id,
    required this.type,
    required this.title,
    required this.metricLabel,
    required this.target,
    this.participants = const [],
    this.stakeCoins,
    required this.endsAt,
    this.lastLeaderName,
  });

  ChallengeParticipant? participantNamed(String name) {
    for (final p in participants) {
      if (p.name == name) return p;
    }
    return null;
  }

  ChallengeParticipant? get currentLeader {
    if (participants.isEmpty) return null;
    return participants.reduce((a, b) => a.progress >= b.progress ? a : b);
  }

  Challenge copyWith({
    List<ChallengeParticipant>? participants,
    String? lastLeaderName,
  }) {
    return Challenge(
      id: id,
      type: type,
      title: title,
      metricLabel: metricLabel,
      target: target,
      participants: participants ?? this.participants,
      stakeCoins: stakeCoins,
      endsAt: endsAt,
      lastLeaderName: lastLeaderName ?? this.lastLeaderName,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'title': title,
    'metricLabel': metricLabel,
    'target': target,
    'participants': [for (final p in participants) p.toJson()],
    'stakeCoins': stakeCoins,
    'endsAt': endsAt.toIso8601String(),
    'lastLeaderName': lastLeaderName,
  };

  factory Challenge.fromJson(Map<String, dynamic> json) {
    return Challenge(
      id: json['id'] as String,
      type: ChallengeType.values.byName(json['type'] as String),
      title: json['title'] as String,
      metricLabel: json['metricLabel'] as String,
      target: json['target'] as int,
      participants: [
        for (final p in json['participants'] as List)
          ChallengeParticipant.fromJson(p as Map<String, dynamic>),
      ],
      stakeCoins: json['stakeCoins'] as int?,
      endsAt: DateTime.parse(json['endsAt'] as String),
      lastLeaderName: json['lastLeaderName'] as String?,
    );
  }
}
