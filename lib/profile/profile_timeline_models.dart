/// PRD §5.19: "Timeline tab = life-in-cricket feed: joined team, debut,
/// first fifty, captaincy, championships — auto-generated, each entry
/// sharable; user can hide individual entries."
library;

enum ProfileTimelineEntryType {
  joinedTeam,
  debut,
  firstFifty,
  captaincy,
  championship,
}

const Map<ProfileTimelineEntryType, String> profileTimelineEntryTypeLabels = {
  ProfileTimelineEntryType.joinedTeam: 'Joined team',
  ProfileTimelineEntryType.debut: 'Debut',
  ProfileTimelineEntryType.firstFifty: 'First fifty',
  ProfileTimelineEntryType.captaincy: 'Captaincy',
  ProfileTimelineEntryType.championship: 'Championship',
};

class ProfileTimelineEntry {
  final String id;
  final ProfileTimelineEntryType type;
  final DateTime date;
  final String title;
  final String subtitle;

  const ProfileTimelineEntry({
    required this.id,
    required this.type,
    required this.date,
    required this.title,
    this.subtitle = '',
  });
}
