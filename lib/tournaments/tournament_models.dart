/// PRD §8.1 (Creation): "Wizard: Identity (name, logo, banner, city,
/// dates) -> Format (league/groups+knockout/pure knockout; overs; ball;
/// players/side; squad size caps) -> Rules (points scheme editable:
/// win/tie/NR/bonus; tie-breakers ordered list: points->H2H->NRR->toss
/// of coin; over-rate penalties on/off; transfer window) -> Money
/// (entry fee, prize structure, umpire/scorer provisioning: organizer-
/// paid vs per-match split) -> Registration (open/invite; team cap;
/// docs required; deadline) -> Publish (Draft->Published; edits
/// post-publish are versioned & notify registrants)."
///
/// Edge cases (PRD §8, "Edge cases" paragraph): "Rain-abandoned finals
/// -> organizer chooses per pre-declared rule (shared trophy / reserve
/// day / league-position winner) -- rule must be set at creation, shown
/// at registration. Team withdrawal mid-league -> past results stand or
/// void per pre-declared rule." Backlog: "all rule declarations incl.
/// tie-breakers order + rain-final rule mandatory at creation." Both
/// pre-declared rules are therefore required fields on the wizard, not
/// optional/defaulted -- publish is blocked until both are chosen.
/// Organizer-abandonment (14d inactivity) is an operational Admin path,
/// not a creation-time rule, so it is out of this story's scope.
library;

enum TournamentFormat { league, groupsPlusKnockout, knockout }

const Map<TournamentFormat, String> tournamentFormatLabels = {
  TournamentFormat.league: 'League',
  TournamentFormat.groupsPlusKnockout: 'Groups + knockout',
  TournamentFormat.knockout: 'Pure knockout',
};

enum TournamentBallType { leather, tennis }

const Map<TournamentBallType, String> tournamentBallTypeLabels = {
  TournamentBallType.leather: 'Leather',
  TournamentBallType.tennis: 'Tennis',
};

enum TieBreaker { points, headToHead, nrr, tossOfCoin }

const Map<TieBreaker, String> tieBreakerLabels = {
  TieBreaker.points: 'Points',
  TieBreaker.headToHead: 'Head-to-head',
  TieBreaker.nrr: 'NRR',
  TieBreaker.tossOfCoin: 'Toss of coin',
};

/// PRD's own worked order -- the wizard's starting default, reorderable.
const List<TieBreaker> defaultTieBreakerOrder = [
  TieBreaker.points,
  TieBreaker.headToHead,
  TieBreaker.nrr,
  TieBreaker.tossOfCoin,
];

enum RainFinalRule { sharedTrophy, reserveDay, leaguePositionWinner }

const Map<RainFinalRule, String> rainFinalRuleLabels = {
  RainFinalRule.sharedTrophy: 'Shared trophy',
  RainFinalRule.reserveDay: 'Reserve day',
  RainFinalRule.leaguePositionWinner: 'League-position winner',
};

enum WithdrawalRule { pastResultsStand, pastResultsVoid }

const Map<WithdrawalRule, String> withdrawalRuleLabels = {
  WithdrawalRule.pastResultsStand: 'Past results stand',
  WithdrawalRule.pastResultsVoid: 'Past results void',
};

enum OfficialsProvisioning { organizerPaid, perMatchSplit }

const Map<OfficialsProvisioning, String> officialsProvisioningLabels = {
  OfficialsProvisioning.organizerPaid: 'Organizer-paid',
  OfficialsProvisioning.perMatchSplit: 'Per-match split',
};

enum RegistrationMode { open, inviteOnly }

const Map<RegistrationMode, String> registrationModeLabels = {
  RegistrationMode.open: 'Open',
  RegistrationMode.inviteOnly: 'Invite-only',
};

/// Backlog cites "G.13" for the registration forms checklist -- no
/// Appendix G exists anywhere in the frozen PRD (only Appendix A
/// "Acceptance Criteria Pattern" and B "Cross-Module Interaction Map"
/// actually exist, confirmed by grepping every `^# Appendix` heading).
/// A curated, real-tournament-domain checklist stands in, same
/// flagged-bigger-gap convention as record_models.dart's category list
/// (E8-02).
const List<String> commonRegistrationDocs = [
  'Signed team roster',
  'Player ID proof',
  'Medical fitness undertaking',
  'Guardian consent (minor players)',
];

enum TournamentStatus { draft, published }

class PointsScheme {
  final int winPoints;
  final int tiePoints;
  final int noResultPoints;
  final bool bonusPointEnabled;

  const PointsScheme({
    this.winPoints = 2,
    this.tiePoints = 1,
    this.noResultPoints = 1,
    this.bonusPointEnabled = false,
  });

  PointsScheme copyWith({
    int? winPoints,
    int? tiePoints,
    int? noResultPoints,
    bool? bonusPointEnabled,
  }) {
    return PointsScheme(
      winPoints: winPoints ?? this.winPoints,
      tiePoints: tiePoints ?? this.tiePoints,
      noResultPoints: noResultPoints ?? this.noResultPoints,
      bonusPointEnabled: bonusPointEnabled ?? this.bonusPointEnabled,
    );
  }
}

/// One class serves both the in-progress wizard draft and the
/// published record -- [status] and [publishedVersion] distinguish
/// them, avoiding a parallel draft/published type pair for what is
/// otherwise identical data.
class Tournament {
  final String id;
  final TournamentStatus status;
  final int publishedVersion;

  // Identity
  final String name;
  final String city;
  final DateTime? startDate;
  final DateTime? endDate;

  // Format
  final TournamentFormat format;
  final int overs;
  final TournamentBallType ballType;
  final int playersPerSide;
  final int squadCapMin;
  final int squadCapMax;

  // Rules
  final PointsScheme pointsScheme;
  final List<TieBreaker> tieBreakerOrder;
  final bool overRatePenaltiesEnabled;
  final bool transferWindowEnabled;
  final RainFinalRule? rainFinalRule;
  final WithdrawalRule? withdrawalRule;

  // Money
  final int entryFee;
  final String prizeStructureNote;
  final OfficialsProvisioning officialsProvisioning;

  // Registration
  final RegistrationMode registrationMode;
  final int teamCap;
  final String docsRequiredNote;
  final DateTime? registrationDeadline;

  /// PRD §8.2: "pays entry fee into tournament wallet (escrow)."
  /// Running total of approved teams' entry fees -- no real payment
  /// gateway exists (flagged, same convention as other missing-
  /// payment-infra gaps this session), so approval just credits this
  /// counter.
  final int escrowedAmount;

  /// PRD §8 edge cases: "Organizer abandonment (inactive 14d mid-
  /// event) -> Admin intervention path visible to captains." Updated
  /// whenever the organizer takes a genuine action on this tournament
  /// (publish, fixture edit, result recorded, payout awarded, ...);
  /// defaults to publish time.
  final DateTime? organizerLastActiveAt;

  const Tournament({
    required this.id,
    this.status = TournamentStatus.draft,
    this.publishedVersion = 0,
    this.name = '',
    this.city = '',
    this.startDate,
    this.endDate,
    this.format = TournamentFormat.league,
    this.overs = 20,
    this.ballType = TournamentBallType.leather,
    this.playersPerSide = 11,
    this.squadCapMin = 11,
    this.squadCapMax = 16,
    this.pointsScheme = const PointsScheme(),
    this.tieBreakerOrder = defaultTieBreakerOrder,
    this.overRatePenaltiesEnabled = false,
    this.transferWindowEnabled = false,
    this.rainFinalRule,
    this.withdrawalRule,
    this.entryFee = 0,
    this.prizeStructureNote = '',
    this.officialsProvisioning = OfficialsProvisioning.organizerPaid,
    this.registrationMode = RegistrationMode.open,
    this.teamCap = 8,
    this.docsRequiredNote = '',
    this.registrationDeadline,
    this.escrowedAmount = 0,
    this.organizerLastActiveAt,
  });

  /// Backlog: rain-final + tie-breaker rules are "mandatory at
  /// creation." Withdrawal rule is the edge-case paragraph's other
  /// pre-declared rule, held to the same bar.
  bool get canPublish =>
      name.trim().isNotEmpty &&
      startDate != null &&
      endDate != null &&
      tieBreakerOrder.length == TieBreaker.values.length &&
      rainFinalRule != null &&
      withdrawalRule != null;

  /// PRD names the exact 14-day window (not a judgment call).
  bool isOrganizerInactive(DateTime now) =>
      organizerLastActiveAt != null &&
      now.difference(organizerLastActiveAt!) > const Duration(days: 14);

  Tournament copyWith({
    TournamentStatus? status,
    int? publishedVersion,
    String? name,
    String? city,
    DateTime? startDate,
    DateTime? endDate,
    TournamentFormat? format,
    int? overs,
    TournamentBallType? ballType,
    int? playersPerSide,
    int? squadCapMin,
    int? squadCapMax,
    PointsScheme? pointsScheme,
    List<TieBreaker>? tieBreakerOrder,
    bool? overRatePenaltiesEnabled,
    bool? transferWindowEnabled,
    RainFinalRule? rainFinalRule,
    WithdrawalRule? withdrawalRule,
    int? entryFee,
    String? prizeStructureNote,
    OfficialsProvisioning? officialsProvisioning,
    RegistrationMode? registrationMode,
    int? teamCap,
    String? docsRequiredNote,
    DateTime? registrationDeadline,
    int? escrowedAmount,
    DateTime? organizerLastActiveAt,
  }) {
    return Tournament(
      id: id,
      status: status ?? this.status,
      publishedVersion: publishedVersion ?? this.publishedVersion,
      name: name ?? this.name,
      city: city ?? this.city,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      format: format ?? this.format,
      overs: overs ?? this.overs,
      ballType: ballType ?? this.ballType,
      playersPerSide: playersPerSide ?? this.playersPerSide,
      squadCapMin: squadCapMin ?? this.squadCapMin,
      squadCapMax: squadCapMax ?? this.squadCapMax,
      pointsScheme: pointsScheme ?? this.pointsScheme,
      tieBreakerOrder: tieBreakerOrder ?? this.tieBreakerOrder,
      overRatePenaltiesEnabled:
          overRatePenaltiesEnabled ?? this.overRatePenaltiesEnabled,
      transferWindowEnabled:
          transferWindowEnabled ?? this.transferWindowEnabled,
      rainFinalRule: rainFinalRule ?? this.rainFinalRule,
      withdrawalRule: withdrawalRule ?? this.withdrawalRule,
      entryFee: entryFee ?? this.entryFee,
      prizeStructureNote: prizeStructureNote ?? this.prizeStructureNote,
      officialsProvisioning:
          officialsProvisioning ?? this.officialsProvisioning,
      registrationMode: registrationMode ?? this.registrationMode,
      teamCap: teamCap ?? this.teamCap,
      docsRequiredNote: docsRequiredNote ?? this.docsRequiredNote,
      registrationDeadline: registrationDeadline ?? this.registrationDeadline,
      escrowedAmount: escrowedAmount ?? this.escrowedAmount,
      organizerLastActiveAt:
          organizerLastActiveAt ?? this.organizerLastActiveAt,
    );
  }
}
