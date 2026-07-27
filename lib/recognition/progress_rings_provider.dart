import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'progress_ring_models.dart';

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
DateTime _weekStart(DateTime d) =>
    _dateOnly(d).subtract(Duration(days: d.weekday - 1));

class ProgressRingsState {
  final Map<RingType, WeeklyRingProgress> rings;
  final RingType? justClosed;

  const ProgressRingsState({this.rings = const {}, this.justClosed});

  WeeklyRingProgress ringFor(
    RingType type, {
    DateTime Function() now = DateTime.now,
  }) {
    final existing = rings[type];
    final currentWeek = _weekStart(now());
    if (existing == null || existing.weekStart != currentWeek) {
      return WeeklyRingProgress(
        type: type,
        target: existing?.target ?? defaultWeeklyTargets[type]!,
        weekStart: currentWeek,
        closeStreak: existing?.closeStreak ?? 0,
      );
    }
    return existing;
  }

  ProgressRingsState copyWith({
    Map<RingType, WeeklyRingProgress>? rings,
    RingType? justClosed,
    bool clearJustClosed = false,
  }) {
    return ProgressRingsState(
      rings: rings ?? this.rings,
      justClosed: clearJustClosed ? null : (justClosed ?? this.justClosed),
    );
  }
}

/// Backlog addendum -- E8-08's Progress Rings engine.
class ProgressRingsNotifier extends Notifier<ProgressRingsState> {
  @override
  ProgressRingsState build() => const ProgressRingsState();

  void setTarget(
    RingType type,
    int target, {
    DateTime Function() now = DateTime.now,
  }) {
    final current = state.ringFor(type, now: now);
    _update(type, current.copyWith(target: target));
  }

  /// Detects a ring crossing 100% and increments its close streak +
  /// flags a burst to play once (consumed via [consumeJustClosed]).
  void recordProgress(
    RingType type,
    int amount, {
    DateTime Function() now = DateTime.now,
  }) {
    final current = state.ringFor(type, now: now);
    final wasClosed = current.isClosed;
    final updated = current.copyWith(progress: current.progress + amount);
    final nowClosed = updated.isClosed;

    _update(
      type,
      updated.copyWith(
        closeStreak: (!wasClosed && nowClosed)
            ? current.closeStreak + 1
            : current.closeStreak,
      ),
    );
    if (!wasClosed && nowClosed) {
      state = state.copyWith(justClosed: type);
    }
  }

  RingType? consumeJustClosed() {
    final closed = state.justClosed;
    if (closed != null) state = state.copyWith(clearJustClosed: true);
    return closed;
  }

  void _update(RingType type, WeeklyRingProgress updated) {
    state = state.copyWith(rings: {...state.rings, type: updated});
  }
}

final progressRingsProvider =
    NotifierProvider<ProgressRingsNotifier, ProgressRingsState>(
      ProgressRingsNotifier.new,
    );
