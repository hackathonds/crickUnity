import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_button.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'bracket_models.dart';
import 'bracket_provider.dart';
import 'fixtures_provider.dart';
import 'registration_models.dart';
import 'registrations_provider.dart';
import 'standings_provider.dart';
import 'tournament_models.dart';
import 'tournaments_provider.dart';

/// PRD §8.5-8.6: "Group standings roll into knockout seeding
/// automatically per rules; bracket view with tappable slots; 'path to
/// final' view for each team." See bracket_models.dart's top-of-file
/// note for the single-group simplification.
class BracketScreen extends ConsumerStatefulWidget {
  const BracketScreen({super.key});

  @override
  ConsumerState<BracketScreen> createState() => _BracketScreenState();
}

class _BracketScreenState extends ConsumerState<BracketScreen> {
  String? _selectedTournamentId;
  String? _pathToFinalTeamId;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final published = ref
        .watch(tournamentsProvider)
        .tournaments
        .where((t) => t.status == TournamentStatus.published)
        .toList();
    final registrationsState = ref.watch(registrationsProvider);
    final bracketState = ref.watch(bracketProvider);
    final bracketNotifier = ref.read(bracketProvider.notifier);
    final standingsNotifier = ref.read(standingsProvider.notifier);
    final fixturesState = ref.watch(fixturesProvider);
    final standingsState = ref.watch(standingsProvider);

    if (_selectedTournamentId == null && published.isNotEmpty) {
      _selectedTournamentId = published.first.id;
    }
    final tournament = published
        .where((t) => t.id == _selectedTournamentId)
        .firstOrNull;

    if (tournament == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Brackets')),
        body: Center(
          child: Text(
            'No published tournaments yet -- publish one first (E10-01).',
            textAlign: TextAlign.center,
            style: AppTypography.body.copyWith(color: colors.textSecondary),
          ),
        ),
      );
    }

    final approvedTeams = registrationsState
        .forTournament(tournament.id)
        .where((r) => r.status == RegistrationStatus.approved)
        .toList();
    final matches = bracketState.forTournament(tournament.id);
    final numRounds = matches.isEmpty
        ? 0
        : matches.map((m) => m.round).reduce((a, b) => a > b ? a : b) + 1;

    return Scaffold(
      appBar: AppBar(title: Text('Bracket · ${tournament.name}')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              for (final t in published)
                ChoiceChip(
                  key: ValueKey('bracketTournamentChip_${t.id}'),
                  label: Text(t.name.isEmpty ? '(unnamed)' : t.name),
                  selected: _selectedTournamentId == t.id,
                  onSelected: (_) =>
                      setState(() => _selectedTournamentId = t.id),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          if (tournament.format == TournamentFormat.league)
            Text(
              'League format has no bracket -- see the Points Table (E10-04).',
              style: AppTypography.body.copyWith(color: colors.textSecondary),
            )
          else ...[
            AppButton(
              key: const ValueKey('generateBracketButton'),
              variant: AppButtonVariant.primary,
              label: 'Generate bracket from seeding',
              fullWidth: true,
              onPressed: approvedTeams.length < 2
                  ? null
                  : () {
                      final seeded =
                          tournament.format ==
                              TournamentFormat.groupsPlusKnockout
                          ? standingsNotifier
                                .computeStandings(
                                  tournament,
                                  approvedTeams,
                                  fixturesState.forTournament(tournament.id),
                                  standingsState.resultsFor(tournament.id),
                                )
                                .map(
                                  (row) => (row.registrationId, row.teamName),
                                )
                                .toList()
                          : [for (final t in approvedTeams) (t.id, t.teamName)];
                      bracketNotifier.generateBracket(tournament.id, seeded);
                    },
            ),
            if (tournament.format == TournamentFormat.groupsPlusKnockout)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Text(
                  'Seeded from current group standings (single group -- '
                  'no separate multi-group split exists yet).',
                  style: AppTypography.caption.copyWith(
                    color: colors.textTertiary,
                  ),
                ),
              ),
            const SizedBox(height: AppSpacing.xl),
            for (var round = 0; round < numRounds; round++)
              _RoundColumn(
                round: round,
                isFinal: round == numRounds - 1,
                matches: matches.where((m) => m.round == round).toList()
                  ..sort((a, b) => a.slotIndex.compareTo(b.slotIndex)),
                colors: colors,
                onTapMatch: (match) =>
                    _showWinnerPicker(context, ref, tournament.id, match),
              ),
            if (matches.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xl),
              Text('Path to final', style: AppTypography.h2),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                children: [
                  for (final team in approvedTeams)
                    ChoiceChip(
                      key: ValueKey('pathToFinalChip_${team.id}'),
                      label: Text(team.teamName),
                      selected: _pathToFinalTeamId == team.id,
                      onSelected: (_) =>
                          setState(() => _pathToFinalTeamId = team.id),
                    ),
                ],
              ),
              if (_pathToFinalTeamId != null) ...[
                const SizedBox(height: AppSpacing.sm),
                for (final match in bracketNotifier.pathToFinal(
                  tournament.id,
                  _pathToFinalTeamId!,
                ))
                  Text(
                    'Round ${match.round + 1}: ${match.teamAName ?? 'TBD'} vs ${match.teamBName ?? 'TBD'}'
                    '${match.winnerId == null ? '' : ' -- winner: ${match.winnerId == match.teamAId ? match.teamAName : match.teamBName}'}',
                    style: AppTypography.body.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
              ],
            ],
          ],
        ],
      ),
    );
  }

  void _showWinnerPicker(
    BuildContext context,
    WidgetRef ref,
    String tournamentId,
    BracketMatch match,
  ) {
    if (!match.isPlayable) return;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Record winner'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              key: ValueKey('bracketWinnerOptionA_${match.id}'),
              title: Text(match.teamAName!),
              onTap: () {
                ref
                    .read(bracketProvider.notifier)
                    .recordWinner(
                      tournamentId,
                      match.id,
                      match.teamAId!,
                      match.teamAName!,
                    );
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              key: ValueKey('bracketWinnerOptionB_${match.id}'),
              title: Text(match.teamBName!),
              onTap: () {
                ref
                    .read(bracketProvider.notifier)
                    .recordWinner(
                      tournamentId,
                      match.id,
                      match.teamBId!,
                      match.teamBName!,
                    );
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundColumn extends StatelessWidget {
  final int round;
  final bool isFinal;
  final List<BracketMatch> matches;
  final AppColors colors;
  final ValueChanged<BracketMatch> onTapMatch;

  const _RoundColumn({
    required this.round,
    required this.isFinal,
    required this.matches,
    required this.colors,
    required this.onTapMatch,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isFinal ? 'Final' : 'Round ${round + 1}',
            style: AppTypography.label.copyWith(color: colors.textTertiary),
          ),
          const SizedBox(height: AppSpacing.xs),
          for (final match in matches)
            GestureDetector(
              key: ValueKey('bracketMatchSlot_${match.id}'),
              onTap: () => onTapMatch(match),
              child: Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: colors.surfaceAlt,
                  borderRadius: BorderRadius.circular(14),
                  border: match.isPlayable
                      ? Border.all(color: colors.primary)
                      : null,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _TeamLine(
                      name: match.teamAName,
                      isWinner:
                          match.winnerId != null &&
                          match.winnerId == match.teamAId,
                      colors: colors,
                    ),
                    _TeamLine(
                      name: match.teamBName,
                      isWinner:
                          match.winnerId != null &&
                          match.winnerId == match.teamBId,
                      colors: colors,
                    ),
                    if (match.isBye)
                      Text(
                        'Bye',
                        style: AppTypography.caption.copyWith(
                          color: colors.textTertiary,
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TeamLine extends StatelessWidget {
  final String? name;
  final bool isWinner;
  final AppColors colors;

  const _TeamLine({
    required this.name,
    required this.isWinner,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      name ?? 'TBD',
      style: AppTypography.body.copyWith(
        color: name == null ? colors.textTertiary : colors.textPrimary,
        fontWeight: isWinner ? FontWeight.w700 : FontWeight.w400,
      ),
    );
  }
}
