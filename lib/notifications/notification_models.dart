/// PRD §3.7 (Notification Center): "Two tabs: For You (personal:
/// mentions, payments, selections, confirmations) and Following
/// (teams/tournaments/players you follow). Grouping: by entity
/// ('Lions CC — 3 updates') expandable inline. Inline actions on
/// notification cards: Accept/Decline, Pay, Confirm, RSVP, Mark read.
/// Filters row: All · Mentions · Money · Matches · Rewards. Long-press
/// a notification: Mute this type · Mute this entity (8h/1w/forever) ·
/// Turn off. 'Clear all read' and per-section mark-read. Priority
/// notifications ... pin to top with colored edge." PRD §3.13 (Swipe
/// Actions): "Notification: swipe right = done/read; swipe left =
/// snooze (1h/tonight/tomorrow options) ... destructive swipes show
/// undo snackbar (5s) before commit."
///
/// Backlog splits the Notification System across two stories: this one
/// (E12-04) builds the center's data model/interactions; E12-05 is
/// explicitly "full catalog wiring per PRD §15 table ... data-driven
/// config" -- wiring every catalog row to its real cross-module
/// trigger. This story therefore seeds a representative set of cards
/// spanning PRD §15's catalog excerpt (flagged as static/seeded, not
/// yet fed by real triggers across every module -- that's E12-05's
/// job), while genuinely implementing every interaction PRD names:
/// tabs, entity rollups, filters, inline actions, mute ladder, swipe
/// done/snooze with undo.
library;

enum NotificationTab { forYou, following }

enum NotificationFilter { all, mentions, money, matches, rewards }

const Map<NotificationFilter, String> notificationFilterLabels = {
  NotificationFilter.all: 'All',
  NotificationFilter.mentions: 'Mentions',
  NotificationFilter.money: 'Money',
  NotificationFilter.matches: 'Matches',
  NotificationFilter.rewards: 'Rewards',
};

/// PRD §15: "P0 (push + persistent card) ... P1 (push) ... P2 (in-app
/// badge only) ... P3 (digest-only)."
enum NotificationPriority { p0, p1, p2, p3 }

enum NotificationActionType {
  accept,
  decline,
  pay,
  confirm,
  rsvpYes,
  rsvpNo,
  view,
}

const Map<NotificationActionType, String> notificationActionLabels = {
  NotificationActionType.accept: 'Accept',
  NotificationActionType.decline: 'Decline',
  NotificationActionType.pay: 'Pay',
  NotificationActionType.confirm: 'Confirm',
  NotificationActionType.rsvpYes: 'Yes',
  NotificationActionType.rsvpNo: 'No',
  NotificationActionType.view: 'View',
};

/// PRD §15: "Mute ladder per type\entity (8h\1w\forever)."
enum MuteDuration { eightHours, oneWeek, forever }

const Map<MuteDuration, String> muteDurationLabels = {
  MuteDuration.eightHours: '8 hours',
  MuteDuration.oneWeek: '1 week',
  MuteDuration.forever: 'Forever',
};

/// PRD §3.13: "swipe left = snooze (1h/tonight/tomorrow options)."
enum SnoozeDuration { oneHour, tonight, tomorrow }

const Map<SnoozeDuration, String> snoozeDurationLabels = {
  SnoozeDuration.oneHour: '1 hour',
  SnoozeDuration.tonight: 'Tonight',
  SnoozeDuration.tomorrow: 'Tomorrow',
};

class NotificationCard {
  final String id;
  final NotificationTab tab;
  final String entityName;
  final String title;
  final NotificationPriority priority;
  final NotificationFilter filter;
  final List<NotificationActionType> actions;
  final bool read;
  final DateTime createdAt;
  final DateTime? snoozedUntil;

  const NotificationCard({
    required this.id,
    required this.tab,
    required this.entityName,
    required this.title,
    required this.priority,
    required this.filter,
    this.actions = const [],
    this.read = false,
    required this.createdAt,
    this.snoozedUntil,
  });

  NotificationCard copyWith({
    bool? read,
    DateTime? snoozedUntil,
    bool clearSnooze = false,
  }) {
    return NotificationCard(
      id: id,
      tab: tab,
      entityName: entityName,
      title: title,
      priority: priority,
      filter: filter,
      actions: actions,
      read: read ?? this.read,
      createdAt: createdAt,
      snoozedUntil: clearSnooze ? null : (snoozedUntil ?? this.snoozedUntil),
    );
  }
}
