/// PRD §11.5: "Collections = planned inflows ('Season fund: ₹500 × 15
/// by 10 Aug'): progress bar, paid grid (avatars green/grey), auto-
/// reminders at deadline-7/1/0, partials allowed if enabled."
class Collection {
  final String id;
  final String title;
  final int amountPerMember;
  final List<String> memberNames;
  final DateTime deadline;
  final bool allowPartial;
  final Map<String, int> contributions;

  const Collection({
    required this.id,
    required this.title,
    required this.amountPerMember,
    required this.memberNames,
    required this.deadline,
    this.allowPartial = false,
    this.contributions = const {},
  });

  int get totalTarget => amountPerMember * memberNames.length;
  int get totalCollected => contributions.values.fold(0, (a, b) => a + b);
  double get progress => totalTarget == 0 ? 0 : totalCollected / totalTarget;

  bool hasPaidFully(String name) =>
      (contributions[name] ?? 0) >= amountPerMember;

  Collection copyWith({Map<String, int>? contributions}) {
    return Collection(
      id: id,
      title: title,
      amountPerMember: amountPerMember,
      memberNames: memberNames,
      deadline: deadline,
      allowPartial: allowPartial,
      contributions: contributions ?? this.contributions,
    );
  }
}

/// PRD §11.5: "auto-reminders at deadline-7/1/0." Mirrors E5-05's
/// reminderCadenceLabel() convention but counting down to a deadline
/// rather than up from a due date.
String collectionDeadlineLabel(
  DateTime deadline, {
  DateTime Function() now = DateTime.now,
}) {
  final daysLeft = deadline.difference(now()).inDays;
  if (daysLeft < 0) return 'Deadline passed ${-daysLeft}d ago';
  if (daysLeft == 0) return 'Due today';
  if (daysLeft <= 1) return 'Reminder: due tomorrow';
  if (daysLeft <= 7) return 'Reminder: $daysLeft days left';
  return '$daysLeft days left';
}
