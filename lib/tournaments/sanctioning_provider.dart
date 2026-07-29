import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../persistence/persisted_notifier.dart';
import 'sanctioning_models.dart';

class SanctioningState {
  final List<Association> associations;
  final List<SanctionRequest> requests;

  const SanctioningState({
    this.associations = const [],
    this.requests = const [],
  });

  SanctioningState copyWith({
    List<Association>? associations,
    List<SanctionRequest>? requests,
  }) {
    return SanctioningState(
      associations: associations ?? this.associations,
      requests: requests ?? this.requests,
    );
  }

  List<SanctionRequest> requestsFor(String associationId) =>
      requests.where((r) => r.associationId == associationId).toList();

  List<SanctionRequest> grantedFor(String associationId) => requestsFor(
    associationId,
  ).where((r) => r.status == SanctionStatus.granted).toList();

  Map<String, dynamic> toJson() => {
    'associations': [for (final a in associations) a.toJson()],
    'requests': [for (final r in requests) r.toJson()],
  };

  factory SanctioningState.fromJson(Map<String, dynamic> json) {
    return SanctioningState(
      associations: [
        for (final a in json['associations'] as List)
          Association.fromJson(a as Map<String, dynamic>),
      ],
      requests: [
        for (final r in json['requests'] as List)
          SanctionRequest.fromJson(r as Map<String, dynamic>),
      ],
    );
  }
}

/// Backlog E10-09 -- Sanctioning + association pages engine. See
/// sanctioning_models.dart's top-of-file note for the exact DS §11.10
/// quote this implements.
class SanctioningNotifier extends PersistedNotifier<SanctioningState> {
  @override
  String get persistenceKey => 'sanctioning_v1';

  @override
  SanctioningState seed() =>
      SanctioningState(associations: _seedAssociations());

  @override
  Map<String, dynamic> toJson(SanctioningState value) => value.toJson();

  @override
  SanctioningState fromJson(Map<String, dynamic> json) =>
      SanctioningState.fromJson(json);

  static List<Association> _seedAssociations() => const [
    Association(
      id: 'assoc-city-cricket-board',
      name: 'City Cricket Board',
      verifiedBody: true,
      memberClubNames: ['Strikers CC', 'Riverside Warriors', 'City Titans'],
      circulars: ['Season fixtures window opens next month.'],
    ),
  ];

  /// DS §11.10: "Sanction request (organizer side): from Tournament
  /// Console -- request card."
  void requestSanction(
    String tournamentId,
    String tournamentName,
    String associationId,
    String associationName, {
    DateTime Function() now = DateTime.now,
  }) {
    state = state.copyWith(
      requests: [
        ...state.requests,
        SanctionRequest(
          id: 'sanction-${now().microsecondsSinceEpoch}',
          tournamentId: tournamentId,
          tournamentName: tournamentName,
          associationId: associationId,
          associationName: associationName,
          requestedAt: now(),
        ),
      ],
    );
  }

  /// DS §11.10: "status tracker (Requested/Review/Granted...)."
  void advanceStatus(String requestId) {
    _update(requestId, (r) {
      final next = switch (r.status) {
        SanctionStatus.requested => SanctionStatus.review,
        SanctionStatus.review => SanctionStatus.granted,
        SanctionStatus.granted => SanctionStatus.granted,
        SanctionStatus.revoked => SanctionStatus.revoked,
      };
      return r.copyWith(status: next);
    });
  }

  /// DS §11.10: "...with public-reason on revoke."
  void revoke(String requestId, String reason) {
    _update(
      requestId,
      (r) => r.copyWith(status: SanctionStatus.revoked, revokedReason: reason),
    );
  }

  void addCircular(String associationId, String text) {
    state = state.copyWith(
      associations: [
        for (final a in state.associations)
          if (a.id == associationId)
            Association(
              id: a.id,
              name: a.name,
              verifiedBody: a.verifiedBody,
              memberClubNames: a.memberClubNames,
              circulars: [...a.circulars, text],
            )
          else
            a,
      ],
    );
  }

  void _update(
    String requestId,
    SanctionRequest Function(SanctionRequest) transform,
  ) {
    state = state.copyWith(
      requests: [
        for (final r in state.requests)
          if (r.id == requestId) transform(r) else r,
      ],
    );
  }
}

final sanctioningProvider =
    NotifierProvider<SanctioningNotifier, SanctioningState>(
      SanctioningNotifier.new,
    );
