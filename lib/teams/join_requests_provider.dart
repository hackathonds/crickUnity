import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../persistence/persisted_notifier.dart';
import 'join_request_models.dart';

class DeniedJoinRequest {
  final JoinRequest request;
  final String? reason;

  const DeniedJoinRequest({required this.request, this.reason});

  Map<String, dynamic> toJson() => {
    'request': request.toJson(),
    'reason': reason,
  };

  factory DeniedJoinRequest.fromJson(Map<String, dynamic> json) {
    return DeniedJoinRequest(
      request: JoinRequest.fromJson(json['request'] as Map<String, dynamic>),
      reason: json['reason'] as String?,
    );
  }
}

class JoinRequestsState {
  final List<JoinRequest> pending;
  final List<DeniedJoinRequest> denied;
  final List<JoinRequest> approved;

  const JoinRequestsState({
    this.pending = const [],
    this.denied = const [],
    this.approved = const [],
  });

  JoinRequestsState copyWith({
    List<JoinRequest>? pending,
    List<DeniedJoinRequest>? denied,
    List<JoinRequest>? approved,
  }) {
    return JoinRequestsState(
      pending: pending ?? this.pending,
      denied: denied ?? this.denied,
      approved: approved ?? this.approved,
    );
  }

  Map<String, dynamic> toJson() => {
    'pending': pending.map((r) => r.toJson()).toList(),
    'denied': denied.map((d) => d.toJson()).toList(),
    'approved': approved.map((r) => r.toJson()).toList(),
  };

  factory JoinRequestsState.fromJson(Map<String, dynamic> json) {
    return JoinRequestsState(
      pending: [
        for (final r in (json['pending'] as List? ?? const []))
          JoinRequest.fromJson(r as Map<String, dynamic>),
      ],
      denied: [
        for (final d in (json['denied'] as List? ?? const []))
          DeniedJoinRequest.fromJson(d as Map<String, dynamic>),
      ],
      approved: [
        for (final r in (json['approved'] as List? ?? const []))
          JoinRequest.fromJson(r as Map<String, dynamic>),
      ],
    );
  }
}

/// PRD §6.4: "Captain/VC Approve/Deny; deny optionally with canned
/// reasons; auto-expire 14d."
class JoinRequestsNotifier extends PersistedNotifier<JoinRequestsState> {
  @override
  String get persistenceKey => 'join_requests_v1';

  @override
  JoinRequestsState seed() => JoinRequestsState(pending: mockJoinRequests());

  @override
  Map<String, dynamic> toJson(JoinRequestsState value) => value.toJson();

  @override
  JoinRequestsState fromJson(Map<String, dynamic> json) =>
      JoinRequestsState.fromJson(json);

  void approve(String id) {
    final request = state.pending.firstWhere((r) => r.id == id);
    state = state.copyWith(
      pending: state.pending.where((r) => r.id != id).toList(),
      approved: [...state.approved, request],
    );
  }

  void deny(String id, {String? reason}) {
    final request = state.pending.firstWhere((r) => r.id == id);
    state = state.copyWith(
      pending: state.pending.where((r) => r.id != id).toList(),
      denied: [
        ...state.denied,
        DeniedJoinRequest(request: request, reason: reason),
      ],
    );
  }
}

final joinRequestsProvider =
    NotifierProvider<JoinRequestsNotifier, JoinRequestsState>(
      JoinRequestsNotifier.new,
    );
