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
/// PRD §15 (Notification System): "Channels (user-mutable
/// independently): Matches · Money · Team · Social · Rewards ·
/// Tournaments · Bookings · Safety/Account (unmutable). Priorities: P0
/// (push + persistent card) ... P1 (push) ... P2 (in-app badge only)
/// ... P3 (digest-only). Quiet hours: user-set (default 23:00–07:00)
/// -- P1 held & delivered after; P0 breaks through only for same-day
/// match logistics. Mute ladder per type/entity (8h/1w/forever).
/// Follow-ups: unactioned decision notifications auto-follow-up once
/// at 24h then stop (except money cadence §11.10 and availability,
/// which follows the captain's deadline)."
///
/// Backlog splits the Notification System across two stories: E12-04
/// built the center's data model/interactions (tabs, entity rollups,
/// filters, inline actions, mute ladder, swipe done/snooze) seeded with
/// a static representative card set. E12-05 (this story) is "full
/// catalog wiring per PRD §15 table -- implement each row's who/when/
/// priority/actions as data-driven config": [NotificationChannel]
/// replaces the narrower 5-value filter with PRD §15's full 8-channel
/// list; quiet hours and follow-ups are genuinely computed rather than
/// static; and notification_catalog.dart's generator reads every real
/// cross-module provider it can (matches, scoring, expenses, teams,
/// tournaments, bookings, rewards, moderation) to produce cards, rather
/// than a hardcoded seed. Catalog rows with no real backing data source
/// yet (no "follow a match/player" relationship graph, no messaging
/// module, no cross-tournament Organizer Score profile, no historical
/// "old record holder" ledger) are flagged in notification_catalog.dart
/// and still emitted as clearly-mocked cards, the same convention used
/// everywhere else this session.
library;

enum NotificationTab { forYou, following }

/// PRD §15: "Channels (user-mutable independently): Matches · Money ·
/// Team · Social · Rewards · Tournaments · Bookings · Safety/Account
/// (unmutable)." [all] is a UI-only sentinel (not a real channel) used
/// by the filter chips row and by [NotificationState.visibleFor] to
/// mean "no channel filter applied."
enum NotificationChannel {
  all,
  matches,
  money,
  team,
  social,
  rewards,
  tournaments,
  bookings,
  safetyAccount,
}

const Map<NotificationChannel, String> notificationChannelLabels = {
  NotificationChannel.all: 'All',
  NotificationChannel.matches: 'Matches',
  NotificationChannel.money: 'Money',
  NotificationChannel.team: 'Team',
  NotificationChannel.social: 'Social',
  NotificationChannel.rewards: 'Rewards',
  NotificationChannel.tournaments: 'Tournaments',
  NotificationChannel.bookings: 'Bookings',
  NotificationChannel.safetyAccount: 'Safety/Account',
};

/// PRD §15: "Safety/Account (unmutable)."
const Set<NotificationChannel> unmutableNotificationChannels = {
  NotificationChannel.safetyAccount,
};

/// PRD §15: "P0 (push + persistent card; e.g., match starts in 1h and
/// you're in XI), P1 (push; e.g., payment reminder), P2 (in-app badge
/// only; e.g., new follower), P3 (digest-only; e.g., weekly ranking
/// movement)."
enum NotificationPriority { p0, p1, p2, p3 }

enum NotificationActionType {
  accept,
  decline,
  pay,
  confirm,
  dispute,
  rsvpYes,
  rsvpNo,
  rsvpMaybe,
  view,
  viewReason,
  reRsvp,
  checkIn,
  directions,
  redeem,
  share,
  respond,
  reply,
  confirmReceipt,
  notReceived,
  doAMission,
  snooze,
}

const Map<NotificationActionType, String> notificationActionLabels = {
  NotificationActionType.accept: 'Accept',
  NotificationActionType.decline: 'Decline',
  NotificationActionType.pay: 'Pay',
  NotificationActionType.confirm: 'Confirm',
  NotificationActionType.dispute: 'Dispute',
  NotificationActionType.rsvpYes: 'Yes',
  NotificationActionType.rsvpNo: 'No',
  NotificationActionType.rsvpMaybe: 'Maybe',
  NotificationActionType.view: 'View',
  NotificationActionType.viewReason: 'View reason',
  NotificationActionType.reRsvp: 'Re-RSVP',
  NotificationActionType.checkIn: 'Check-in',
  NotificationActionType.directions: 'Directions',
  NotificationActionType.redeem: 'Redeem',
  NotificationActionType.share: 'Share',
  NotificationActionType.respond: 'Respond',
  NotificationActionType.reply: 'Reply',
  NotificationActionType.confirmReceipt: 'Confirm receipt',
  NotificationActionType.notReceived: 'Not received',
  NotificationActionType.doAMission: 'Do a mission',
  NotificationActionType.snooze: 'Snooze',
};

/// PRD §15: "Mute ladder per type/entity (8h/1w/forever)."
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

/// PRD §15: "Quiet hours: user-set (default 23:00–07:00)." Only the
/// hour-of-day is user-set (PRD gives no minute-level example), so a
/// plain hour int (0-23) is enough; [isActive] handles the overnight
/// wraparound (e.g. 23 -> 7 crosses midnight).
class QuietHoursSettings {
  final int startHour;
  final int endHour;
  final bool enabled;

  const QuietHoursSettings({
    this.startHour = 23,
    this.endHour = 7,
    this.enabled = true,
  });

  bool isActive(DateTime now) {
    if (!enabled) return false;
    final hour = now.hour;
    if (startHour == endHour) return true; // 24h quiet hours, edge case
    if (startHour < endHour) {
      return hour >= startHour && hour < endHour;
    }
    return hour >= startHour || hour < endHour; // wraps past midnight
  }

  QuietHoursSettings copyWith({int? startHour, int? endHour, bool? enabled}) {
    return QuietHoursSettings(
      startHour: startHour ?? this.startHour,
      endHour: endHour ?? this.endHour,
      enabled: enabled ?? this.enabled,
    );
  }
}

class NotificationCard {
  final String id;
  final NotificationTab tab;
  final String entityName;
  final String title;
  final NotificationPriority priority;
  final NotificationChannel channel;
  final List<NotificationActionType> actions;
  final bool read;
  final DateTime createdAt;
  final DateTime? snoozedUntil;

  /// PRD §15: "P0 breaks through only for same-day match logistics" --
  /// the sole named carve-out from the quiet-hours hold. See
  /// [QuietHoursSettings] / NotificationState.isHeldByQuietHours for how
  /// this is used: literally, only P0 cards flagged true here break
  /// through quiet hours; every other P0 (e.g. account/safety alerts)
  /// is held exactly like P1, since PRD names no broader carve-out.
  final bool isSameDayMatchLogistics;

  /// PRD §15: "Follow-ups: unactioned decision notifications
  /// auto-follow-up once at 24h then stop (except money cadence §11.10
  /// and availability, which follows the captain's deadline)." Money
  /// cards already have their own cadence via remindersProvider/
  /// reminderCadenceLabel; availability-poll cards follow the match's
  /// own captain-set deadline instead -- both are exempted from this
  /// generic 24h follow-up so the two cadences never fight.
  final bool followUpExempt;
  final DateTime? followedUpAt;

  const NotificationCard({
    required this.id,
    required this.tab,
    required this.entityName,
    required this.title,
    required this.priority,
    required this.channel,
    this.actions = const [],
    this.read = false,
    required this.createdAt,
    this.snoozedUntil,
    this.isSameDayMatchLogistics = false,
    this.followUpExempt = false,
    this.followedUpAt,
  });

  /// PRD §15: a card with inline actions represents a decision the
  /// notified party hasn't made yet.
  bool get isDecision => actions.isNotEmpty;

  NotificationCard copyWith({
    bool? read,
    DateTime? snoozedUntil,
    bool clearSnooze = false,
    DateTime? followedUpAt,
  }) {
    return NotificationCard(
      id: id,
      tab: tab,
      entityName: entityName,
      title: title,
      priority: priority,
      channel: channel,
      actions: actions,
      read: read ?? this.read,
      createdAt: createdAt,
      snoozedUntil: clearSnooze ? null : (snoozedUntil ?? this.snoozedUntil),
      isSameDayMatchLogistics: isSameDayMatchLogistics,
      followUpExempt: followUpExempt,
      followedUpAt: followedUpAt ?? this.followedUpAt,
    );
  }
}
