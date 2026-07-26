/// PRD §6.8: "Captain/VC/Manager post announcements (push-priority) →
/// pinned in team space + push ... Read-receipts list visible to poster
/// ('Seen by 11/15'). Members can react but comments toggleable per
/// announcement. Max 1 push-priority announcement per 6h (anti-spam)."
const int pushPriorityCooldownHours = 6;

class Announcement {
  final String id;
  final String authorName;
  final String body;
  final DateTime postedAt;
  final bool isPushPriority;
  final bool commentsEnabled;
  final Set<String> seenBy;
  final int totalMembers;

  const Announcement({
    required this.id,
    required this.authorName,
    required this.body,
    required this.postedAt,
    this.isPushPriority = false,
    this.commentsEnabled = true,
    this.seenBy = const {},
    required this.totalMembers,
  });

  Announcement copyWith({bool? commentsEnabled, Set<String>? seenBy}) {
    return Announcement(
      id: id,
      authorName: authorName,
      body: body,
      postedAt: postedAt,
      isPushPriority: isPushPriority,
      commentsEnabled: commentsEnabled ?? this.commentsEnabled,
      seenBy: seenBy ?? this.seenBy,
      totalMembers: totalMembers,
    );
  }
}

/// Mock data for the debug demo and tests -- no backend announcements
/// feed exists yet.
List<Announcement> mockAnnouncements({DateTime Function() now = DateTime.now}) {
  final today = now();
  return [
    Announcement(
      id: 'ann-1',
      authorName: 'Arjun Rao',
      body: 'Practice moved to Sunday 7 AM -- ground unavailable Saturday.',
      postedAt: today.subtract(const Duration(hours: 2)),
      isPushPriority: true,
      seenBy: const {'Priya Nair', 'Kabir Singh'},
      totalMembers: 18,
    ),
    Announcement(
      id: 'ann-2',
      authorName: 'Kabir Singh',
      body: 'Jersey orders close Friday -- confirm your size in the sheet.',
      postedAt: today.subtract(const Duration(days: 2)),
      seenBy: const {'Priya Nair'},
      totalMembers: 18,
    ),
  ];
}
