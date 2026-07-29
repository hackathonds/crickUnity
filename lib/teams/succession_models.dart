/// PRD §2.3/2.4/2.9 + team edge cases (§6): captaincy/ownership
/// succession rules. A person can hold Captain, Vice-Captain, and Owner
/// simultaneously (the same account often founds and captains a team),
/// so roles here are independent booleans derived from comparing a
/// viewer's name against [SuccessionState]'s captainName/
/// viceCaptainName/ownerName -- not the single-value `TeamMemberRole`
/// enum used elsewhere, which assumes one role per member.
class ElevationRecord {
  final String matchLabel;
  final String viceCaptainName;
  final DateTime elevatedAt;

  const ElevationRecord({
    required this.matchLabel,
    required this.viceCaptainName,
    required this.elevatedAt,
  });

  Map<String, dynamic> toJson() => {
    'matchLabel': matchLabel,
    'viceCaptainName': viceCaptainName,
    'elevatedAt': elevatedAt.toIso8601String(),
  };

  factory ElevationRecord.fromJson(Map<String, dynamic> json) {
    return ElevationRecord(
      matchLabel: json['matchLabel'] as String,
      viceCaptainName: json['viceCaptainName'] as String,
      elevatedAt: DateTime.parse(json['elevatedAt'] as String),
    );
  }
}

/// PRD §2.9: "transfer team ownership (7-day cooling period, notified
/// to all members)."
const int ownershipCoolingPeriodDays = 7;

class OwnershipTransfer {
  final String newOwnerName;
  final DateTime initiatedAt;

  const OwnershipTransfer({
    required this.newOwnerName,
    required this.initiatedAt,
  });

  DateTime get coolingEndsAt =>
      initiatedAt.add(const Duration(days: ownershipCoolingPeriodDays));

  bool isCoolingComplete({DateTime Function() now = DateTime.now}) =>
      !now().isBefore(coolingEndsAt);

  Map<String, dynamic> toJson() => {
    'newOwnerName': newOwnerName,
    'initiatedAt': initiatedAt.toIso8601String(),
  };

  factory OwnershipTransfer.fromJson(Map<String, dynamic> json) {
    return OwnershipTransfer(
      newOwnerName: json['newOwnerName'] as String,
      initiatedAt: DateTime.parse(json['initiatedAt'] as String),
    );
  }
}

/// PRD §2.9: "If an Owner account is inactive 180 days, Captain can
/// petition ownership transfer; petition notifies Owner across
/// channels with 30-day response window." PRD does not say what
/// happens if the 30-day window elapses with no Owner response --
/// flagged here rather than guessed; [isResponseWindowExpired] is
/// exposed so the screen can surface that as an open state without
/// this model inventing an auto-transfer outcome PRD never specifies.
const int ownerInactivityThresholdDays = 180;
const int inactivityPetitionResponseDays = 30;

class InactivityPetition {
  final DateTime initiatedAt;

  const InactivityPetition({required this.initiatedAt});

  DateTime get responseDeadline =>
      initiatedAt.add(const Duration(days: inactivityPetitionResponseDays));

  bool isResponseWindowExpired({DateTime Function() now = DateTime.now}) =>
      now().isAfter(responseDeadline);

  Map<String, dynamic> toJson() => {
    'initiatedAt': initiatedAt.toIso8601String(),
  };

  factory InactivityPetition.fromJson(Map<String, dynamic> json) {
    return InactivityPetition(
      initiatedAt: DateTime.parse(json['initiatedAt'] as String),
    );
  }
}
