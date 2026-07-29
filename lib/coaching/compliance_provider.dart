import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../persistence/persisted_notifier.dart';
import 'compliance_models.dart';

class ComplianceState {
  final List<ComplianceDocument> documents;

  const ComplianceState({this.documents = const []});

  ComplianceState copyWith({List<ComplianceDocument>? documents}) =>
      ComplianceState(documents: documents ?? this.documents);

  Map<String, dynamic> toJson() => {
    'documents': [for (final d in documents) d.toJson()],
  };

  factory ComplianceState.fromJson(Map<String, dynamic> json) {
    return ComplianceState(
      documents: [
        for (final d in json['documents'] as List)
          ComplianceDocument.fromJson(d as Map<String, dynamic>),
      ],
    );
  }

  List<ComplianceDocument> forCoach(String coachName) =>
      documents.where((d) => d.coachName == coachName).toList();

  /// "Signed-status matrix" -- one row per required doc type, null
  /// where the coach has no document of that type on file yet.
  Map<ComplianceDocType, ComplianceDocument?> matrixFor(String coachName) {
    final docs = forCoach(coachName);
    return {
      for (final type in requiredComplianceDocs)
        type: docs.where((d) => d.docType == type).firstOrNull,
    };
  }

  /// Backlog: "signed-status matrix blocking registration." A coach is
  /// compliant only when every required doc type is on file, signed,
  /// and not expired.
  bool isCoachCompliant(String coachName, DateTime now) {
    final matrix = matrixFor(coachName);
    return requiredComplianceDocs.every(
      (type) => matrix[type]?.isValid(now) ?? false,
    );
  }
}

/// Backlog E11-04 -- Compliance vault engine. See
/// compliance_models.dart's top-of-file note for the flagged phantom
/// "G.13" citation and this story's own-words scope.
class ComplianceNotifier extends PersistedNotifier<ComplianceState> {
  @override
  String get persistenceKey => 'compliance_v1';

  @override
  Map<String, dynamic> toJson(ComplianceState value) => value.toJson();

  @override
  ComplianceState fromJson(Map<String, dynamic> json) =>
      ComplianceState.fromJson(json);

  @override
  ComplianceState seed() => ComplianceState(
    documents: [
      ComplianceDocument(
        id: 'compliance-seed-1',
        coachName: 'Coach Ramesh',
        docType: ComplianceDocType.coachingCertification,
        issuedDate: DateTime.now().subtract(const Duration(days: 200)),
        expiryDate: DateTime.now().add(const Duration(days: 165)),
        signed: true,
      ),
    ],
  );

  void addDocument(
    String coachName,
    ComplianceDocType docType,
    DateTime expiryDate, {
    DateTime Function() now = DateTime.now,
  }) {
    state = state.copyWith(
      documents: [
        for (final d in state.documents)
          if (!(d.coachName == coachName && d.docType == docType)) d,
        ComplianceDocument(
          id: 'compliance-${now().microsecondsSinceEpoch}',
          coachName: coachName,
          docType: docType,
          issuedDate: now(),
          expiryDate: expiryDate,
        ),
      ],
    );
  }

  void signDocument(String documentId) {
    state = state.copyWith(
      documents: [
        for (final d in state.documents)
          if (d.id == documentId) d.copyWith(signed: true) else d,
      ],
    );
  }
}

final complianceProvider =
    NotifierProvider<ComplianceNotifier, ComplianceState>(
      ComplianceNotifier.new,
    );
