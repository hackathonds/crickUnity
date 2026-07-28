import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_avatar.dart';
import '../design_system/components/app_coin_chip.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import '../notifications/notification_center_screen.dart';
import '../rewards/rewards_provider.dart';
import '../search/global_search_screen.dart';
import '../social/composer_screen.dart' show composerViewerName;
import 'edit_home_screen.dart';
import 'home_dashboard_provider.dart';
import 'home_widget_models.dart';
import 'onboarding_checklist_provider.dart';
import 'onboarding_checklist_widget.dart';
import 'widgets/cricket_home_widgets.dart';
import 'widgets/money_rewards_home_widgets.dart';
import 'widgets/social_progress_home_widgets.dart';
import 'widgets/weather_home_widget.dart';

/// DS §7.1 screen 1 (Home): "app bar: avatar 32 · greeting/context
/// title · search · bell · coin chip → quick-chips row (max 3 urgent)
/// → widget stack per PRD §4 ordering (urgency > pinned > recency) →
/// 'More for you' footer ... long-press widget = Edit-Home reorder
/// mode ... pull-refresh Arc; widget ⋮ = hide/pin. Edge: new user
/// shows Onboarding-Checklist widget replacing stack until 2 items
/// done."
///
/// E18-01 built the shell (app bar, ordering engine, pin/hide, pull-
/// refresh, "More for you"); E18-02 added drag-reorder; E18-03/04/05
/// filled in every widget's real content; E18-07 (this addition) wires
/// the quick-chips row to real dynamic actions. Sits directly inside
/// AppShell's shared Scaffold (no Scaffold of its own), same
/// convention as TabRootScreen.
class HomeDashboardScreen extends ConsumerWidget {
  const HomeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final showOnboarding = ref.watch(
      onboardingChecklistProvider.select((s) => s.shouldShow),
    );

    return RefreshIndicator(
      onRefresh: () async =>
          ref.read(homeDashboardProvider.notifier).refreshAll(),
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 96,
            collapsedHeight: 56,
            backgroundColor: colors.surface,
            leading: Builder(
              builder: (innerContext) => IconButton(
                icon: const AppAvatar(
                  size: AppAvatarSize.sm,
                  name: composerViewerName,
                ),
                onPressed: () => Scaffold.of(innerContext).openDrawer(),
              ),
            ),
            flexibleSpace: const FlexibleSpaceBar(
              title: Text('Hi, Deepak', style: AppTypography.h1),
              titlePadding: EdgeInsetsDirectional.only(
                start: AppSpacing.lg,
                bottom: AppSpacing.sm,
              ),
            ),
            actions: [
              IconButton(
                key: const ValueKey('homeSearchButton'),
                icon: const Icon(Icons.search),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const GlobalSearchScreen()),
                ),
              ),
              IconButton(
                key: const ValueKey('homeBellButton'),
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const NotificationCenterScreen(),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.md),
                child: Center(
                  child: AppCoinChip(
                    balance: ref.watch(rewardsProvider).coinBalance,
                  ),
                ),
              ),
              IconButton(
                key: const ValueKey('editHomeButton'),
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Edit Home',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const EditHomeScreen()),
                ),
              ),
            ],
          ),
          if (showOnboarding)
            const SliverPadding(
              padding: EdgeInsets.all(AppSpacing.lg),
              sliver: SliverToBoxAdapter(child: OnboardingChecklistWidget()),
            )
          else ...[
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                0,
              ),
              sliver: SliverToBoxAdapter(
                child: _QuickActionChipsRow(
                  chips: computeQuickActionChips(ref),
                ),
              ),
            ),
            ..._widgetStackSlivers(context, ref, colors),
          ],
        ],
      ),
    );
  }

  List<Widget> _widgetStackSlivers(
    BuildContext context,
    WidgetRef ref,
    AppColors colors,
  ) {
    final visible = computeHomeWidgets(ref);
    final hidden = computeHiddenHomeWidgets(ref);

    return [
      SliverPadding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        sliver: SliverList.list(
          children: [
            for (final widgetInstance in visible)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: _HomeWidgetCard(instance: widgetInstance),
              ),
            if (hidden.isNotEmpty) _MoreForYouFooter(hidden: hidden),
          ],
        ),
      ),
    ];
  }
}

class _QuickActionChipsRow extends StatelessWidget {
  final List<QuickActionChip> chips;
  const _QuickActionChipsRow({required this.chips});

  @override
  Widget build(BuildContext context) {
    if (chips.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: AppSpacing.sm,
      children: [
        for (final chip in chips)
          ActionChip(
            key: ValueKey('quickActionChip_${chip.label}'),
            label: Text(chip.label),
            onPressed: () => chip.onTap(context),
          ),
      ],
    );
  }
}

class _HomeWidgetCard extends ConsumerWidget {
  final HomeWidgetInstance instance;
  const _HomeWidgetCard({required this.instance});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final notifier = ref.read(homeDashboardProvider.notifier);

    return GestureDetector(
      key: ValueKey('homeWidgetCard_${instance.id.name}'),
      // PRD §4: "Edit Home mode (long-press any widget or via ⋮)."
      onLongPress: () => Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const EditHomeScreen())),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border.all(color: colors.border),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (instance.isPinned)
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.xs),
                    child: Icon(
                      Icons.push_pin,
                      size: 14,
                      color: colors.primary,
                    ),
                  ),
                Expanded(
                  child: Text(
                    homeWidgetTitles[instance.id]!,
                    style: AppTypography.title.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  key: ValueKey('homeWidgetMenu_${instance.id.name}'),
                  icon: const Icon(Icons.more_vert, size: 18),
                  onSelected: (value) {
                    if (value == 'pin') notifier.togglePin(instance.id);
                    if (value == 'hide') notifier.toggleHide(instance.id);
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'pin',
                      child: Text(instance.isPinned ? 'Unpin' : 'Pin'),
                    ),
                    const PopupMenuItem(value: 'hide', child: Text('Hide')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            _HomeWidgetBody(id: instance.id),
          ],
        ),
      ),
    );
  }
}

/// E18-03 added the cricket batch, E18-04 the money & rewards batch,
/// E18-05 (this story) the social & progress batch. Every
/// [HomeWidgetId] now has real content; a few (Suggested Friends/
/// Teams, Followers delta) render an honest "no backing data source
/// exists" message rather than fabricated suggestions, since this
/// codebase has no mutual-connections/recruitment-matching graph or
/// follower-count history to derive them from.
class _HomeWidgetBody extends ConsumerWidget {
  final HomeWidgetId id;
  const _HomeWidgetBody({required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    switch (id) {
      case HomeWidgetId.pendingPayments:
        return const PendingPaymentsBody();
      case HomeWidgetId.coinBalance:
        return const CoinBalanceBody();
      case HomeWidgetId.expenseSummary:
        return const ExpenseSummaryBody();
      case HomeWidgetId.rewards:
        return const RewardsBody();
      case HomeWidgetId.challenges:
        return const ChallengesBody();
      case HomeWidgetId.upcomingMatches:
        return const UpcomingMatchesBody();
      case HomeWidgetId.todaysActivity:
        return const TodaysActivityBody();
      case HomeWidgetId.liveMatches:
        return const LiveMatchesBody();
      case HomeWidgetId.nearbyMatches:
        return const NearbyMatchesBody();
      case HomeWidgetId.recentPerformance:
        return const RecentPerformanceBody();
      case HomeWidgetId.suggestedFriends:
        return const SuggestedFriendsBody();
      case HomeWidgetId.suggestedTeams:
        return const SuggestedTeamsBody();
      case HomeWidgetId.suggestedGrounds:
        return const SuggestedGroundsBody();
      case HomeWidgetId.recentPosts:
        return const RecentPostsBody();
      case HomeWidgetId.recentAchievements:
        return const RecentAchievementsBody();
      case HomeWidgetId.followers:
        return const FollowersDeltaBody();
      case HomeWidgetId.messages:
        return const MessagesPreviewBody();
      case HomeWidgetId.invitations:
        return const InvitationsBody();
      case HomeWidgetId.unreadNotifications:
        return const UnreadNotificationsBody();
      case HomeWidgetId.playerRanking:
        return const PlayerRankingBody();
      case HomeWidgetId.fitnessProgress:
        return const FitnessProgressBody();
      case HomeWidgetId.attendance:
        return const AttendanceBody();
      case HomeWidgetId.tournamentUpdates:
        return const TournamentUpdatesBody();
      case HomeWidgetId.weather:
        return const WeatherHomeWidgetBody();
    }
  }
}

class _MoreForYouFooter extends ConsumerWidget {
  final List<HomeWidgetInstance> hidden;
  const _MoreForYouFooter({required this.hidden});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'More for you',
            style: AppTypography.label.copyWith(color: colors.textTertiary),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final widgetInstance in hidden)
            ListTile(
              key: ValueKey('hiddenWidgetRow_${widgetInstance.id.name}'),
              contentPadding: EdgeInsets.zero,
              title: Text(
                homeWidgetTitles[widgetInstance.id]!,
                style: AppTypography.body.copyWith(color: colors.textPrimary),
              ),
              trailing: TextButton(
                key: ValueKey('unhideWidgetButton_${widgetInstance.id.name}'),
                onPressed: () => ref
                    .read(homeDashboardProvider.notifier)
                    .toggleHide(widgetInstance.id),
                child: const Text('Show'),
              ),
            ),
        ],
      ),
    );
  }
}
