/// PRD §13.1: "Referral (referee plays 1st verified match): 100/100
/// coins/XP to referrer; referee gets 50/50." DS §11.14: "progress list
/// of referees with state chips (Joined -> First verified match = both
/// reward rows)."
enum ReferralStatus { joined, firstMatchVerified }

const Map<ReferralStatus, String> referralStatusLabels = {
  ReferralStatus.joined: 'Joined',
  ReferralStatus.firstMatchVerified: 'First verified match',
};

class ReferralEntry {
  final String id;
  final String name;
  final ReferralStatus status;
  final DateTime joinedAt;

  const ReferralEntry({
    required this.id,
    required this.name,
    required this.status,
    required this.joinedAt,
  });

  ReferralEntry copyWith({ReferralStatus? status}) {
    return ReferralEntry(
      id: id,
      name: name,
      status: status ?? this.status,
      joinedAt: joinedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'status': status.name,
    'joinedAt': joinedAt.toIso8601String(),
  };

  factory ReferralEntry.fromJson(Map<String, dynamic> json) {
    return ReferralEntry(
      id: json['id'] as String,
      name: json['name'] as String,
      status: ReferralStatus.values.byName(json['status'] as String),
      joinedAt: DateTime.parse(json['joinedAt'] as String),
    );
  }
}
