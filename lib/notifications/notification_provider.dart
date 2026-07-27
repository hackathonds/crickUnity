import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'notification_models.dart';

class NotificationState {
  final List<NotificationCard> cards;
  final Map<String, DateTime?> mutedEntities;
  final Map<NotificationFilter, DateTime?> mutedTypes;

  const NotificationState({
    this.cards = const [],
    this.mutedEntities = const {},
    this.mutedTypes = const {},
  });

  NotificationState copyWith({
    List<NotificationCard>? cards,
    Map<String, DateTime?>? mutedEntities,
    Map<NotificationFilter, DateTime?>? mutedTypes,
  }) {
    return NotificationState(
      cards: cards ?? this.cards,
      mutedEntities: mutedEntities ?? this.mutedEntities,
      mutedTypes: mutedTypes ?? this.mutedTypes,
    );
  }

  bool _muteActive(DateTime? mutedUntil) =>
      mutedUntil == null || DateTime.now().isBefore(mutedUntil);

  /// PRD §15: mute is either a timed hold (8h/1w) or permanent
  /// ("forever" is stored as a null value meaning "no expiry").
  bool isEntityMuted(String entityName) =>
      mutedEntities.containsKey(entityName) &&
      _muteActive(mutedEntities[entityName]);

  bool isTypeMuted(NotificationFilter filter) =>
      mutedTypes.containsKey(filter) && _muteActive(mutedTypes[filter]);

  List<NotificationCard> visibleFor(
    NotificationTab tab,
    NotificationFilter filter,
    DateTime now,
  ) {
    return cards.where((c) {
      if (c.tab != tab) return false;
      if (c.snoozedUntil != null && now.isBefore(c.snoozedUntil!)) return false;
      if (isEntityMuted(c.entityName)) return false;
      if (isTypeMuted(c.filter)) return false;
      if (filter != NotificationFilter.all && c.filter != filter) return false;
      return true;
    }).toList()..sort((a, b) {
      if (a.priority != b.priority) {
        return a.priority.index.compareTo(b.priority.index);
      }
      return b.createdAt.compareTo(a.createdAt);
    });
  }
}

/// Backlog E12-04 -- Notification center engine. See
/// notification_models.dart's top-of-file note for the exact PRD
/// §3.7/§3.13 quotes and the E12-04/E12-05 scope split.
class NotificationNotifier extends Notifier<NotificationState> {
  @override
  NotificationState build() => NotificationState(cards: _seedCards());

  static List<NotificationCard> _seedCards() {
    final now = DateTime.now();
    return [
      NotificationCard(
        id: 'notif-availability',
        tab: NotificationTab.forYou,
        entityName: 'Strikers CC',
        title: 'Availability poll: Sunday vs Riverside Warriors',
        priority: NotificationPriority.p1,
        filter: NotificationFilter.matches,
        actions: const [
          NotificationActionType.rsvpYes,
          NotificationActionType.rsvpNo,
        ],
        createdAt: now.subtract(const Duration(hours: 2)),
      ),
      NotificationCard(
        id: 'notif-match-soon',
        tab: NotificationTab.forYou,
        entityName: 'Strikers CC',
        title: 'Match starts in 2h -- Green Valley Ground',
        priority: NotificationPriority.p0,
        filter: NotificationFilter.matches,
        actions: const [NotificationActionType.view],
        createdAt: now.subtract(const Duration(minutes: 30)),
      ),
      NotificationCard(
        id: 'notif-scorecard',
        tab: NotificationTab.forYou,
        entityName: 'Strikers CC',
        title: 'Scorecard confirmation needed',
        priority: NotificationPriority.p1,
        filter: NotificationFilter.matches,
        actions: const [
          NotificationActionType.confirm,
          NotificationActionType.decline,
        ],
        createdAt: now.subtract(const Duration(hours: 5)),
      ),
      NotificationCard(
        id: 'notif-share-finalized',
        tab: NotificationTab.forYou,
        entityName: 'Strikers CC',
        title: 'Your share finalized: ₹283',
        priority: NotificationPriority.p1,
        filter: NotificationFilter.money,
        actions: const [
          NotificationActionType.pay,
          NotificationActionType.view,
        ],
        createdAt: now.subtract(const Duration(hours: 8)),
      ),
      NotificationCard(
        id: 'notif-payment-received',
        tab: NotificationTab.forYou,
        entityName: 'Riverside Warriors',
        title: 'Payment received -- confirm ₹150 from Priya Nair',
        priority: NotificationPriority.p1,
        filter: NotificationFilter.money,
        actions: const [NotificationActionType.confirm],
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      NotificationCard(
        id: 'notif-team-invite',
        tab: NotificationTab.forYou,
        entityName: 'City Titans',
        title: 'Team invite from City Titans',
        priority: NotificationPriority.p1,
        filter: NotificationFilter.mentions,
        actions: const [
          NotificationActionType.accept,
          NotificationActionType.decline,
        ],
        createdAt: now.subtract(const Duration(days: 1, hours: 3)),
      ),
      NotificationCard(
        id: 'notif-coins',
        tab: NotificationTab.forYou,
        entityName: 'CricUnity Rewards',
        title: 'Coins credited: +25 for man of the match',
        priority: NotificationPriority.p2,
        filter: NotificationFilter.rewards,
        actions: const [NotificationActionType.view],
        createdAt: now.subtract(const Duration(days: 2)),
        read: true,
      ),
      NotificationCard(
        id: 'notif-streak',
        tab: NotificationTab.forYou,
        entityName: 'CricUnity Rewards',
        title: 'Streak at risk -- do a mission before 20:00',
        priority: NotificationPriority.p2,
        filter: NotificationFilter.rewards,
        actions: const [NotificationActionType.view],
        createdAt: now.subtract(const Duration(hours: 4)),
      ),
      NotificationCard(
        id: 'notif-fixture-published',
        tab: NotificationTab.following,
        entityName: 'Monsoon Cup',
        title: 'Fixtures published',
        priority: NotificationPriority.p1,
        filter: NotificationFilter.matches,
        actions: const [NotificationActionType.view],
        createdAt: now.subtract(const Duration(hours: 6)),
      ),
      NotificationCard(
        id: 'notif-registration-approved',
        tab: NotificationTab.following,
        entityName: 'Monsoon Cup',
        title: 'Registration approved for Strikers CC',
        priority: NotificationPriority.p1,
        filter: NotificationFilter.matches,
        actions: const [NotificationActionType.view],
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      NotificationCard(
        id: 'notif-prize-payout',
        tab: NotificationTab.following,
        entityName: 'Monsoon Cup',
        title: 'Prize payout sent -- ₹5,000',
        priority: NotificationPriority.p1,
        filter: NotificationFilter.money,
        actions: const [NotificationActionType.confirm],
        createdAt: now.subtract(const Duration(days: 3)),
      ),
      NotificationCard(
        id: 'notif-booking-confirmed',
        tab: NotificationTab.following,
        entityName: 'Green Valley Ground',
        title: 'Booking confirmed -- Sat 6 AM',
        priority: NotificationPriority.p1,
        filter: NotificationFilter.matches,
        actions: const [NotificationActionType.view],
        createdAt: now.subtract(const Duration(days: 2, hours: 4)),
        read: true,
      ),
    ];
  }

  void _update(
    String id,
    NotificationCard Function(NotificationCard) transform,
  ) {
    state = state.copyWith(
      cards: [
        for (final c in state.cards)
          if (c.id == id) transform(c) else c,
      ],
    );
  }

  /// PRD §15: "acting marks read." Every inline action call this.
  void performAction(String id, NotificationActionType action) {
    _update(id, (c) => c.copyWith(read: true));
  }

  void markRead(String id) => _update(id, (c) => c.copyWith(read: true));

  void markAllReadInSection(NotificationTab tab, NotificationFilter filter) {
    state = state.copyWith(
      cards: [
        for (final c in state.cards)
          if (c.tab == tab &&
              (filter == NotificationFilter.all || c.filter == filter))
            c.copyWith(read: true)
          else
            c,
      ],
    );
  }

  /// PRD §3.7: "Clear all read."
  void clearAllRead() {
    state = state.copyWith(cards: state.cards.where((c) => !c.read).toList());
  }

  /// PRD §3.13: "swipe right = done/read."
  void swipeDone(String id) => markRead(id);

  /// PRD §3.13: "swipe left = snooze (1h/tonight/tomorrow options)."
  void snooze(
    String id,
    SnoozeDuration duration, {
    DateTime Function() now = DateTime.now,
  }) {
    final until = switch (duration) {
      SnoozeDuration.oneHour => now().add(const Duration(hours: 1)),
      SnoozeDuration.tonight => DateTime(
        now().year,
        now().month,
        now().day,
        20,
      ),
      SnoozeDuration.tomorrow => DateTime(
        now().year,
        now().month,
        now().day + 1,
        9,
      ),
    };
    _update(id, (c) => c.copyWith(snoozedUntil: until));
  }

  void unsnooze(String id) => _update(id, (c) => c.copyWith(clearSnooze: true));

  /// PRD §15: "Mute ladder per type\entity (8h\1w\forever)."
  void muteEntity(
    String entityName,
    MuteDuration duration, {
    DateTime Function() now = DateTime.now,
  }) {
    state = state.copyWith(
      mutedEntities: {
        ...state.mutedEntities,
        entityName: _muteUntil(duration, now),
      },
    );
  }

  void muteType(
    NotificationFilter filter,
    MuteDuration duration, {
    DateTime Function() now = DateTime.now,
  }) {
    state = state.copyWith(
      mutedTypes: {...state.mutedTypes, filter: _muteUntil(duration, now)},
    );
  }

  DateTime? _muteUntil(MuteDuration duration, DateTime Function() now) {
    return switch (duration) {
      MuteDuration.eightHours => now().add(const Duration(hours: 8)),
      MuteDuration.oneWeek => now().add(const Duration(days: 7)),
      MuteDuration.forever => null,
    };
  }

  /// PRD §3.7 long-press: "Turn off." Removes the card entirely.
  void turnOff(String id) {
    state = state.copyWith(
      cards: state.cards.where((c) => c.id != id).toList(),
    );
  }
}

final notificationProvider =
    NotifierProvider<NotificationNotifier, NotificationState>(
      NotificationNotifier.new,
    );
