import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'join_request_models.dart';

class DeniedJoinRequest {
  final JoinRequest request;
  final String? reason;

  const DeniedJoinRequest({required this.request, this.reason});
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
}

/// PRD §6.4: "Captain/VC Approve/Deny; deny optionally with canned
/// reasons; auto-expire 14d."
class JoinRequestsNotifier extends Notifier<JoinRequestsState> {
  @override
  JoinRequestsState build() => JoinRequestsState(pending: mockJoinRequests());

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
