import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'team_document_models.dart';
import 'team_member_models.dart';

class UploadResult {
  final String? error;

  const UploadResult({this.error});

  bool get succeeded => error == null;
}

class TeamDocumentsState {
  final List<TeamDocument> documents;

  const TeamDocumentsState({this.documents = const []});

  TeamDocumentsState copyWith({List<TeamDocument>? documents}) {
    return TeamDocumentsState(documents: documents ?? this.documents);
  }
}

/// DS §7 screen 20 (Documents): a "list + submit sheet" pattern screen,
/// gated to the roles the backlog names as able to upload ("role-based
/// doc uploads").
class TeamDocumentsNotifier extends Notifier<TeamDocumentsState> {
  @override
  TeamDocumentsState build() =>
      TeamDocumentsState(documents: mockTeamDocuments());

  UploadResult upload({
    required String name,
    required String uploaderName,
    required TeamMemberRole uploaderRole,
    DateTime Function() now = DateTime.now,
  }) {
    if (!documentUploadRoles.contains(uploaderRole)) {
      return const UploadResult(
        error: "You don't have permission to upload documents.",
      );
    }
    if (name.trim().isEmpty) {
      return const UploadResult(error: 'Name the document before uploading.');
    }
    state = state.copyWith(
      documents: [
        TeamDocument(
          id: 'doc-${now().millisecondsSinceEpoch}',
          name: name.trim(),
          uploaderName: uploaderName,
          uploadedAt: now(),
        ),
        ...state.documents,
      ],
    );
    return const UploadResult();
  }
}

final teamDocumentsProvider =
    NotifierProvider<TeamDocumentsNotifier, TeamDocumentsState>(
      TeamDocumentsNotifier.new,
    );
