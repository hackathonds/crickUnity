import '../teams/availability_matrix_models.dart';

/// PRD §7.1: "Types: Friendly (my team vs opponent team / vs ad-hoc
/// 'guest team' created inline), Challenge (send/accept a challenge
/// card), Tournament fixture (organizer-generated; captains cannot
/// create)." Tournament fixtures are explicitly out of this story's
/// scope per the backlog ("Out: tournament fixtures").
enum MatchType { friendly, challenge }

const Map<MatchType, String> matchTypeLabels = {
  MatchType.friendly: 'Friendly',
  MatchType.challenge: 'Challenge',
};

/// PRD §7.1: "ball type (tennis/leather/other -- affects stat pools:
/// tennis and leather stats never merge)."
enum BallType { tennis, leather, other }

const Map<BallType, String> ballTypeLabels = {
  BallType.tennis: 'Tennis',
  BallType.leather: 'Leather',
  BallType.other: 'Other',
};

enum MatchVisibility { public, community, private }

const Map<MatchVisibility, String> matchVisibilityLabels = {
  MatchVisibility.public: 'Public',
  MatchVisibility.community: 'Community',
  MatchVisibility.private: 'Private',
};

/// PRD §7.1: "scorer assignment (self/member/hire from Gig Board)."
/// Gig Board is E14-01, a much later epic that doesn't exist yet --
/// [hireFromGigBoard] is selectable (so the picker itself is complete)
/// but resolves to no assignment, same "mock the missing piece, build
/// everything else" treatment used for every other cross-epic gap this
/// session.
enum ScorerAssignment { self, member, hireFromGigBoard }

const Map<ScorerAssignment, String> scorerAssignmentLabels = {
  ScorerAssignment.self: 'Score it myself',
  ScorerAssignment.member: 'Assign a team member',
  ScorerAssignment.hireFromGigBoard: 'Hire from Gig Board',
};

/// PRD §7.1: "format (overs, players/side, wide/no-ball rules preset
/// with editable sub-rules: rebowl on/off, runs per extra)."
class MatchFormat {
  final String label;
  final int oversPerSide;
  final int playersPerSide;

  const MatchFormat({
    required this.label,
    required this.oversPerSide,
    required this.playersPerSide,
  });

  Map<String, dynamic> toJson() => {
    'label': label,
    'oversPerSide': oversPerSide,
    'playersPerSide': playersPerSide,
  };

  factory MatchFormat.fromJson(Map<String, dynamic> json) {
    return MatchFormat(
      label: json['label'] as String,
      oversPerSide: json['oversPerSide'] as int,
      playersPerSide: json['playersPerSide'] as int,
    );
  }
}

const MatchFormat defaultMatchFormat = MatchFormat(
  label: 'Tennis, 8 overs, 8-a-side',
  oversPerSide: 8,
  playersPerSide: 8,
);

const List<MatchFormat> matchFormatPresets = [
  defaultMatchFormat,
  MatchFormat(
    label: 'Leather T20, 11-a-side',
    oversPerSide: 20,
    playersPerSide: 11,
  ),
  MatchFormat(
    label: 'Leather 40-over, 11-a-side',
    oversPerSide: 40,
    playersPerSide: 11,
  ),
];

class ExtraSubRules {
  final bool noBallRebowl;
  final int noBallRuns;
  final int wideRuns;

  const ExtraSubRules({
    this.noBallRebowl = true,
    this.noBallRuns = 1,
    this.wideRuns = 1,
  });

  ExtraSubRules copyWith({bool? noBallRebowl, int? noBallRuns, int? wideRuns}) {
    return ExtraSubRules(
      noBallRebowl: noBallRebowl ?? this.noBallRebowl,
      noBallRuns: noBallRuns ?? this.noBallRuns,
      wideRuns: wideRuns ?? this.wideRuns,
    );
  }

  Map<String, dynamic> toJson() => {
    'noBallRebowl': noBallRebowl,
    'noBallRuns': noBallRuns,
    'wideRuns': wideRuns,
  };

  factory ExtraSubRules.fromJson(Map<String, dynamic> json) {
    return ExtraSubRules(
      noBallRebowl: json['noBallRebowl'] as bool? ?? true,
      noBallRuns: json['noBallRuns'] as int? ?? 1,
      wideRuns: json['wideRuns'] as int? ?? 1,
    );
  }
}

/// PRD §7.3: "Availability poll auto-sent on match confirm (deadline
/// default 24h before start; captain-editable)."
const int defaultAvailabilityDeadlineHours = 24;

/// All fields the 4-step wizard collects. No Ground module exists yet
/// (map/listed-ground booking, DS §7.2's "Ground Selection" sub-flow) --
/// ground is free text only, same honest-gap treatment as other
/// cross-epic stand-ins this session.
class MatchDraft {
  final MatchType matchType;
  final MatchFormat format;
  final BallType ballType;
  final ExtraSubRules subRules;
  final String opponentTeamName;
  final bool isGuestTeam;
  final String groundName;
  final DateTime dateTime;
  final MatchVisibility visibility;
  final ScorerAssignment scorerAssignment;
  final String? scorerMemberName;
  final List<String> umpireNames;
  final bool expensePresetEnabled;
  final int availabilityDeadlineHours;

  const MatchDraft({
    this.matchType = MatchType.friendly,
    this.format = defaultMatchFormat,
    this.ballType = BallType.tennis,
    this.subRules = const ExtraSubRules(),
    this.opponentTeamName = '',
    this.isGuestTeam = false,
    this.groundName = '',
    required this.dateTime,
    this.visibility = MatchVisibility.community,
    this.scorerAssignment = ScorerAssignment.self,
    this.scorerMemberName,
    this.umpireNames = const [],
    this.expensePresetEnabled = true,
    this.availabilityDeadlineHours = defaultAvailabilityDeadlineHours,
  });

  MatchDraft copyWith({
    MatchType? matchType,
    MatchFormat? format,
    BallType? ballType,
    ExtraSubRules? subRules,
    String? opponentTeamName,
    bool? isGuestTeam,
    String? groundName,
    DateTime? dateTime,
    MatchVisibility? visibility,
    ScorerAssignment? scorerAssignment,
    String? scorerMemberName,
    bool clearScorerMemberName = false,
    List<String>? umpireNames,
    bool? expensePresetEnabled,
    int? availabilityDeadlineHours,
  }) {
    return MatchDraft(
      matchType: matchType ?? this.matchType,
      format: format ?? this.format,
      ballType: ballType ?? this.ballType,
      subRules: subRules ?? this.subRules,
      opponentTeamName: opponentTeamName ?? this.opponentTeamName,
      isGuestTeam: isGuestTeam ?? this.isGuestTeam,
      groundName: groundName ?? this.groundName,
      dateTime: dateTime ?? this.dateTime,
      visibility: visibility ?? this.visibility,
      scorerAssignment: scorerAssignment ?? this.scorerAssignment,
      scorerMemberName: clearScorerMemberName
          ? null
          : (scorerMemberName ?? this.scorerMemberName),
      umpireNames: umpireNames ?? this.umpireNames,
      expensePresetEnabled: expensePresetEnabled ?? this.expensePresetEnabled,
      availabilityDeadlineHours:
          availabilityDeadlineHours ?? this.availabilityDeadlineHours,
    );
  }

  Map<String, dynamic> toJson() => {
    'matchType': matchType.name,
    'format': format.toJson(),
    'ballType': ballType.name,
    'subRules': subRules.toJson(),
    'opponentTeamName': opponentTeamName,
    'isGuestTeam': isGuestTeam,
    'groundName': groundName,
    'dateTime': dateTime.toIso8601String(),
    'visibility': visibility.name,
    'scorerAssignment': scorerAssignment.name,
    'scorerMemberName': scorerMemberName,
    'umpireNames': umpireNames,
    'expensePresetEnabled': expensePresetEnabled,
    'availabilityDeadlineHours': availabilityDeadlineHours,
  };

  factory MatchDraft.fromJson(Map<String, dynamic> json) {
    return MatchDraft(
      matchType: MatchType.values.byName(json['matchType'] as String),
      format: MatchFormat.fromJson(json['format'] as Map<String, dynamic>),
      ballType: BallType.values.byName(json['ballType'] as String),
      subRules: ExtraSubRules.fromJson(
        json['subRules'] as Map<String, dynamic>,
      ),
      opponentTeamName: json['opponentTeamName'] as String? ?? '',
      isGuestTeam: json['isGuestTeam'] as bool? ?? false,
      groundName: json['groundName'] as String? ?? '',
      dateTime: DateTime.parse(json['dateTime'] as String),
      visibility: MatchVisibility.values.byName(
        json['visibility'] as String? ?? MatchVisibility.community.name,
      ),
      scorerAssignment: ScorerAssignment.values.byName(
        json['scorerAssignment'] as String? ?? ScorerAssignment.self.name,
      ),
      scorerMemberName: json['scorerMemberName'] as String?,
      umpireNames: (json['umpireNames'] as List? ?? const []).cast<String>(),
      expensePresetEnabled: json['expensePresetEnabled'] as bool? ?? true,
      availabilityDeadlineHours:
          json['availabilityDeadlineHours'] as int? ??
          defaultAvailabilityDeadlineHours,
    );
  }
}

/// AC: "Given I created a match last week, When I start the wizard,
/// Then format/ground/time pre-fill from it." No real match archive
/// exists yet, so this is a fixed mock "last match" the wizard seeds
/// its smart defaults from.
MatchDraft mockLastMatchDraft({DateTime Function() now = DateTime.now}) {
  return MatchDraft(
    format: matchFormatPresets[1],
    ballType: BallType.leather,
    groundName: 'Riverside Ground',
    dateTime: now().add(const Duration(days: 7, hours: 9)),
  );
}

enum MatchStatus {
  pendingOpponent,
  changesProposedToComposer,
  accepted,
  declined,
  cancelled,
}

/// Mock squad for the debug demo -- no real team-roster lookup is wired
/// into match creation yet.
List<String> mockSquadNames() => const [
  'Kabir Singh',
  'Priya Nair',
  'Arjun Mehta',
  'Sana Iyer',
];

/// PRD §7.6: "Toss screen at match start: digital coin flip (either
/// captain taps; animation; result recorded) or manual entry ('Real
/// coin used: Titans won, chose to bat')."
enum TossDecision { bat, bowl }

const Map<TossDecision, String> tossDecisionLabels = {
  TossDecision.bat: 'Bat',
  TossDecision.bowl: 'Bowl',
};

class TossResult {
  final String winningTeamName;
  final TossDecision decision;
  final bool isManual;
  final DateTime recordedAt;

  const TossResult({
    required this.winningTeamName,
    required this.decision,
    required this.isManual,
    required this.recordedAt,
  });

  Map<String, dynamic> toJson() => {
    'winningTeamName': winningTeamName,
    'decision': decision.name,
    'isManual': isManual,
    'recordedAt': recordedAt.toIso8601String(),
  };

  factory TossResult.fromJson(Map<String, dynamic> json) {
    return TossResult(
      winningTeamName: json['winningTeamName'] as String,
      decision: TossDecision.values.byName(json['decision'] as String),
      isManual: json['isManual'] as bool,
      recordedAt: DateTime.parse(json['recordedAt'] as String),
    );
  }
}

/// PRD §7.1: "Creating notifies opponent captain -> Accept/Propose
/// changes (diff view)/Decline. Match is Draft until both accept."
/// PRD §7.2's Ground Selection and Ground&Time step name are the two
/// fields opponents realistically negotiate, so [proposedGroundName]/
/// [proposedDateTime] are the only diffable fields modeled -- not every
/// draft field, keeping the diff view meaningful rather than exhaustive.
///
/// DS §7 screen 25's "Cancelled: struck header + reason banner +
/// re-RSVP if rescheduled" is read as two distinct actions rather than
/// one combined construct (PRD's notification table also lists
/// "cancelled/rescheduled" as two triggers sharing one outcome: "View
/// reason, Re-RSVP"): [cancelledReason] is a terminal cancellation with
/// no further action; [rescheduleReason] keeps the match otherwise live
/// but resets [availabilityResponses], forcing a fresh RSVP round for
/// the new time.
class MatchRecord {
  final String id;
  final String composerTeamName;
  final MatchDraft draft;
  final MatchStatus status;
  final String? proposedGroundName;
  final DateTime? proposedDateTime;
  final bool availabilityPollSent;
  final DateTime? availabilityDeadline;
  final String? cancelledReason;
  final String? rescheduleReason;
  final List<String> squadNames;
  final Map<String, AvailabilityResponse> availabilityResponses;
  final String? pendingTossWinner;
  final TossResult? tossResult;
  final List<String> timelineEntries;
  final List<String> pendingViewerRequests;
  final List<String> approvedViewerNames;
  final bool composerCaptainApprovedSelfScoring;
  final bool opponentCaptainApprovedSelfScoring;
  final bool composerCaptainWaivedUmpireConflict;
  final bool opponentCaptainWaivedUmpireConflict;

  const MatchRecord({
    required this.id,
    required this.composerTeamName,
    required this.draft,
    required this.status,
    this.proposedGroundName,
    this.proposedDateTime,
    this.availabilityPollSent = false,
    this.availabilityDeadline,
    this.cancelledReason,
    this.rescheduleReason,
    this.squadNames = const [],
    this.availabilityResponses = const {},
    this.pendingTossWinner,
    this.tossResult,
    this.timelineEntries = const [],
    this.pendingViewerRequests = const [],
    this.approvedViewerNames = const [],
    this.composerCaptainApprovedSelfScoring = false,
    this.opponentCaptainApprovedSelfScoring = false,
    this.composerCaptainWaivedUmpireConflict = false,
    this.opponentCaptainWaivedUmpireConflict = false,
  });

  bool get selfScoringOverrideApproved =>
      composerCaptainApprovedSelfScoring && opponentCaptainApprovedSelfScoring;

  bool get umpireConflictWaived =>
      composerCaptainWaivedUmpireConflict &&
      opponentCaptainWaivedUmpireConflict;

  MatchRecord copyWith({
    MatchDraft? draft,
    MatchStatus? status,
    String? proposedGroundName,
    bool clearProposedGroundName = false,
    DateTime? proposedDateTime,
    bool clearProposedDateTime = false,
    bool? availabilityPollSent,
    DateTime? availabilityDeadline,
    String? cancelledReason,
    String? rescheduleReason,
    bool clearRescheduleReason = false,
    Map<String, AvailabilityResponse>? availabilityResponses,
    String? pendingTossWinner,
    bool clearPendingTossWinner = false,
    TossResult? tossResult,
    List<String>? timelineEntries,
    List<String>? pendingViewerRequests,
    List<String>? approvedViewerNames,
    bool? composerCaptainApprovedSelfScoring,
    bool? opponentCaptainApprovedSelfScoring,
    bool? composerCaptainWaivedUmpireConflict,
    bool? opponentCaptainWaivedUmpireConflict,
  }) {
    return MatchRecord(
      id: id,
      composerTeamName: composerTeamName,
      draft: draft ?? this.draft,
      status: status ?? this.status,
      proposedGroundName: clearProposedGroundName
          ? null
          : (proposedGroundName ?? this.proposedGroundName),
      proposedDateTime: clearProposedDateTime
          ? null
          : (proposedDateTime ?? this.proposedDateTime),
      availabilityPollSent: availabilityPollSent ?? this.availabilityPollSent,
      availabilityDeadline: availabilityDeadline ?? this.availabilityDeadline,
      cancelledReason: cancelledReason ?? this.cancelledReason,
      rescheduleReason: clearRescheduleReason
          ? null
          : (rescheduleReason ?? this.rescheduleReason),
      squadNames: squadNames,
      availabilityResponses:
          availabilityResponses ?? this.availabilityResponses,
      pendingTossWinner: clearPendingTossWinner
          ? null
          : (pendingTossWinner ?? this.pendingTossWinner),
      tossResult: tossResult ?? this.tossResult,
      timelineEntries: timelineEntries ?? this.timelineEntries,
      pendingViewerRequests:
          pendingViewerRequests ?? this.pendingViewerRequests,
      approvedViewerNames: approvedViewerNames ?? this.approvedViewerNames,
      composerCaptainApprovedSelfScoring:
          composerCaptainApprovedSelfScoring ??
          this.composerCaptainApprovedSelfScoring,
      opponentCaptainApprovedSelfScoring:
          opponentCaptainApprovedSelfScoring ??
          this.opponentCaptainApprovedSelfScoring,
      composerCaptainWaivedUmpireConflict:
          composerCaptainWaivedUmpireConflict ??
          this.composerCaptainWaivedUmpireConflict,
      opponentCaptainWaivedUmpireConflict:
          opponentCaptainWaivedUmpireConflict ??
          this.opponentCaptainWaivedUmpireConflict,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'composerTeamName': composerTeamName,
    'draft': draft.toJson(),
    'status': status.name,
    'proposedGroundName': proposedGroundName,
    'proposedDateTime': proposedDateTime?.toIso8601String(),
    'availabilityPollSent': availabilityPollSent,
    'availabilityDeadline': availabilityDeadline?.toIso8601String(),
    'cancelledReason': cancelledReason,
    'rescheduleReason': rescheduleReason,
    'squadNames': squadNames,
    'availabilityResponses': availabilityResponses.map(
      (k, v) => MapEntry(k, v.name),
    ),
    'pendingTossWinner': pendingTossWinner,
    'tossResult': tossResult?.toJson(),
    'timelineEntries': timelineEntries,
    'pendingViewerRequests': pendingViewerRequests,
    'approvedViewerNames': approvedViewerNames,
    'composerCaptainApprovedSelfScoring': composerCaptainApprovedSelfScoring,
    'opponentCaptainApprovedSelfScoring': opponentCaptainApprovedSelfScoring,
    'composerCaptainWaivedUmpireConflict': composerCaptainWaivedUmpireConflict,
    'opponentCaptainWaivedUmpireConflict': opponentCaptainWaivedUmpireConflict,
  };

  factory MatchRecord.fromJson(Map<String, dynamic> json) {
    final tossJson = json['tossResult'] as Map<String, dynamic>?;
    return MatchRecord(
      id: json['id'] as String,
      composerTeamName: json['composerTeamName'] as String,
      draft: MatchDraft.fromJson(json['draft'] as Map<String, dynamic>),
      status: MatchStatus.values.byName(json['status'] as String),
      proposedGroundName: json['proposedGroundName'] as String?,
      proposedDateTime: (json['proposedDateTime'] as String?) == null
          ? null
          : DateTime.parse(json['proposedDateTime'] as String),
      availabilityPollSent: json['availabilityPollSent'] as bool? ?? false,
      availabilityDeadline: (json['availabilityDeadline'] as String?) == null
          ? null
          : DateTime.parse(json['availabilityDeadline'] as String),
      cancelledReason: json['cancelledReason'] as String?,
      rescheduleReason: json['rescheduleReason'] as String?,
      squadNames: (json['squadNames'] as List? ?? const []).cast<String>(),
      availabilityResponses: {
        for (final entry
            in (json['availabilityResponses'] as Map<String, dynamic>? ??
                    const {})
                .entries)
          entry.key: AvailabilityResponse.values.byName(entry.value as String),
      },
      pendingTossWinner: json['pendingTossWinner'] as String?,
      tossResult: tossJson == null ? null : TossResult.fromJson(tossJson),
      timelineEntries: (json['timelineEntries'] as List? ?? const [])
          .cast<String>(),
      pendingViewerRequests:
          (json['pendingViewerRequests'] as List? ?? const []).cast<String>(),
      approvedViewerNames: (json['approvedViewerNames'] as List? ?? const [])
          .cast<String>(),
      composerCaptainApprovedSelfScoring:
          json['composerCaptainApprovedSelfScoring'] as bool? ?? false,
      opponentCaptainApprovedSelfScoring:
          json['opponentCaptainApprovedSelfScoring'] as bool? ?? false,
      composerCaptainWaivedUmpireConflict:
          json['composerCaptainWaivedUmpireConflict'] as bool? ?? false,
      opponentCaptainWaivedUmpireConflict:
          json['opponentCaptainWaivedUmpireConflict'] as bool? ?? false,
    );
  }
}

/// PRD §13: "Anti-fraud gate: ... anomaly checks (same 4 players
/// 'playing' daily) flag to review." PRD names the example but no exact
/// algorithm -- a flagged judgment call, same convention as
/// `registration_models.dart`'s `duplicatePlayersAcross`: the same exact
/// squad (>= [minSquadSize] players) appearing in completed matches on
/// [dayThreshold]+ distinct calendar days within a trailing
/// [windowDays]-day window is the "playing daily" pattern PRD's example
/// describes.
class LineupAnomaly {
  final List<String> squad;
  final int distinctDays;
  final DateTime mostRecentMatchDate;

  const LineupAnomaly({
    required this.squad,
    required this.distinctDays,
    required this.mostRecentMatchDate,
  });
}

List<LineupAnomaly> detectDailyLineupAnomalies(
  List<MatchRecord> matches, {
  DateTime Function() now = DateTime.now,
  int dayThreshold = 3,
  int windowDays = 7,
  int minSquadSize = 4,
}) {
  final nowValue = now();
  final cutoff = nowValue.subtract(Duration(days: windowDays));
  final completed = matches.where(
    (m) =>
        m.status == MatchStatus.accepted &&
        m.draft.dateTime.isBefore(nowValue) &&
        m.draft.dateTime.isAfter(cutoff) &&
        m.squadNames.length >= minSquadSize,
  );

  final bySquad = <String, List<MatchRecord>>{};
  for (final m in completed) {
    final key = (List<String>.from(m.squadNames)..sort()).join('|');
    (bySquad[key] ??= []).add(m);
  }

  final anomalies = <LineupAnomaly>[];
  for (final entry in bySquad.entries) {
    final distinctDays = entry.value
        .map(
          (m) => DateTime(
            m.draft.dateTime.year,
            m.draft.dateTime.month,
            m.draft.dateTime.day,
          ),
        )
        .toSet()
        .length;
    if (distinctDays < dayThreshold) continue;
    final mostRecent = entry.value
        .map((m) => m.draft.dateTime)
        .reduce((a, b) => a.isAfter(b) ? a : b);
    anomalies.add(
      LineupAnomaly(
        squad: List<String>.from(entry.value.first.squadNames)..sort(),
        distinctDays: distinctDays,
        mostRecentMatchDate: mostRecent,
      ),
    );
  }
  return anomalies;
}
