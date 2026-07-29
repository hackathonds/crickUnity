import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../design_system/components/app_button.dart';
import '../design_system/icons/app_icon.dart';
import '../design_system/icons/app_icon_id.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_motion.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import '../matches/live_match_view_screen.dart';
import '../roles/active_role_view_provider.dart';
import '../roles/current_roles_provider.dart';
import '../roles/user_role.dart';
import '../widgets/app_drawer.dart';
import 'pinned_live_match_provider.dart';
import 'tab_badges_provider.dart';
import 'tab_interaction_providers.dart';

/// The persistent shell around all 4 bottom-nav branches — PRD §3.1/§3.3,
/// DS §2.1 layout constants. Owns the drawer, the notched bottom bar with
/// the raised FAB-in-bar, and the re-tap/long-press behaviors; each
/// branch's own content (see `TabRootScreen`) owns its collapsing app bar.
class AppShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({super.key, required this.navigationShell});

  void _onTabTapped(BuildContext context, WidgetRef ref, int index) {
    final currentIndex = navigationShell.currentIndex;
    if (index != currentIndex) {
      navigationShell.goBranch(index);
      return;
    }
    final controller = ref.read(tabScrollControllerProvider(index));
    if (controller.hasClients && controller.offset > 4) {
      controller.animateTo(
        0,
        duration: AppMotion.resolveDuration(context, AppMotionToken.standard),
        curve: AppMotionCurves.standard,
      );
    } else {
      ref.read(tabRefreshSignalProvider(index).notifier).state++;
    }
  }

  /// DS §1.5 "Open my next match": budget 2 (long-press Matches tab ->
  /// pinned next). E4-11's real [LiveMatchViewScreen] now exists -- this
  /// app has only one mock live match at a time (no multi-match model),
  /// so [pinnedLiveMatchProvider]'s label is enough to know *that* a
  /// match is pinned; the destination is the one real live match.
  void _onLongPressMatches(BuildContext context, WidgetRef ref) {
    final pinned = ref.read(pinnedLiveMatchProvider);
    if (pinned == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No live match pinned right now.')),
      );
      return;
    }
    Navigator.of(
      context,
      rootNavigator: true,
    ).push(MaterialPageRoute(builder: (_) => const LiveMatchViewScreen()));
  }

  void _onCreatePressed(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => const _CreateSheet(),
    );
  }

  /// PRD §3.1/§3.6: "Long-press Profile → account switcher (multi-role
  /// identities)." Only ever offers roles the account already holds
  /// (non-negotiable #10) -- never a role picker.
  void _onLongPressProfile(BuildContext context, WidgetRef ref) {
    final heldRoles = ref.read(currentRolesProvider);
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => Consumer(
        builder: (context, ref, _) {
          final active = ref.watch(activeRoleViewProvider);
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  key: const ValueKey('roleViewOption_player'),
                  title: const Text('Deepak — Player view'),
                  trailing: active == null ? const Icon(Icons.check) : null,
                  onTap: () {
                    ref.read(activeRoleViewProvider.notifier).setView(null);
                    Navigator.of(context).pop();
                  },
                ),
                for (final role in heldRoles)
                  ListTile(
                    key: ValueKey('roleViewOption_${role.name}'),
                    title: Text('Deepak — ${userRoleLabels[role]} view'),
                    trailing: active == role ? const Icon(Icons.check) : null,
                    onTap: () {
                      ref.read(activeRoleViewProvider.notifier).setView(role);
                      Navigator.of(context).pop();
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final badges = ref.watch(tabBadgesProvider);
    final heldRoles = ref.watch(currentRolesProvider);
    // PRD §3.1: "Ground Owners see Bookings replacing Community if
    // they enable 'Business mode' toggle; Fans see Live replacing
    // Matches."
    final businessMode =
        heldRoles.contains(UserRole.groundOwner) &&
        ref.watch(businessModeProvider);
    final isFan = heldRoles.contains(UserRole.fan);

    return Scaffold(
      drawer: const AppDrawer(),
      body: navigationShell,
      floatingActionButton: AppFab(
        icon: AppIconId.plus,
        semanticLabel: 'Create',
        onPressed: () => _onCreatePressed(context),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        color: colors.surface,
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              _NavItem(
                icon: AppIconId.home,
                label: 'Home',
                active: navigationShell.currentIndex == 0,
                showDot: badges.homeActionNeeded,
                onTap: () => _onTabTapped(context, ref, 0),
              ),
              _NavItem(
                key: const ValueKey('matchesOrLiveTab'),
                icon: isFan ? AppIconId.live : AppIconId.matches,
                label: isFan ? 'Live' : 'Matches',
                active: navigationShell.currentIndex == 1,
                count: badges.liveMatchCount,
                onTap: () => _onTabTapped(context, ref, 1),
                onLongPress: () => _onLongPressMatches(context, ref),
              ),
              const SizedBox(width: 56),
              _NavItem(
                key: const ValueKey('communityOrBookingsTab'),
                icon: businessMode ? AppIconId.pitch : AppIconId.people,
                label: businessMode ? 'Bookings' : 'Community',
                active: navigationShell.currentIndex == 2,
                countLabel: badges.newCommunityPostCount > 0
                    ? formatCommunityBadge(badges.newCommunityPostCount)
                    : null,
                onTap: () => _onTabTapped(context, ref, 2),
              ),
              _NavItem(
                key: const ValueKey('profileTab'),
                icon: AppIconId.avatar,
                label: 'Profile',
                active: navigationShell.currentIndex == 3,
                showDot: badges.profileNeedsAttention,
                onTap: () => _onTabTapped(context, ref, 3),
                onLongPress: () => _onLongPressProfile(context, ref),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final AppIconId icon;
  final String label;
  final bool active;
  final bool showDot;
  final int? count;
  final String? countLabel;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _NavItem({
    super.key,
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
    this.showDot = false,
    this.count,
    this.countLabel,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final tint = active ? colors.primary : colors.textSecondary;
    final resolvedCountLabel =
        countLabel ?? (count != null && count! > 0 ? '$count' : null);

    return Expanded(
      child: InkWell(
        key: ValueKey('bottomNavItem-$label'),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Badge(
              isLabelVisible: showDot || resolvedCountLabel != null,
              label: resolvedCountLabel != null
                  ? Text(resolvedCountLabel)
                  : null,
              child: AppIcon(
                id: icon,
                active: active,
                semanticLabel: label,
                color: tint,
                size: AppIconSize.tabBar,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              label,
              style: AppTypography.label.copyWith(color: tint),
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateSheet extends StatelessWidget {
  const _CreateSheet();

  // PRD §3.4's "Everyone" tier only — the full role-aware Create sheet
  // (Player+/Captain/Organizer/Ground-Owner actions) belongs to the epics
  // that own each action (E4 matches, E3 teams, E10 tournaments, ...).
  static const _everyoneActions = ['Post', 'Story', 'Reel', 'Poll'];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final action in _everyoneActions)
            ListTile(
              title: Text(
                action,
                style: AppTypography.body.copyWith(color: colors.textPrimary),
              ),
              onTap: () => Navigator.of(context).pop(),
            ),
        ],
      ),
    );
  }
}
