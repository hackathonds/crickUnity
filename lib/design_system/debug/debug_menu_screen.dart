import 'package:flutter/material.dart';

import '../../guest/guest_live_match_preview_screen.dart';
import '../../onboarding/onboarding_flow.dart';
import '../../profile/edit_profile_screen.dart';
import 'avatar_screen.dart';
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
