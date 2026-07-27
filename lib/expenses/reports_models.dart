import 'expense_models.dart';
import 'settlement_models.dart';

enum ReportPeriod { thisMonth, thisYear }

bool _inPeriod(DateTime date, ReportPeriod period, DateTime now) {
  return switch (period) {
    ReportPeriod.thisMonth => date.year == now.year && date.month == now.month,
    ReportPeriod.thisYear => date.year == now.year,
  };
}

/// PRD §11.9: "Monthly & yearly reports (per person / per team): total
/// spent." The viewer's total *owed* share across the period -- not
/// the raw expense totals, which would double-count group spend.
int totalSpentFor(
  String viewerName,
  List<Expense> expenses,
  ReportPeriod period, {
  DateTime Function() now = DateTime.now,
}) {
  final n = now();
  var total = 0;
  for (final e in expenses) {
    if (!_inPeriod(e.date, period, n)) continue;
    for (final s in e.splitAmong) {
      if (s.name == viewerName) total += s.amount;
    }
  }
  return total;
}

class CategoryTotal {
  final ExpenseCategory category;
  final int amount;

  const CategoryTotal({required this.category, required this.amount});
}

/// PRD §11.9: "by category donut." Rendered as a simplified bar/list
/// breakdown rather than a real custom-paint donut -- same convention
/// as E4-11's Charts tab (Manhattan/Worm/Wagon simplifications),
/// proportionate to a debug-demo build.
List<CategoryTotal> categoryBreakdown(
  List<Expense> expenses,
  ReportPeriod period, {
  DateTime Function() now = DateTime.now,
}) {
  final n = now();
  final totals = <ExpenseCategory, int>{};
  for (final e in expenses) {
    if (!_inPeriod(e.date, period, n)) continue;
    totals[e.category] = (totals[e.category] ?? 0) + e.amount;
  }
  final list = [
    for (final entry in totals.entries)
      CategoryTotal(category: entry.key, amount: entry.value),
  ];
  list.sort((a, b) => b.amount.compareTo(a.amount));
  return list;
}

class MonthlyTotal {
  final int year;
  final int month;
  final int amount;

  const MonthlyTotal({
    required this.year,
    required this.month,
    required this.amount,
  });
}

/// PRD §11.9: "cost trend line." Per-calendar-month totals across every
/// expense on record (not period-filtered, since a trend needs history
/// to show a trend), most recent last.
List<MonthlyTotal> monthlyTrend(List<Expense> expenses) {
  final totals = <String, MonthlyTotal>{};
  for (final e in expenses) {
    final key = '${e.date.year}-${e.date.month}';
    final existing = totals[key];
    totals[key] = MonthlyTotal(
      year: e.date.year,
      month: e.date.month,
      amount: (existing?.amount ?? 0) + e.amount,
    );
  }
  final list = totals.values.toList();
  list.sort((a, b) {
    final byYear = a.year.compareTo(b.year);
    return byYear != 0 ? byYear : a.month.compareTo(b.month);
  });
  return list;
}

/// PRD §11.9: "top counterparties." Whoever the viewer shares the most
/// transaction volume with (paid-together or split-together), summed
/// across every expense on record.
String? topCounterparty(String viewerName, List<Expense> expenses) {
  final volumeByName = <String, int>{};
  for (final e in expenses) {
    final names = {
      for (final p in e.paidBy) p.name,
      for (final s in e.splitAmong) s.name,
    };
    if (!names.contains(viewerName)) continue;
    for (final name in names) {
      if (name == viewerName) continue;
      volumeByName[name] = (volumeByName[name] ?? 0) + e.amount;
    }
  }
  if (volumeByName.isEmpty) return null;
  return volumeByName.entries.reduce((a, b) => b.value > a.value ? b : a).key;
}

/// PRD §11.9: "settlement speed metric." A Settlement isn't tied to one
/// originating expense (E5-04's model nets several at once), so this
/// approximates speed as the average days between a settlement being
/// proposed and confirmed -- flagged simplification.
double? averageSettlementSpeedDays(List<Settlement> settlements) {
  final confirmed = [
    for (final s in settlements)
      if (s.status == SettlementStatus.confirmed && s.confirmedAt != null) s,
  ];
  if (confirmed.isEmpty) return null;
  final totalDays = confirmed.fold(
    0,
    (sum, s) => sum + s.confirmedAt!.difference(s.createdAt).inHours,
  );
  return (totalDays / confirmed.length) / 24;
}

/// PRD §11.9: "Your cricket costs ₹1,140/month, 22% below team
/// average." Positive percent means the viewer spends *more* than the
/// team average; negative means less.
double? teamAverageComparisonPercent(
  String viewerName,
  List<Expense> expenses,
  Set<String> allParticipants,
) {
  if (allParticipants.length <= 1) return null;
  final totals = <String, int>{for (final p in allParticipants) p: 0};
  for (final e in expenses) {
    for (final s in e.splitAmong) {
      if (totals.containsKey(s.name)) {
        totals[s.name] = totals[s.name]! + s.amount;
      }
    }
  }
  final viewerTotal = totals[viewerName] ?? 0;
  final teamAverage =
      totals.values.fold(0, (a, b) => a + b) / allParticipants.length;
  if (teamAverage == 0) return null;
  return ((viewerTotal - teamAverage) / teamAverage) * 100;
}

/// PRD §11.9: "'3 members cause 80% of pending dues' (captain-only,
/// phrased neutrally in any shared surface)." Ranks debtors by their
/// outstanding (negative) net and reports the smallest number of top
/// debtors whose combined debt covers at least 80% of the total
/// pending debt.
String pendingDuesConcentration(Map<String, int> netBalances) {
  final debtors = [
    for (final entry in netBalances.entries)
      if (entry.value < 0) entry,
  ];
  if (debtors.isEmpty) return 'No pending dues.';
  debtors.sort((a, b) => a.value.compareTo(b.value));
  final totalDebt = debtors.fold(0, (sum, e) => sum + -e.value);
  if (totalDebt == 0) return 'No pending dues.';
  var running = 0;
  var count = 0;
  for (final d in debtors) {
    running += -d.value;
    count++;
    if (running / totalDebt >= 0.8) break;
  }
  final pct = ((running / totalDebt) * 100).round();
  return '$count member${count == 1 ? '' : 's'} cause $pct% of pending dues.';
}

/// PRD §11.9: "Export as image/PDF-style share card." No real image/
/// PDF rendering pipeline exists in this codebase -- CSV is the
/// backlog's own literal deliverable ("CSV statement export") and is
/// genuinely implementable without one.
String generateCsvStatement(List<Expense> expenses) {
  final buffer = StringBuffer('Date,Title,Category,Amount,Created by\n');
  for (final e in expenses) {
    final date =
        '${e.date.year}-${e.date.month.toString().padLeft(2, '0')}-'
        '${e.date.day.toString().padLeft(2, '0')}';
    buffer.writeln(
      '$date,${e.title},${expenseCategoryLabels[e.category]},'
      '${e.amount},${e.createdByName}',
    );
  }
  return buffer.toString();
}
