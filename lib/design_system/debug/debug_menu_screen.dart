import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../expenses/add_edit_expense_screen.dart';
import '../../expenses/auto_split_review_screen.dart';
import '../../expenses/collections_provider.dart';
import '../../expenses/expense_comments_provider.dart';
import '../../expenses/expense_detail_screen.dart';
import '../../expenses/expense_models.dart';
import '../../expenses/expenses_home_screen.dart';
import '../../expenses/expenses_provider.dart';
import '../../expenses/recently_deleted_screen.dart';
import '../../expenses/recurring_series_models.dart';
import '../../expenses/recurring_series_provider.dart';
import '../../expenses/reports_screen.dart';
import '../../expenses/settle_up_screen.dart';
import '../../expenses/treasury_screen.dart';
import '../../expenses/wallet_payouts_provider.dart';
import '../../academies/academy_console_screen.dart';
import '../../clubs/club_home_screen.dart';
import '../../coaching/coach_console_screen.dart';
import '../../coaching/compliance_vault_screen.dart';
import '../../coaching/personal_training_log_screen.dart';
import '../../grounds/booking_flow_screen.dart';
import '../../notifications/notification_center_screen.dart';
import '../../search/global_search_screen.dart';
import '../../search/qr_scanner_screen.dart';
import '../../grounds/ground_profile_screen.dart';
import '../../grounds/grounds_discovery_screen.dart';
import '../../grounds/caretaker_mode_screen.dart';
import '../../tournaments/auction_room_screen.dart';
import '../../tournaments/association_screen.dart';
import '../../tournaments/organizer_console_screen.dart';
import '../../tournaments/sanction_request_screen.dart';
import '../../tournaments/stats_hub_screen.dart';
import '../../tournaments/bracket_screen.dart';
import '../../tournaments/fixtures_editor_screen.dart';
import '../../tournaments/points_table_screen.dart';
import '../../tournaments/tournament_creation_wizard_screen.dart';
import '../../tournaments/tournament_registration_screen.dart';
import '../../grounds/owner_console_screen.dart';
import '../../grounds/review_composer_screen.dart';
import '../../guest/guest_live_match_preview_screen.dart';
import '../../matches/awards_screen.dart';
import '../../matches/create_match_flow.dart';
import '../../matches/match_detail_screen.dart';
import '../../matches/match_models.dart';
import '../../matches/match_opponent_decision_screen.dart';
import '../../matches/match_proposal_review_screen.dart';
import '../../matches/field_map_screen.dart';
import '../../matches/gallery_screen.dart';
import '../../matches/highlights_builder_screen.dart';
import '../../matches/insights_screen.dart';
import '../../matches/scorecard_screen.dart';
import '../../matches/scoring_models.dart';
import '../../matches/live_scoring_console_screen.dart';
import '../../matches/live_match_view_screen.dart';
import '../../matches/post_match_summary_screen.dart';
import '../../matches/scoring_provider.dart';
import '../../matches/matches_provider.dart';
import '../../matches/toss_screen.dart';
import '../../onboarding/onboarding_flow.dart';
import '../../rewards/achievements_provider.dart';
import '../../rewards/badge_engine_screen.dart';
import '../../rewards/luck_layer_screen.dart';
import '../../rewards/luck_provider.dart';
import '../../rewards/missions_board_screen.dart';
import '../../rewards/missions_models.dart';
import '../../rewards/missions_provider.dart';
import '../../rewards/pro_paywall_screen.dart';
import '../../rewards/referral_screen.dart';
import '../../rewards/rewards_provider.dart';
import '../../rewards/rewards_summary_screen.dart';
import '../../rewards/wallet_screen.dart';
import '../../messaging/chat_list_screen.dart';
import '../../moderation/moderation_settings_screen.dart';
import '../../recognition/leaderboard_hub_screen.dart';
import '../../recognition/challenges_hub_screen.dart';
import '../../recognition/compare_screen.dart';
import '../../recognition/goals_screen.dart';
import '../../recognition/awards_screen.dart';
import '../../recognition/progress_rings_screen.dart';
import '../../recognition/ranks_screen.dart';
import '../../rewards/season_screen.dart';
import '../../recognition/year_in_review_screen.dart';
import '../../recognition/grounds_heatmap_screen.dart';
import '../../recognition/personal_bests_screen.dart';
import '../../recognition/records_hub_screen.dart';
import '../../social/events_list_screen.dart';
import '../../social/feed_screen.dart';
import '../../social/groups_list_screen.dart';
import '../../social/fan_engagement_screen.dart';
import '../../social/saved_screen.dart';
import '../../rewards/streaks_summary_screen.dart';
import '../../profile/achievement_models.dart';
import '../../profile/achievements_wall_screen.dart';
import '../../profile/activity_calendar_models.dart';
import '../../profile/activity_calendar_screen.dart';
import '../../profile/edit_profile_screen.dart';
import '../../profile/free_agent_screen.dart';
import '../../profile/profile_models.dart';
import '../../teams/create_team_flow.dart';
import '../../teams/edit_team_screen.dart';
import '../../teams/join_requests_screen.dart';
import '../../teams/team_invite_decision_screen.dart';
import '../../teams/team_invite_models.dart';
import '../../teams/team_invite_sheet.dart';
import '../../teams/team_models.dart';
import '../../teams/availability_matrix_models.dart';
import '../../teams/availability_matrix_screen.dart';
import 'announcements_demo.dart';
import 'avatar_screen.dart';
import 'members_roles_demo.dart';
import '../../teams/selection_board_screen.dart';
import '../../teams/carpool_screen.dart';
import '../../teams/duty_roster_screen.dart';
import '../../teams/kit_inventory_screen.dart';
import '../../teams/recruitment_board_screen.dart';
import '../../teams/season_summary_models.dart';
import '../../teams/season_summary_screen.dart';
import '../../teams/succession_screen.dart';
import '../../teams/team_documents_screen.dart';
import '../../teams/team_member_models.dart';
import '../../teams/transfer_screen.dart';
import 'jersey_board_demo.dart';
import 'practice_session_demo.dart';
import 'team_home_demo.dart';
import 'nearby_matches_preview_screen.dart';
import 'onboarding_checklist_screen.dart';
import 'profile_screen_demo.dart';
import 'badge_tile_screen.dart';
import 'buttons_screen.dart';
import 'card_screen.dart';
import '../../analytics/custom_stats_explorer_screen.dart';
import '../../analytics/entity_analytics_screen.dart';
import '../../analytics/player_analytics_screen.dart';
import '../../analytics/team_captain_analytics_screen.dart';
import '../../officials/commentator_room_screen.dart';
import '../../officials/knowledge_hub_screen.dart';
import '../../streaming/go_live_screen.dart';
import '../../sponsors/sponsor_console_screen.dart';
import '../../streaming/production_kit_screen.dart';
import '../../officials/conduct_report_screen.dart';
import '../../officials/gig_board_models.dart' show OfficialRole;
import '../../officials/gig_board_screen.dart';
import '../../officials/officials_console_screen.dart';
import 'chart_gallery_screen.dart';
import 'chart_shell_screen.dart';
import 'comment_widget_screen.dart';
import 'chips_screen.dart';
import 'coin_xp_screen.dart';
import 'calendar_screen.dart';
import 'dropdown_screen.dart';
import 'forms_kit_screen.dart';
import 'gamification_cards_screen.dart';
import 'leaderboard_screen.dart';
import 'match_cards_screen.dart';
import 'money_cards_screen.dart';
import 'player_stat_cards_screen.dart';
import 'reaction_picker_screen.dart';
import 'stepper_screen.dart';
import 'timeline_screen.dart';
import 'icon_gallery_screen.dart';
import 'sheet_dialog_snackbar_screen.dart';
import 'scoreboard_screen.dart';
import 'search_bar_screen.dart';
import 'segmented_control_screen.dart';
import 'shell_debug_screen.dart';
import 'state_scaffolds_screen.dart';
import 'type_specimen_screen.dart';

/// Lists the internal QA screens built up across the E0 stories so far.
/// Since E0-04, the app's real home is the navigation shell — this menu is
/// reached via a temporary link on the Profile tab instead of being the
/// app's `home`.
class DebugMenuScreen extends StatelessWidget {
  const DebugMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Design system QA')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Type specimen'),
            subtitle: const Text('E0-02 — every type role'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const TypeSpecimenScreen()),
            ),
          ),
          ListTile(
            title: const Text('Icon gallery'),
            subtitle: const Text('E0-03 — every icon family'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const IconGalleryScreen()),
            ),
          ),
          ListTile(
            title: const Text('Shell debug controls'),
            subtitle: const Text('E0-04 — roles, badges, pinned live match'),
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const ShellDebugScreen())),
          ),
          ListTile(
            title: const Text('Sheet / dialog / snackbar'),
            subtitle: const Text('E0-05 — bottom sheet, dialogs, snackbar'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const SheetDialogSnackbarScreen(),
              ),
            ),
          ),
          ListTile(
            title: const Text('State scaffolds'),
            subtitle: const Text(
              'E0-06 — empty/loading/error/offline, queued actions',
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const StateScaffoldsScreen()),
            ),
          ),
          ListTile(
            title: const Text('Buttons'),
            subtitle: const Text(
              'E0-07 (1/10) — primary/secondary/tertiary/destructive, chip, icon, FAB',
            ),
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const ButtonsScreen())),
          ),
          ListTile(
            title: const Text('Cards'),
            subtitle: const Text(
              'E0-07 (2/10) — base card, header/menu, money surface, loading',
            ),
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const CardScreen())),
          ),
          ListTile(
            title: const Text('Search bar'),
            subtitle: const Text(
              'E0-07 (3/10) — pill, expansion, recent list, voice, QR hook',
            ),
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const SearchBarScreen())),
          ),
          ListTile(
            title: const Text('Segmented control'),
            subtitle: const Text(
              'E0-07 (4/10) — sliding track, scrollable-chip-row fallback',
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SegmentedControlScreen()),
            ),
          ),
          ListTile(
            title: const Text('Chips'),
            subtitle: const Text(
              'E0-07 (5/10) — static tag/status chips, delta chip',
            ),
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const ChipsScreen())),
          ),
          ListTile(
            title: const Text('Avatars'),
            subtitle: const Text(
              'E0-07 (6/10) — sizes, level ring, presence, verified badge',
            ),
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const AvatarScreen())),
          ),
          ListTile(
            title: const Text('Forms kit'),
            subtitle: const Text(
              'E0-07 (7/10) — floating label field, currency field, step progress',
            ),
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const FormsKitScreen())),
          ),
          ListTile(
            title: const Text('Stepper'),
            subtitle: const Text(
              'E0-07 (8/10) — bounds, long-press auto-repeat, manual entry',
            ),
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const StepperScreen())),
          ),
          ListTile(
            title: const Text('Dropdown-as-sheet'),
            subtitle: const Text(
              'E0-07 (9/10) — radio rows, search row above 8 options',
            ),
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const DropdownScreen())),
          ),
          ListTile(
            title: const Text('Calendar'),
            subtitle: const Text(
              'E0-07 (10/10) — month grid, event dots, range-select, heat variant',
            ),
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const CalendarScreen())),
          ),
          ListTile(
            title: const Text('Match-context cards'),
            subtitle: const Text(
              'E0-08 (1/12) — Match, Live Match, Tournament cards',
            ),
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const MatchCardsScreen())),
          ),
          ListTile(
            title: const Text('Money cards'),
            subtitle: const Text(
              'E0-08 (2/12) — Expense card, Expense row (states, swipe)',
            ),
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const MoneyCardsScreen())),
          ),
          ListTile(
            title: const Text('Player & stat cards'),
            subtitle: const Text('E0-08 (3/12) — Player card, Statistics card'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PlayerStatCardsScreen()),
            ),
          ),
          ListTile(
            title: const Text('Gamification cards'),
            subtitle: const Text('E0-08 (4/12) — Reward card, Progress card'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const GamificationCardsScreen(),
              ),
            ),
          ),
          ListTile(
            title: const Text('Leaderboard'),
            subtitle: const Text(
              'E0-08 (5/12) — row, top-3, sticky self-clone',
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const LeaderboardScreen()),
            ),
          ),
          ListTile(
            title: const Text('Timeline & ball-scrub'),
            subtitle: const Text(
              'E0-08 (6/12) — sticky date separators, drag-to-scrub',
            ),
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const TimelineScreen())),
          ),
          ListTile(
            title: const Text('Comment widget'),
            subtitle: const Text(
              'E0-08 (7/12) — composer, thread rows, expandable replies',
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CommentWidgetScreen()),
            ),
          ),
          ListTile(
            title: const Text('Reaction arc-picker'),
            subtitle: const Text(
              'E0-08 (8/12) — quick-tap clap, long-press radial picker',
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ReactionPickerScreen()),
            ),
          ),
          ListTile(
            title: const Text('Coin & XP widgets'),
            subtitle: const Text(
              'E0-08 (9/12) — coin chip earn animation, XP ring sweep + toast',
            ),
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const CoinXpScreen())),
          ),
          ListTile(
            title: const Text('Badge tile'),
            subtitle: const Text(
              'E0-08 (10/12) — hex-soft tile, earned/locked, detail sheet',
            ),
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const BadgeTileScreen())),
          ),
          ListTile(
            title: const Text('Scoreboard'),
            subtitle: const Text(
              'E0-08 (11/12) — odometer roll, wicket flash, TV mode',
            ),
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const ScoreboardScreen())),
          ),
          ListTile(
            title: const Text('Chart shell'),
            subtitle: const Text(
              'E0-08 (12/12) — scrub tooltip, sticky legend, table toggle',
            ),
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const ChartShellScreen())),
          ),
          ListTile(
            title: const Text('Chart gallery'),
            subtitle: const Text(
              'E13-01 — Manhattan, win-prob worm, wagon wheel, radar, '
              'dot-pressure gauge, race chart, tag-coverage caption',
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ChartGalleryScreen()),
            ),
          ),
          ListTile(
            title: const Text('Player analytics'),
            subtitle: const Text(
              'E13-02 — phase splits, vs pace/spin, entry points, form '
              'index, fatigue, insights + recommendations',
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PlayerAnalyticsScreen()),
            ),
          ),
          ListTile(
            title: const Text('Team & captain analytics'),
            subtitle: const Text(
              'E13-03 — toss/bowling-change/lineup-cluster analysis, '
              'margins, collapse frequency, ground record',
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const TeamCaptainAnalyticsScreen(),
              ),
            ),
          ),
          ListTile(
            title: const Text('Custom Stats Explorer'),
            subtitle: const Text(
              'E13-04 — query builder, qualification stepper, sortable '
              'results table, save/pin-as-widget',
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const CustomStatsExplorerScreen(),
              ),
            ),
          ),
          ListTile(
            title: const Text('Entity analytics'),
            subtitle: const Text(
              'E13-05 — Ground/Expense (link out) + Social/Rewards/'
              'Attendance analytics',
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const EntityAnalyticsScreen()),
            ),
          ),
          ListTile(
            title: const Text('Gig board (scorer)'),
            subtitle: const Text(
              'E14-01 — distance/fee/date filters, gig cards, accept -> '
              'calendar add',
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const GigBoardScreen(role: OfficialRole.scorer),
              ),
            ),
          ),
          ListTile(
            title: const Text('Gig board (umpire)'),
            subtitle: const Text('E14-01 — same board, umpire-scoped gigs'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const GigBoardScreen(role: OfficialRole.umpire),
              ),
            ),
          ),
          ListTile(
            title: const Text('Officials console'),
            subtitle: const Text(
              'E14-02 — assignments/earnings/ratings tabs, credential '
              'tier progress, payment reminder, dispute-appeal',
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const OfficialsConsoleScreen()),
            ),
          ),
          ListTile(
            title: const Text('Conduct report + appeal'),
            subtitle: const Text(
              'E14-03 — stepped incident sheet, organizer review routing, '
              'appeal flow',
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ConductReportScreen()),
            ),
          ),
          ListTile(
            title: const Text('Commentator room'),
            subtitle: const Text(
              'E14-04 — stream-audio tile, Mark moment, marker history, '
              'mute-self, assigned-only gate',
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CommentatorRoomScreen()),
            ),
          ),
          ListTile(
            title: const Text('Knowledge hub'),
            subtitle: const Text(
              'E14-05 — daily trivia, quiz packs, certification exam '
              'mode + tier-gated certificate mint',
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const KnowledgeHubScreen()),
            ),
          ),
          ListTile(
            title: const Text('Go live'),
            subtitle: const Text(
              'E15-01 — preflight checklist, overlay theme, sponsor slot, '
              'countdown, live HUD, VOD chapters',
            ),
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const GoLiveScreen())),
          ),
          ListTile(
            title: const Text('Production kit'),
            subtitle: const Text(
              'E15-02 — overlay theme, lower-third editor + live '
              'preview, destination checklist, commentator-assign',
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProductionKitScreen()),
            ),
          ),
          ListTile(
            title: const Text('Sponsor console'),
            subtitle: const Text(
              'E15-03 — marketplace, make-offer form, offer states, '
              'campaign dashboard, sponsored badge',
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SponsorConsoleScreen()),
            ),
          ),
          ListTile(
            title: const Text('Onboarding: full pre-tab stack'),
            subtitle: const Text(
              'E1-01/02/03 — Welcome→OTP→DOB→guardian gate→profile wizard→'
              'permissions→warm-up',
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => OnboardingFlow(
                  showDebugSimulateApproval: true,
                  onOnboardingComplete: () {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Onboarding complete')),
                    );
                  },
                  onExploreAsGuest: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => GuestLiveMatchPreviewScreen(
                          onContinueWithPhone: () {
                            Navigator.of(context).pop();
                          },
                        ),
                      ),
                    );
                  },
                  onContactSupport: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Support is E16-07 — not built yet'),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          ListTile(
            title: const Text('Onboarding checklist widget'),
            subtitle: const Text(
              'E1-05 — 4-item checklist, coin float, auto-hides at 2 done',
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const OnboardingChecklistScreen(),
              ),
            ),
          ),
          ListTile(
            title: const Text('Profile screen'),
            subtitle: const Text(
              'E2-01 — viewer-relative, private lock, blocked, verified stats',
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProfileScreenDemo()),
            ),
          ),
          ListTile(
            title: const Text('Edit profile'),
            subtitle: const Text(
              'E2-02 — grouped form, name-change 2/yr limit, dirty-leave guard',
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const EditProfileScreen()),
            ),
          ),
          ListTile(
            title: const Text('Achievements wall'),
            subtitle: const Text(
              'E2-05 — badge wall, category filter, locked-tile criteria',
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    AchievementsWallScreen(badges: mockAchievementBadges()),
              ),
            ),
          ),
          ListTile(
            title: const Text('Activity calendar'),
            subtitle: const Text(
              'E2-06 — heat grid, month pager, viewer-tiered day peek',
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ActivityCalendarScreen(
                  entries: mockActivityEntries(),
                  relation: ViewerRelation.self,
                ),
              ),
            ),
          ),
          ListTile(
            title: const Text('Create team'),
            subtitle: const Text(
              'E3-01 — name/logo/location/format/access/colors wizard',
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => CreateTeamFlow(onTeamCreated: (_) {}),
              ),
            ),
          ),
          ListTile(
            title: const Text('Edit team'),
            subtitle: const Text(
              'E3-01 — identity vs logistics fields, "formerly known as"',
            ),
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const EditTeamScreen())),
          ),
          ListTile(
            title: const Text('Team home'),
            subtitle: const Text(
              'E3-02 — role-gated tabs (hidden not disabled), archived banner',
            ),
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const TeamHomeDemo())),
          ),
          ListTile(
            title: const Text('Invite to team'),
            subtitle: const Text('E3-03 — QR / link (7d, revocable) / search'),
            onTap: () => showTeamInviteSheet(
              context: context,
              teamName: mockTeam().name,
            ),
          ),
          ListTile(
            title: const Text('Join requests'),
            subtitle: const Text(
              'E3-03 — stats+Trust band+mutuals, approve/deny, rival-flag notice',
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const JoinRequestsScreen()),
            ),
          ),
          ListTile(
            title: const Text('Team invite (invitee view)'),
            subtitle: const Text(
              'E3-03 — accept/decline, expiry countdown, 10-team cap AC',
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => TeamInviteDecisionScreen(
                  offer: TeamInviteOffer(
                    teamName: mockTeam().name,
                    roleOffered: 'Player',
                    expiresAt: DateTime.now().add(const Duration(days: 6)),
                  ),
                ),
              ),
            ),
          ),
          ListTile(
            title: const Text('Roles & permission matrix'),
            subtitle: const Text(
              'E3-04 — roster change-role/remove, read-only matrix + owner toggles',
            ),
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const MembersRolesDemo())),
          ),
          ListTile(
            title: const Text('Announcements'),
            subtitle: const Text(
              'E3-05 — push-priority (1/6h), seen-by (author-only), comment toggle',
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AnnouncementsDemo()),
            ),
          ),
          ListTile(
            title: const Text('Availability matrix'),
            subtitle: const Text(
              'E3-06 — tri-state grid, sticky names, 1 nudge/12h/event, footer summary',
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const AvailabilityMatrixScreen(),
              ),
            ),
          ),
          ListTile(
            title: const Text('Practice session + attendance'),
            subtitle: const Text(
              'E3-07 — RSVP, check-in ±1h window, roll-call, no-show excuse, recap',
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PracticeSessionDemo()),
            ),
          ),
          ListTile(
            title: const Text('Selection board & lineup'),
            subtitle: const Text(
              'E3-08 — drag pool to XI, WK warning, publish, lock, replacement flow',
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SelectionBoardScreen()),
            ),
          ),
          ListTile(
            title: const Text('Jersey board'),
            subtitle: const Text(
              'E3-09 — size sheet, number-conflict resolver, order tracker',
            ),
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const JerseyBoardDemo())),
          ),
          ListTile(
            title: const Text('Carpool'),
            subtitle: const Text(
              'E3-10 (1/4) — seat pips, Join confirm, fuel-split suggestion',
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const CarpoolScreen(viewerName: 'Priya Nair'),
              ),
            ),
          ),
          ListTile(
            title: const Text('Duty roster'),
            subtitle: const Text(
              'E3-10 (2/4) — claim/unclaim slots, Volunteer coins/XP',
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    const DutyRosterScreen(viewerName: 'Priya Nair'),
              ),
            ),
          ),
          ListTile(
            title: const Text('Kit inventory'),
            subtitle: const Text(
              'E3-10 (3/4) — custody hand-over, both sides confirm',
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    const KitInventoryScreen(viewerName: 'Kabir Singh'),
              ),
            ),
          ),
          ListTile(
            title: const Text('Documents (Captain)'),
            subtitle: const Text(
              'E3-10 (4/4) — role-based upload, Captain can upload',
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const TeamDocumentsScreen(
                  viewerName: 'Rohan Kapoor',
                  viewerRole: TeamMemberRole.captain,
                ),
              ),
            ),
          ),
          ListTile(
            title: const Text('Documents (Player)'),
            subtitle: const Text(
              'E3-10 (4/4) — role-based upload, Player cannot upload',
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const TeamDocumentsScreen(
                  viewerName: 'Sana Iyer',
                  viewerRole: TeamMemberRole.player,
                ),
              ),
            ),
          ),
          ListTile(
            title: const Text('Recruitment board (Captain)'),
            subtitle: const Text(
              'E3-11 — post listing, kanban pipeline, drag to move stage',
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const RecruitmentBoardScreen(
                  viewerName: 'Rohan Kapoor',
                  viewerRole: TeamMemberRole.captain,
                ),
              ),
            ),
          ),
          ListTile(
            title: const Text('Recruitment board (Free agent)'),
            subtitle: const Text('E3-11 — browse listings, Apply'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const RecruitmentBoardScreen(
                  viewerName: 'Karan Bhatt',
                  viewerRole: TeamMemberRole.player,
                ),
              ),
            ),
          ),
          ListTile(
            title: const Text('Season summary (Captain)'),
            subtitle: const Text(
              'E3-13 — milestones, wrap cards, Present ceremony mode',
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => SeasonSummaryScreen(
                  viewerRole: TeamMemberRole.captain,
                  data: mockSeasonSummary(),
                ),
              ),
            ),
          ),
          ListTile(
            title: const Text('Season summary (new team)'),
            subtitle: const Text('E3-13 — insufficient-data state'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const SeasonSummaryScreen(
                  viewerRole: TeamMemberRole.player,
                  data: SeasonSummaryData(
                    matchesPlayed: 0,
                    winsCount: 0,
                    lossesCount: 0,
                    drawsCount: 0,
                    championshipsWon: 0,
                    topScorerName: '',
                    topScorerRuns: 0,
                    topWicketTakerName: '',
                    topWicketTakerWickets: 0,
                    bestWinDescription: '',
                    chemistryTrendPercent: 0,
                    moneyCollectedRupees: 0,
                    moneySpentRupees: 0,
                    perHeadCostRupees: 0,
                  ),
                ),
              ),
            ),
          ),
          ListTile(
            title: const Text('Transfer'),
            subtitle: const Text(
              'E3-14 — player-move flow, window enforcement, courtesy note',
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const TransferScreen(
                  playerName: 'Karan Bhatt',
                  fromTeamName: 'Riverside Strikers',
                ),
              ),
            ),
          ),
          ListTile(
            title: const Text('Captaincy & ownership (as Captain/Owner)'),
            subtitle: const Text(
              'E3-15 — VC auto-elevation, ownership transfer, petitions',
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    const SuccessionScreen(viewerName: 'Rohan Kapoor'),
              ),
            ),
          ),
          ListTile(
            title: const Text('Captaincy & ownership (as VC)'),
            subtitle: const Text('E3-15 — viewer is Vice-Captain'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    const SuccessionScreen(viewerName: 'Kabir Singh'),
              ),
            ),
          ),
          ListTile(
            title: const Text('Find a Game (free agent)'),
            subtitle: const Text(
              'E3-16 — free-agent toggle, browse needs, auction pools',
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const FreeAgentScreen(playerName: 'Neha Rao'),
              ),
            ),
          ),
          ListTile(
            title: const Text('Start a match'),
            subtitle: const Text(
              'E4-01 — 4-step create-match wizard, smart defaults',
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => CreateMatchFlow(
                  composerTeamName: 'Riverside Strikers',
                  onMatchSent: (_) {},
                ),
              ),
            ),
          ),
          ListTile(
            title: const Text('Match invite (opponent view)'),
            subtitle: const Text('E4-01 — Accept / Propose changes / Decline'),
            onTap: () {
              final container = ProviderScope.containerOf(
                context,
                listen: false,
              );
              final id = container
                  .read(matchesProvider.notifier)
                  .submitMatch(
                    draft: MatchDraft(
                      dateTime: DateTime.now().add(const Duration(days: 3)),
                      opponentTeamName: 'Riverside Strikers',
                      groundName: 'Central Ground',
                    ),
                    composerTeamName: 'Central Warriors',
                  );
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => MatchOpponentDecisionScreen(matchId: id),
                ),
              );
            },
          ),
          ListTile(
            title: const Text('Match proposal review (composer view)'),
            subtitle: const Text('E4-01 — field-level diff, one-tap accept'),
            onTap: () {
              final container = ProviderScope.containerOf(
                context,
                listen: false,
              );
              final notifier = container.read(matchesProvider.notifier);
              final id = notifier.submitMatch(
                draft: MatchDraft(
                  dateTime: DateTime.now().add(const Duration(days: 3)),
                  opponentTeamName: 'Central Warriors',
                  groundName: 'Riverside Ground',
                ),
                composerTeamName: 'Riverside Strikers',
              );
              notifier.proposeChanges(
                id,
                groundName: 'Central Ground',
                dateTime: DateTime.now().add(const Duration(days: 4)),
              );
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => MatchProposalReviewScreen(matchId: id),
                ),
              );
            },
          ),
          ListTile(
            title: const Text('Match detail (captain, upcoming)'),
            subtitle: const Text(
              'E4-02 — info rows, squad grid, expense preview, sticky RSVP',
            ),
            onTap: () {
              final container = ProviderScope.containerOf(
                context,
                listen: false,
              );
              final id = container
                  .read(matchesProvider.notifier)
                  .submitMatch(
                    draft: MatchDraft(
                      dateTime: DateTime.now().add(const Duration(days: 3)),
                      opponentTeamName: 'Central Warriors',
                      groundName: 'Riverside Ground',
                    ),
                    composerTeamName: 'Riverside Strikers',
                  );
              container.read(matchesProvider.notifier).acceptMatch(id);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => MatchDetailScreen(
                    matchId: id,
                    viewerName: 'Rohan Kapoor',
                    isCaptain: true,
                  ),
                ),
              );
            },
          ),
          ListTile(
            title: const Text('Match detail (cancelled)'),
            subtitle: const Text('E4-02 — struck header + reason banner'),
            onTap: () {
              final container = ProviderScope.containerOf(
                context,
                listen: false,
              );
              final notifier = container.read(matchesProvider.notifier);
              final id = notifier.submitMatch(
                draft: MatchDraft(
                  dateTime: DateTime.now().add(const Duration(days: 3)),
                  opponentTeamName: 'Central Warriors',
                  groundName: 'Riverside Ground',
                ),
                composerTeamName: 'Riverside Strikers',
              );
              notifier.acceptMatch(id);
              notifier.cancelMatch(id, 'Ground waterlogged after rain');
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      MatchDetailScreen(matchId: id, viewerName: 'Kabir Singh'),
                ),
              );
            },
          ),
          ListTile(
            title: const Text('Match detail (private, approval queue)'),
            subtitle: const Text(
              'E4-16 — share sheet, privacy row, viewer approval queue',
            ),
            onTap: () {
              final container = ProviderScope.containerOf(
                context,
                listen: false,
              );
              final notifier = container.read(matchesProvider.notifier);
              final id = notifier.submitMatch(
                draft: MatchDraft(
                  dateTime: DateTime.now().add(const Duration(days: 3)),
                  opponentTeamName: 'Central Warriors',
                  groundName: 'Riverside Ground',
                  visibility: MatchVisibility.private,
                ),
                composerTeamName: 'Riverside Strikers',
              );
              notifier.acceptMatch(id);
              notifier.requestViewerAccess(id, 'Guest Viewer');
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => MatchDetailScreen(
                    matchId: id,
                    viewerName: 'Rohan Kapoor',
                    isCaptain: true,
                  ),
                ),
              );
            },
          ),
          ListTile(
            title: const Text('Match detail (scorer/umpire conflicts)'),
            subtitle: const Text(
              'E4-17 — self-scoring block + umpire own-squad conflict',
            ),
            onTap: () {
              final container = ProviderScope.containerOf(
                context,
                listen: false,
              );
              final notifier = container.read(matchesProvider.notifier);
              final id = notifier.submitMatch(
                draft: MatchDraft(
                  dateTime: DateTime.now().add(const Duration(days: 3)),
                  opponentTeamName: 'Central Warriors',
                  groundName: 'Riverside Ground',
                  scorerAssignment: ScorerAssignment.member,
                  scorerMemberName: 'Kabir Singh',
                  umpireNames: const ['Priya Nair'],
                ),
                composerTeamName: 'Riverside Strikers',
              );
              notifier.acceptMatch(id);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => MatchDetailScreen(
                    matchId: id,
                    viewerName: 'Rohan Kapoor',
                    isCaptain: true,
                  ),
                ),
              );
            },
          ),
          ListTile(
            title: const Text('Match detail (rescheduled)'),
            subtitle: const Text('E4-02 — banner + cleared responses'),
            onTap: () {
              final container = ProviderScope.containerOf(
                context,
                listen: false,
              );
              final notifier = container.read(matchesProvider.notifier);
              final id = notifier.submitMatch(
                draft: MatchDraft(
                  dateTime: DateTime.now().add(const Duration(days: 3)),
                  opponentTeamName: 'Central Warriors',
                  groundName: 'Riverside Ground',
                ),
                composerTeamName: 'Riverside Strikers',
              );
              notifier.acceptMatch(id);
              notifier.respondAvailability(
                id,
                'Kabir Singh',
                AvailabilityResponse.yes,
              );
              notifier.rescheduleMatch(
                id,
                newDateTime: DateTime.now().add(const Duration(days: 5)),
                reason: 'Ground unavailable on original date',
              );
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      MatchDetailScreen(matchId: id, viewerName: 'Kabir Singh'),
                ),
              );
            },
          ),
          ListTile(
            title: const Text('Toss'),
            subtitle: const Text(
              'E4-03 — 3D coin flip, Bat/Bowl choice, manual entry fallback',
            ),
            onTap: () {
              final container = ProviderScope.containerOf(
                context,
                listen: false,
              );
              final id = container
                  .read(matchesProvider.notifier)
                  .submitMatch(
                    draft: MatchDraft(
                      dateTime: DateTime.now().add(const Duration(hours: 2)),
                      opponentTeamName: 'Central Warriors',
                      groundName: 'Riverside Ground',
                    ),
                    composerTeamName: 'Riverside Strikers',
                  );
              container.read(matchesProvider.notifier).acceptMatch(id);
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => TossScreen(matchId: id)),
              );
            },
          ),
          ListTile(
            title: const Text('Live scoring console'),
            subtitle: const Text(
              'E4-04 — pad, extras, bowler-select, strike-swap',
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const LiveScoringConsoleScreen(),
              ),
            ),
          ),
          ListTile(
            title: const Text('Live scoring console (2nd-innings chase)'),
            subtitle: const Text(
              'E4-07 — interrupt/resume, revised overs, CRR/RRR strip',
            ),
            onTap: () {
              final container = ProviderScope.containerOf(
                context,
                listen: false,
              );
              container.read(inningsProvider.notifier).setTarget(165);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const LiveScoringConsoleScreen(),
                ),
              );
            },
          ),
          ListTile(
            title: const Text('Live Match View (spectator)'),
            subtitle: const Text(
              'E4-11 — Commentary/Scorecard/Charts/Gallery tabs, jump-to-live',
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const LiveMatchViewScreen()),
            ),
          ),
          ListTile(
            title: const Text('Live Match View (scorer commentary edit)'),
            subtitle: const Text(
              'E4-18 — quick-edit commentary, add notes, key-moment highlight',
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const LiveMatchViewScreen(isScorer: true),
              ),
            ),
          ),
          ListTile(
            title: const Text('Expenses home'),
            subtitle: const Text(
              'E5-01/E5-05 — net header, I-owe/Owed/All tabs, age chips, '
              'reminders',
            ),
            onTap: () {
              final container = ProviderScope.containerOf(
                context,
                listen: false,
              );
              final notifier = container.read(expensesProvider.notifier);
              if (container.read(expensesProvider).expenses.isEmpty) {
                notifier.addExpense(
                  title: 'Ground fee',
                  category: ExpenseCategory.groundFees,
                  amount: 800,
                  paidBy: const [PaidByEntry(name: 'Kabir Singh', amount: 800)],
                  splitMethod: SplitMethod.equal,
                  splitAmong: equalSplit(800, mockExpenseParticipants()),
                  createdByName: 'Kabir Singh',
                  createdByIsCaptain: true,
                  // E5-05 demo: backdated so the age chip/reminder
                  // cadence shows the "firm" (>7d) stage on first view.
                  now: () => DateTime.now().subtract(const Duration(days: 8)),
                );
                notifier.addExpense(
                  title: 'Post-match chai',
                  category: ExpenseCategory.food,
                  amount: 200,
                  paidBy: const [PaidByEntry(name: 'Priya Nair', amount: 200)],
                  splitMethod: SplitMethod.equal,
                  splitAmong: equalSplit(200, mockExpenseParticipants()),
                  createdByName: 'Priya Nair',
                  createdByIsCaptain: false,
                );
                notifier.addExpense(
                  title: 'Tournament entry',
                  category: ExpenseCategory.tournamentEntry,
                  amount: 1500,
                  paidBy: const [
                    PaidByEntry(name: 'Kabir Singh', amount: 1500),
                  ],
                  splitMethod: SplitMethod.equal,
                  splitAmong: equalSplit(1500, mockExpenseParticipants()),
                  createdByName: 'Kabir Singh',
                  createdByIsCaptain: true,
                );
              }
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ExpensesHomeScreen(
                    viewerName: 'Kabir Singh',
                    viewerIsCaptain: true,
                  ),
                ),
              );
            },
          ),
          ListTile(
            title: const Text('Settle up (who-owes-whom)'),
            subtitle: const Text(
              'E5-04 — simplify suggestion, full/partial/custom, handshake',
            ),
            onTap: () {
              final container = ProviderScope.containerOf(
                context,
                listen: false,
              );
              final notifier = container.read(expensesProvider.notifier);
              if (container.read(expensesProvider).expenses.isEmpty) {
                notifier.addExpense(
                  title: 'Ground fee',
                  category: ExpenseCategory.groundFees,
                  amount: 800,
                  paidBy: const [PaidByEntry(name: 'Kabir Singh', amount: 800)],
                  splitMethod: SplitMethod.equal,
                  splitAmong: equalSplit(800, mockExpenseParticipants()),
                  createdByName: 'Kabir Singh',
                  createdByIsCaptain: true,
                );
                notifier.addExpense(
                  title: 'Tournament entry',
                  category: ExpenseCategory.tournamentEntry,
                  amount: 1500,
                  paidBy: const [
                    PaidByEntry(name: 'Kabir Singh', amount: 1500),
                  ],
                  splitMethod: SplitMethod.equal,
                  splitAmong: equalSplit(1500, mockExpenseParticipants()),
                  createdByName: 'Kabir Singh',
                  createdByIsCaptain: true,
                );
              }
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      const SettleUpScreen(viewerName: 'Kabir Singh'),
                ),
              );
            },
          ),
          ListTile(
            title: const Text('Expense detail (disputed)'),
            subtitle: const Text(
              'E5-06 — frozen banner, activity log, amend/uphold/escalate',
            ),
            onTap: () {
              final container = ProviderScope.containerOf(
                context,
                listen: false,
              );
              final notifier = container.read(expensesProvider.notifier);
              final id = notifier.addExpense(
                title: 'Ground fee',
                category: ExpenseCategory.groundFees,
                amount: 800,
                paidBy: const [PaidByEntry(name: 'Kabir Singh', amount: 800)],
                splitMethod: SplitMethod.equal,
                splitAmong: equalSplit(800, mockExpenseParticipants()),
                createdByName: 'Kabir Singh',
                createdByIsCaptain: true,
              );
              notifier.disputeExpense(
                id,
                'Priya Nair',
                "This wasn't the agreed ground fee amount",
              );
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ExpenseDetailScreen(
                    expenseId: id,
                    viewerName: 'Kabir Singh',
                    viewerIsCaptain: true,
                  ),
                ),
              );
            },
          ),
          ListTile(
            title: const Text('Treasury (team wallet)'),
            subtitle: const Text(
              'E5-07 — wallet balance, collections, dual-approval payout',
            ),
            onTap: () {
              final container = ProviderScope.containerOf(
                context,
                listen: false,
              );
              final expensesNotifier = container.read(
                expensesProvider.notifier,
              );
              expensesNotifier.addExpense(
                title: 'Ground fee',
                category: ExpenseCategory.groundFees,
                amount: 800,
                paidBy: const [
                  PaidByEntry(name: teamWalletPayerName, amount: 800),
                ],
                splitMethod: SplitMethod.equal,
                splitAmong: equalSplit(800, mockExpenseParticipants()),
                createdByName: 'Kabir Singh',
                createdByIsCaptain: true,
              );
              expensesNotifier.addExpense(
                title: 'Late-arrival fine',
                category: ExpenseCategory.penaltyFine,
                amount: 100,
                paidBy: const [
                  PaidByEntry(name: teamWalletPayerName, amount: 100),
                ],
                splitMethod: SplitMethod.custom,
                splitAmong: const [SplitShare(name: 'Sana Iyer', amount: 100)],
                createdByName: 'Kabir Singh',
                createdByIsCaptain: true,
              );
              container
                  .read(collectionsProvider.notifier)
                  .createCollection(
                    title: 'Season fund',
                    amountPerMember: 500,
                    memberNames: mockExpenseParticipants(),
                    deadline: DateTime.now().add(const Duration(days: 5)),
                  );
              container
                  .read(walletPayoutsProvider.notifier)
                  .requestPayout(
                    purpose: 'New training kit',
                    amount: 2500,
                    createdByName: 'Kabir Singh',
                  );
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const TreasuryScreen(
                    viewerName: 'Kabir Singh',
                    viewerIsManagerOrCaptain: true,
                  ),
                ),
              );
            },
          ),
          ListTile(
            title: const Text('Reports (donut/trend/insights/export)'),
            subtitle: const Text(
              'E5-08 — period segmented, category breakdown, CSV export',
            ),
            onTap: () {
              final container = ProviderScope.containerOf(
                context,
                listen: false,
              );
              final notifier = container.read(expensesProvider.notifier);
              if (container.read(expensesProvider).expenses.isEmpty) {
                notifier.addExpense(
                  title: 'Ground fee',
                  category: ExpenseCategory.groundFees,
                  amount: 800,
                  paidBy: const [PaidByEntry(name: 'Kabir Singh', amount: 800)],
                  splitMethod: SplitMethod.equal,
                  splitAmong: equalSplit(800, mockExpenseParticipants()),
                  createdByName: 'Kabir Singh',
                  createdByIsCaptain: true,
                );
                notifier.addExpense(
                  title: 'Post-match chai',
                  category: ExpenseCategory.food,
                  amount: 200,
                  paidBy: const [PaidByEntry(name: 'Priya Nair', amount: 200)],
                  splitMethod: SplitMethod.equal,
                  splitAmong: equalSplit(200, mockExpenseParticipants()),
                  createdByName: 'Priya Nair',
                  createdByIsCaptain: false,
                );
              }
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ReportsScreen(
                    viewerName: 'Kabir Singh',
                    viewerIsCaptain: true,
                  ),
                ),
              );
            },
          ),
          ListTile(
            title: const Text('Recurring expense series'),
            subtitle: const Text(
              'E5-09 (1/3) — ⟳ glyph, generate next instance, amend scope',
            ),
            onTap: () {
              final container = ProviderScope.containerOf(
                context,
                listen: false,
              );
              final seriesNotifier = container.read(
                recurringSeriesProvider.notifier,
              );
              final seriesId = seriesNotifier.createSeries(
                title: 'Monthly ground booking',
                category: ExpenseCategory.groundFees,
                amount: 800,
                splitMethod: SplitMethod.equal,
                splitAmong: equalSplit(800, mockExpenseParticipants()),
                cadence: RecurrenceCadence.monthly,
                startDate: DateTime.now(),
                createdByName: 'Kabir Singh',
                createdByIsCaptain: true,
              );
              seriesNotifier.generateNextInstance(seriesId);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ExpensesHomeScreen(
                    viewerName: 'Kabir Singh',
                    viewerIsCaptain: true,
                  ),
                ),
              );
            },
          ),
          ListTile(
            title: const Text('Recently deleted'),
            subtitle: const Text(
              'E5-09 (3/3) — 30-day list, deleted-by + countdown, restore',
            ),
            onTap: () {
              final container = ProviderScope.containerOf(
                context,
                listen: false,
              );
              final notifier = container.read(expensesProvider.notifier);
              final id = notifier.addExpense(
                title: 'Ball purchase',
                category: ExpenseCategory.ballPurchase,
                amount: 300,
                paidBy: const [PaidByEntry(name: 'Kabir Singh', amount: 300)],
                splitMethod: SplitMethod.equal,
                splitAmong: equalSplit(300, mockExpenseParticipants()),
                createdByName: 'Kabir Singh',
                createdByIsCaptain: true,
              );
              notifier.deleteExpense(id, 'Kabir Singh');
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const RecentlyDeletedScreen(),
                ),
              );
            },
          ),
          ListTile(
            title: const Text('Expense detail (multi-currency)'),
            subtitle: const Text(
              'E5-10 — currency per expense, home-currency conversion note',
            ),
            onTap: () {
              final container = ProviderScope.containerOf(
                context,
                listen: false,
              );
              final notifier = container.read(expensesProvider.notifier);
              final id = notifier.addExpense(
                title: 'Touring kit (overseas order)',
                category: ExpenseCategory.equipmentJersey,
                amount: 60,
                paidBy: const [PaidByEntry(name: 'Kabir Singh', amount: 60)],
                splitMethod: SplitMethod.equal,
                splitAmong: equalSplit(60, mockExpenseParticipants()),
                createdByName: 'Kabir Singh',
                createdByIsCaptain: true,
                currency: Currency.usd,
              );
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ExpenseDetailScreen(
                    expenseId: id,
                    viewerName: 'Kabir Singh',
                    viewerIsCaptain: true,
                  ),
                ),
              );
            },
          ),
          ListTile(
            title: const Text('Expense detail (comments)'),
            subtitle: const Text(
              'E5-11 — participant-only thread, @mentions, dispute-link',
            ),
            onTap: () {
              final container = ProviderScope.containerOf(
                context,
                listen: false,
              );
              final expensesNotifier = container.read(
                expensesProvider.notifier,
              );
              final id = expensesNotifier.addExpense(
                title: 'Ground fee',
                category: ExpenseCategory.groundFees,
                amount: 800,
                paidBy: const [PaidByEntry(name: 'Kabir Singh', amount: 800)],
                splitMethod: SplitMethod.equal,
                splitAmong: equalSplit(800, mockExpenseParticipants()),
                createdByName: 'Kabir Singh',
                createdByIsCaptain: true,
              );
              container
                  .read(expenseCommentsProvider.notifier)
                  .addComment(
                    expenseId: id,
                    authorName: 'Priya Nair',
                    text: '@Kabir Singh wasn\'t this ₹700 last time?',
                    participantNames: mockExpenseParticipants(),
                  );
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ExpenseDetailScreen(
                    expenseId: id,
                    viewerName: 'Kabir Singh',
                    viewerIsCaptain: true,
                  ),
                ),
              );
            },
          ),
          ListTile(
            title: const Text('Add expense'),
            subtitle: const Text(
              'E5-01 — category grid, split editor (6 methods), approval note',
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const AddEditExpenseScreen(
                  viewerName: 'Kabir Singh',
                  viewerIsCaptain: true,
                ),
              ),
            ),
          ),
          ListTile(
            title: const Text('Auto-split bundle (captain review)'),
            subtitle: const Text(
              'E5-03 — draft/finalize vs final squad, MVP-exempt, void-if-fake',
            ),
            onTap: () {
              final container = ProviderScope.containerOf(
                context,
                listen: false,
              );
              final matchesNotifier = container.read(matchesProvider.notifier);
              final id = matchesNotifier.submitMatch(
                draft: MatchDraft(
                  dateTime: DateTime.now().add(const Duration(days: 3)),
                  opponentTeamName: 'Central Warriors',
                  groundName: 'Riverside Ground',
                  scorerAssignment: ScorerAssignment.member,
                  scorerMemberName: 'Kabir Singh',
                ),
                composerTeamName: 'Riverside Strikers',
              );
              matchesNotifier.acceptMatch(id);
              matchesNotifier.respondAvailability(
                id,
                'Sana Iyer',
                AvailabilityResponse.no,
              );
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AutoSplitReviewScreen(
                    matchId: id,
                    viewerName: 'Kabir Singh',
                    viewerIsCaptain: true,
                  ),
                ),
              );
            },
          ),
          ListTile(
            title: const Text('Post-match summary'),
            subtitle: const Text(
              'E4-12 — result hero, MVP, XP/coins, expense, ratings, insights',
            ),
            onTap: () {
              final container = ProviderScope.containerOf(
                context,
                listen: false,
              );
              final notifier = container.read(inningsProvider.notifier);
              notifier.confirmScorecard(ConfirmerRole.composerCaptain);
              notifier.confirmScorecard(ConfirmerRole.opponentCaptain);
              notifier.confirmScorecard(ConfirmerRole.scorer);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const PostMatchSummaryScreen(
                    viewerPlayerName: 'Rohan Verma',
                  ),
                ),
              );
            },
          ),
          ListTile(
            title: const Text('Rewards summary (coin/XP engine)'),
            subtitle: const Text(
              'E6-01 — real coin/XP award on scorecard confirm, level-up ceremony',
            ),
            onTap: () {
              final container = ProviderScope.containerOf(
                context,
                listen: false,
              );
              final notifier = container.read(inningsProvider.notifier);
              notifier.confirmScorecard(ConfirmerRole.composerCaptain);
              notifier.confirmScorecard(ConfirmerRole.opponentCaptain);
              notifier.confirmScorecard(ConfirmerRole.scorer);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      const RewardsSummaryScreen(viewerName: 'Deepak Sharma'),
                ),
              );
            },
          ),
          ListTile(
            title: const Text('Streaks (login/playing)'),
            subtitle: const Text(
              'E6-02 — shield auto-apply, injury pause, playing streak milestones',
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const StreaksSummaryScreen()),
            ),
          ),
          ListTile(
            title: const Text('Missions board'),
            subtitle: const Text(
              'E6-03 — Daily/Weekly/Monthly/Epic tabs, claim states, Season Planner',
            ),
            onTap: () {
              final container = ProviderScope.containerOf(
                context,
                listen: false,
              );
              final notifier = container.read(missionsProvider.notifier);
              notifier.ensureCurrentPeriod();
              notifier.recordAction(MissionActionType.scoreRuns, amount: 30);
              notifier.recordAction(MissionActionType.takeWicket);
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MissionsBoardScreen()),
              );
            },
          ),
          ListTile(
            title: const Text('Badge engine'),
            subtitle: const Text(
              'E6-04 — Iron Player/Scorer Supreme/Ground Collector tiers, '
              'ceremonies, achievements wall',
            ),
            onTap: () {
              final container = ProviderScope.containerOf(
                context,
                listen: false,
              );
              container.read(achievementsProvider.notifier)
                ..recordDisputeFreeMatchScored()
                ..recordPlayingStreakWeeks(4);
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const BadgeEngineScreen()),
              );
            },
          ),
          ListTile(
            title: const Text('Wallet & Coins'),
            subtitle: const Text(
              'E6-05 — Expiring FIFO coin strip, Marketplace, redemption, '
              'My Rewards',
            ),
            onTap: () {
              final container = ProviderScope.containerOf(
                context,
                listen: false,
              );
              container
                  .read(rewardsProvider.notifier)
                  .awardBonus(500, label: 'Debug seed');
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const WalletScreen()));
            },
          ),
          ListTile(
            title: const Text('Luck Layer'),
            subtitle: const Text(
              'E6-06 — Scratch card, spin wheel, chest, odds page, lucky draw',
            ),
            onTap: () {
              final container = ProviderScope.containerOf(
                context,
                listen: false,
              );
              container
                  .read(rewardsProvider.notifier)
                  .awardBonus(600, label: 'Debug seed');
              container
                  .read(luckLayerProvider.notifier)
                  .grantScratchCard(label: 'Debug seed');
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LuckLayerScreen()),
              );
            },
          ),
          ListTile(
            title: const Text('Refer a friend'),
            subtitle: const Text(
              'E6-07 (1/2) — Code card, referee rows, terms',
            ),
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const ReferralScreen())),
          ),
          ListTile(
            title: const Text('CricUnity Pro'),
            subtitle: const Text(
              'E6-07 (2/2) — Paywall, integrity note, Family manager',
            ),
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const ProPaywallScreen())),
          ),
          ListTile(
            title: const Text('Feed'),
            subtitle: const Text(
              'E7-01 — Ranked/Latest toggle, why-am-I-seeing-this, '
              'attached-object cards, caught-up interstitial',
            ),
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const FeedScreen())),
          ),
          ListTile(
            title: const Text('Saved'),
            subtitle: const Text(
              'E7-08 — Bookmark posts into private collections, '
              'saved-from context',
            ),
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const SavedScreen())),
          ),
          ListTile(
            title: const Text('Fan engagement'),
            subtitle: const Text(
              'E7-09 — Predictions, fan leaderboards, superfan streaks',
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const FanEngagementScreen()),
            ),
          ),
          ListTile(
            title: const Text('Messenger'),
            subtitle: const Text(
              'E7-05 — Chat list, thread, requests, voice notes, object cards',
            ),
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const ChatListScreen())),
          ),
          ListTile(
            title: const Text('Groups'),
            subtitle: const Text(
              'E7-06 (1/2) — Privacy tiers, join questions, post approval',
            ),
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const GroupsListScreen())),
          ),
          ListTile(
            title: const Text('Events'),
            subtitle: const Text(
              'E7-06 (2/2) — RSVP, co-hosts, discussion, coin ticketing',
            ),
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const EventsListScreen())),
          ),
          ListTile(
            title: const Text('Privacy & Moderation'),
            subtitle: const Text(
              'E7-07 — Report reason tree, tracker, offender ladder, block',
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const ModerationSettingsScreen(),
              ),
            ),
          ),
          ListTile(
            title: const Text('Leaderboards hub'),
            subtitle: const Text(
              'E8-01 — Scope x metric x window, sticky self-row, '
              'qualification progress, age/experience filters',
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const LeaderboardHubScreen()),
            ),
          ),
          ListTile(
            title: const Text('Records hub'),
            subtitle: const Text(
              'E8-02 — Vacant "be first", provenance links, live '
              'approach alerts, record-transfer flow',
            ),
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const RecordsHubScreen())),
          ),
          ListTile(
            title: const Text('Challenges hub'),
            subtitle: const Text(
              'E8-03 — Global/club/friend H2H live bars, stakes cap 50, '
              'overtaken notifications',
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ChallengesHubScreen()),
            ),
          ),
          ListTile(
            title: const Text('Compare tool'),
            subtitle: const Text(
              'E8-04 (1/3) — Consent-gated side-by-side + radar stand-in',
            ),
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const CompareScreen())),
          ),
          ListTile(
            title: const Text('Grounds heatmap'),
            subtitle: const Text(
              'E8-04 (2/3) — Visited-grounds grid, my-city toggle, '
              'ground record card',
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const GroundsHeatmapScreen()),
            ),
          ),
          ListTile(
            title: const Text('Personal Bests'),
            subtitle: const Text(
              'E8-04 (3/3) — PB shelf, live PB-detection announcements',
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PersonalBestsScreen()),
            ),
          ),
          ListTile(
            title: const Text('Goals'),
            subtitle: const Text(
              'E8-05 — Pace ring + on/off-track chip, coach-proposed '
              'accept/decline',
            ),
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const GoalsScreen())),
          ),
          ListTile(
            title: const Text('Year in Review'),
            subtitle: const Text(
              'E8-06 — Swipeable story cards, per-card exclusion, share',
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const YearInReviewScreen()),
            ),
          ),
          ListTile(
            title: const Text('Ranks'),
            subtitle: const Text(
              'E6-08 — Percentile bands, 60-day soft decay, rank vs '
              'level explainer',
            ),
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const RanksScreen())),
          ),
          ListTile(
            title: const Text('Season rewards'),
            subtitle: const Text(
              'E6-09 — Bronze-to-Legend season-XP tiers, exclusive '
              'frames, rollover ceremony',
            ),
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const SeasonScreen())),
          ),
          ListTile(
            title: const Text('Periodic awards'),
            subtitle: const Text(
              'E8-07 — Auto-nominee computation, winner announcements, '
              'certificate cards',
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PeriodicAwardsScreen()),
            ),
          ),
          ListTile(
            title: const Text('Progress rings'),
            subtitle: const Text(
              'E8-08 — Weekly Play/Train/Contribute rings, ring-close '
              'streaks + burst',
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProgressRingsScreen()),
            ),
          ),
          ListTile(
            title: const Text('Notification center'),
            subtitle: const Text(
              'E12-04/05 — Tabs, rollups, channels, quiet hours, mute ladder, follow-ups',
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const NotificationCenterScreen(),
              ),
            ),
          ),
          ListTile(
            title: const Text('Global search'),
            subtitle: const Text(
              'E12-01 — Grouped results, typo-tolerant, zero-state',
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const GlobalSearchScreen()),
            ),
          ),
          ListTile(
            title: const Text('QR search / scanner'),
            subtitle: const Text(
              'E12-03 — Jump to object, reads booking check-in QRs',
            ),
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const QrScannerScreen())),
          ),
          ListTile(
            title: const Text('Club home + console'),
            subtitle: const Text(
              'E11-01 — Members/dues grid, tiers/grace, inter-team scheduler, wall of fame',
            ),
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const ClubHomeScreen())),
          ),
          ListTile(
            title: const Text('Academy console'),
            subtitle: const Text(
              'E11-02 — Batches, guardian-consent enrollment, fee ledgers, trials',
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AcademyConsoleScreen()),
            ),
          ),
          ListTile(
            title: const Text('Coach console + drill library'),
            subtitle: const Text(
              'E11-03 — Template sessions, rings, PB tracking, progress cards',
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CoachConsoleScreen()),
            ),
          ),
          ListTile(
            title: const Text('Compliance vault'),
            subtitle: const Text(
              'E11-04 — Cert/first-aid expiries, signed-status matrix',
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ComplianceVaultScreen()),
            ),
          ),
          ListTile(
            title: const Text('My training log'),
            subtitle: const Text(
              'E11-05 — Drill Library for all users, PBs, missions/badges',
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const PersonalTrainingLogScreen(),
              ),
            ),
          ),
          ListTile(
            title: const Text('Grounds discovery'),
            subtitle: const Text(
              'E9-01 — Search, facility/pitch filters, map-view fallback',
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const GroundsDiscoveryScreen()),
            ),
          ),
          ListTile(
            title: const Text('Book a slot (sample)'),
            subtitle: const Text(
              'E9-03 — Hold 15:00, policy ack, QR ticket, reschedule/cancel',
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    const BookingFlowScreen(groundId: 'ground-green-valley'),
              ),
            ),
          ),
          ListTile(
            title: const Text('Write a review (sample)'),
            subtitle: const Text(
              'E9-04 — Verified-booker gate, facet stars, single owner reply',
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    const ReviewComposerScreen(groundId: 'ground-green-valley'),
              ),
            ),
          ),
          ListTile(
            title: const Text('Create tournament (wizard)'),
            subtitle: const Text(
              'E10-01 — Identity/format/rules/money/registration/publish',
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const TournamentCreationWizardScreen(),
              ),
            ),
          ),
          ListTile(
            title: const Text('Fixtures generator + editor'),
            subtitle: const Text(
              'E10-03 — Constraints honored, drag-adjust conflicts, change-records',
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const FixturesEditorScreen()),
            ),
          ),
          ListTile(
            title: const Text('Brackets + seeding'),
            subtitle: const Text(
              'E10-05 — Auto-seed from standings, tappable slots, path to final',
            ),
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const BracketScreen())),
          ),
          ListTile(
            title: const Text('Auction room'),
            subtitle: const Text(
              'E10-06 — Lot/bidding/purse/spectator/reconnect',
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AuctionRoomScreen()),
            ),
          ),
          ListTile(
            title: const Text('Organizer console + wallet + payouts'),
            subtitle: const Text(
              'E10-07 — Transparency summary, payout confirm, Organizer-Score input',
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const OrganizerConsoleScreen()),
            ),
          ),
          ListTile(
            title: const Text('Stats hub + awards + records'),
            subtitle: const Text(
              'E10-08 — Orange/purple lists, awards minting, hall of champions',
            ),
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const StatsHubScreen())),
          ),
          ListTile(
            title: const Text('Sanction requests (organizer side)'),
            subtitle: const Text(
              'E10-09 — Request tracker, revocation with public reason',
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SanctionRequestScreen()),
            ),
          ),
          ListTile(
            title: const Text('Association profile (sample)'),
            subtitle: const Text(
              'E10-09 — Member clubs, sanctioned tournaments, rankings, circulars',
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const AssociationScreen(
                  associationId: 'assoc-city-cricket-board',
                ),
              ),
            ),
          ),
          ListTile(
            title: const Text('Points table + NRR + what-if'),
            subtitle: const Text(
              'E10-04 — Tap-formula NRR, adjusted badges, savable scenarios',
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PointsTableScreen()),
            ),
          ),
          ListTile(
            title: const Text('Tournament registration'),
            subtitle: const Text(
              'E10-02 — Squad/docs/escrow, duplicate-player block, waitlist',
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const TournamentRegistrationScreen(),
              ),
            ),
          ),
          ListTile(
            title: const Text('Caretaker check-in (sample)'),
            subtitle: const Text(
              'E9-06 — Single-purpose today\'s bookings: check-in / no-show',
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    const CaretakerModeScreen(groundId: 'ground-green-valley'),
              ),
            ),
          ),
          ListTile(
            title: const Text('Owner console (sample)'),
            subtitle: const Text(
              'E9-05 — Occupancy/revenue/nudges/payouts, maintenance blocks, staff',
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    const OwnerConsoleScreen(groundId: 'ground-green-valley'),
              ),
            ),
          ),
          ListTile(
            title: const Text('Ground profile (sample)'),
            subtitle: const Text(
              'E9-02 — Facilities/pitch/boundary/records shelf/par-score, follow',
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    const GroundProfileScreen(groundId: 'ground-green-valley'),
              ),
            ),
          ),
          ListTile(
            title: const Text('Field map tool (captain)'),
            subtitle: const Text(
              'E4-09 — drag 11 fielder tokens, phase presets, team-private',
            ),
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const FieldMapScreen())),
          ),
          ListTile(
            title: const Text('Scorecard (as scorer)'),
            subtitle: const Text(
              'E4-10 — batting/bowling accordions, FoW ladder, confirm/dispute',
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    const ScorecardScreen(viewerRole: ConfirmerRole.scorer),
              ),
            ),
          ),
          ListTile(
            title: const Text('Scorecard (spectator)'),
            subtitle: const Text('E4-10 — read-only confirmation panel'),
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const ScorecardScreen())),
          ),
          ListTile(
            title: const Text('Awards (opposing captain)'),
            subtitle: const Text(
              'E4-13 — MVP pick, Best Batter/Bowler/Fielder, mint awards',
            ),
            onTap: () {
              final container = ProviderScope.containerOf(
                context,
                listen: false,
              );
              final notifier = container.read(inningsProvider.notifier);
              notifier.confirmScorecard(ConfirmerRole.composerCaptain);
              notifier.confirmScorecard(ConfirmerRole.opponentCaptain);
              notifier.confirmScorecard(ConfirmerRole.scorer);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const AwardsScreen(isOpposingCaptain: true),
                ),
              );
            },
          ),
          ListTile(
            title: const Text('Awards (spectator)'),
            subtitle: const Text('E4-13 — read-only awards view'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const AwardsScreen(isOpposingCaptain: false),
              ),
            ),
          ),
          ListTile(
            title: const Text('Gallery (squad member)'),
            subtitle: const Text(
              'E4-14 — upload, pin-to-ball, no captain curate actions',
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const GalleryScreen(
                  viewerName: 'Ananya Iyer',
                  isCaptain: false,
                ),
              ),
            ),
          ),
          ListTile(
            title: const Text('Gallery (captain)'),
            subtitle: const Text(
              'E4-14 — feature/hide items, open Highlights builder',
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const GalleryScreen(
                  viewerName: 'Rohan Verma',
                  isCaptain: true,
                ),
              ),
            ),
          ),
          ListTile(
            title: const Text('Highlights builder (captain)'),
            subtitle: const Text(
              'E4-14 — clip rail, drag-reorder, auto-cut chips, publish reel',
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const HighlightsBuilderScreen(isCaptain: true),
              ),
            ),
          ),
          ListTile(
            title: const Text('AI insights (player)'),
            subtitle: const Text(
              'E4-15 — team + own-notes cards, no minors section',
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const InsightsScreen(
                  viewerPlayerName: 'Rohan Verma',
                  viewerRole: InsightViewerRole.player,
                ),
              ),
            ),
          ),
          ListTile(
            title: const Text('AI insights (coach/guardian)'),
            subtitle: const Text(
              'E4-15 — adds minor players\' notes (PRD §7.19 exception)',
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const InsightsScreen(
                  viewerPlayerName: 'Deepak Sharma',
                  viewerRole: InsightViewerRole.coach,
                ),
              ),
            ),
          ),
          ListTile(
            title: const Text('Guest mode preview'),
            subtitle: const Text(
              'E1-04 — guest chip, blocked-action sheet, private-link lock',
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => GuestLiveMatchPreviewScreen(
                  onContinueWithPhone: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          ),
          ListTile(
            title: const Text('Nearby matches (QA preview)'),
            subtitle: const Text(
              'E1-03 AC — location denial shows the enable-prompt state',
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const NearbyMatchesPreviewScreen(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
