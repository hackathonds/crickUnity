import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_button.dart';
import '../design_system/components/app_tag_chip.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'registration_models.dart';
import 'registrations_provider.dart';
import 'tournament_models.dart';
import 'tournaments_provider.dart';

/// PRD §8.2 (Registration): squad list (min/max enforced), entry-fee
/// escrow, refund rules displayed upfront, duplicate-player auto-flag
/// blocking approval, waitlist auto-promote on dropout. Backlog: "G.13"
/// forms checklist -- flagged as a phantom Appendix citation in
/// tournament_models.dart's commonRegistrationDocs comment.
///
/// One screen covers both sides of this story: a "Register a team"
/// form (the team-captain side) and an organizer review list per
/// tournament (approve/reject/withdraw + duplicate-conflict
/// resolution) -- same single-account convention as every other
/// cross-party flow this session (no separate captain/organizer login
/// exists to split these into two screens).
class TournamentRegistrationScreen extends ConsumerStatefulWidget {
  const TournamentRegistrationScreen({super.key});

  @override
  ConsumerState<TournamentRegistrationScreen> createState() =>
      _TournamentRegistrationScreenState();
}

class _TournamentRegistrationScreenState
    extends ConsumerState<TournamentRegistrationScreen> {
  String? _selectedTournamentId;
  final _teamNameController = TextEditingController();
  final _squadController = TextEditingController();
  final Set<String> _docsChecked = {};
  String? _formError;

  @override
  void dispose() {
    _teamNameController.dispose();
    _squadController.dispose();
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
    final registrationsNotifier = ref.read(registrationsProvider.notifier);
    ref.watch(registrationsProvider);

    if (_selectedTournamentId == null && published.isNotEmpty) {
      _selectedTournamentId = published.first.id;
    }
    final selected = published
        .where((t) => t.id == _selectedTournamentId)
        .firstOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Tournament registration')),
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
                Text(
                  'Tournament',
                  style: AppTypography.label.copyWith(
                    color: colors.textTertiary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.sm,
                  children: [
                    for (final t in published)
                      ChoiceChip(
                        key: ValueKey('tournamentChip_${t.id}'),
                        label: Text(t.name.isEmpty ? '(unnamed)' : t.name),
                        selected: _selectedTournamentId == t.id,
                        onSelected: (_) =>
                            setState(() => _selectedTournamentId = t.id),
                      ),
                  ],
                ),
                if (selected != null) ...[
                  const SizedBox(height: AppSpacing.lg),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: colors.surfaceAlt,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Entry fee ₹${selected.entryFee} · Escrow ₹${selected.escrowedAmount}',
                          style: AppTypography.body.copyWith(
                            color: colors.textPrimary,
                          ),
                        ),
                        Text(
                          'Full refund if rejected/cancelled. Withdrawal refund follows a sliding '
                          'scale by days-to-start (organizer policy).',
                          style: AppTypography.caption.copyWith(
                            color: colors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text('Register a team', style: AppTypography.h2),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    key: const ValueKey('registrationTeamNameField'),
                    controller: _teamNameController,
                    decoration: const InputDecoration(labelText: 'Team name'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    key: const ValueKey('registrationSquadField'),
                    controller: _squadController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText:
                          'Squad (comma-separated names, ${selected.squadCapMin}-${selected.squadCapMax})',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Required docs',
                    style: AppTypography.label.copyWith(
                      color: colors.textTertiary,
                    ),
                  ),
                  for (final doc in commonRegistrationDocs)
                    CheckboxListTile(
                      key: ValueKey('registrationDocCheckbox_$doc'),
                      contentPadding: EdgeInsets.zero,
                      title: Text(doc),
                      value: _docsChecked.contains(doc),
                      onChanged: (v) => setState(() {
                        if (v ?? false) {
                          _docsChecked.add(doc);
                        } else {
                          _docsChecked.remove(doc);
                        }
                      }),
                    ),
                  if (_formError != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      _formError!,
                      style: AppTypography.caption.copyWith(
                        color: colors.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  AppButton(
                    key: const ValueKey('submitRegistrationButton'),
                    variant: AppButtonVariant.primary,
                    label: 'Submit registration',
                    fullWidth: true,
                    onPressed: () {
                      final squad = _squadController.text
                          .split(',')
                          .map((s) => s.trim())
                          .where((s) => s.isNotEmpty)
                          .toList();
                      final error = registrationsNotifier.registerTeam(
                        tournamentId: selected.id,
                        teamName: _teamNameController.text.trim(),
                        squad: squad,
                        docsChecked: _docsChecked,
                      );
                      setState(() {
                        _formError = error;
                        if (error == null) {
                          _teamNameController.clear();
                          _squadController.clear();
                          _docsChecked.clear();
                        }
                      });
                    },
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text('Registrations', style: AppTypography.h2),
                  const SizedBox(height: AppSpacing.sm),
                  for (final registration
                      in ref
                          .watch(registrationsProvider)
                          .forTournament(selected.id))
                    _RegistrationCard(
                      key: ValueKey('registrationCard_${registration.id}'),
                      registration: registration,
                      tournament: selected,
                      colors: colors,
                    ),
                ],
              ],
            ),
    );
  }
}

class _RegistrationCard extends ConsumerWidget {
  final TeamRegistration registration;
  final Tournament tournament;
  final AppColors colors;

  const _RegistrationCard({
    super.key,
    required this.registration,
    required this.tournament,
    required this.colors,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(registrationsProvider.notifier);
    final duplicates = notifier.duplicatesFor(registration.tournamentId);
    final conflicting = registration.squad.where(duplicates.contains).toList();
    final statusVariant = switch (registration.status) {
      RegistrationStatus.approved => AppTagChipVariant.success,
      RegistrationStatus.waitlisted => AppTagChipVariant.warning,
      RegistrationStatus.rejected ||
      RegistrationStatus.withdrawn => AppTagChipVariant.error,
      RegistrationStatus.pending => AppTagChipVariant.neutral,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  registration.teamName,
                  style: AppTypography.subtitle.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
              ),
              AppTagChip(
                label: registration.status == RegistrationStatus.waitlisted
                    ? 'Waitlisted #${registration.waitlistPosition}'
                    : registrationStatusLabels[registration.status]!,
                variant: statusVariant,
              ),
            ],
          ),
          Text(
            '${registration.squad.length} players',
            style: AppTypography.caption.copyWith(color: colors.textTertiary),
          ),
          if (conflicting.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: colors.error.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Duplicate player(s) across teams: ${conflicting.join(', ')}',
                    style: AppTypography.caption.copyWith(color: colors.error),
                  ),
                  for (final player in conflicting)
                    TextButton(
                      key: ValueKey(
                        'resolveDuplicateButton_${registration.id}_$player',
                      ),
                      onPressed: () => notifier.removePlayerFromSquad(
                        registration.id,
                        player,
                      ),
                      child: Text(
                        'Remove $player from ${registration.teamName}',
                      ),
                    ),
                ],
              ),
            ),
          ],
          if (!registration.docsComplete) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Docs incomplete',
              style: AppTypography.caption.copyWith(color: colors.warning),
            ),
          ],
          if (registration.status == RegistrationStatus.pending ||
              registration.status == RegistrationStatus.waitlisted) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                if (registration.status == RegistrationStatus.pending)
                  Expanded(
                    child: AppButton(
                      key: ValueKey(
                        'approveRegistrationButton_${registration.id}',
                      ),
                      variant: AppButtonVariant.primary,
                      label: 'Approve',
                      fullWidth: true,
                      onPressed:
                          conflicting.isEmpty && registration.docsComplete
                          ? () => notifier.approveRegistration(registration.id)
                          : null,
                    ),
                  ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppButton(
                    key: ValueKey(
                      'rejectRegistrationButton_${registration.id}',
                    ),
                    variant: AppButtonVariant.destructive,
                    label: 'Reject',
                    fullWidth: true,
                    onPressed: () =>
                        notifier.rejectRegistration(registration.id),
                  ),
                ),
              ],
            ),
          ],
          if (registration.status == RegistrationStatus.approved) ...[
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              key: ValueKey('withdrawRegistrationButton_${registration.id}'),
              variant: AppButtonVariant.secondary,
              label: 'Withdraw',
              fullWidth: true,
              onPressed: tournament.startDate == null
                  ? null
                  : () {
                      final refundFraction = notifier.withdrawRegistration(
                        registration.id,
                        tournament.startDate!,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '${(refundFraction * 100).round()}% refund per the withdrawal policy.',
                          ),
                        ),
                      );
                    },
            ),
          ],
        ],
      ),
    );
  }
}
