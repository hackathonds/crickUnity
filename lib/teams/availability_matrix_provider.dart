import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../persistence/persisted_notifier.dart';
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

  Map<String, dynamic> toJson() => {
    'members': members,
    'events': events.map((e) => e.toJson()).toList(),
    'responses': responses.map((k, v) => MapEntry(k, v.name)),
    'lastNudgeAt': lastNudgeAt.map((k, v) => MapEntry(k, v.toIso8601String())),
  };

  factory AvailabilityMatrixState.fromJson(Map<String, dynamic> json) {
    return AvailabilityMatrixState(
      members: (json['members'] as List? ?? const []).cast<String>(),
      events: [
        for (final e in (json['events'] as List? ?? const []))
          AvailabilityEvent.fromJson(e as Map<String, dynamic>),
      ],
      responses: {
        for (final entry
            in (json['responses'] as Map<String, dynamic>? ?? const {}).entries)
          entry.key: AvailabilityResponse.values.byName(entry.value as String),
      },
      lastNudgeAt: {
        for (final entry
            in (json['lastNudgeAt'] as Map<String, dynamic>? ?? const {})
                .entries)
          entry.key: DateTime.parse(entry.value as String),
      },
    );
  }
}

/// Nudging isn't wired to a real notification backend (none exists yet
/// in this codebase) -- this only enforces and records the rate limit
/// itself, same "state without a real side-effect" precedent as other
/// reward/notification stubs this session.
class AvailabilityMatrixNotifier
    extends PersistedNotifier<AvailabilityMatrixState> {
  @override
  String get persistenceKey => 'availability_matrix_v1';

  @override
  AvailabilityMatrixState seed() => AvailabilityMatrixState(
    members: mockMatrixMembers(),
    events: mockMatrixEvents(),
    responses: mockMatrixResponses(),
  );

  @override
  Map<String, dynamic> toJson(AvailabilityMatrixState value) => value.toJson();

  @override
  AvailabilityMatrixState fromJson(Map<String, dynamic> json) =>
      AvailabilityMatrixState.fromJson(json);

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
