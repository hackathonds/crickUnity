import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_button.dart';
import '../design_system/components/app_stepper.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'fixture_models.dart';
import 'fixtures_provider.dart';
import 'registration_models.dart';
import 'registrations_provider.dart';
import 'standings_models.dart';
import 'standings_provider.dart';
import 'tournament_models.dart';
import 'tournaments_provider.dart';

/// PRD §8.4: "Points table live-updates on match confirmation; NRR
/// computed & tappable to see formula inputs; manual adjustments
/// (penalties/walkovers) badge-marked with public reason." Backlog
/// (what-if calculator, "G.3" -- phantom, flagged in
/// standings_models.dart): slider scenarios savable.
class PointsTableScreen extends ConsumerStatefulWidget {
  const PointsTableScreen({super.key});

  @override
  ConsumerState<PointsTableScreen> createState() => _PointsTableScreenState();
}

class _PointsTableScreenState extends ConsumerState<PointsTableScreen> {
  String? _selectedTournamentId;
  String? _whatIfFixtureId;
  String? _whatIfWinnerRegId;
  int _whatIfMargin = 20;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final published = ref
        .watch(tournamentsProvider)
        .tournaments
        .where((t) => t.status == TournamentStatus.published)
        .toList();
    final fixturesState = ref.watch(fixturesProvider);
    final registrationsState = ref.watch(registrationsProvider);
    final standingsState = ref.watch(standingsProvider);
    final standingsNotifier = ref.read(standingsProvider.notifier);

    if (_selectedTournamentId == null && published.isNotEmpty) {
      _selectedTournamentId = published.first.id;
    }
    final tournament = published
        .where((t) => t.id == _selectedTournamentId)
        .firstOrNull;

    if (tournament == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Points table')),
        body: Center(
          child: Text(
            'No published tournaments yet -- publish one first (E10-01).',
            textAlign: TextAlign.center,
            style: AppTypography.body.copyWith(color: colors.textSecondary),
          ),
        ),
      );
    }

    // computeStandings needs withdrawn teams too, to apply PRD §8 edge
    // cases' withdrawal rule (their rows still exist so opponents'
    // past results can be credited correctly under "results stand").
    final standingsTeams = registrationsState
        .forTournament(tournament.id)
        .where(
          (r) =>
              r.status == RegistrationStatus.approved ||
              r.status == RegistrationStatus.withdrawn,
        )
        .toList();
    final fixtures = fixturesState.forTournament(tournament.id);
    final results = standingsState.resultsFor(tournament.id);
    final playedFixtureIds = results.map((r) => r.fixtureId).toSet();
    final unplayed = fixtures
        .where((f) => !playedFixtureIds.contains(f.id) && f.isScheduled)
        .toList();

    final standings = standingsNotifier.computeStandings(
      tournament,
      standingsTeams,
      fixtures,
      results,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Points table')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              for (final t in published)
                ChoiceChip(
                  key: ValueKey('standingsTournamentChip_${t.id}'),
                  label: Text(t.name.isEmpty ? '(unnamed)' : t.name),
                  selected: _selectedTournamentId == t.id,
                  onSelected: (_) =>
                      setState(() => _selectedTournamentId = t.id),
                ),
            ],
          ),
          if (tournament.isOrganizerInactive(DateTime.now())) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              key: const ValueKey('organizerInactiveBanner'),
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: colors.error.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      // PRD §8 edge cases: "Organizer abandonment
                      // (inactive 14d mid-event) -> Admin intervention
                      // path visible to captains." No real Admin
                      // console/escalation queue exists yet (flagged,
                      // same convention as other missing-infra gaps).
                      'Organizer has been inactive 14+ days -- escalation to Admin is available.',
                      style: AppTypography.caption.copyWith(
                        color: colors.error,
                      ),
                    ),
                  ),
                  TextButton(
                    key: const ValueKey('escalateToAdminButton'),
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Escalated to Admin (no Admin console exists yet).',
                        ),
                      ),
                    ),
                    child: const Text('Escalate'),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          _StandingsTable(rows: standings, colors: colors),
          const SizedBox(height: AppSpacing.xl),
          Text('Record a result', style: AppTypography.h2),
          const SizedBox(height: AppSpacing.sm),
          for (final fixture in unplayed)
            _RecordResultRow(
              key: ValueKey('recordResultRow_${fixture.id}'),
              tournamentId: tournament.id,
              fixture: fixture,
              colors: colors,
            ),
          if (unplayed.isEmpty)
            Text(
              'All scheduled fixtures have results.',
              style: AppTypography.body.copyWith(color: colors.textSecondary),
            ),
          const SizedBox(height: AppSpacing.xl),
          Text('Recorded results', style: AppTypography.h2),
          const SizedBox(height: AppSpacing.sm),
          for (final fixture in fixtures.where(
            (f) => playedFixtureIds.contains(f.id),
          ))
            Builder(
              builder: (context) {
                final result = results.firstWhere(
                  (r) => r.fixtureId == fixture.id,
                );
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (result.committeeRulingReason != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                          child: Text(
                            'Committee ruling (public): ${result.committeeRulingReason}',
                            style: AppTypography.caption.copyWith(
                              color: colors.warning,
                            ),
                          ),
                        ),
                      _RecordResultRow(
                        key: ValueKey('changeResultRow_${fixture.id}'),
                        tournamentId: tournament.id,
                        fixture: fixture,
                        colors: colors,
                        isChange: true,
                      ),
                    ],
                  ),
                );
              },
            ),
          const SizedBox(height: AppSpacing.xl),
          Text('What-if calculator', style: AppTypography.h2),
          const SizedBox(height: AppSpacing.sm),
          if (unplayed.isEmpty)
            Text(
              'No unplayed fixtures to project.',
              style: AppTypography.body.copyWith(color: colors.textSecondary),
            )
          else ...[
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                for (final fixture in unplayed)
                  ChoiceChip(
                    key: ValueKey('whatIfFixtureChip_${fixture.id}'),
                    label: Text(
                      '${fixture.homeTeamName} vs ${fixture.awayTeamName}',
                    ),
                    selected: _whatIfFixtureId == fixture.id,
                    onSelected: (_) => setState(() {
                      _whatIfFixtureId = fixture.id;
                      _whatIfWinnerRegId = fixture.homeRegistrationId;
                    }),
                  ),
              ],
            ),
            if (_whatIfFixtureId != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Builder(
                builder: (context) {
                  final fixture = unplayed.firstWhere(
                    (f) => f.id == _whatIfFixtureId,
                  );
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: AppSpacing.sm,
                        children: [
                          ChoiceChip(
                            label: Text('${fixture.homeTeamName} wins'),
                            selected:
                                _whatIfWinnerRegId ==
                                fixture.homeRegistrationId,
                            onSelected: (_) => setState(
                              () => _whatIfWinnerRegId =
                                  fixture.homeRegistrationId,
                            ),
                          ),
                          ChoiceChip(
                            label: Text('${fixture.awayTeamName} wins'),
                            selected:
                                _whatIfWinnerRegId ==
                                fixture.awayRegistrationId,
                            onSelected: (_) => setState(
                              () => _whatIfWinnerRegId =
                                  fixture.awayRegistrationId,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Margin (runs)',
                              style: AppTypography.body,
                            ),
                          ),
                          AppStepper(
                            value: _whatIfMargin,
                            min: 1,
                            max: 200,
                            semanticLabel: 'What-if margin',
                            onChanged: (v) => setState(() => _whatIfMargin = v),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Projected table',
                        style: AppTypography.label.copyWith(
                          color: colors.textTertiary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      _StandingsTable(
                        rows: standingsNotifier.computeStandings(
                          tournament,
                          standingsTeams,
                          fixtures,
                          results,
                          extraResult: MatchResult(
                            fixtureId: fixture.id,
                            homeRuns:
                                _whatIfWinnerRegId == fixture.homeRegistrationId
                                ? 150 + _whatIfMargin
                                : 150,
                            homeOvers: 20,
                            awayRuns:
                                _whatIfWinnerRegId == fixture.awayRegistrationId
                                ? 150 + _whatIfMargin
                                : 150,
                            awayOvers: 20,
                            winnerRegistrationId: _whatIfWinnerRegId,
                          ),
                        ),
                        colors: colors,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      AppButton(
                        key: const ValueKey('saveWhatIfScenarioButton'),
                        variant: AppButtonVariant.secondary,
                        label: 'Save scenario',
                        fullWidth: true,
                        onPressed: () {
                          standingsNotifier.addScenario(
                            tournament.id,
                            WhatIfScenario(
                              id: 'scenario-${DateTime.now().microsecondsSinceEpoch}',
                              name:
                                  '${fixture.homeTeamName} vs ${fixture.awayTeamName} (+$_whatIfMargin)',
                              fixtureId: fixture.id,
                              hypotheticalWinnerRegistrationId:
                                  _whatIfWinnerRegId!,
                              hypotheticalMargin: _whatIfMargin,
                              createdAt: DateTime.now(),
                            ),
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            for (final scenario in standingsState.scenariosFor(tournament.id))
              ListTile(
                key: ValueKey('savedScenarioRow_${scenario.id}'),
                contentPadding: EdgeInsets.zero,
                title: Text(scenario.name),
                trailing: IconButton(
                  key: ValueKey('removeScenarioButton_${scenario.id}'),
                  icon: const Icon(Icons.close),
                  onPressed: () => standingsNotifier.removeScenario(
                    tournament.id,
                    scenario.id,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _StandingsTable extends StatelessWidget {
  final List<StandingsRow> rows;
  final AppColors colors;

  const _StandingsTable({required this.rows, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            const Expanded(flex: 3, child: Text('Team')),
            _HeaderCell('P'),
            _HeaderCell('W'),
            _HeaderCell('L'),
            _HeaderCell('Pts'),
            _HeaderCell('NRR'),
          ],
        ),
        const Divider(),
        for (var i = 0; i < rows.length; i++)
          GestureDetector(
            key: ValueKey('standingsRow_${rows[i].registrationId}'),
            onTap: () => _showNrrFormula(context, rows[i]),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      // PRD §8 edge cases: a withdrawn team whose
                      // results stand still appears here, visually
                      // marked so it reads as no longer active.
                      '${i + 1}. ${rows[i].teamName}${rows[i].isWithdrawn ? ' (withdrawn)' : ''}',
                      style: AppTypography.body.copyWith(
                        color: rows[i].isWithdrawn
                            ? colors.textTertiary
                            : colors.textPrimary,
                      ),
                    ),
                  ),
                  _Cell('${rows[i].played}'),
                  _Cell('${rows[i].won}'),
                  _Cell('${rows[i].lost}'),
                  _Cell('${rows[i].points}', bold: true),
                  _Cell(rows[i].nrr.toStringAsFixed(3)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  void _showNrrFormula(BuildContext context, StandingsRow row) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${row.teamName} -- NRR formula'),
        content: Text(
          '(${row.runsFor} runs / ${row.oversFor} overs) - '
          '(${row.runsAgainst} runs / ${row.oversAgainst} overs) = ${row.nrr.toStringAsFixed(3)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String label;
  const _HeaderCell(this.label);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: AppTypography.label,
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  final String value;
  final bool bold;
  const _Cell(this.value, {this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Text(
        value,
        textAlign: TextAlign.center,
        style: bold
            ? AppTypography.stat.copyWith(fontSize: 14, height: 18 / 14)
            : AppTypography.body,
      ),
    );
  }
}

class _RecordResultRow extends ConsumerWidget {
  final String tournamentId;
  final Fixture fixture;
  final AppColors colors;
  final bool isChange;

  const _RecordResultRow({
    super.key,
    required this.tournamentId,
    required this.fixture,
    required this.colors,
    this.isChange = false,
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
            child: Text(
              '${fixture.homeTeamName} vs ${fixture.awayTeamName}',
              style: AppTypography.body,
            ),
          ),
          TextButton(
            key: ValueKey(
              isChange
                  ? 'changeResultButton_${fixture.id}'
                  : 'recordResultButton_${fixture.id}',
            ),
            onPressed: () => _showResultSheet(context, ref),
            child: Text(isChange ? 'Change result' : 'Record result'),
          ),
          if (!isChange)
            TextButton(
              key: ValueKey('recordWalkoverButton_${fixture.id}'),
              onPressed: () => _showWalkoverSheet(context, ref),
              child: const Text('Walkover'),
            ),
        ],
      ),
    );
  }

  void _showResultSheet(BuildContext context, WidgetRef ref) {
    final homeRunsController = TextEditingController();
    final awayRunsController = TextEditingController();
    final reasonController = TextEditingController();
    String? winnerRegId;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            top: AppSpacing.lg,
            bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isChange ? 'Change result' : 'Record result',
                style: AppTypography.h2,
              ),
              TextField(
                controller: homeRunsController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: '${fixture.homeTeamName} runs (20 overs)',
                ),
              ),
              TextField(
                controller: awayRunsController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: '${fixture.awayTeamName} runs (20 overs)',
                ),
              ),
              Wrap(
                spacing: AppSpacing.sm,
                children: [
                  ChoiceChip(
                    label: Text('${fixture.homeTeamName} won'),
                    selected: winnerRegId == fixture.homeRegistrationId,
                    onSelected: (_) => setSheetState(
                      () => winnerRegId = fixture.homeRegistrationId,
                    ),
                  ),
                  ChoiceChip(
                    label: Text('${fixture.awayTeamName} won'),
                    selected: winnerRegId == fixture.awayRegistrationId,
                    onSelected: (_) => setSheetState(
                      () => winnerRegId = fixture.awayRegistrationId,
                    ),
                  ),
                  ChoiceChip(
                    label: const Text('Tie'),
                    selected: winnerRegId == null,
                    onSelected: (_) => setSheetState(() => winnerRegId = null),
                  ),
                ],
              ),
              if (isChange) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  // PRD §2.12: changing a completed result requires
                  // both-captains+scorer ack or a publicly-logged
                  // committee ruling -- only the ruling path is
                  // reachable (no multi-account ack system exists).
                  'Changing a recorded result requires a documented, publicly-logged committee ruling.',
                  style: AppTypography.caption.copyWith(
                    color: colors.textTertiary,
                  ),
                ),
                TextField(
                  key: const ValueKey('committeeRulingReasonField'),
                  controller: reasonController,
                  decoration: const InputDecoration(
                    labelText: 'Committee ruling reason (required)',
                  ),
                  onChanged: (_) => setSheetState(() {}),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              AppButton(
                key: const ValueKey('saveResultButton'),
                variant: AppButtonVariant.primary,
                label: 'Save result',
                fullWidth: true,
                onPressed: isChange && reasonController.text.trim().isEmpty
                    ? null
                    : () {
                        final error = ref
                            .read(standingsProvider.notifier)
                            .recordResult(
                              tournamentId,
                              fixture.id,
                              homeRuns:
                                  int.tryParse(homeRunsController.text) ?? 0,
                              homeOvers: 20,
                              awayRuns:
                                  int.tryParse(awayRunsController.text) ?? 0,
                              awayOvers: 20,
                              winnerRegistrationId: winnerRegId,
                              committeeRulingReason: reasonController.text
                                  .trim(),
                            );
                        if (error != null) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text(error)));
                          return;
                        }
                        Navigator.of(context).pop();
                      },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showWalkoverSheet(BuildContext context, WidgetRef ref) {
    final reasonController = TextEditingController();
    String winnerRegId = fixture.homeRegistrationId;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            top: AppSpacing.lg,
            bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Walkover', style: AppTypography.h2),
              Wrap(
                spacing: AppSpacing.sm,
                children: [
                  ChoiceChip(
                    label: Text('${fixture.homeTeamName} awarded'),
                    selected: winnerRegId == fixture.homeRegistrationId,
                    onSelected: (_) => setSheetState(
                      () => winnerRegId = fixture.homeRegistrationId,
                    ),
                  ),
                  ChoiceChip(
                    label: Text('${fixture.awayTeamName} awarded'),
                    selected: winnerRegId == fixture.awayRegistrationId,
                    onSelected: (_) => setSheetState(
                      () => winnerRegId = fixture.awayRegistrationId,
                    ),
                  ),
                ],
              ),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Public reason (required)',
                ),
                onChanged: (_) => setSheetState(() {}),
              ),
              const SizedBox(height: AppSpacing.md),
              AppButton(
                variant: AppButtonVariant.destructive,
                label: 'Confirm walkover',
                fullWidth: true,
                onPressed: reasonController.text.trim().isEmpty
                    ? null
                    : () {
                        ref
                            .read(standingsProvider.notifier)
                            .recordWalkover(
                              tournamentId,
                              fixture.id,
                              winnerRegId,
                              reasonController.text.trim(),
                            );
                        Navigator.of(context).pop();
                      },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
