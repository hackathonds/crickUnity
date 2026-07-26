import 'package:flutter/material.dart';

import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_motion.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'team_models.dart';
import 'team_viewer_role.dart';

String _initialsFor(String name) {
  final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
  final initials = words.take(2).map((w) => w[0].toUpperCase()).join();
  return initials.isEmpty ? '?' : initials;
}

class _TeamTab {
  final String label;
  final Widget Function() contentBuilder;

  const _TeamTab(this.label, this.contentBuilder);
}

/// DS §7 screen 11 (Team Home, viewer-relative): "Cover+crest header →
/// follower/member counts → tabs [Feed·Matches·Members·Stats·Media·
/// Money*·Manage*] (*role-gated, gated tabs hidden not disabled for
/// outsiders)." PRD §6 edge: "archived team = read-only banner."
///
/// Every tab's actual content (Feed's announcements are E3-05, Matches
/// is the match module, Members/roles is E3-04, Stats/Media/Money are
/// their own later stories) is a placeholder citing its real story --
/// same "stand-in for a later screen" pattern used throughout E1/E2.
/// This story's own job is the header, the *tab structure itself*, its
/// role-gating, and the archived banner.
class TeamHomeScreen extends StatefulWidget {
  final Team team;
  final TeamViewerRole viewerRole;

  const TeamHomeScreen({
    super.key,
    required this.team,
    required this.viewerRole,
  });

  @override
  State<TeamHomeScreen> createState() => _TeamHomeScreenState();
}

class _TeamHomeScreenState extends State<TeamHomeScreen> {
  int _tabIndex = 0;

  List<_TeamTab> _visibleTabs() {
    final role = widget.viewerRole;
    return [
      _TeamTab(
        'Feed',
        () => const _TeamTabPlaceholder(
          text: 'Announcements + posts are E3-05 and later Feed stories.',
        ),
      ),
      _TeamTab(
        'Matches',
        () => const _TeamTabPlaceholder(
          text: 'The match module is a later epic.',
        ),
      ),
      _TeamTab(
        'Members',
        () => const _TeamTabPlaceholder(
          text: 'Roster + role management is E3-04.',
        ),
      ),
      _TeamTab(
        'Stats',
        () => const _TeamTabPlaceholder(
          text: 'Team stats/history/milestones are later stories.',
        ),
      ),
      _TeamTab(
        'Media',
        () => const _TeamTabPlaceholder(
          text: 'Team media auto-albums are a later story.',
        ),
      ),
      if (role.canSeeMoneyTab)
        _TeamTab(
          'Money',
          () => const _TeamTabPlaceholder(
            text: 'Expenses/collection/wallet are later stories.',
          ),
        ),
      if (role.canSeeManageTab)
        _TeamTab(
          'Manage',
          () => const _TeamTabPlaceholder(
            text: 'Permission matrix + team settings are E3-04.',
          ),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final team = widget.team;
    final tabs = _visibleTabs();
    final tabIndex = _tabIndex >= tabs.length ? 0 : _tabIndex;

    return Scaffold(
      appBar: AppBar(title: Text(team.name)),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (team.isArchived)
                  Container(
                    key: const ValueKey('teamArchivedBanner'),
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    color: colors.surfaceAlt,
                    child: Text(
                      'This team is archived. Records are preserved as '
                      'read-only.',
                      style: AppTypography.caption.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                _TeamCoverAndCrest(team: team),
                const SizedBox(height: AppSpacing.xxl),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Row(
                    key: const ValueKey('teamFollowerMemberCounts'),
                    children: [
                      Text(
                        '${team.memberCount} members',
                        style: AppTypography.body.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      Text(
                        '${team.followerCount} followers',
                        style: AppTypography.body.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: _TeamTabBar(
              labels: [for (final tab in tabs) tab.label],
              selectedIndex: tabIndex,
              onChanged: (index) => setState(() => _tabIndex = index),
            ),
          ),
          SliverToBoxAdapter(child: tabs[tabIndex].contentBuilder()),
        ],
      ),
    );
  }
}

class _TeamCoverAndCrest extends StatelessWidget {
  final Team team;

  const _TeamCoverAndCrest({required this.team});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        AspectRatio(aspectRatio: 3, child: Container(color: team.primaryColor)),
        Positioned(
          left: AppSpacing.lg,
          bottom: -32,
          child: Container(
            key: const ValueKey('teamCrest'),
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: team.secondaryColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).extension<AppColors>()!.surface,
                width: 3,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              _initialsFor(team.name),
              style: TextStyle(
                fontFamily: AppTypography.displayFamily,
                fontWeight: FontWeight.w600,
                fontSize: 22,
                color:
                    ThemeData.estimateBrightnessForColor(team.secondaryColor) ==
                        Brightness.dark
                    ? Colors.white
                    : Colors.black,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TeamTabBar extends StatelessWidget {
  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const _TeamTabBar({
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final duration = AppMotion.resolveDuration(context, AppMotionToken.fast);

    return Container(
      key: const ValueKey('teamTabBar'),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.divider)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var i = 0; i < labels.length; i++)
              GestureDetector(
                key: ValueKey('teamTab_${labels[i]}'),
                onTap: () => onChanged(i),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.md,
                        ),
                        child: Text(
                          labels[i],
                          style: AppTypography.button.copyWith(
                            color: i == selectedIndex
                                ? colors.textPrimary
                                : colors.textTertiary,
                          ),
                        ),
                      ),
                      AnimatedContainer(
                        duration: duration,
                        curve: AppMotionCurves.standard,
                        height: 2,
                        width: 24,
                        color: i == selectedIndex
                            ? colors.primary
                            : Colors.transparent,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TeamTabPlaceholder extends StatelessWidget {
  final String text;

  const _TeamTabPlaceholder({required this.text});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Text(
        text,
        style: AppTypography.body.copyWith(color: colors.textSecondary),
      ),
    );
  }
}
