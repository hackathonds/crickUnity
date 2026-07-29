import 'expense_models.dart';

/// DS §11.13: "cadence row (Off/Weekly/Monthly/Season)."
enum RecurrenceCadence { off, weekly, monthly, season }

const Map<RecurrenceCadence, String> recurrenceCadenceLabels = {
  RecurrenceCadence.off: 'Off',
  RecurrenceCadence.weekly: 'Weekly',
  RecurrenceCadence.monthly: 'Monthly',
  RecurrenceCadence.season: 'Season',
};

/// DS §11.13: "series summary line ('Creates on the 1st, 3 days
/// notice')." Template an expense series generates from -- the
/// template's own fields (title/category/amount/split) are what each
/// new instance is stamped with.
class RecurringSeries {
  final String id;
  final String title;
  final ExpenseCategory category;
  final int amount;
  final SplitMethod splitMethod;
  final List<SplitShare> splitAmong;
  final RecurrenceCadence cadence;
  final DateTime startDate;
  final DateTime? endDate;
  final int noticeDays;
  final String createdByName;
  final bool createdByIsCaptain;

  const RecurringSeries({
    required this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.splitMethod,
    required this.splitAmong,
    required this.cadence,
    required this.startDate,
    this.endDate,
    this.noticeDays = 3,
    required this.createdByName,
    required this.createdByIsCaptain,
  });

  RecurringSeries copyWith({int? amount, List<SplitShare>? splitAmong}) {
    return RecurringSeries(
      id: id,
      title: title,
      category: category,
      amount: amount ?? this.amount,
      splitMethod: splitMethod,
      splitAmong: splitAmong ?? this.splitAmong,
      cadence: cadence,
      startDate: startDate,
      endDate: endDate,
      noticeDays: noticeDays,
      createdByName: createdByName,
      createdByIsCaptain: createdByIsCaptain,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'category': category.name,
    'amount': amount,
    'splitMethod': splitMethod.name,
    'splitAmong': [for (final s in splitAmong) s.toJson()],
    'cadence': cadence.name,
    'startDate': startDate.toIso8601String(),
    'endDate': endDate?.toIso8601String(),
    'noticeDays': noticeDays,
    'createdByName': createdByName,
    'createdByIsCaptain': createdByIsCaptain,
  };

  factory RecurringSeries.fromJson(Map<String, dynamic> json) {
    return RecurringSeries(
      id: json['id'] as String,
      title: json['title'] as String,
      category: ExpenseCategory.values.byName(json['category'] as String),
      amount: json['amount'] as int,
      splitMethod: SplitMethod.values.byName(json['splitMethod'] as String),
      splitAmong: [
        for (final s in json['splitAmong'] as List)
          SplitShare.fromJson(s as Map<String, dynamic>),
      ],
      cadence: RecurrenceCadence.values.byName(json['cadence'] as String),
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'] as String)
          : null,
      noticeDays: json['noticeDays'] as int? ?? 3,
      createdByName: json['createdByName'] as String,
      createdByIsCaptain: json['createdByIsCaptain'] as bool,
    );
  }

  Duration get _step => switch (cadence) {
    RecurrenceCadence.off => Duration.zero,
    RecurrenceCadence.weekly => const Duration(days: 7),
    RecurrenceCadence.monthly => const Duration(days: 30),
    RecurrenceCadence.season => const Duration(days: 90),
  };

  /// DS §11.13: "upcoming-instances preview list."
  List<DateTime> upcomingInstances({int count = 4}) {
    if (cadence == RecurrenceCadence.off) return const [];
    final dates = <DateTime>[];
    var next = startDate.add(_step);
    for (var i = 0; i < count; i++) {
      if (endDate != null && next.isAfter(endDate!)) break;
      dates.add(next);
      next = next.add(_step);
    }
    return dates;
  }

  String get summaryLine =>
      'Creates every ${recurrenceCadenceLabels[cadence]!.toLowerCase()}, '
      '$noticeDays days notice';
}
