import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../persistence/persisted_notifier.dart';
import 'notification_catalog.dart';
import 'notification_models.dart';

class NotificationState {
  final List<NotificationCard> cards;
  final Map<String, DateTime?> mutedEntities;
  final Map<NotificationChannel, DateTime?> mutedChannels;
  final QuietHoursSettings quietHours;

  const NotificationState({
    this.cards = const [],
    this.mutedEntities = const {},
    this.mutedChannels = const {},
    this.quietHours = const QuietHoursSettings(),
  });

  NotificationState copyWith({
    List<NotificationCard>? cards,
    Map<String, DateTime?>? mutedEntities,
    Map<NotificationChannel, DateTime?>? mutedChannels,
    QuietHoursSettings? quietHours,
  }) {
    return NotificationState(
      cards: cards ?? this.cards,
      mutedEntities: mutedEntities ?? this.mutedEntities,
      mutedChannels: mutedChannels ?? this.mutedChannels,
      quietHours: quietHours ?? this.quietHours,
    );
  }

  bool _muteActive(DateTime? mutedUntil) =>
      mutedUntil == null || DateTime.now().isBefore(mutedUntil);

  /// PRD §15: mute is either a timed hold (8h/1w) or permanent
  /// ("forever" is stored as a null value meaning "no expiry").
  bool isEntityMuted(String entityName) =>
      mutedEntities.containsKey(entityName) &&
      _muteActive(mutedEntities[entityName]);

  bool isChannelMuted(NotificationChannel channel) =>
      mutedChannels.containsKey(channel) && _muteActive(mutedChannels[channel]);

  /// PRD §15: "Quiet hours ... P1 held & delivered after; P0 breaks
  /// through only for same-day match logistics." Read literally: the
  /// only named carve-out from the hold is a P0 card flagged as
  /// same-day match logistics -- every other P0 is held exactly like
  /// P1. P2/P3 were never pushed in the first place (in-app-badge-only/
  /// digest-only per their own definition), so quiet hours has nothing
  /// to hold there.
  bool isHeldByQuietHours(NotificationCard card, DateTime now) {
    if (!quietHours.isActive(now)) return false;
    if (card.priority == NotificationPriority.p0) {
      return !card.isSameDayMatchLogistics;
    }
    return card.priority == NotificationPriority.p1;
  }

  List<NotificationCard> visibleFor(
    NotificationTab tab,
    NotificationChannel channel,
    DateTime now,
  ) {
    return cards.where((c) {
      if (c.tab != tab) return false;
      if (c.snoozedUntil != null && now.isBefore(c.snoozedUntil!)) return false;
      if (isEntityMuted(c.entityName)) return false;
      if (isChannelMuted(c.channel)) return false;
      if (isHeldByQuietHours(c, now)) return false;
      if (channel != NotificationChannel.all && c.channel != channel) {
        return false;
      }
      return true;
    }).toList()..sort((a, b) {
      if (a.priority != b.priority) {
        return a.priority.index.compareTo(b.priority.index);
      }
      return b.createdAt.compareTo(a.createdAt);
    });
  }

  /// Only the genuinely durable pieces persist -- [mutedEntities],
  /// [mutedChannels], [quietHours], and each card's own interaction
  /// state (read/snoozedUntil/followedUpAt), keyed by id. [cards]
  /// itself is always regenerated fresh from live provider state via
  /// [generateCatalogCards] (see [NotificationNotifier.fromJson]) --
  /// persisting the generated cards verbatim would freeze them stale
  /// instead of reflecting whatever's real by the time the app reopens.
  Map<String, dynamic> toJson() => {
    'mutedEntities': {
      for (final entry in mutedEntities.entries)
        entry.key: entry.value?.toIso8601String(),
    },
    'mutedChannels': {
      for (final entry in mutedChannels.entries)
        entry.key.name: entry.value?.toIso8601String(),
    },
    'quietHours': quietHours.toJson(),
    'cardOverrides': {
      for (final c in cards)
        c.id: {
          'read': c.read,
          'snoozedUntil': c.snoozedUntil?.toIso8601String(),
          'followedUpAt': c.followedUpAt?.toIso8601String(),
        },
    },
  };
}

/// Backlog E12-04/E12-05 -- Notification center engine. See
/// notification_models.dart's top-of-file note for the exact PRD
/// §3.7/§3.13/§15 quotes and the E12-04/E12-05 scope split.
/// notification_catalog.dart's [generateCatalogCards] is the real,
/// data-driven catalog wiring E12-05 adds -- this notifier just owns
/// the mutable interaction state (read/snooze/mute/quiet-hours/
/// follow-up) layered on top of whatever it generates.
class NotificationNotifier extends PersistedNotifier<NotificationState> {
  @override
  String get persistenceKey => 'notifications_v1';

  @override
  Map<String, dynamic> toJson(NotificationState value) => value.toJson();

  /// Regenerates the catalog fresh (same as [seed]) and layers the
  /// saved per-card interaction overrides back on by id -- mirrors
  /// [refresh]'s own merge logic.
  @override
  NotificationState fromJson(Map<String, dynamic> json) {
    final now = DateTime.now();
    final mutedEntities = {
      for (final entry
          in (json['mutedEntities'] as Map<String, dynamic>).entries)
        entry.key: entry.value != null
            ? DateTime.parse(entry.value as String)
            : null,
    };
    final mutedChannels = {
      for (final entry
          in (json['mutedChannels'] as Map<String, dynamic>).entries)
        NotificationChannel.values.byName(entry.key): entry.value != null
            ? DateTime.parse(entry.value as String)
            : null,
    };
    final quietHours = QuietHoursSettings.fromJson(
      json['quietHours'] as Map<String, dynamic>,
    );
    final overrides = json['cardOverrides'] as Map<String, dynamic>;

    final fresh = generateCatalogCards(ref, now);
    final merged = [
      for (final c in fresh)
        if (overrides[c.id] case final Map<String, dynamic> o?)
          c.copyWith(
            read: o['read'] as bool? ?? false,
            snoozedUntil: o['snoozedUntil'] != null
                ? DateTime.parse(o['snoozedUntil'] as String)
                : null,
            followedUpAt: o['followedUpAt'] != null
                ? DateTime.parse(o['followedUpAt'] as String)
                : null,
          )
        else
          c,
    ];

    return NotificationState(
      cards: _applyFollowUps(merged, now),
      mutedEntities: mutedEntities,
      mutedChannels: mutedChannels,
      quietHours: quietHours,
    );
  }

  @override
  NotificationState seed() {
    final now = DateTime.now();
    return NotificationState(
      cards: _applyFollowUps(generateCatalogCards(ref, now), now),
    );
  }

  /// Re-runs the catalog generator against current provider state.
  /// Read/snooze/mute state on cards that still exist is preserved by
  /// id; follow-up timestamps are recomputed fresh.
  void refresh({DateTime Function() now = DateTime.now}) {
    final current = now();
    final byId = {for (final c in state.cards) c.id: c};
    final fresh = generateCatalogCards(ref, current);
    final merged = [
      for (final f in fresh)
        if (byId[f.id] case final existing?)
          f.copyWith(
            read: existing.read,
            snoozedUntil: existing.snoozedUntil,
            followedUpAt: existing.followedUpAt,
          )
        else
          f,
    ];
    state = state.copyWith(cards: _applyFollowUps(merged, current));
  }

  /// PRD §15: "Follow-ups: unactioned decision notifications
  /// auto-follow-up once at 24h then stop." Computed fresh on every
  /// generation rather than persisted turn-by-turn, since it's a pure
  /// function of (unread, has actions, not exempt, age >= 24h).
  static List<NotificationCard> _applyFollowUps(
    List<NotificationCard> cards,
    DateTime now,
  ) {
    return [
      for (final c in cards)
        if (!c.read &&
            c.isDecision &&
            !c.followUpExempt &&
            c.followedUpAt == null &&
            now.difference(c.createdAt).inHours >= 24)
          c.copyWith(followedUpAt: now)
        else
          c,
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

  void markAllReadInSection(NotificationTab tab, NotificationChannel channel) {
    state = state.copyWith(
      cards: [
        for (final c in state.cards)
          if (c.tab == tab &&
              (channel == NotificationChannel.all || c.channel == channel))
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

  /// PRD §15: "Mute ladder per type/entity (8h/1w/forever)."
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

  /// PRD §15: "Safety/Account (unmutable)." No-op for that channel.
  void muteChannel(
    NotificationChannel channel,
    MuteDuration duration, {
    DateTime Function() now = DateTime.now,
  }) {
    if (unmutableNotificationChannels.contains(channel)) return;
    state = state.copyWith(
      mutedChannels: {
        ...state.mutedChannels,
        channel: _muteUntil(duration, now),
      },
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

  /// PRD §15: "Quiet hours: user-set (default 23:00-07:00)."
  void setQuietHours({int? startHour, int? endHour, bool? enabled}) {
    state = state.copyWith(
      quietHours: state.quietHours.copyWith(
        startHour: startHour,
        endHour: endHour,
        enabled: enabled,
      ),
    );
  }
}

final notificationProvider =
    NotifierProvider<NotificationNotifier, NotificationState>(
      NotificationNotifier.new,
    );
