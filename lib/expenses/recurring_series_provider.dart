import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'expense_models.dart';
import 'expenses_provider.dart';
import 'recurring_series_models.dart';

class RecurringSeriesState {
  final List<RecurringSeries> series;

  const RecurringSeriesState({this.series = const []});

  RecurringSeriesState copyWith({List<RecurringSeries>? series}) {
    return RecurringSeriesState(series: series ?? this.series);
  }
}

/// DS §11.13 -- E5-09's recurring-expense series. No real background
/// cron exists to fire cadence notices automatically -- instance
/// generation is manually triggered (a debug/QA action standing in for
/// "the notice date arrived"), same convention as every other
/// simulated-elapsed-time mechanic this session.
class RecurringSeriesNotifier extends Notifier<RecurringSeriesState> {
  int _nextId = 0;

  @override
  RecurringSeriesState build() => const RecurringSeriesState();

  String createSeries({
    required String title,
    required ExpenseCategory category,
    required int amount,
    required SplitMethod splitMethod,
    required List<SplitShare> splitAmong,
    required RecurrenceCadence cadence,
    required DateTime startDate,
    DateTime? endDate,
    required String createdByName,
    required bool createdByIsCaptain,
  }) {
    final id = 'series-${_nextId++}';
    state = state.copyWith(
      series: [
        ...state.series,
        RecurringSeries(
          id: id,
          title: title,
          category: category,
          amount: amount,
          splitMethod: splitMethod,
          splitAmong: splitAmong,
          cadence: cadence,
          startDate: startDate,
          endDate: endDate,
          createdByName: createdByName,
          createdByIsCaptain: createdByIsCaptain,
        ),
      ],
    );
    return id;
  }

  /// Creates the next instance as a real [Expense] tagged with this
  /// series' id, respecting [RecurringSeries.endDate].
  String? generateNextInstance(
    String seriesId, {
    DateTime Function() now = DateTime.now,
  }) {
    final matches = state.series.where((s) => s.id == seriesId);
    if (matches.isEmpty) return null;
    final series = matches.first;
    if (series.endDate != null && now().isAfter(series.endDate!)) return null;
    return ref
        .read(expensesProvider.notifier)
        .addExpense(
          title: series.title,
          category: series.category,
          amount: series.amount,
          paidBy: [
            PaidByEntry(name: series.createdByName, amount: series.amount),
          ],
          splitMethod: series.splitMethod,
          splitAmong: series.splitAmong,
          createdByName: series.createdByName,
          createdByIsCaptain: series.createdByIsCaptain,
          recurrenceSeriesId: seriesId,
          now: now,
        );
  }

  /// DS §11.13: "editing asks 'This one / All future' sheet." This is
  /// the "All future" path -- updates the template so every
  /// subsequently-generated instance uses the corrected amount/split.
  void updateSeriesTemplate(String seriesId, int newAmount) {
    state = state.copyWith(
      series: [
        for (final s in state.series)
          if (s.id == seriesId)
            s.copyWith(
              amount: newAmount,
              splitAmong: rescaleSplit(s.splitAmong, newAmount),
            )
          else
            s,
      ],
    );
  }
}

final recurringSeriesProvider =
    NotifierProvider<RecurringSeriesNotifier, RecurringSeriesState>(
      RecurringSeriesNotifier.new,
    );
