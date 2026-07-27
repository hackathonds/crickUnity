import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'achievements_provider.dart';
import 'rewards_models.dart';
import 'rewards_provider.dart';

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
DateTime _weekStart(DateTime d) =>
    _dateOnly(d).subtract(Duration(days: d.weekday - 1));
int _monthKey(DateTime d) => d.year * 12 + d.month;

class StreakState {
  final DateTime? lastLoginDate;
  final int currentLoginStreakDays;
  final int? loginShieldUsedMonth;
  final DateTime? lastActivityWeekStart;
  final int currentPlayingStreakWeeks;
  final bool injuryModeActive;
  final List<String> log;

  const StreakState({
    this.lastLoginDate,
    this.currentLoginStreakDays = 0,
    this.loginShieldUsedMonth,
    this.lastActivityWeekStart,
    this.currentPlayingStreakWeeks = 0,
    this.injuryModeActive = false,
    this.log = const [],
  });

  StreakState copyWith({
    DateTime? lastLoginDate,
    int? currentLoginStreakDays,
    int? loginShieldUsedMonth,
    DateTime? lastActivityWeekStart,
    int? currentPlayingStreakWeeks,
    bool? injuryModeActive,
    List<String>? log,
  }) {
    return StreakState(
      lastLoginDate: lastLoginDate ?? this.lastLoginDate,
      currentLoginStreakDays:
          currentLoginStreakDays ?? this.currentLoginStreakDays,
      loginShieldUsedMonth: loginShieldUsedMonth ?? this.loginShieldUsedMonth,
      lastActivityWeekStart:
          lastActivityWeekStart ?? this.lastActivityWeekStart,
      currentPlayingStreakWeeks:
          currentPlayingStreakWeeks ?? this.currentPlayingStreakWeeks,
      injuryModeActive: injuryModeActive ?? this.injuryModeActive,
      log: log ?? this.log,
    );
  }
}

const List<int> _playingStreakMilestoneWeeks = [4, 12, 26, 52];

/// PRD §13.2 -- E6-02's streak system. Daily missions/weekly-monthly-
/// season chests are E6-03's separate story ("Missions board"), out of
/// scope here.
class StreaksNotifier extends Notifier<StreakState> {
  @override
  StreakState build() => const StreakState();

  /// "missing a day offers 1 'streak shield' per month (auto-applies)."
  /// AC: "missed day with shield available shows shield-used note,
  /// streak intact." "Injury-mode pauses streaks without breaking" --
  /// checked first, since a pause never consumes a shield.
  void recordLogin({DateTime Function() now = DateTime.now}) {
    final today = _dateOnly(now());
    final last = state.lastLoginDate == null
        ? null
        : _dateOnly(state.lastLoginDate!);
    if (last == today) return;

    final gapDays = last == null ? 1 : today.difference(last).inDays;
    int newStreak;
    String note;
    var shieldMonth = state.loginShieldUsedMonth;

    if (last == null || gapDays == 1) {
      newStreak = state.currentLoginStreakDays + 1;
      note = 'Logged in -- streak day $newStreak';
    } else if (state.injuryModeActive) {
      newStreak = state.currentLoginStreakDays + 1;
      note = 'Injury-mode pause -- streak intact at day $newStreak';
    } else if (shieldMonth != _monthKey(today)) {
      newStreak = state.currentLoginStreakDays + 1;
      shieldMonth = _monthKey(today);
      note = 'Streak shield used -- streak intact at day $newStreak';
    } else {
      newStreak = 1;
      note = 'Streak reset to day 1 (shield already used this month)';
    }

    final notifier = ref.read(rewardsProvider.notifier);
    notifier.awardActions(const [
      EarningAction.dailyLogin,
    ], contextLabel: 'daily login');
    if (newStreak == 7) {
      notifier.awardBonus(20, label: 'Login streak day 7');
    } else if (newStreak == 30) {
      note += ' + scratch card earned (mock -- Luck Layer/E6-06 not built yet)';
    }

    state = state.copyWith(
      lastLoginDate: today,
      currentLoginStreakDays: newStreak,
      loginShieldUsedMonth: shieldMonth,
      log: [...state.log, note],
    );
  }

  /// "Playing streak: consecutive weeks with >=1 cricket activity."
  /// Same injury-pause/shield-free-pause semantics as login, at week
  /// granularity (no separate shield concept for playing streaks per
  /// PRD -- only injury-mode pauses it without breaking).
  void recordActivity({DateTime Function() now = DateTime.now}) {
    final thisWeek = _weekStart(now());
    final lastWeek = state.lastActivityWeekStart == null
        ? null
        : _weekStart(state.lastActivityWeekStart!);
    if (lastWeek == thisWeek) return;

    final gapWeeks = lastWeek == null
        ? 1
        : thisWeek.difference(lastWeek).inDays ~/ 7;
    int newStreak;
    String note;
    if (lastWeek == null || gapWeeks == 1) {
      newStreak = state.currentPlayingStreakWeeks + 1;
      note = 'Cricket activity logged -- playing streak $newStreak week(s)';
    } else if (state.injuryModeActive) {
      newStreak = state.currentPlayingStreakWeeks + 1;
      note = 'Injury-mode pause -- playing streak intact at $newStreak week(s)';
    } else {
      newStreak = 1;
      note = 'Playing streak reset to 1 week';
    }

    if (_playingStreakMilestoneWeeks.contains(newStreak)) {
      note += ' -- milestone chest';
      ref
          .read(rewardsProvider.notifier)
          .awardBonus(50, label: 'Playing streak milestone: $newStreak weeks');
      ref
          .read(achievementsProvider.notifier)
          .recordPlayingStreakWeeks(newStreak);
    }

    state = state.copyWith(
      lastActivityWeekStart: thisWeek,
      currentPlayingStreakWeeks: newStreak,
      log: [...state.log, note],
    );
  }

  void setInjuryMode(bool active) {
    state = state.copyWith(injuryModeActive: active);
  }
}

final streaksProvider = NotifierProvider<StreaksNotifier, StreakState>(
  StreaksNotifier.new,
);
