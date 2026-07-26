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

/// PRD §7.1: "scorer assignment (self/member/hire from Gig Board)." No
/// Gig Board module exists yet (a later epic), so only the two
/// self-contained options are offered here.
enum ScorerAssignment { self, member }

const Map<ScorerAssignment, String> scorerAssignmentLabels = {
  ScorerAssignment.self: 'Score it myself',
  ScorerAssignment.member: 'Assign a team member',
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
      expensePresetEnabled: expensePresetEnabled ?? this.expensePresetEnabled,
      availabilityDeadlineHours:
          availabilityDeadlineHours ?? this.availabilityDeadlineHours,
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
  });

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
    );
  }
}
