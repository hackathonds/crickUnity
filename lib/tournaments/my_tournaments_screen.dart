import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_match_card.dart';
import '../design_system/components/app_state_scaffolds.dart';
import '../design_system/tokens/app_spacing.dart';
import 'bracket_screen.dart';
import 'fixtures_editor_screen.dart';
import 'points_table_screen.dart';
import 'registrations_provider.dart';
import 'tournament_models.dart';
import 'tournament_registration_screen.dart';
import 'tournaments_provider.dart';

/// The demo "self" team every tournament-registration flow in this app
/// registers on behalf of (same convention as `my_matches_screen.dart`'s
/// `_composerTeamName`).
const _composerTeamName = 'Lions CC';

/// Neither DS's numbered screen list (1-69) nor the backlog describe a
/// dedicated "My Tournaments" screen -- only "Discover Tournaments" (a
/// browse/filter screen, never built) and "Tournament Home" (per-
/// tournament, not "mine") exist as named destinations. This aggregates
/// the tournaments `_composerTeamName` is actually registered in (via
/// [TeamRegistration]) into cards, reusing [AppTournamentCard] (DS
/// §3.2.4) exactly as My Matches/My Teams reuse their own DS-specified
/// cards -- the list itself is a judgment call, not the card design.
///
/// Fixtures/points table/bracket are each a single global screen in this
/// codebase (picked via an internal dropdown, not a `tournamentId`
/// parameter) -- tapping a card offers all three via the same long-press
/// menu mechanic [AppCard] already provides, rather than guessing which
/// one the viewer wants.
class MyTournamentsScreen extends ConsumerWidget {
  const MyTournamentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final registrations = ref
        .watch(registrationsProvider)
        .registrations
        .where((r) => r.teamName == _composerTeamName)
        .toList();
    final tournamentsState = ref.watch(tournamentsProvider);
    final myTournaments = <Tournament>[
      for (final r in registrations)
        if (tournamentsState.tournamentById(r.tournamentId) != null)
          tournamentsState.tournamentById(r.tournamentId)!,
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('My Tournaments')),
      body: myTournaments.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: AppEmptyState(
                key: const ValueKey('myTournamentsEmptyState'),
                message: "You haven't registered for any tournaments yet.",
                primaryLabel: 'Register a team',
                onPrimary: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const TournamentRegistrationScreen(),
                  ),
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                for (final tournament in myTournaments)
                  Padding(
                    key: ValueKey('myTournamentCard_${tournament.id}'),
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: _TournamentCard(tournament: tournament),
                  ),
              ],
            ),
    );
  }
}

class _TournamentCard extends StatelessWidget {
  final Tournament tournament;

  const _TournamentCard({required this.tournament});

  @override
  Widget build(BuildContext context) {
    return AppTournamentCard(
      name: tournament.name.isEmpty ? 'Untitled tournament' : tournament.name,
      teamsCountDatesEntryFeeLine:
          '${tournament.teamCap} teams · '
          '${tournamentFormatLabels[tournament.format]} · '
          '₹${tournament.entryFee} entry',
      registrationCloses: tournament.registrationDeadline,
      onTap: () => _openMenu(context),
    );
  }

  void _openMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.event_note_outlined),
              title: const Text('Fixtures'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const FixturesEditorScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.leaderboard_outlined),
              title: const Text('Points table'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PointsTableScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.emoji_events_outlined),
              title: const Text('Bracket'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const BracketScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
