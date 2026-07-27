/// DS §11.16 (Safety & identity flows): "Guardian view (guardian's
/// drawer): child cards -> per-child dashboard (followers/messages
/// surface read-only, coach notes, session completion, consents pending
/// queue with approve sheets)."
library;

class LinkedChild {
  final String name;
  final int age;
  final int followerCount;
  final int pendingMessageRequests;

  const LinkedChild({
    required this.name,
    required this.age,
    this.followerCount = 0,
    this.pendingMessageRequests = 0,
  });
}

class CoachNote {
  final String childName;
  final String coachName;
  final String note;
  final DateTime date;

  const CoachNote({
    required this.childName,
    required this.coachName,
    required this.note,
    required this.date,
  });
}

class SessionCompletion {
  final String childName;
  final int completedThisMonth;
  final int totalThisMonth;

  const SessionCompletion({
    required this.childName,
    required this.completedThisMonth,
    required this.totalThisMonth,
  });
}

enum ConsentType { mediaTagging, academyEnrollment, teamInvite }

const Map<ConsentType, String> consentTypeLabels = {
  ConsentType.mediaTagging: 'Media tagging',
  ConsentType.academyEnrollment: 'Academy enrollment',
  ConsentType.teamInvite: 'Team invite',
};

class ConsentRequest {
  final String id;
  final String childName;
  final ConsentType type;
  final String description;

  const ConsentRequest({
    required this.id,
    required this.childName,
    required this.type,
    required this.description,
  });
}
