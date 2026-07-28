import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../expenses/expense_models.dart';
import '../expenses/expenses_provider.dart';
import '../matches/match_models.dart';
import '../matches/matches_provider.dart';
import '../matches/scoring_provider.dart';
import '../messaging/chat_provider.dart';
import '../notifications/notification_provider.dart';
import '../recognition/challenges_provider.dart';
import '../rewards/luck_provider.dart';
import 'widgets/weather_home_widget.dart';
import '../rewards/rewards_models.dart' show coinsExpiringWithin;
import '../rewards/rewards_provider.dart';
import '../social/composer_screen.dart' show composerViewerName;
import 'home_widget_models.dart';

class HomeDashboardState {
  final HomeRolePreset preset;

  /// Ordered, not a Set -- PRD §4/DS §7-3: Edit Home's "reorder" drag
  /// applies to the pinned tier specifically (the only tier with a
  /// user-controlled order; urgency/recency order the rest
  /// automatically), so pin position must be preserved.
  final List<HomeWidgetId> pinned;
  final Set<HomeWidgetId> hidden;
  final Map<HomeWidgetId, DateTime> lastUpdated;

  /// PRD §4.11 (Nearby Matches): "Requires location permission; else
  /// shows 'Enable location to find cricket around you.'" No real
  /// device location API exists in this codebase -- a flagged mock
  /// toggle stands in, same convention as every other missing-device-
  /// API gap this session (camera, share, etc.).
  final bool locationPermissionGranted;

  const HomeDashboardState({
    this.preset = HomeRolePreset.playerFirst,
    this.pinned = const [],
    this.hidden = const {},
    this.lastUpdated = const {},
    this.locationPermissionGranted = false,
  });

  HomeDashboardState copyWith({
    HomeRolePreset? preset,
    List<HomeWidgetId>? pinned,
    Set<HomeWidgetId>? hidden,
    Map<HomeWidgetId, DateTime>? lastUpdated,
    bool? locationPermissionGranted,
  }) {
    return HomeDashboardState(
      preset: preset ?? this.preset,
      pinned: pinned ?? this.pinned,
      hidden: hidden ?? this.hidden,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      locationPermissionGranted:
          locationPermissionGranted ?? this.locationPermissionGranted,
    );
  }
}

/// PRD §4 -- the Home shell's pin/hide/preset state (E18-01). Ordering
/// itself is computed on read by [computeHomeWidgets], not stored here,
/// so it always reflects live cross-module state (e.g. a newly-overdue
/// payment) rather than a stale snapshot.
class HomeDashboardNotifier extends Notifier<HomeDashboardState> {
  @override
  HomeDashboardState build() => const HomeDashboardState();

  /// PRD §4: "pin (max 3 pinned)." Silently no-ops past the cap rather
  /// than erroring -- the Edit Home UI (E18-02) is the one responsible
  /// for surfacing the cap to the user.
  void togglePin(HomeWidgetId id) {
    final current = [...state.pinned];
    if (current.remove(id)) {
      state = state.copyWith(pinned: current);
      return;
    }
    if (current.length >= maxPinnedHomeWidgets) return;
    current.add(id);
    state = state.copyWith(pinned: current);
  }

  void toggleHide(HomeWidgetId id) {
    final current = {...state.hidden};
    if (!current.remove(id)) current.add(id);
    state = state.copyWith(hidden: current);
  }

  /// DS §7-3 (Edit Home): "Full-screen reorder list" -- drag-reorders
  /// the pinned tier's mutual order. [newIndex] is expected already
  /// adjusted for the removed item (ReorderableListView.onReorderItem's
  /// contract), unlike the deprecated onReorder callback.
  void reorderPinned(int oldIndex, int newIndex) {
    final current = [...state.pinned];
    final id = current.removeAt(oldIndex);
    current.insert(newIndex, id);
    state = state.copyWith(pinned: current);
  }

  /// DS §7-3: "Reset-to-default tertiary." Clears every user
  /// customization back to the role preset's plain order.
  void resetToDefault() {
    state = state.copyWith(pinned: const [], hidden: const {});
  }

  void grantLocationPermission() {
    state = state.copyWith(locationPermissionGranted: true);
  }

  /// PRD §4: "Pull-to-refresh refreshes all." Touches every widget's
  /// recency stamp so the recency tier of the ordering reflects "just
  /// refreshed," and re-derivation of urgency (done at read-time by
  /// [computeHomeWidgets]) naturally picks up whatever changed
  /// underneath since the last refresh.
  void refreshAll() {
    final now = DateTime.now();
    state = state.copyWith(
      lastUpdated: {for (final id in HomeWidgetId.values) id: now},
    );
  }
}

final homeDashboardProvider =
    NotifierProvider<HomeDashboardNotifier, HomeDashboardState>(
      HomeDashboardNotifier.new,
    );

/// PRD §4 layout model: "Order = (1) pinned by user, (2) urgency score
/// (action needed > time-sensitive > informational), (3) recency."
/// Combines [HomeDashboardState]'s pin/hide/recency prefs with
/// urgency freshly derived from real cross-module state wherever a
/// widget is genuinely wired (pendingPayments, coinBalance); every
/// other widget defaults to informational until E18-03/04/05 wire its
/// real urgency signal too.
List<HomeWidgetInstance> computeHomeWidgets(WidgetRef ref) {
  final state = ref.watch(homeDashboardProvider);
  final order = homeRolePresetOrder[state.preset]!;
  final now = DateTime.now();

  final expenses = ref.watch(expensesProvider).expenses;
  final unpaidShares = expenses.where(
    (e) =>
        !e.isDeleted &&
        e.approvalState != ExpenseApprovalState.pendingApproval &&
        e.netFor(composerViewerName) < 0 &&
        e.splitAmong.any((s) => s.name == composerViewerName),
  );
  final hasOverduePayment = unpaidShares.any(
    (e) => now.difference(e.date).inDays > 7,
  );
  final hasAnyPendingPayment = unpaidShares.isNotEmpty;

  final rewards = ref.watch(rewardsProvider);
  final coinsExpiringSoon =
      coinsExpiringWithin(rewards.coinBatches, 7, now: () => now) > 0;

  final myMatches = ref
      .watch(matchesProvider)
      .matches
      .where(
        (m) =>
            m.squadNames.contains(composerViewerName) &&
            m.status == MatchStatus.accepted,
      )
      .toList();
  final needsAvailabilityResponse = myMatches.any(
    (m) =>
        m.availabilityPollSent &&
        !m.availabilityResponses.containsKey(composerViewerName),
  );
  final hasMatchWithin24h = myMatches.any((m) {
    final until = m.draft.dateTime.difference(now);
    return until.inMinutes > 0 && until <= const Duration(hours: 24);
  });
  final hasMatchToday = myMatches.any(
    (m) =>
        m.draft.dateTime.year == now.year &&
        m.draft.dateTime.month == now.month &&
        m.draft.dateTime.day == now.day,
  );
  final innings = ref.watch(inningsProvider);
  final hasLiveMatch =
      !innings.isFullyConfirmed && innings.deliveries.isNotEmpty;

  final luck = ref.watch(luckLayerProvider);
  final canSpin =
      ref
          .read(luckLayerProvider.notifier)
          .spinBlockReason(viewerLevel: rewards.level) ==
      null;
  final hasUnclaimedRewards =
      luck.scratchCardsAvailable > 0 ||
      canSpin ||
      rewards.ceremonyQueue.isNotEmpty;

  final myChallenges = ref
      .watch(challengesProvider)
      .challenges
      .where((c) => c.participantNamed(composerViewerName) != null)
      .toList();
  final hasNearCompleteChallenge = myChallenges.any((c) {
    final mine = c.participantNamed(composerViewerName)!;
    return c.target > 0 && mine.progress / c.target >= 0.8;
  });

  final hasUnreadMessages = ref
      .watch(chatsProvider)
      .chats
      .any((c) => c.unreadCount > 0);
  final unreadNotificationCount = ref
      .watch(notificationProvider)
      .cards
      .where((c) => !c.read)
      .length;
  final hasPendingInvitation = ref
      .watch(matchesProvider)
      .matches
      .any((m) => m.status == MatchStatus.pendingOpponent);

  final hasSevereWeather = myMatches.any(
    (m) => forecastFor(m.draft.groundName, m.draft.dateTime).isSevere,
  );

  HomeWidgetUrgency urgencyFor(HomeWidgetId id) {
    switch (id) {
      case HomeWidgetId.pendingPayments:
      case HomeWidgetId.expenseSummary:
        if (hasOverduePayment) return HomeWidgetUrgency.actionNeeded;
        if (hasAnyPendingPayment) return HomeWidgetUrgency.timeSensitive;
        return HomeWidgetUrgency.informational;
      case HomeWidgetId.coinBalance:
        return coinsExpiringSoon
            ? HomeWidgetUrgency.timeSensitive
            : HomeWidgetUrgency.informational;
      case HomeWidgetId.rewards:
        return hasUnclaimedRewards
            ? HomeWidgetUrgency.timeSensitive
            : HomeWidgetUrgency.informational;
      case HomeWidgetId.challenges:
        return hasNearCompleteChallenge
            ? HomeWidgetUrgency.timeSensitive
            : HomeWidgetUrgency.informational;
      case HomeWidgetId.upcomingMatches:
        if (needsAvailabilityResponse) return HomeWidgetUrgency.actionNeeded;
        if (hasMatchWithin24h) return HomeWidgetUrgency.timeSensitive;
        return HomeWidgetUrgency.informational;
      case HomeWidgetId.todaysActivity:
        return hasMatchToday
            ? HomeWidgetUrgency.timeSensitive
            : HomeWidgetUrgency.informational;
      case HomeWidgetId.liveMatches:
        return HomeWidgetUrgency.timeSensitive;
      case HomeWidgetId.invitations:
        return hasPendingInvitation
            ? HomeWidgetUrgency.actionNeeded
            : HomeWidgetUrgency.informational;
      case HomeWidgetId.messages:
        return hasUnreadMessages
            ? HomeWidgetUrgency.timeSensitive
            : HomeWidgetUrgency.informational;
      case HomeWidgetId.weather:
        return hasSevereWeather
            ? HomeWidgetUrgency.actionNeeded
            : HomeWidgetUrgency.informational;
      default:
        return HomeWidgetUrgency.informational;
    }
  }

  // PRD §4.19/§4.12/§4.6/§4.16/§4.17/§4.18: widgets with nothing
  // relevant self-hide, same convention as every other "only when
  // relevant" widget this session.
  final selfHidden = <HomeWidgetId>{
    if (!hasAnyPendingPayment) HomeWidgetId.pendingPayments,
    if (!hasLiveMatch) HomeWidgetId.liveMatches,
    if (!hasUnclaimedRewards) HomeWidgetId.rewards,
    if (myChallenges.isEmpty) HomeWidgetId.challenges,
    if (!hasUnreadMessages) HomeWidgetId.messages,
    if (!hasPendingInvitation) HomeWidgetId.invitations,
    if (unreadNotificationCount < 5) HomeWidgetId.unreadNotifications,
  };

  final instances = [
    for (final id in order)
      HomeWidgetInstance(
        id: id,
        urgency: urgencyFor(id),
        isPinned: state.pinned.contains(id),
        isHidden: state.hidden.contains(id) || selfHidden.contains(id),
        lastUpdated: state.lastUpdated[id] ?? now,
      ),
  ];

  final pinnedList = [
    for (final id in state.pinned)
      instances.where((w) => w.id == id && !w.isHidden).firstOrNull,
  ].whereType<HomeWidgetInstance>().toList();
  final unpinned = instances.where((w) => !w.isPinned && !w.isHidden).toList()
    ..sort((a, b) {
      final urgencyCompare = a.urgency.index.compareTo(b.urgency.index);
      if (urgencyCompare != 0) return urgencyCompare;
      return b.lastUpdated.compareTo(a.lastUpdated);
    });

  return [...pinnedList, ...unpinned];
}

List<HomeWidgetInstance> computeHiddenHomeWidgets(WidgetRef ref) {
  final state = ref.watch(homeDashboardProvider);
  return [
    for (final id in state.hidden)
      HomeWidgetInstance(
        id: id,
        urgency: HomeWidgetUrgency.informational,
        isHidden: true,
        lastUpdated: state.lastUpdated[id] ?? DateTime.now(),
      ),
  ];
}
