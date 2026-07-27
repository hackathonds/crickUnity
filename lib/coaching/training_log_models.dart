/// Backlog E11-05 (Personal training log, [E11-03]): "Drill Library
/// access for *all* users (not only academy students): self-log drills
/// with units, optional proof (+bonus), partner-confirm, per-drill PBs
/// & progress graphs, feeds daily missions D5/D7/D8 and Net-Grinder/
/// Circle-Runner badges, age workload caps (PRD Appx C.1/E -- the
/// library was coach-console-only in E11-03)."
///
/// Both "PRD Appx C.1" and "Appx E" are phantom citations -- no
/// Appendix C or E exists anywhere in the frozen PRD (only Appendix A
/// and B are real, same pattern flagged repeatedly this session). The
/// mission IDs "D5/D7/D8" also appear nowhere in the frozen PRD/DS
/// (confirmed by grep) -- a bigger gap than the usual phantom-citation
/// pattern, since the backlog invents identifiers with no definition
/// anywhere. This reuses coaching/coach_models.dart's real Drill/
/// AgeBand/scaledPrescription/maxSessionsPerWeek (the module DS §7-46
/// scoped to coach-console-only) rather than a second drill catalog,
/// and wires two new mission defs + two new badge trackers standing in
/// for the unresolvable D5/D7/D8 and Net-Grinder/Circle-Runner names.
library;

import 'coach_models.dart';

/// PRD names no exact bonus for attaching proof -- a flagged judgment
/// call, same convention as every other unspecified numeric reward.
const int proofBonusCoins = 5;

class TrainingLogEntry {
  final String id;
  final String userName;
  final String drillId;
  final int value;
  final bool hasProof;
  final bool partnerConfirmed;
  final String? partnerName;
  final DateTime loggedAt;

  const TrainingLogEntry({
    required this.id,
    required this.userName,
    required this.drillId,
    required this.value,
    this.hasProof = false,
    this.partnerConfirmed = false,
    this.partnerName,
    required this.loggedAt,
  });

  TrainingLogEntry copyWith({bool? partnerConfirmed, String? partnerName}) {
    return TrainingLogEntry(
      id: id,
      userName: userName,
      drillId: drillId,
      value: value,
      hasProof: hasProof,
      partnerConfirmed: partnerConfirmed ?? this.partnerConfirmed,
      partnerName: partnerName ?? this.partnerName,
      loggedAt: loggedAt,
    );
  }
}

/// Backlog: "Net-Grinder/Circle-Runner badges." No definition exists
/// anywhere in the frozen docs for either name -- flagged judgment
/// calls: Net-Grinder counts logged batting/bowling drills (net-
/// practice categories), Circle-Runner counts logged fitness drills.
/// Kept local to this module rather than folded into
/// rewards/achievements_provider.dart's TieredBadgeId, which its own
/// top-of-file comment explicitly scopes to 3 badges.
enum TrainingBadgeId { netGrinder, circleRunner }

const Map<TrainingBadgeId, String> trainingBadgeNames = {
  TrainingBadgeId.netGrinder: 'Net-Grinder',
  TrainingBadgeId.circleRunner: 'Circle-Runner',
};

const Map<TrainingBadgeId, List<DrillCategory>> trainingBadgeCategories = {
  TrainingBadgeId.netGrinder: [DrillCategory.batting, DrillCategory.bowling],
  TrainingBadgeId.circleRunner: [DrillCategory.fitness],
};

const Map<TrainingBadgeId, List<int>> trainingBadgeTiers = {
  TrainingBadgeId.netGrinder: [10, 30, 75],
  TrainingBadgeId.circleRunner: [10, 30, 75],
};

const List<String> trainingBadgeTierLabels = ['Bronze', 'Silver', 'Gold'];
