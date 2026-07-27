import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'verification_models.dart';

class VerificationState {
  final List<VerificationRequest> requests;

  const VerificationState({this.requests = const []});

  VerificationState copyWith({List<VerificationRequest>? requests}) {
    return VerificationState(requests: requests ?? this.requests);
  }
}

/// No real document-upload or Admin-review backend exists -- flagged
/// mock, same convention as every other missing-backend gap this
/// session. "document-based" is represented as a boolean checkbox
/// rather than a real file upload (no file-picker package exists).
class VerificationNotifier extends Notifier<VerificationState> {
  @override
  VerificationState build() {
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
