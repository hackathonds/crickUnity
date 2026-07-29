import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../persistence/persisted_notifier.dart';
import 'verification_models.dart';

class VerificationState {
  final List<VerificationRequest> requests;

  const VerificationState({this.requests = const []});

  VerificationState copyWith({List<VerificationRequest>? requests}) {
    return VerificationState(requests: requests ?? this.requests);
  }

  Map<String, dynamic> toJson() => {
    'requests': [for (final r in requests) r.toJson()],
  };

  factory VerificationState.fromJson(Map<String, dynamic> json) {
    return VerificationState(
      requests: [
        for (final r in json['requests'] as List)
          VerificationRequest.fromJson(r as Map<String, dynamic>),
      ],
    );
  }
}

/// No real document-upload or Admin-review backend exists -- flagged
/// mock, same convention as every other missing-backend gap this
/// session. "document-based" is represented as a boolean checkbox
/// rather than a real file upload (no file-picker package exists).
class VerificationNotifier extends PersistedNotifier<VerificationState> {
  @override
  String get persistenceKey => 'verification_v1';

  @override
  Map<String, dynamic> toJson(VerificationState value) => value.toJson();

  @override
  VerificationState fromJson(Map<String, dynamic> json) =>
      VerificationState.fromJson(json);

  @override
  VerificationState seed() {
    return const VerificationState(
      requests: [
        VerificationRequest(
          id: 'verif-seed-1',
          requesterName: 'Green Valley Ground',
          markType: VerificationMarkType.greenVerifiedRecord,
          entityName: 'Green Valley Ground',
          justification: 'Ownership deed and utility bill attached.',
          documentAttached: true,
        ),
      ],
    );
  }

  String submitRequest({
    required String requesterName,
    required VerificationMarkType markType,
    required String entityName,
    required String justification,
    required bool documentAttached,
  }) {
    final id = 'verif-${DateTime.now().millisecondsSinceEpoch}';
    state = state.copyWith(
      requests: [
        VerificationRequest(
          id: id,
          requesterName: requesterName,
          markType: markType,
          entityName: entityName,
          justification: justification,
          documentAttached: documentAttached,
        ),
        ...state.requests,
      ],
    );
    return id;
  }

  void approve(String requestId, {String? adminNote}) {
    state = state.copyWith(
      requests: [
        for (final r in state.requests)
          if (r.id == requestId)
            r.copyWith(
              status: VerificationRequestStatus.approved,
              adminNote: adminNote,
            )
          else
            r,
      ],
    );
  }

  void reject(String requestId, {required String adminNote}) {
    state = state.copyWith(
      requests: [
        for (final r in state.requests)
          if (r.id == requestId)
            r.copyWith(
              status: VerificationRequestStatus.rejected,
              adminNote: adminNote,
            )
          else
            r,
      ],
    );
  }
}

final verificationProvider =
    NotifierProvider<VerificationNotifier, VerificationState>(
      VerificationNotifier.new,
    );
