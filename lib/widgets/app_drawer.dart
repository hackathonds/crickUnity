import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../academies/academy_console_screen.dart';
import '../clubs/club_home_screen.dart';
import '../coaching/coach_console_screen.dart';
import '../coaching/my_academy_screen.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import '../expenses/expenses_home_screen.dart';
import '../expenses/reports_screen.dart';
import '../expenses/settle_up_screen.dart';
import '../expenses/treasury_screen.dart';
import '../grounds/my_bookings_screen.dart';
import '../grounds/owner_console_screen.dart';
import '../matches/my_matches_screen.dart';
import '../notifications/notification_center_screen.dart';
import '../officials/officials_console_screen.dart';
import '../privacy/privacy_center_screen.dart';
import '../profile/achievement_models.dart';
import '../profile/achievements_wall_screen.dart';
import '../profile/activity_calendar_models.dart';
import '../profile/activity_calendar_screen.dart';
import '../profile/availability_sheet.dart';
import '../profile/edit_profile_screen.dart';
import '../profile/profile_models.dart';
import '../profile/profile_screen.dart';
import '../recognition/year_in_review_screen.dart';
import '../rewards/my_rewards_screen.dart';
import '../rewards/wallet_screen.dart';
import '../roles/console_registry.dart';
import '../roles/current_roles_provider.dart';
import '../settings/localization_settings_screen.dart';
import '../sponsors/sponsor_console_screen.dart';
import '../teams/my_teams_screen.dart';
import '../tournaments/my_tournaments_screen.dart';
import '../tournaments/organizer_console_screen.dart';
import 'unbuilt_destination_screen.dart';

/// PRD §3.3's 5 drawer sections. Only "Consoles" is role-gated — it's
/// empty (and hidden) until the account holds a console-granting role
/// (non-negotiable #10: never a role picker, only ever a reflection of
/// activity already granted).
///
/// Every item used to push a generic `PlaceholderScreen` regardless of
/// whether a real destination existed -- by the time this was revisited,
/// most of them did (each built by its own later story). This wires
/// every genuine destination for real. My Teams/My Matches/My
/// Tournaments/My Bookings/My Academy each got their own aggregator
/// screen even though only My Teams and My Matches have a dedicated DS
/// spec (screens 10 and 23) -- the other three's "list of things I'm in"
/// concept is a direct, non-invented consequence of their name and the
/// per-instance screens that already exist for their contents (see each
/// screen's own doc comment for the exact reasoning). Captain Console
/// has no screen of its own anywhere in DS/backlog and routes to My
/// Teams instead of a redundant one. Help and Report a Problem are the
/// two items with zero PRD/DS grounding at all -- per CLAUDE.md's "never
/// guess behavior" rule, they keep an honest, explained gap notice
/// instead of invented content.
///
/// No session/auth concept exists anywhere in this app (confirmed by a
/// full-codebase search) -- "Log out" cannot actually reset anything, so
/// it's a confirm dialog naming that limitation rather than a fake
/// navigation to the onboarding flow.
class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  static const _myIdentity = [
    'Profile',
    'Wallet & Coins',
    'Rewards',
    'Achievements',
    'Activity Calendar',
    'Year in Review',
  ];

  static const _myCricket = [
    'My Teams',
    'My Matches',
    'My Tournaments',
    'My Bookings',
    'My Academy',
    'Availability settings',
  ];

  static const _money = ['Expenses', 'Settlements', 'Reports'];

  static const _settings = [
    'Privacy',
    'Notifications',
    'Language',
    'Help',
    'Report a Problem',
    'Log out',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final roles = ref.watch(currentRolesProvider);
    final consoles = consolesFor(roles);

    return Drawer(
      backgroundColor: colors.surface,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: colors.surfaceAlt),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Text(
                'CricUnity',
                style: AppTypography.h2.copyWith(color: colors.textPrimary),
              ),
            ),
          ),
          _DrawerSection(title: 'My Identity', items: _myIdentity),
          _DrawerSection(title: 'My Cricket', items: _myCricket),
          if (consoles.isNotEmpty)
            _DrawerSection(
              title: 'Consoles',
              items: consoles.map((c) => c.name).toList(),
            ),
          _DrawerSection(title: 'Money', items: _money),
          _DrawerSection(title: 'Settings', items: _settings),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

/// The one identity every money-domain debug entry already uses
/// (expenses/reports/treasury) -- reused here rather than introducing a
/// third mock "current user" name alongside `mockPlayerProfile()`'s
/// 'Rohan Verma' and messaging's 'Deepak Sharma' (a pre-existing
/// inconsistency across this app's mock data, not something this drawer
/// fix should try to unify).
const _moneyViewerName = 'Kabir Singh';

class _DrawerSection extends StatelessWidget {
  final String title;
  final List<String> items;

  const _DrawerSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          child: Text(
            title,
            style: AppTypography.label.copyWith(color: colors.textTertiary),
          ),
        ),
        for (final item in items)
          ListTile(
            key: ValueKey('drawerItem_$item'),
            title: Text(item, style: AppTypography.body),
            onTap: () => _handleTap(context, item),
          ),
        const Divider(height: AppSpacing.xl),
      ],
    );
  }

  void _handleTap(BuildContext context, String item) {
    Navigator.of(context).pop();

    // Sheet, not a screen push.
    if (item == 'Availability settings') {
      showAvailabilitySheet(context: context);
      return;
    }

    // No session/auth concept exists anywhere in this app to actually
    // reset -- an honest confirm dialog, not a fake navigation.
    if (item == 'Log out') {
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Log out'),
          content: const Text(
            'This prototype has no real session/account system to log '
            'out of -- there is nothing to reset.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    Navigator.of(
      context,
      rootNavigator: true,
    ).push(MaterialPageRoute(builder: (_) => _destinationFor(item)));
  }

  Widget _destinationFor(String item) {
    switch (item) {
      case 'Profile':
        return _SelfProfileScreen();
      case 'Wallet & Coins':
        return const WalletScreen();
      case 'Rewards':
        return const MyRewardsScreen();
      case 'Achievements':
        return AchievementsWallScreen(badges: mockAchievementBadges());
      case 'Activity Calendar':
        return ActivityCalendarScreen(
          entries: mockActivityEntries(),
          relation: ViewerRelation.self,
        );
      case 'Year in Review':
        return const YearInReviewScreen();

      case 'Expenses':
        return const ExpensesHomeScreen(
          viewerName: _moneyViewerName,
          viewerIsCaptain: true,
        );
      case 'Settlements':
        return const SettleUpScreen(viewerName: _moneyViewerName);
      case 'Reports':
        return const ReportsScreen(
          viewerName: _moneyViewerName,
          viewerIsCaptain: true,
        );

      case 'Privacy':
        return const PrivacyCenterScreen();
      case 'Notifications':
        return const NotificationCenterScreen();
      case 'Language':
        return const LocalizationSettingsScreen();

      // Consoles — role-gated, so whoever reaches these already holds
      // the granting role; Scorer/Umpire share the one real Officials
      // Console (assignments/earnings/ratings), same approximation
      // this app's own debug menu makes for both roles.
      case 'Manager / Treasury':
        return const TreasuryScreen(
          viewerName: _moneyViewerName,
          viewerIsManagerOrCaptain: true,
        );
      case 'Scorer Console':
      case 'Umpire Console':
        return const OfficialsConsoleScreen();
      case 'Coach Console':
        return const CoachConsoleScreen();
      case 'Ground Console':
        return const OwnerConsoleScreen(groundId: 'ground-green-valley');
      case 'Academy Console':
        return const AcademyConsoleScreen();
      case 'Organizer Console':
        return const OrganizerConsoleScreen();
      case 'Club Console':
        return const ClubHomeScreen();
      case 'Sponsor Console':
        return const SponsorConsoleScreen();
      // No console screen exists independent of a specific team -- every
      // team feature (selection, availability, treasury) is reached from
      // that team's own home page today, not a cross-team captain
      // console. My Teams is the real entry point into that, so it
      // routes here rather than to a redundant, never-specified screen.
      case 'Captain Console':
        return const MyTeamsScreen();

      case 'My Teams':
        return const MyTeamsScreen();
      case 'My Matches':
        return const MyMatchesScreen();
      case 'My Tournaments':
        return const MyTournamentsScreen();
      case 'My Bookings':
        return const MyBookingsScreen();
      case 'My Academy':
        return const MyAcademyScreen();
      case 'Help':
        return const UnbuiltDestinationScreen(
          title: 'Help',
          explanation:
              'Help has no design or behavior spec in the PRD or Design '
              'Spec -- confirmed absent, same as its Sandbox tutorial '
              'sibling (E16-07), which was built; a real Help/FAQ screen '
              'was not.',
        );
      case 'Report a Problem':
        return const UnbuiltDestinationScreen(
          title: 'Report a Problem',
          explanation:
              'Only reporting a specific post/user/profile exists '
              '(Moderation\'s report sheet) -- there is no general '
              '"report a problem with the app" flow.',
        );

      default:
        // Any future console name added to console_registry.dart without
        // a matching case here lands here rather than crashing.
        return UnbuiltDestinationScreen(
          title: item,
          explanation: 'No real screen is wired up for "$item" yet.',
        );
    }
  }
}

/// PRD §5's "own profile" view -- reuses the exact self-view
/// construction pattern `profile_screen_demo.dart` already established
/// (rebuild [PlayerProfile] from the one mock shape, wire the same real
/// callbacks), rather than inventing a second one for the drawer.
class _SelfProfileScreen extends StatefulWidget {
  @override
  State<_SelfProfileScreen> createState() => _SelfProfileScreenState();
}

class _SelfProfileScreenState extends State<_SelfProfileScreen> {
  late List<String> _styleTags = mockPlayerProfile().styleTags;

  @override
  Widget build(BuildContext context) {
    final profile = mockPlayerProfile();
    return ProfileScreen(
      profile: PlayerProfile(
        name: profile.name,
        city: profile.city,
        bio: profile.bio,
        roleChips: profile.roleChips,
        headerStats: profile.headerStats,
        pinnedBadges: profile.pinnedBadges,
        recentForm: profile.recentForm,
        favoriteTeams: profile.favoriteTeams,
        endorsements: profile.endorsements,
        styleTags: _styleTags,
        weaknesses: profile.weaknesses,
      ),
      relation: ViewerRelation.self,
      onEdit: () => Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const EditProfileScreen())),
      onStyleTagsChanged: (tags) => setState(() => _styleTags = tags),
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
            relation: ViewerRelation.self,
          ),
        ),
      ),
    );
  }
}
