import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'conduct_report_models.dart';

class ConductReportState {
  final List<ConductReport> reports;

  const ConductReportState({this.reports = const []});

  ConductReportState copyWith({List<ConductReport>? reports}) {
    return ConductReportState(reports: reports ?? this.reports);
  }
}

/// No real organizer-review pipeline exists (Epic E8's tournaments never
/// route conduct incidents anywhere) -- filed reports move straight to
/// [ConductReportStatus.underOrganizerReview] locally rather than being
/// sent to a real backend, same convention as every other
/// missing-backend gap this session.
class ConductReportNotifier extends Notifier<ConductReportState> {
  @override
  ConductReportState build() {
    return ConductReportState(
      reports: [
        ConductReport(
          id: 'conduct-seed-1',
          matchLabel: 'vs City Titans',
          reporterName: 'Imran Khan',
          reportedPlayerName: 'Kunal Mehta',
          incidentType: ConductIncidentType.dissent,
          description:
              'Player argued an LBW decision for over a minute, delaying '
              'play and using aggressive language toward the umpire.',
          severity: ConductSeverity.moderate,
          status: ConductReportStatus.actionTaken,
          filedAt: DateTime.now().subtract(const Duration(days: 6)),
        ),
      ],
    );
  }

  String fileReport({
    required String matchLabel,
    required String reporterName,
    required String reportedPlayerName,
    required ConductIncidentType incidentType,
    required String description,
    required ConductSeverity severity,
    required bool relationshipDisclosed,
    DateTime Function() now = DateTime.now,
  }) {
    final id = 'conduct-${now().millisecondsSinceEpoch}';
    state = state.copyWith(
      reports: [
        ConductReport(
          id: id,
          matchLabel: matchLabel,
          reporterName: reporterName,
          reportedPlayerName: reportedPlayerName,
          incidentType: incidentType,
          description: description,
          severity: severity,
          status: ConductReportStatus.underOrganizerReview,
          filedAt: now(),
          relationshipDisclosed: relationshipDisclosed,
        ),
        ...state.reports,
      ],
    );
    return id;
  }

  /// PRD notification catalog: "Conduct report filed on you ... After
  /// review opens | P1 | Respond/Appeal."
  void appeal(String reportId, String appealText) {
    state = state.copyWith(
      reports: [
        for (final r in state.reports)
          if (r.id == reportId)
            r.copyWith(
              status: ConductReportStatus.appealed,
              appealText: appealText,
            )
          else
            r,
      ],
    );
  }
}

final conductReportProvider =
    NotifierProvider<ConductReportNotifier, ConductReportState>(
      ConductReportNotifier.new,
    );
