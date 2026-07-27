import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_button.dart';
import '../design_system/components/app_tag_chip.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'stats_models.dart';
import 'stats_provider.dart';
import 'tournament_models.dart';
import 'tournaments_provider.dart';

/// PRD §8.10-8.12 (stat hub/awards/leaderboards) + §8.16 (history/
/// records). See stats_models.dart's top-of-file note for the exact
/// quotes and the flagged per-fixture stat-entry simplification.
class StatsHubScreen extends ConsumerStatefulWidget {
  const StatsHubScreen({super.key});

  @override
  ConsumerState<StatsHubScreen> createState() => _StatsHubScreenState();
}

class _StatsHubScreenState extends ConsumerState<StatsHubScreen> {
  String? _selectedTournamentId;
  final _playerNameController = TextEditingController();
  final _teamNameController = TextEditingController();
  final _runsController = TextEditingController();
  final _ballsController = TextEditingController();
  final _wicketsController = TextEditingController();
  final _runsConcededController = TextEditingController();
  final _oversController = TextEditingController();
  final _championController = TextEditingController();

  @override
  void dispose() {
    _playerNameController.dispose();
    _teamNameController.dispose();
    _runsController.dispose();
    _ballsController.dispose();
    _wicketsController.dispose();
    _runsConcededController.dispose();
    _oversController.dispose();
    _championController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final published = ref
        .watch(tournamentsProvider)
        .tournaments
        .where((t) => t.status == TournamentStatus.published)
        .toList();
    final statsState = ref.watch(statsProvider);
    final statsNotifier = ref.read(statsProvider.notifier);

    if (_selectedTournamentId == null && published.isNotEmpty) {
      _selectedTournamentId = published.first.id;
    }
    final tournament = published
        .where((t) => t.id == _selectedTournamentId)
        .firstOrNull;

    if (tournament == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Stats hub')),
        body: Center(
          child: Text(
            'No published tournaments yet -- publish one first (E10-01).',
            textAlign: TextAlign.center,
            style: AppTypography.body.copyWith(color: colors.textSecondary),
          ),
        ),
      );
    }

    final qualification = statsState.qualificationFor(tournament.id);
    final record = statsNotifier.highestTeamTotalRecord(tournament.id);

    return Scaffold(
      appBar: AppBar(title: Text('Stats hub · ${tournament.name}')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              for (final t in published)
                ChoiceChip(
                  key: ValueKey('statsTournamentChip_${t.id}'),
                  label: Text(t.name.isEmpty ? '(unnamed)' : t.name),
                  selected: _selectedTournamentId == t.id,
                  onSelected: (_) =>
                      setState(() => _selectedTournamentId = t.id),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Record a player performance', style: AppTypography.h2),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _playerNameController,
                  decoration: const InputDecoration(labelText: 'Player'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: TextField(
                  controller: _teamNameController,
                  decoration: const InputDecoration(labelText: 'Team'),
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _runsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Runs'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: TextField(
                  controller: _ballsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Balls faced'),
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _wicketsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Wickets'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: TextField(
                  controller: _runsConcededController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Runs conceded'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: TextField(
                  controller: _oversController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Overs bowled'),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            key: const ValueKey('recordPlayerStatButton'),
            variant: AppButtonVariant.secondary,
            label: 'Add / update stat line',
            fullWidth: true,
            onPressed: _playerNameController.text.trim().isEmpty
                ? null
                : () {
                    statsNotifier.recordPlayerStat(
                      tournament.id,
                      _playerNameController.text.trim(),
                      _teamNameController.text.trim(),
                      runs: int.tryParse(_runsController.text) ?? 0,
                      ballsFaced: int.tryParse(_ballsController.text) ?? 0,
                      wickets: int.tryParse(_wicketsController.text) ?? 0,
                      runsConceded:
                          int.tryParse(_runsConcededController.text) ?? 0,
                      oversBowled: double.tryParse(_oversController.text) ?? 0,
                    );
                    for (final c in [
                      _playerNameController,
                      _teamNameController,
                      _runsController,
                      _ballsController,
                      _wicketsController,
                      _runsConcededController,
                      _oversController,
                    ]) {
                      c.clear();
                    }
                    setState(() {});
                  },
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Qualifications',
            style: AppTypography.label.copyWith(color: colors.textTertiary),
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    labelText:
                        'Min balls for SR (${qualification.minBallsFacedForStrikeRate})',
                  ),
                  keyboardType: TextInputType.number,
                  onSubmitted: (v) => statsNotifier.setQualification(
                    tournament.id,
                    minBallsFacedForStrikeRate: int.tryParse(v),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    labelText:
                        'Min overs for Econ (${qualification.minOversBowledForEconomy})',
                  ),
                  keyboardType: TextInputType.number,
                  onSubmitted: (v) => statsNotifier.setQualification(
                    tournament.id,
                    minOversBowledForEconomy: int.tryParse(v),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          _StatList(
            title: 'Orange list -- most runs',
            rows: statsState
                .orangeList(tournament.id)
                .map((s) => '${s.playerName} (${s.teamName}) -- ${s.runs}')
                .toList(),
            colors: colors,
          ),
          _StatList(
            title: 'Purple list -- most wickets',
            rows: statsState
                .purpleList(tournament.id)
                .map((s) => '${s.playerName} (${s.teamName}) -- ${s.wickets}')
                .toList(),
            colors: colors,
          ),
          _StatList(
            title: 'Best strike rate',
            rows: statsState
                .bestStrikeRateList(tournament.id)
                .map(
                  (s) =>
                      '${s.playerName} -- ${s.strikeRate.toStringAsFixed(1)}',
                )
                .toList(),
            colors: colors,
          ),
          _StatList(
            title: 'Best economy',
            rows: statsState
                .bestEconomyList(tournament.id)
                .map(
                  (s) => '${s.playerName} -- ${s.economy.toStringAsFixed(2)}',
                )
                .toList(),
            colors: colors,
          ),
          _StatList(
            title: 'Best figures',
            rows: statsState
                .bestFiguresList(tournament.id)
                .map((s) => '${s.playerName} -- ${s.wickets}/${s.runsConceded}')
                .toList(),
            colors: colors,
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Awards', style: AppTypography.h2),
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            key: const ValueKey('generateNomineesButton'),
            variant: AppButtonVariant.secondary,
            label: 'Generate nominees',
            fullWidth: true,
            onPressed: () => statsNotifier.generateNominees(tournament.id),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final award in statsState.awardsFor(tournament.id))
            _AwardRow(
              key: ValueKey('awardRow_${award.id}'),
              tournamentId: tournament.id,
              award: award,
              colors: colors,
            ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Evergreen records & hall of champions',
            style: AppTypography.h2,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            record == null
                ? 'No confirmed results yet -- record a match result (Points Table, E10-04) to set the first evergreen record.'
                : 'Highest total in ${tournament.name} history: ${record.$1} -- ${record.$2}',
            style: AppTypography.body.copyWith(color: colors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final entry in statsState.championHistoryFor(tournament.id))
            Text(
              entry,
              style: AppTypography.body.copyWith(color: colors.textSecondary),
            ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _championController,
                  decoration: const InputDecoration(
                    hintText: 'e.g. "2024: Strikers CC"',
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  if (_championController.text.trim().isEmpty) return;
                  statsNotifier.logChampion(
                    tournament.id,
                    _championController.text.trim(),
                  );
                  _championController.clear();
                  setState(() {});
                },
                child: const Text('Log champion'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatList extends StatelessWidget {
  final String title;
  final List<String> rows;
  final AppColors colors;

  const _StatList({
    required this.title,
    required this.rows,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.label.copyWith(color: colors.textTertiary),
          ),
          const SizedBox(height: AppSpacing.xs),
          if (rows.isEmpty)
            Text(
              'No qualifying players yet.',
              style: AppTypography.caption.copyWith(color: colors.textTertiary),
            )
          else
            for (var i = 0; i < rows.length; i++)
              Text(
                '${i + 1}. ${rows[i]}',
                style: AppTypography.body.copyWith(color: colors.textPrimary),
              ),
        ],
      ),
    );
  }
}

class _AwardRow extends ConsumerWidget {
  final String tournamentId;
  final TournamentAward award;
  final AppColors colors;

  const _AwardRow({
    super.key,
    required this.tournamentId,
    required this.award,
    required this.colors,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  awardCategoryLabels[award.category]!,
                  style: AppTypography.label.copyWith(
                    color: colors.textTertiary,
                  ),
                ),
                Text(
                  award.nomineeName,
                  style: AppTypography.body.copyWith(color: colors.textPrimary),
                ),
              ],
            ),
          ),
          if (award.confirmed)
            AppTagChip(label: 'Confirmed', variant: AppTagChipVariant.success)
          else
            TextButton(
              key: ValueKey('confirmAwardButton_${award.id}'),
              onPressed: () => ref
                  .read(statsProvider.notifier)
                  .confirmAward(tournamentId, award.id),
              child: const Text('Confirm winner'),
            ),
        ],
      ),
    );
  }
}
