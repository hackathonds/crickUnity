import 'package:flutter/material.dart';

import '../../profile/achievement_models.dart';
import '../../profile/achievements_wall_screen.dart';
import '../../profile/activity_calendar_models.dart';
import '../../profile/activity_calendar_screen.dart';
import '../../profile/edit_profile_screen.dart';
import '../../profile/follower_models.dart';
import '../../profile/profile_models.dart';
import '../../profile/profile_screen.dart';
import '../components/app_dropdown_field.dart';
import '../tokens/app_spacing.dart';

/// QA tool for E2-01: every [ViewerRelation] / [ProfileVisibility] /
/// minor / verified-stats combination the AC calls out.
class ProfileScreenDemo extends StatefulWidget {
  const ProfileScreenDemo({super.key});

  @override
  State<ProfileScreenDemo> createState() => _ProfileScreenDemoState();
}

class _ProfileScreenDemoState extends State<ProfileScreenDemo> {
  ViewerRelation _relation = ViewerRelation.self;
  ProfileVisibility _visibility = ProfileVisibility.public;
  bool _isMinor = false;
  bool _isFollowing = false;
  bool _statsVerified = true;
  bool _viewerIsRestricted = false;
  late List<String> _styleTags = mockPlayerProfile().styleTags;

  @override
  Widget build(BuildContext context) {
    // E16-02: a restricted follower's effective relation silently
    // downgrades to public -- they never see any indication of this.
    final effectiveRelation = resolveViewerRelation(
      actual: _relation,
      viewerIsRestricted: _viewerIsRestricted,
    );
    final base = mockPlayerProfile();
    final profile = PlayerProfile(
      name: base.name,
      city: base.city,
      bio: base.bio,
      roleChips: base.roleChips,
      headerStats: ProfileHeaderStats(
        matches: base.headerStats.matches,
        runs: base.headerStats.runs,
        wickets: base.headerStats.wickets,
        rating: base.headerStats.rating,
        verified: _statsVerified,
      ),
      pinnedBadges: base.pinnedBadges,
      recentForm: base.recentForm,
      favoriteTeams: base.favoriteTeams,
      endorsements: base.endorsements,
      styleTags: _styleTags,
      weaknesses: base.weaknesses,
      isMinor: _isMinor,
      visibility: _visibility,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile screen (QA)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: 'Controls',
            onPressed: () => _openControls(context),
          ),
        ],
      ),
      body: ProfileScreen(
        profile: profile,
        relation: effectiveRelation,
        isFollowing: _isFollowing,
        onFollow: () => setState(() => _isFollowing = !_isFollowing),
        onStyleTagsChanged: (tags) => setState(() => _styleTags = tags),
        onEdit: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const EditProfileScreen())),
        onOpenAchievements: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                AchievementsWallScreen(badges: mockAchievementBadges()),
          ),
        ),
        onOpenActivityCalendar: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ActivityCalendarScreen(
              entries: mockActivityEntries(),
              relation: effectiveRelation,
            ),
          ),
        ),
      ),
    );
  }

  void _openControls(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppDropdownField<ViewerRelation>(
                key: const ValueKey('profileDemoRelationField'),
                label: 'Viewer relation',
                value: _relation,
                options: ViewerRelation.values,
                labelBuilder: (r) => r.name,
                onChanged: (value) => setState(() {
                  setSheetState(() => _relation = value);
                }),
              ),
              const SizedBox(height: AppSpacing.md),
              AppDropdownField<ProfileVisibility>(
                key: const ValueKey('profileDemoVisibilityField'),
                label: 'Profile visibility',
                value: _visibility,
                options: ProfileVisibility.values,
                labelBuilder: (v) => v.name,
                onChanged: (value) => setState(() {
                  setSheetState(() => _visibility = value);
                }),
              ),
              SwitchListTile(
                key: const ValueKey('profileDemoMinorSwitch'),
                title: const Text('Is minor'),
                value: _isMinor,
                onChanged: (value) => setState(() {
                  setSheetState(() => _isMinor = value);
                }),
              ),
              SwitchListTile(
                key: const ValueKey('profileDemoVerifiedSwitch'),
                title: const Text('Stats verified'),
                value: _statsVerified,
                onChanged: (value) => setState(() {
                  setSheetState(() => _statsVerified = value);
                }),
              ),
              SwitchListTile(
                key: const ValueKey('profileDemoRestrictedSwitch'),
                title: const Text('Viewer is Restricted (E16-02)'),
                subtitle: const Text(
                  'Only changes anything when relation is Follower -- '
                  'silently renders as Public',
                ),
                value: _viewerIsRestricted,
                onChanged: (value) => setState(() {
                  setSheetState(() => _viewerIsRestricted = value);
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
