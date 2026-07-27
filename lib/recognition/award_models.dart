/// PRD §14: "Awards (periodic, auto+curated): Consistency (played
/// every week of month), Fair Play (Exemplary sportsmanship + zero
/// conduct flags, opponent-voted), Fitness (session streaks),
/// Attendance (Iron Player >=95% season), Volunteer (most service
/// actions), Community (most helpful: props given, scoring gigs,
/// new-player onboarding). Winners announced monthly per city/club with
/// certificate cards."
enum AwardCategory {
  consistency,
  fairPlay,
  fitness,
  attendance,
  volunteer,
  community,
}

const Map<AwardCategory, String> awardCategoryLabels = {
  AwardCategory.consistency: 'Consistency',
  AwardCategory.fairPlay: 'Fair Play',
  AwardCategory.fitness: 'Fitness',
  AwardCategory.attendance: 'Attendance',
  AwardCategory.volunteer: 'Volunteer',
  AwardCategory.community: 'Community',
};

const Map<AwardCategory, String> awardCategoryCriteria = {
  AwardCategory.consistency: 'Played every week of the month',
  AwardCategory.fairPlay:
      'Exemplary sportsmanship, zero conduct flags '
      '(opponent-voted)',
  AwardCategory.fitness: 'Session streaks',
  AwardCategory.attendance: 'Iron Player -- 95%+ season attendance',
  AwardCategory.volunteer: 'Most service actions',
  AwardCategory.community:
      'Most helpful: props given, scoring gigs, '
      'new-player onboarding',
};

class AwardWinner {
  final AwardCategory category;
  final String scopeLabel;
  final String winnerName;
  final String periodLabel;
  final DateTime certificateIssuedAt;

  const AwardWinner({
    required this.category,
    required this.scopeLabel,
    required this.winnerName,
    required this.periodLabel,
    required this.certificateIssuedAt,
  });
}
