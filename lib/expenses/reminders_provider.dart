import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_tag_chip.dart';
import '../persistence/persisted_notifier.dart';

/// PRD §11.10: "Auto-reminder cadence for a due share: T+3d gentle,
/// T+7d firm, weekly after (payer can see the schedule)."
String reminderCadenceLabel(int ageDays) {
  if (ageDays < 3) {
    return 'Next reminder in ${3 - ageDays}d (gentle)';
  }
  if (ageDays < 7) {
    return 'Gentle reminder active -- firm reminder in ${7 - ageDays}d';
  }
  final weeksSinceFirm = (ageDays - 7) ~/ 7;
  return 'Firm reminder active -- weekly reminders since day 7 '
      '($weeksSinceFirm sent)';
}

/// PRD §11.10: "Reminder copy is polite & contextual ('₹250 for
/// Sunday's ground vs Titans')."
String reminderCopy({required int amount, required String contextCaption}) =>
    '₹$amount for $contextCaption';

/// Same warning/error thresholds already established for the overdue
/// chip in [AppExpenseCard] (DS §3.2.5): >3d warning, >7d error.
AppTagChipVariant ageChipVariant(int ageDays) {
  if (ageDays > 7) return AppTagChipVariant.error;
  if (ageDays > 3) return AppTagChipVariant.warning;
  return AppTagChipVariant.neutral;
}

class ReminderState {
  final DateTime? snoozedUntil;
  final DateTime? lastManualReminderAt;
  final List<String> log;

  const ReminderState({
    this.snoozedUntil,
    this.lastManualReminderAt,
    this.log = const [],
  });

  ReminderState copyWith({
    DateTime? snoozedUntil,
    DateTime? lastManualReminderAt,
    List<String>? log,
  }) {
    return ReminderState(
      snoozedUntil: snoozedUntil ?? this.snoozedUntil,
      lastManualReminderAt: lastManualReminderAt ?? this.lastManualReminderAt,
      log: log ?? this.log,
    );
  }

  Map<String, dynamic> toJson() => {
    'snoozedUntil': snoozedUntil?.toIso8601String(),
    'lastManualReminderAt': lastManualReminderAt?.toIso8601String(),
    'log': log,
  };

  factory ReminderState.fromJson(Map<String, dynamic> json) {
    return ReminderState(
      snoozedUntil: json['snoozedUntil'] != null
          ? DateTime.parse(json['snoozedUntil'] as String)
          : null,
      lastManualReminderAt: json['lastManualReminderAt'] != null
          ? DateTime.parse(json['lastManualReminderAt'] as String)
          : null,
      log: [for (final l in json['log'] as List) l as String],
    );
  }
}

class RemindersState {
  final Map<String, ReminderState> byExpenseId;

  const RemindersState({this.byExpenseId = const {}});

  ReminderState stateFor(String expenseId) =>
      byExpenseId[expenseId] ?? const ReminderState();

  RemindersState copyWith({Map<String, ReminderState>? byExpenseId}) {
    return RemindersState(byExpenseId: byExpenseId ?? this.byExpenseId);
  }

  Map<String, dynamic> toJson() => {
    'byExpenseId': {
      for (final entry in byExpenseId.entries) entry.key: entry.value.toJson(),
    },
  };

  factory RemindersState.fromJson(Map<String, dynamic> json) {
    return RemindersState(
      byExpenseId: {
        for (final entry
            in (json['byExpenseId'] as Map<String, dynamic>).entries)
          entry.key: ReminderState.fromJson(
            entry.value as Map<String, dynamic>,
          ),
      },
    );
  }
}

/// PRD §11.10 -- E5-05. Keyed by expenseId only, not per payer pair:
/// snooze is the current viewer's own reminder state for that expense;
/// a manual reminder is a bulk nudge to every unpaid participant on it
/// at once. A fully general per-payer reminder model would need more
/// UI than this story's scope -- flagged simplification, same
/// convention as every other scope boundary this session.
class RemindersNotifier extends PersistedNotifier<RemindersState> {
  @override
  String get persistenceKey => 'reminders_v1';

  @override
  RemindersState seed() => const RemindersState();

  @override
  Map<String, dynamic> toJson(RemindersState value) => value.toJson();

  @override
  RemindersState fromJson(Map<String, dynamic> json) =>
      RemindersState.fromJson(json);

  /// PRD §11.10: "Payer can Snooze once/48h."
  bool canSnooze(String expenseId, {DateTime Function() now = DateTime.now}) {
    final snoozedUntil = state.stateFor(expenseId).snoozedUntil;
    return snoozedUntil == null || !now().isBefore(snoozedUntil);
  }

  void snooze(String expenseId, {DateTime Function() now = DateTime.now}) {
    if (!canSnooze(expenseId, now: now)) return;
    _update(
      expenseId,
      (s) => s.copyWith(snoozedUntil: now().add(const Duration(hours: 48))),
    );
  }

  /// PRD §11.10: "payee can send 1 manual/day."
  bool canSendManualReminder(
    String expenseId, {
    DateTime Function() now = DateTime.now,
  }) {
    final lastSent = state.stateFor(expenseId).lastManualReminderAt;
    return lastSent == null || now().difference(lastSent).inHours >= 24;
  }

  void sendManualReminder(
    String expenseId,
    List<String> message, {
    DateTime Function() now = DateTime.now,
  }) {
    if (!canSendManualReminder(expenseId, now: now)) return;
    _update(
      expenseId,
      (s) =>
          s.copyWith(lastManualReminderAt: now(), log: [...s.log, ...message]),
    );
  }

  void _update(String expenseId, ReminderState Function(ReminderState) f) {
    final current = state.stateFor(expenseId);
    state = state.copyWith(
      byExpenseId: {...state.byExpenseId, expenseId: f(current)},
    );
  }
}

final remindersProvider = NotifierProvider<RemindersNotifier, RemindersState>(
  RemindersNotifier.new,
);
