import 'profile_models.dart';

/// PRD §12.8: "Follower management: remove follower, restrict (they see
/// public-only without knowing)." DS §64: "Followers/Following lists with
/// mutual chips; restrict/remove via ⋮."
class FollowerEntry {
  final String name;

  /// Mutual = mutual follow (PRD §12.8's "Friends" definition), shown as a
  /// chip on the row.
  final bool isMutual;

  const FollowerEntry({required this.name, this.isMutual = false});

  Map<String, dynamic> toJson() => {'name': name, 'isMutual': isMutual};

  factory FollowerEntry.fromJson(Map<String, dynamic> json) {
    return FollowerEntry(
      name: json['name'] as String,
      isMutual: json['isMutual'] as bool? ?? false,
    );
  }
}

/// PRD's restriction is silent to the restricted person -- it never shows
/// on their side, it only changes what content resolves for them. Any
/// screen that renders a profile for a given viewer should pass the
/// *actual* [ViewerRelation] plus that viewer's restricted flag through
/// this function rather than branching on restriction directly, so the
/// downgrade rule lives in exactly one place.
ViewerRelation resolveViewerRelation({
  required ViewerRelation actual,
  required bool viewerIsRestricted,
}) {
  if (viewerIsRestricted && actual == ViewerRelation.follower) {
    return ViewerRelation.public;
  }
  return actual;
}

/// Mock roster for the debug demo -- no follow-graph backend exists yet,
/// same convention as every other module in this app.
List<FollowerEntry> mockFollowers() => const [
  FollowerEntry(name: 'Priya Nair', isMutual: true),
  FollowerEntry(name: 'Farhan Ali', isMutual: true),
  FollowerEntry(name: 'Vikram Shah'),
  FollowerEntry(name: 'Meera Joshi'),
  FollowerEntry(name: 'Suresh Patel'),
];

List<FollowerEntry> mockFollowing() => const [
  FollowerEntry(name: 'Priya Nair', isMutual: true),
  FollowerEntry(name: 'Farhan Ali', isMutual: true),
  FollowerEntry(name: 'Kunal Mehta'),
  FollowerEntry(name: 'Aditya Kumar'),
];
