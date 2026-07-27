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
}

class Student {
  final String id;
  final String name;
  final bool isMinor;
  final String? guardianName;
  final bool guardianConsentGiven;
  final String batchId;
  final bool talentShowcaseOptIn;

  const Student({
    required this.id,
    required this.name,
    this.isMinor = false,
    this.guardianName,
    this.guardianConsentGiven = false,
    required this.batchId,
    this.talentShowcaseOptIn = false,
  });

  Student copyWith({bool? talentShowcaseOptIn}) {
    return Student(
      id: id,
      name: name,
      isMinor: isMinor,
      guardianName: guardianName,
      guardianConsentGiven: guardianConsentGiven,
      batchId: batchId,
      talentShowcaseOptIn: talentShowcaseOptIn ?? this.talentShowcaseOptIn,
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
}
