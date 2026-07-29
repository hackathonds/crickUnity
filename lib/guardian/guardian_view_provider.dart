import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../persistence/persisted_notifier.dart';
import 'guardian_view_models.dart';

class GuardianViewState {
  final List<LinkedChild> children;
  final List<CoachNote> coachNotes;
  final List<SessionCompletion> sessionCompletions;
  final List<ConsentRequest> pendingConsents;

  const GuardianViewState({
    this.children = const [],
    this.coachNotes = const [],
    this.sessionCompletions = const [],
    this.pendingConsents = const [],
  });

  GuardianViewState copyWith({List<ConsentRequest>? pendingConsents}) {
    return GuardianViewState(
      children: children,
      coachNotes: coachNotes,
      sessionCompletions: sessionCompletions,
      pendingConsents: pendingConsents ?? this.pendingConsents,
    );
  }

  /// Only [pendingConsents] persists -- [children]/[coachNotes]/
  /// [sessionCompletions] are static mock rosters no method ever
  /// mutates, re-seeded fresh on every load rather than round-tripped
  /// through storage.
  Map<String, dynamic> toJson() => {
    'pendingConsents': [for (final c in pendingConsents) c.toJson()],
  };
}

/// No real guardian-child linking backend exists (the onboarding
/// guardian gate, E1-02, only ever models the child's own side of
/// consent) -- flagged mock linked-children roster, same convention as
/// every other missing-backend gap this session.
class GuardianViewNotifier extends PersistedNotifier<GuardianViewState> {
  @override
  String get persistenceKey => 'guardian_view_v1';

  @override
  Map<String, dynamic> toJson(GuardianViewState value) => value.toJson();

  @override
  GuardianViewState fromJson(Map<String, dynamic> json) {
    final base = seed();
    return base.copyWith(
      pendingConsents: [
        for (final c in json['pendingConsents'] as List)
          ConsentRequest.fromJson(c as Map<String, dynamic>),
      ],
    );
  }

  @override
  GuardianViewState seed() {
    final now = DateTime.now();
    return GuardianViewState(
      children: const [
        LinkedChild(
          name: 'Aarav Sharma',
          age: 14,
          followerCount: 32,
          pendingMessageRequests: 1,
        ),
        LinkedChild(name: 'Diya Sharma', age: 11, followerCount: 8),
      ],
      coachNotes: [
        CoachNote(
          childName: 'Aarav Sharma',
          coachName: 'Coach Mehta',
          note: 'Great improvement on off-side drives this week.',
          date: now.subtract(const Duration(days: 2)),
        ),
      ],
      sessionCompletions: const [
        SessionCompletion(
          childName: 'Aarav Sharma',
          completedThisMonth: 6,
          totalThisMonth: 8,
        ),
        SessionCompletion(
          childName: 'Diya Sharma',
          completedThisMonth: 3,
          totalThisMonth: 4,
        ),
      ],
      pendingConsents: const [
        ConsentRequest(
          id: 'consent-1',
          childName: 'Aarav Sharma',
          type: ConsentType.mediaTagging,
          description: 'Tag Aarav in a team photo from Sunday\'s match.',
        ),
      ],
    );
  }

  void approveConsent(String id) {
    state = state.copyWith(
      pendingConsents: state.pendingConsents.where((c) => c.id != id).toList(),
    );
  }

  void declineConsent(String id) {
    state = state.copyWith(
      pendingConsents: state.pendingConsents.where((c) => c.id != id).toList(),
    );
  }
}

final guardianViewProvider =
    NotifierProvider<GuardianViewNotifier, GuardianViewState>(
      GuardianViewNotifier.new,
    );
