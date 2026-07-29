import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../persistence/persisted_notifier.dart';
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

  Map<String, dynamic> toJson() => {
    'documents': documents.map((d) => d.toJson()).toList(),
  };

  factory TeamDocumentsState.fromJson(Map<String, dynamic> json) {
    return TeamDocumentsState(
      documents: [
        for (final d in (json['documents'] as List? ?? const []))
          TeamDocument.fromJson(d as Map<String, dynamic>),
      ],
    );
  }
}

/// DS §7 screen 20 (Documents): a "list + submit sheet" pattern screen,
/// gated to the roles the backlog names as able to upload ("role-based
/// doc uploads").
class TeamDocumentsNotifier extends PersistedNotifier<TeamDocumentsState> {
  @override
  String get persistenceKey => 'team_documents_v1';

  @override
  TeamDocumentsState seed() =>
      TeamDocumentsState(documents: mockTeamDocuments());

  @override
  Map<String, dynamic> toJson(TeamDocumentsState value) => value.toJson();

  @override
  TeamDocumentsState fromJson(Map<String, dynamic> json) =>
      TeamDocumentsState.fromJson(json);

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
