/// PRD §6.12: "order status tracker (Collecting sizes → Ordered →
/// Arrived → Distributed)."
enum JerseyOrderStatus { collectingSizes, ordered, arrived, distributed }

const List<JerseyOrderStatus> jerseyOrderStatusSequence = [
  JerseyOrderStatus.collectingSizes,
  JerseyOrderStatus.ordered,
  JerseyOrderStatus.arrived,
  JerseyOrderStatus.distributed,
];

const Map<JerseyOrderStatus, String> jerseyOrderStatusLabels = {
  JerseyOrderStatus.collectingSizes: 'Collecting sizes',
  JerseyOrderStatus.ordered: 'Ordered',
  JerseyOrderStatus.arrived: 'Arrived',
  JerseyOrderStatus.distributed: 'Distributed',
};

/// PRD §6.12: "members submit size/name/number; conflicts on number
/// flagged with claim-by-seniority suggestion." [joinedAt] is what
/// seniority is judged by -- no real team-membership-history backend
/// exists yet, so it's a plain mock field on the submission itself
/// rather than a cross-referenced roster lookup.
class JerseySizeSubmission {
  final String memberName;
  final String size;
  final String nameOnJersey;
  final int? number;
  final DateTime joinedAt;

  const JerseySizeSubmission({
    required this.memberName,
    required this.size,
    required this.nameOnJersey,
    required this.number,
    required this.joinedAt,
  });

  JerseySizeSubmission copyWith({int? number, bool clearNumber = false}) {
    return JerseySizeSubmission(
      memberName: memberName,
      size: size,
      nameOnJersey: nameOnJersey,
      number: clearNumber ? null : (number ?? this.number),
      joinedAt: joinedAt,
    );
  }
}

/// Mock data for the debug demo and tests -- no backend jersey-board
/// service exists yet.
List<JerseySizeSubmission> mockJerseySubmissions() => [
  JerseySizeSubmission(
    memberName: 'Arjun Rao',
    size: 'L',
    nameOnJersey: 'RAO',
    number: 7,
    joinedAt: DateTime(2023, 1, 1),
  ),
  JerseySizeSubmission(
    memberName: 'Priya Nair',
    size: 'M',
    nameOnJersey: 'NAIR',
    number: 10,
    joinedAt: DateTime(2023, 6, 1),
  ),
  JerseySizeSubmission(
    memberName: 'Kabir Singh',
    size: 'XL',
    nameOnJersey: 'SINGH',
    number: 7,
    joinedAt: DateTime(2024, 3, 1),
  ),
];
