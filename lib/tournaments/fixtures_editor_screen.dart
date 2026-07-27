import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_button.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'fixture_models.dart';
import 'fixtures_provider.dart';
import 'registration_models.dart';
import 'registrations_provider.dart';
import 'tournament_models.dart';
import 'tournaments_provider.dart';

/// PRD §8.3: auto-generator honoring ground availability/blackout
/// dates/rest gaps/double-header limits; manual drag-adjust with
/// conflict warnings; publish notifies squads; any change is a
/// change-record with reason. See fixture_models.dart's top-of-file
/// note for the flagged judgment calls this implements.
class FixturesEditorScreen extends ConsumerStatefulWidget {
  const FixturesEditorScreen({super.key});

  @override
  ConsumerState<FixturesEditorScreen> createState() =>
      _FixturesEditorScreenState();
}

class _FixturesEditorScreenState extends ConsumerState<FixturesEditorScreen> {
  String? _selectedTournamentId;
  final _venueNameController = TextEditingController();
  DateTime? _venueDate;

  @override
  void dispose() {
    _venueNameController.dispose();
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
    final fixturesNotifier = ref.read(fixturesProvider.notifier);
    final fixturesState = ref.watch(fixturesProvider);
    final registrationsState = ref.watch(registrationsProvider);

    if (_selectedTournamentId == null && published.isNotEmpty) {
      _selectedTournamentId = published.first.id;
    }
    final selected = published
        .where((t) => t.id == _selectedTournamentId)
        .firstOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Fixtures')),
      body: published.isEmpty
          ? Center(
              child: Text(
                'No published tournaments yet -- publish one first (E10-01).',
                textAlign: TextAlign.center,
                style: AppTypography.body.copyWith(color: colors.textSecondary),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                Wrap(
                  spacing: AppSpacing.sm,
                  children: [
                    for (final t in published)
                      ChoiceChip(
                        key: ValueKey('fixturesTournamentChip_${t.id}'),
                        label: Text(t.name.isEmpty ? '(unnamed)' : t.name),
                        selected: _selectedTournamentId == t.id,
                        onSelected: (_) =>
                            setState(() => _selectedTournamentId = t.id),
                      ),
                  ],
                ),
                if (selected != null) ...[
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Venue pool (ground availability)',
                    style: AppTypography.h2,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  for (final slot in fixturesState.venueSlotsFor(selected.id))
                    Text(
                      '${slot.venueName} · ${slot.date.day}/${slot.date.month}/${slot.date.year}',
                      style: AppTypography.body.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          key: const ValueKey('venueNameField'),
                          controller: _venueNameController,
                          decoration: const InputDecoration(
                            labelText: 'Venue name',
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      TextButton(
                        key: const ValueKey('pickVenueDateButton'),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selected.startDate ?? DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365),
                            ),
                          );
                          if (picked != null) {
                            setState(() => _venueDate = picked);
                          }
                        },
                        child: Text(
                          _venueDate == null
                              ? 'Pick date'
                              : '${_venueDate!.day}/${_venueDate!.month}',
                        ),
                      ),
                    ],
                  ),
                  AppButton(
                    key: const ValueKey('addVenueSlotButton'),
                    variant: AppButtonVariant.secondary,
                    label: 'Add venue slot',
                    fullWidth: true,
                    onPressed:
                        _venueNameController.text.trim().isEmpty ||
                            _venueDate == null
                        ? null
                        : () {
                            fixturesNotifier.addVenueSlot(
                              selected.id,
                              VenueSlot(
                                venueName: _venueNameController.text.trim(),
                                date: _venueDate!,
                              ),
                            );
                            setState(() {
                              _venueNameController.clear();
                              _venueDate = null;
                            });
                          },
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    'Team blackout dates (up to 2)',
                    style: AppTypography.label.copyWith(
                      color: colors.textTertiary,
                    ),
                  ),
                  for (final team
                      in registrationsState.forTournament(selected.id)
                        ..removeWhere(
                          (r) => r.status != RegistrationStatus.approved,
                        ))
                    _BlackoutRow(
                      key: ValueKey('blackoutRow_${team.id}'),
                      team: team,
                      colors: colors,
                    ),
                  const SizedBox(height: AppSpacing.xl),
                  AppButton(
                    key: const ValueKey('generateFixturesButton'),
                    variant: AppButtonVariant.primary,
                    label: 'Generate fixtures',
                    fullWidth: true,
                    onPressed: () {
                      final approved = registrationsState
                          .forTournament(selected.id)
                          .where((r) => r.status == RegistrationStatus.approved)
                          .toList();
                      fixturesNotifier.generateFixtures(selected.id, approved);
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text('Fixtures', style: AppTypography.h2),
                  const SizedBox(height: AppSpacing.sm),
                  for (final fixture in fixturesState.forTournament(
                    selected.id,
                  ))
                    _FixtureCard(
                      key: ValueKey('fixtureCard_${fixture.id}'),
                      fixture: fixture,
                      colors: colors,
                    ),
                  const SizedBox(height: AppSpacing.lg),
                  AppButton(
                    key: const ValueKey('publishFixturesButton'),
                    variant: AppButtonVariant.primary,
                    label:
                        fixturesState.publishedTournamentIds.contains(
                          selected.id,
                        )
                        ? 'Published -- re-publish'
                        : 'Publish fixtures',
                    fullWidth: true,
                    onPressed: fixturesState.forTournament(selected.id).isEmpty
                        ? null
                        : () => fixturesNotifier.publishFixtures(selected.id),
                  ),
                ],
              ],
            ),
    );
  }
}

class _BlackoutRow extends ConsumerWidget {
  final TeamRegistration team;
  final AppColors colors;

  const _BlackoutRow({super.key, required this.team, required this.colors});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Expanded(
          child: Text(
            '${team.teamName}: ${team.blackoutDates.isEmpty ? 'none' : team.blackoutDates.map((d) => '${d.day}/${d.month}').join(', ')}',
            style: AppTypography.body.copyWith(color: colors.textSecondary),
          ),
        ),
        TextButton(
          key: ValueKey('addBlackoutDateButton_${team.id}'),
          onPressed: team.blackoutDates.length >= maxBlackoutDates
              ? null
              : () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    ref.read(registrationsProvider.notifier).setBlackoutDates(
                      team.id,
                      [...team.blackoutDates, picked],
                    );
                  }
                },
          child: const Text('Add blackout date'),
        ),
      ],
    );
  }
}

class _FixtureCard extends ConsumerWidget {
  final Fixture fixture;
  final AppColors colors;

  const _FixtureCard({super.key, required this.fixture, required this.colors});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      key: ValueKey('fixtureCardBox_${fixture.id}'),
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${fixture.homeTeamName} vs ${fixture.awayTeamName}',
            style: AppTypography.subtitle.copyWith(color: colors.textPrimary),
          ),
          Text(
            fixture.isScheduled
                ? '${fixture.venueName} · ${fixture.date!.day}/${fixture.date!.month}/${fixture.date!.year}'
                : 'Unscheduled -- no venue slot fit all constraints',
            style: AppTypography.caption.copyWith(
              color: fixture.isScheduled ? colors.textTertiary : colors.warning,
            ),
          ),
          if (fixture.changeHistory.isNotEmpty)
            Text(
              '${fixture.changeHistory.length} change(s) -- latest: "${fixture.changeHistory.last.reason}"',
              style: AppTypography.caption.copyWith(color: colors.textTertiary),
            ),
          const SizedBox(height: AppSpacing.xs),
          TextButton(
            key: ValueKey('editFixtureButton_${fixture.id}'),
            onPressed: () => _showEditSheet(context, ref),
            child: const Text('Drag-adjust (edit venue/date)'),
          ),
        ],
      ),
    );
  }

  void _showEditSheet(BuildContext context, WidgetRef ref) {
    final venueController = TextEditingController(
      text: fixture.venueName ?? '',
    );
    final reasonController = TextEditingController();
    DateTime? newDate = fixture.date;
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
              Text('Edit fixture', style: AppTypography.h2),
              const SizedBox(height: AppSpacing.md),
              TextField(
                key: const ValueKey('editFixtureVenueField'),
                controller: venueController,
                decoration: const InputDecoration(labelText: 'Venue'),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextButton(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: newDate ?? DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) setSheetState(() => newDate = picked);
                },
                child: Text(
                  newDate == null
                      ? 'Pick date'
                      : '${newDate!.day}/${newDate!.month}/${newDate!.year}',
                ),
              ),
              TextField(
                key: const ValueKey('editFixtureReasonField'),
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Reason for change (required)',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AppButton(
                key: const ValueKey('saveFixtureEditButton'),
                variant: AppButtonVariant.primary,
                label: 'Save',
                fullWidth: true,
                onPressed:
                    venueController.text.trim().isEmpty ||
                        newDate == null ||
                        reasonController.text.trim().isEmpty
                    ? null
                    : () {
                        final registrations = ref
                            .read(registrationsProvider)
                            .registrations;
                        final home = registrations
                            .where((r) => r.id == fixture.homeRegistrationId)
                            .firstOrNull;
                        final away = registrations
                            .where((r) => r.id == fixture.awayRegistrationId)
                            .firstOrNull;
                        if (home == null || away == null) return;
                        final warnings = ref
                            .read(fixturesProvider.notifier)
                            .editFixture(
                              fixture.id,
                              venueController.text.trim(),
                              newDate!,
                              reasonController.text.trim(),
                              home: home,
                              away: away,
                            );
                        Navigator.of(context).pop();
                        if (warnings.isNotEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(warnings.join(' '))),
                          );
                        }
                      },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
