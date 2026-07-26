import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'availability_matrix_models.dart';

/// PRD §6.11: "One-tap 'Nudge all pending' (max 1 nudge/12h/event)."
const int nudgeCooldownHours = 12;

class AvailabilityMatrixState {
  final List<String> members;
  final List<AvailabilityEvent> events;
  final Map<String, AvailabilityResponse> responses;
  final Map<String, DateTime> lastNudgeAt;

  const AvailabilityMatrixState({
    this.members = const [],
    this.events = const [],
    this.responses = const {},
    this.lastNudgeAt = const {},
  });

  AvailabilityResponse? responseFor(String member, String eventId) =>
      responses['$member|$eventId'];

  AvailabilityMatrixState copyWith({Map<String, DateTime>? lastNudgeAt}) {
    return AvailabilityMatrixState(
      members: members,
      events: events,
      responses: responses,
      lastNudgeAt: lastNudgeAt ?? this.lastNudgeAt,
    );
  }
}

/// Nudging isn't wired to a real notification backend (none exists yet
/// in this codebase) -- this only enforces and records the rate limit
/// itself, same "state without a real side-effect" precedent as other
/// reward/notification stubs this session.
class AvailabilityMatrixNotifier extends Notifier<AvailabilityMatrixState> {
  @override
  AvailabilityMatrixState build() => AvailabilityMatrixState(
    members: mockMatrixMembers(),
    events: mockMatrixEvents(),
    responses: mockMatrixResponses(),
  );

  bool canNudge(String eventId, {DateTime Function() now = DateTime.now}) {
    final last = state.lastNudgeAt[eventId];
    if (last == null) return true;
    return now().difference(last).inHours >= nudgeCooldownHours;
  }

  /// Returns null on success; a human-readable denial reason otherwise.
  String? nudgePending(
    String eventId, {
    DateTime Function() now = DateTime.now,
  }) {
    if (!canNudge(eventId, now: now)) {
      return 'Already nudged this event in the last $nudgeCooldownHours '
          'hours.';
    }
    state = state.copyWith(lastNudgeAt: {...state.lastNudgeAt, eventId: now()});
    return null;
  }
}

final availabilityMatrixProvider =
    NotifierProvider<AvailabilityMatrixNotifier, AvailabilityMatrixState>(
      AvailabilityMatrixNotifier.new,
    );
