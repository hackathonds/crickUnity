import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../guest/guest_live_match_preview_screen.dart';
import '../../matches/create_match_flow.dart';
import '../../matches/match_detail_screen.dart';
import '../../matches/match_models.dart';
import '../../matches/match_opponent_decision_screen.dart';
import '../../matches/match_proposal_review_screen.dart';
import '../../matches/live_scoring_console_screen.dart';
import '../../matches/scoring_provider.dart';
import '../../matches/matches_provider.dart';
import '../../matches/toss_screen.dart';
import '../../onboarding/onboarding_flow.dart';
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
