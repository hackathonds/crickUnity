/// DS §1.3 (Deep links & quick actions): "Every object screen has a
/// canonical link (match, team, profile, tournament, ground, expense,
/// post) that restores exact scroll-target (e.g., link to ball 14.3
/// opens Scorecard scrolled + highlighted). Launcher shortcuts
/// (long-press app icon): Start Scoring / My Next Match / Scan QR / Add
/// Expense. Notification taps always deep-link to the *actionable*
/// state, not the parent list (payment reminder -> Settle sheet
/// pre-filled, one tap from done)."
///
/// Backlog cites this story (E16-08) as "DS §1.3" only for the landing
/// rule -- real, no phantom citation here. No OS-level deep-link
/// (app_links), launcher-shortcut (quick_actions), or calendar-sync
/// (device_calendar) package exists in this project (pubspec.yaml has
/// none of them) -- everything here is the in-app Dart-side resolution
/// logic those packages would eventually call into, not real OS
/// registration.
library;

enum DeepLinkObjectType {
  match,
  team,
  profile,
  tournament,
  ground,
  expense,
  post,
}

const Map<DeepLinkObjectType, String> deepLinkObjectTypeLabels = {
  DeepLinkObjectType.match: 'Match',
  DeepLinkObjectType.team: 'Team',
  DeepLinkObjectType.profile: 'Profile',
  DeepLinkObjectType.tournament: 'Tournament',
  DeepLinkObjectType.ground: 'Ground',
  DeepLinkObjectType.expense: 'Expense',
  DeepLinkObjectType.post: 'Post',
};

/// A parsed canonical link, e.g. "cricunity://match/m-1/ball/14.3" ->
/// type=match, id='m-1', anchor='14.3'.
class DeepLinkTarget {
  final DeepLinkObjectType type;
  final String objectId;
  final String? anchor;

  const DeepLinkTarget({
    required this.type,
    required this.objectId,
    this.anchor,
  });

  static const _scheme = 'cricunity://';

  static DeepLinkTarget? parse(String link) {
    if (!link.startsWith(_scheme)) return null;
    final segments = link.substring(_scheme.length).split('/');
    if (segments.length < 2) return null;
    DeepLinkObjectType? type;
    for (final t in DeepLinkObjectType.values) {
      if (t.name == segments[0]) type = t;
    }
    if (type == null) return null;
    return DeepLinkTarget(
      type: type,
      objectId: segments[1],
      anchor: segments.length >= 4 && segments[2] == 'ball'
          ? segments[3]
          : null,
    );
  }

  String get canonicalLink =>
      '$_scheme${type.name}/$objectId${anchor != null ? '/ball/$anchor' : ''}';
}

enum LauncherShortcut { startScoring, myNextMatch, scanQr, addExpense }

const Map<LauncherShortcut, String> launcherShortcutLabels = {
  LauncherShortcut.startScoring: 'Start Scoring',
  LauncherShortcut.myNextMatch: 'My Next Match',
  LauncherShortcut.scanQr: 'Scan QR',
  LauncherShortcut.addExpense: 'Add Expense',
};

enum CalendarSyncCategory { matches, practice, bookings }

const Map<CalendarSyncCategory, String> calendarSyncCategoryLabels = {
  CalendarSyncCategory.matches: 'Matches',
  CalendarSyncCategory.practice: 'Practice',
  CalendarSyncCategory.bookings: 'Bookings',
};
