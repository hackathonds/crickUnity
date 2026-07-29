/// PRD §9 (Club Module): "Club Dashboard (Owner/Admins): headline
/// tiles -- active members, teams, this-month revenue vs dues
/// outstanding, upcoming events, pending join requests; recent
/// activity stream across all club teams. Members: directory with
/// tier chips (Playing/Social/Junior/Honorary), join dates, dues
/// status (green/amber/red), roles ... Teams: teams under the banner;
/// create/link/unlink (linking requires that team Owner's acceptance)
/// ... inter-team friendly scheduler ... Membership & Subscriptions:
/// tier definitions (price, cadence, benefits list); renewal reminders
/// (7d/1d), grace period (owner-set), lapse state (benefits pause,
/// never data deletion) ... Recognition: Wall of Fame (curated)..."
///
/// Backlog E11-01's line narrows this to 4 sub-features: members/dues
/// grid, tiers/subscriptions/grace, inter-team scheduler, wall of
/// fame. The rest of §9 (grounds booking integration, revenue
/// dashboards, sponsor cascade, announcements/events, Clubman of the
/// Month, long-service badges, treasury) is out of this story's line
/// and not built here -- flagged rather than silently scoped in.
///
/// Team linking normally "requires that team Owner's acceptance" (a
/// multi-party flow) -- no second-account acceptance system exists
/// (same flagged convention as every other cross-party flow this
/// session), so linked teams are simple named entries the club owner
/// manages directly.
library;

enum MembershipTierType { playing, social, junior, honorary }

const Map<MembershipTierType, String> membershipTierTypeLabels = {
  MembershipTierType.playing: 'Playing',
  MembershipTierType.social: 'Social',
  MembershipTierType.junior: 'Junior',
  MembershipTierType.honorary: 'Honorary',
};

enum DuesStatus { green, amber, red }

const Map<DuesStatus, String> duesStatusLabels = {
  DuesStatus.green: 'Paid',
  DuesStatus.amber: 'Due soon',
  DuesStatus.red: 'Overdue',
};

enum ClubRole { member, treasurer, admin, owner }

const Map<ClubRole, String> clubRoleLabels = {
  ClubRole.member: 'Member',
  ClubRole.treasurer: 'Treasurer',
  ClubRole.admin: 'Admin',
  ClubRole.owner: 'Owner',
};

class ClubMember {
  final String id;
  final String name;
  final MembershipTierType tier;
  final DuesStatus duesStatus;
  final ClubRole role;
  final DateTime joinDate;

  const ClubMember({
    required this.id,
    required this.name,
    required this.tier,
    required this.duesStatus,
    this.role = ClubRole.member,
    required this.joinDate,
  });

  ClubMember copyWith({
    DuesStatus? duesStatus,
    ClubRole? role,
    MembershipTierType? tier,
  }) {
    return ClubMember(
      id: id,
      name: name,
      tier: tier ?? this.tier,
      duesStatus: duesStatus ?? this.duesStatus,
      role: role ?? this.role,
      joinDate: joinDate,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'tier': tier.name,
    'duesStatus': duesStatus.name,
    'role': role.name,
    'joinDate': joinDate.toIso8601String(),
  };

  factory ClubMember.fromJson(Map<String, dynamic> json) {
    return ClubMember(
      id: json['id'] as String,
      name: json['name'] as String,
      tier: MembershipTierType.values.byName(json['tier'] as String),
      duesStatus: DuesStatus.values.byName(json['duesStatus'] as String),
      role: ClubRole.values.byName(json['role'] as String),
      joinDate: DateTime.parse(json['joinDate'] as String),
    );
  }
}

enum SubscriptionCadence { monthly, yearly }

const Map<SubscriptionCadence, String> subscriptionCadenceLabels = {
  SubscriptionCadence.monthly: 'Monthly',
  SubscriptionCadence.yearly: 'Yearly',
};

/// PRD: "tier definitions (price, cadence, benefits list) ... grace
/// period (owner-set)."
class MembershipTierDefinition {
  final MembershipTierType type;
  final int price;
  final SubscriptionCadence cadence;
  final List<String> benefits;
  final int gracePeriodDays;

  const MembershipTierDefinition({
    required this.type,
    required this.price,
    required this.cadence,
    this.benefits = const [],
    this.gracePeriodDays = 7,
  });

  MembershipTierDefinition copyWith({
    int? price,
    SubscriptionCadence? cadence,
    List<String>? benefits,
    int? gracePeriodDays,
  }) {
    return MembershipTierDefinition(
      type: type,
      price: price ?? this.price,
      cadence: cadence ?? this.cadence,
      benefits: benefits ?? this.benefits,
      gracePeriodDays: gracePeriodDays ?? this.gracePeriodDays,
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'price': price,
    'cadence': cadence.name,
    'benefits': benefits,
    'gracePeriodDays': gracePeriodDays,
  };

  factory MembershipTierDefinition.fromJson(Map<String, dynamic> json) {
    return MembershipTierDefinition(
      type: MembershipTierType.values.byName(json['type'] as String),
      price: json['price'] as int,
      cadence: SubscriptionCadence.values.byName(json['cadence'] as String),
      benefits: [for (final b in json['benefits'] as List) b as String],
      gracePeriodDays: json['gracePeriodDays'] as int? ?? 7,
    );
  }
}

class InterTeamFriendly {
  final String id;
  final String teamAName;
  final String teamBName;
  final DateTime date;
  final String venueNote;

  const InterTeamFriendly({
    required this.id,
    required this.teamAName,
    required this.teamBName,
    required this.date,
    this.venueNote = '',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'teamAName': teamAName,
    'teamBName': teamBName,
    'date': date.toIso8601String(),
    'venueNote': venueNote,
  };

  factory InterTeamFriendly.fromJson(Map<String, dynamic> json) {
    return InterTeamFriendly(
      id: json['id'] as String,
      teamAName: json['teamAName'] as String,
      teamBName: json['teamBName'] as String,
      date: DateTime.parse(json['date'] as String),
      venueNote: json['venueNote'] as String? ?? '',
    );
  }
}

class WallOfFameEntry {
  final String id;
  final String memberName;
  final String citation;
  final DateTime addedAt;

  const WallOfFameEntry({
    required this.id,
    required this.memberName,
    required this.citation,
    required this.addedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'memberName': memberName,
    'citation': citation,
    'addedAt': addedAt.toIso8601String(),
  };

  factory WallOfFameEntry.fromJson(Map<String, dynamic> json) {
    return WallOfFameEntry(
      id: json['id'] as String,
      memberName: json['memberName'] as String,
      citation: json['citation'] as String,
      addedAt: DateTime.parse(json['addedAt'] as String),
    );
  }
}

class Club {
  final String id;
  final String name;
  final String ownerName;
  final List<String> linkedTeamNames;
  final int upcomingEventsCount;
  final int pendingJoinRequests;

  /// Backlog addendum (PRD §2.13): "club treasury (separate from team
  /// treasuries; inter-wallet transfers require both treasurers'
  /// confirmation)."
  final int treasuryBalance;

  /// AC amendment #2 (PRD §9): "linking requires that team Owner's
  /// acceptance; club-branded surfaces on linked teams" -- a team in
  /// [linkedTeamNames] but not in this set is a pending link: it shows
  /// up in the club's own Teams list, but the team's public page
  /// renders no club branding until its owner accepts.
  final Set<String> ownerAcceptedTeamNames;

  const Club({
    required this.id,
    required this.name,
    required this.ownerName,
    this.linkedTeamNames = const [],
    this.upcomingEventsCount = 0,
    this.pendingJoinRequests = 0,
    this.treasuryBalance = 0,
    this.ownerAcceptedTeamNames = const {},
  });

  Club copyWith({
    int? treasuryBalance,
    Set<String>? ownerAcceptedTeamNames,
    List<String>? linkedTeamNames,
  }) {
    return Club(
      id: id,
      name: name,
      ownerName: ownerName,
      linkedTeamNames: linkedTeamNames ?? this.linkedTeamNames,
      upcomingEventsCount: upcomingEventsCount,
      pendingJoinRequests: pendingJoinRequests,
      treasuryBalance: treasuryBalance ?? this.treasuryBalance,
      ownerAcceptedTeamNames:
          ownerAcceptedTeamNames ?? this.ownerAcceptedTeamNames,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'ownerName': ownerName,
    'linkedTeamNames': linkedTeamNames,
    'upcomingEventsCount': upcomingEventsCount,
    'pendingJoinRequests': pendingJoinRequests,
    'treasuryBalance': treasuryBalance,
    'ownerAcceptedTeamNames': ownerAcceptedTeamNames.toList(),
  };

  factory Club.fromJson(Map<String, dynamic> json) {
    return Club(
      id: json['id'] as String,
      name: json['name'] as String,
      ownerName: json['ownerName'] as String,
      linkedTeamNames: [
        for (final n in json['linkedTeamNames'] as List) n as String,
      ],
      upcomingEventsCount: json['upcomingEventsCount'] as int? ?? 0,
      pendingJoinRequests: json['pendingJoinRequests'] as int? ?? 0,
      treasuryBalance: json['treasuryBalance'] as int? ?? 0,
      ownerAcceptedTeamNames: {
        for (final n in json['ownerAcceptedTeamNames'] as List) n as String,
      },
    );
  }
}

enum TransferDirection { clubToTeam, teamToClub }

/// PRD §2.13: "inter-wallet transfers between club and team treasuries
/// require both treasurers' confirmation." No multi-account system
/// exists to seat a distinct team-treasurer identity separate from the
/// club treasurer (same flagged convention as every other cross-party
/// flow this session) -- both confirmations are recorded, but from the
/// same single account.
class InterWalletTransferRequest {
  final String id;
  final TransferDirection direction;
  final String teamName;
  final int amount;
  final bool clubTreasurerConfirmed;
  final bool teamTreasurerConfirmed;
  final bool completed;

  const InterWalletTransferRequest({
    required this.id,
    required this.direction,
    required this.teamName,
    required this.amount,
    this.clubTreasurerConfirmed = false,
    this.teamTreasurerConfirmed = false,
    this.completed = false,
  });

  bool get bothConfirmed => clubTreasurerConfirmed && teamTreasurerConfirmed;

  InterWalletTransferRequest copyWith({
    bool? clubTreasurerConfirmed,
    bool? teamTreasurerConfirmed,
    bool? completed,
  }) {
    return InterWalletTransferRequest(
      id: id,
      direction: direction,
      teamName: teamName,
      amount: amount,
      clubTreasurerConfirmed:
          clubTreasurerConfirmed ?? this.clubTreasurerConfirmed,
      teamTreasurerConfirmed:
          teamTreasurerConfirmed ?? this.teamTreasurerConfirmed,
      completed: completed ?? this.completed,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'direction': direction.name,
    'teamName': teamName,
    'amount': amount,
    'clubTreasurerConfirmed': clubTreasurerConfirmed,
    'teamTreasurerConfirmed': teamTreasurerConfirmed,
    'completed': completed,
  };

  factory InterWalletTransferRequest.fromJson(Map<String, dynamic> json) {
    return InterWalletTransferRequest(
      id: json['id'] as String,
      direction: TransferDirection.values.byName(json['direction'] as String),
      teamName: json['teamName'] as String,
      amount: json['amount'] as int,
      clubTreasurerConfirmed: json['clubTreasurerConfirmed'] as bool? ?? false,
      teamTreasurerConfirmed: json['teamTreasurerConfirmed'] as bool? ?? false,
      completed: json['completed'] as bool? ?? false,
    );
  }
}
