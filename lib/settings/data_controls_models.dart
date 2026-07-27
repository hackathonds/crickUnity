/// PRD §17 (Privacy) "Data controls": "view/download my data summary;
/// deactivate (profile hidden, stats preserved in opponents' verified
/// records as 'Deactivated player' -- competitive-integrity rule
/// disclosed at signup); delete account (30-day grace; personal content
/// removed; verified scorecard lines persist anonymized, since a
/// match's opponents own the shared record too)."
library;

enum AccountLifecycleStatus { active, deactivated, pendingDeletion }

const int deletionGraceDays = 30;

class DataExportSummary {
  final int postsCount;
  final int matchesPlayed;
  final int expensesTracked;
  final int coinsEarnedLifetime;
  final int followersCount;

  const DataExportSummary({
    this.postsCount = 0,
    this.matchesPlayed = 0,
    this.expensesTracked = 0,
    this.coinsEarnedLifetime = 0,
    this.followersCount = 0,
  });
}
