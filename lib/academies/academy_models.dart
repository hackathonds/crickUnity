/// PRD §2.10 (Academy Owner): "Purpose: Run a cricket academy as a
/// business: batches, fees, coaches, talent pipeline. Permissions:
/// Academy profile & verification; create batches (age groups,
/// schedules, fees); enroll students (guardian consent flow for
/// minors); assign coaches; fee collection ledger with due-date
/// reminders; publish trials/events; showcase academy achievements;
/// talent showcase board visible to Team Owners/Organizers (student
/// opt-in). Restrictions: Cannot view student data beyond academy
/// context; minor data is guardian-gated; cannot message minors
/// directly (messages route through guardian-visible channel)."
///
/// The messaging restriction ("route through guardian-visible
/// channel") is noted in the UI but not wired into the real Messaging
/// module (lib/messaging/) -- that would mean threading a guardian-
/// routing rule through an unrelated module's DM pipeline, out of
/// proportion for this story; flagged rather than silently built.
library;

class Batch {
  final String id;
  final String name;
  final String ageGroup;
  final String scheduleNote;
  final int feeAmount;
  final String? coachName;

  const Batch({
    required this.id,
    required this.name,
    required this.ageGroup,
    required this.scheduleNote,
    required this.feeAmount,
    this.coachName,
  });

  Batch copyWith({String? coachName}) {
    return Batch(
      id: id,
      name: name,
      ageGroup: ageGroup,
      scheduleNote: scheduleNote,
      feeAmount: feeAmount,
      coachName: coachName ?? this.coachName,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'ageGroup': ageGroup,
    'scheduleNote': scheduleNote,
    'feeAmount': feeAmount,
    'coachName': coachName,
  };

  factory Batch.fromJson(Map<String, dynamic> json) {
    return Batch(
      id: json['id'] as String,
      name: json['name'] as String,
      ageGroup: json['ageGroup'] as String,
      scheduleNote: json['scheduleNote'] as String,
      feeAmount: json['feeAmount'] as int,
      coachName: json['coachName'] as String?,
    );
  }
}

class Student {
  final String id;
  final String name;
  final bool isMinor;
  final String? guardianName;
  final bool guardianConsentGiven;
  final String batchId;
  final bool talentShowcaseOptIn;

  /// Backlog addendum (PRD §2.8, Coach): "view attached players' full
  /// analytics (with player consent toggle, default ON for academy
  /// students, OFF for adult team attachments)." Every Student here is
  /// an academy enrollee, so the default is ON per that rule; "adult
  /// team attachments" is a different, non-academy coach-player
  /// relationship with no model in this codebase yet -- flagged.
  final bool analyticsConsentEnabled;

  const Student({
    required this.id,
    required this.name,
    this.isMinor = false,
    this.guardianName,
    this.guardianConsentGiven = false,
    required this.batchId,
    this.talentShowcaseOptIn = false,
    this.analyticsConsentEnabled = true,
  });

  Student copyWith({bool? talentShowcaseOptIn, bool? analyticsConsentEnabled}) {
    return Student(
      id: id,
      name: name,
      isMinor: isMinor,
      guardianName: guardianName,
      guardianConsentGiven: guardianConsentGiven,
      batchId: batchId,
      analyticsConsentEnabled:
          analyticsConsentEnabled ?? this.analyticsConsentEnabled,
      talentShowcaseOptIn: talentShowcaseOptIn ?? this.talentShowcaseOptIn,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'isMinor': isMinor,
    'guardianName': guardianName,
    'guardianConsentGiven': guardianConsentGiven,
    'batchId': batchId,
    'talentShowcaseOptIn': talentShowcaseOptIn,
    'analyticsConsentEnabled': analyticsConsentEnabled,
  };

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'] as String,
      name: json['name'] as String,
      isMinor: json['isMinor'] as bool? ?? false,
      guardianName: json['guardianName'] as String?,
      guardianConsentGiven: json['guardianConsentGiven'] as bool? ?? false,
      batchId: json['batchId'] as String,
      talentShowcaseOptIn: json['talentShowcaseOptIn'] as bool? ?? false,
      analyticsConsentEnabled: json['analyticsConsentEnabled'] as bool? ?? true,
    );
  }
}

/// PRD: "fee collection ledger with due-date reminders."
class FeeLedgerEntry {
  final String id;
  final String studentId;
  final String monthLabel;
  final int amount;
  final DateTime dueDate;
  final bool paid;

  const FeeLedgerEntry({
    required this.id,
    required this.studentId,
    required this.monthLabel,
    required this.amount,
    required this.dueDate,
    this.paid = false,
  });

  FeeLedgerEntry copyWith({bool? paid}) {
    return FeeLedgerEntry(
      id: id,
      studentId: studentId,
      monthLabel: monthLabel,
      amount: amount,
      dueDate: dueDate,
      paid: paid ?? this.paid,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'studentId': studentId,
    'monthLabel': monthLabel,
    'amount': amount,
    'dueDate': dueDate.toIso8601String(),
    'paid': paid,
  };

  factory FeeLedgerEntry.fromJson(Map<String, dynamic> json) {
    return FeeLedgerEntry(
      id: json['id'] as String,
      studentId: json['studentId'] as String,
      monthLabel: json['monthLabel'] as String,
      amount: json['amount'] as int,
      dueDate: DateTime.parse(json['dueDate'] as String),
      paid: json['paid'] as bool? ?? false,
    );
  }
}

class Trial {
  final String id;
  final String name;
  final String ageGroup;
  final DateTime date;
  final int registrationsCount;

  const Trial({
    required this.id,
    required this.name,
    required this.ageGroup,
    required this.date,
    this.registrationsCount = 0,
  });

  Trial copyWith({int? registrationsCount}) {
    return Trial(
      id: id,
      name: name,
      ageGroup: ageGroup,
      date: date,
      registrationsCount: registrationsCount ?? this.registrationsCount,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'ageGroup': ageGroup,
    'date': date.toIso8601String(),
    'registrationsCount': registrationsCount,
  };

  factory Trial.fromJson(Map<String, dynamic> json) {
    return Trial(
      id: json['id'] as String,
      name: json['name'] as String,
      ageGroup: json['ageGroup'] as String,
      date: DateTime.parse(json['date'] as String),
      registrationsCount: json['registrationsCount'] as int? ?? 0,
    );
  }
}
