import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'availability_matrix_models.dart';
import 'practice_session_models.dart';

/// PRD's AC: "check-in only within venue window ±1h."
const int checkInWindowHours = 1;

/// PRD §13.1 earning table: "Practice attendance | 8 coins | 15 XP |
/// Cap 4/week."
const int practiceAttendanceCoins = 8;
const int practiceAttendanceXp = 15;
const int practiceAttendanceWeeklyCap = 4;

class CheckInResult {
  final String? error;
  final int coinsGranted;
  final int xpGranted;

  const CheckInResult({this.error, this.coinsGranted = 0, this.xpGranted = 0});

  bool get succeeded => error == null;
}

class PracticeSessionState {
  final PracticeSession session;

  /// Mock stand-in for "how many practice sessions has this member
  /// already been credited for this week" -- no attendance-history
  /// backend exists yet (same pattern as CreateTeamProvider's
  /// ownedTeamCount). Seeded so the cap is reachable in the debug demo.
  final Map<String, int> weeklyAttendanceCount;

  const PracticeSessionState({
    required this.session,
    this.weeklyAttendanceCount = const {},
  });

  PracticeSessionState copyWith({
    PracticeSession? session,
    Map<String, int>? weeklyAttendanceCount,
  }) {
    return PracticeSessionState(
      session: session ?? this.session,
      weeklyAttendanceCount:
          weeklyAttendanceCount ?? this.weeklyAttendanceCount,
    );
  }
}

class PracticeSessionNotifier extends Notifier<PracticeSessionState> {
  @override
  PracticeSessionState build() => PracticeSessionState(
    session: mockPracticeSession(),
    weeklyAttendanceCount: const {'Kabir Singh': practiceAttendanceWeeklyCap},
  );

  bool canCheckIn({DateTime Function() now = DateTime.now}) {
    final diff = now().difference(state.session.scheduledAt).abs();
    return diff.inMinutes <= checkInWindowHours * 60;
  }

  void rsvp(String memberName, AvailabilityResponse response) {
    state = state.copyWith(
      session: state.session.copyWith(
        rsvps: {...state.session.rsvps, memberName: response},
      ),
    );
  }

  /// Roll-call mode (coach) uses the same check-in path a self-scan QR
  /// would -- both just mark a member present; no real QR-scan/camera
  /// package exists in this codebase (same gap class as the Team invite
  /// sheet's QR tab), so "scanning" isn't distinguished from a manual tap
  /// here.
  CheckInResult checkIn(
    String memberName, {
    DateTime Function() now = DateTime.now,
  }) {
    if (state.session.checkedIn.contains(memberName)) {
      return const CheckInResult(error: 'Already checked in.');
    }
    if (!canCheckIn(now: now)) {
      return CheckInResult(
        error:
            'Check-in only opens $checkInWindowHours hour before/after the '
            'session.',
      );
    }

    final weekly = state.weeklyAttendanceCount[memberName] ?? 0;
    final underCap = weekly < practiceAttendanceWeeklyCap;
    state = state.copyWith(
      session: state.session.copyWith(
        checkedIn: {...state.session.checkedIn, memberName},
      ),
      weeklyAttendanceCount: {
        ...state.weeklyAttendanceCount,
        memberName: weekly + 1,
      },
    );
    return CheckInResult(
      coinsGranted: underCap ? practiceAttendanceCoins : 0,
      xpGranted: underCap ? practiceAttendanceXp : 0,
    );
  }

  void excuseNoShow(String memberName, {required String reason}) {
    final updated = [
      for (final record in state.session.noShows)
        if (record.memberName != memberName) record,
      NoShowRecord(memberName: memberName, excused: true, reason: reason),
    ];
    state = state.copyWith(session: state.session.copyWith(noShows: updated));
  }

  /// PRD §6.9: "No-show after 'Yes' logs a Trust ding (captain can excuse
  /// with reason -- excused = neutral)." No Trust-score computation
  /// exists anywhere in this codebase (Trust is band-only, per E2-07) --
  /// this just records the no-show itself, it doesn't move a real score.
  void endSession() {
    final alreadyExcused = state.session.noShows
        .map((r) => r.memberName)
        .toSet();
    final noShows = [
      ...state.session.noShows,
      for (final member in state.session.roster)
        if (state.session.rsvps[member] == AvailabilityResponse.yes &&
            !state.session.checkedIn.contains(member) &&
            !alreadyExcused.contains(member))
          NoShowRecord(memberName: member),
    ];
    state = state.copyWith(
      session: state.session.copyWith(ended: true, noShows: noShows),
    );
  }
}

final practiceSessionProvider =
    NotifierProvider<PracticeSessionNotifier, PracticeSessionState>(
      PracticeSessionNotifier.new,
    );
