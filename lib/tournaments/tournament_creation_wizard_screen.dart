import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_button.dart';
import '../design_system/components/app_stepper.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'tournament_models.dart';
import 'tournaments_provider.dart';

/// PRD §8.1's 6-step creation wizard: Identity -> Format -> Rules ->
/// Money -> Registration -> Publish. matches/create_match_flow.dart
/// establishes a separate-screen-per-step convention via chained
/// Navigator pushes; this wizard instead keeps one file with an
/// internal step index (same convention as booking_flow_screen.dart's
/// multi-part flow, E9-03) since every step here reads/writes the same
/// single Tournament draft rather than passing distinct data forward --
/// a page-index switch avoids threading six callback chains for what is
/// one growing object.
class TournamentCreationWizardScreen extends ConsumerStatefulWidget {
  const TournamentCreationWizardScreen({super.key});

  @override
  ConsumerState<TournamentCreationWizardScreen> createState() =>
      _TournamentCreationWizardScreenState();
}

const List<String> _stepTitles = [
  'Identity',
  'Format',
  'Rules',
  'Money',
  'Registration',
  'Publish',
];

class _TournamentCreationWizardScreenState
    extends ConsumerState<TournamentCreationWizardScreen> {
  int _step = 0;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final draft = ref.watch(tournamentsProvider).draft;
    final notifier = ref.read(tournamentsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: Text('New tournament · ${_stepTitles[_step]}')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                for (var i = 0; i < _stepTitles.length; i++)
                  Expanded(
                    child: Container(
                      key: ValueKey('wizardStepDot_$i'),
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: i <= _step ? colors.primary : colors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: switch (_step) {
                0 => _IdentityStep(
                  draft: draft,
                  notifier: notifier,
                  colors: colors,
                ),
                1 => _FormatStep(
                  draft: draft,
                  notifier: notifier,
                  colors: colors,
                ),
                2 => _RulesStep(
                  draft: draft,
                  notifier: notifier,
                  colors: colors,
                ),
                3 => _MoneyStep(
                  draft: draft,
                  notifier: notifier,
                  colors: colors,
                ),
                4 => _RegistrationStep(
                  draft: draft,
                  notifier: notifier,
                  colors: colors,
                ),
                _ => _PublishStep(
                  draft: draft,
                  notifier: notifier,
                  colors: colors,
                ),
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                if (_step > 0)
                  Expanded(
                    child: AppButton(
                      key: const ValueKey('wizardBackButton'),
                      variant: AppButtonVariant.secondary,
                      label: 'Back',
                      fullWidth: true,
                      onPressed: () => setState(() => _step--),
                    ),
                  ),
                if (_step > 0) const SizedBox(width: AppSpacing.sm),
                if (_step < _stepTitles.length - 1)
                  Expanded(
                    child: AppButton(
                      key: const ValueKey('wizardContinueButton'),
                      variant: AppButtonVariant.primary,
                      label: 'Continue',
                      fullWidth: true,
                      onPressed: () => setState(() => _step++),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StepScaffold extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _StepScaffold({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTypography.h2),
        const SizedBox(height: AppSpacing.lg),
        ...children,
      ],
    );
  }
}

class _IdentityStep extends StatelessWidget {
  final Tournament draft;
  final TournamentsNotifier notifier;
  final AppColors colors;

  const _IdentityStep({
    required this.draft,
    required this.notifier,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return _StepScaffold(
      title: 'Identity',
      children: [
        TextField(
          key: const ValueKey('tournamentNameField'),
          decoration: const InputDecoration(labelText: 'Tournament name'),
          controller: TextEditingController(text: draft.name)
            ..selection = TextSelection.collapsed(offset: draft.name.length),
          onChanged: (v) => notifier.updateDraft((t) => t.copyWith(name: v)),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          key: const ValueKey('tournamentCityField'),
          decoration: const InputDecoration(labelText: 'City'),
          controller: TextEditingController(text: draft.city)
            ..selection = TextSelection.collapsed(offset: draft.city.length),
          onChanged: (v) => notifier.updateDraft((t) => t.copyWith(city: v)),
        ),
        const SizedBox(height: AppSpacing.md),
        // No image-upload pipeline exists (flagged, same convention as
        // every other missing-asset gap this session) -- logo/banner
        // are acknowledged as mock placeholders rather than built out.
        Text(
          'Logo & banner uploads (mock -- no image pipeline exists yet).',
          style: AppTypography.caption.copyWith(color: colors.textTertiary),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _DateField(
                key: const ValueKey('tournamentStartDateField'),
                label: 'Start date',
                value: draft.startDate,
                onPicked: (d) =>
                    notifier.updateDraft((t) => t.copyWith(startDate: d)),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _DateField(
                key: const ValueKey('tournamentEndDateField'),
                label: 'End date',
                value: draft.endDate,
                onPicked: (d) =>
                    notifier.updateDraft((t) => t.copyWith(endDate: d)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onPicked;

  const _DateField({
    super.key,
    required this.label,
    required this.value,
    required this.onPicked,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 730)),
        );
        if (picked != null) onPicked(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(labelText: label),
        child: Text(
          value == null
              ? 'Select'
              : '${value!.day}/${value!.month}/${value!.year}',
        ),
      ),
    );
  }
}

class _FormatStep extends StatelessWidget {
  final Tournament draft;
  final TournamentsNotifier notifier;
  final AppColors colors;

  const _FormatStep({
    required this.draft,
    required this.notifier,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return _StepScaffold(
      title: 'Format',
      children: [
        Text(
          'Competition format',
          style: AppTypography.label.copyWith(color: colors.textTertiary),
        ),
        Wrap(
          spacing: AppSpacing.sm,
          children: [
            for (final f in TournamentFormat.values)
              ChoiceChip(
                key: ValueKey('formatChip_${f.name}'),
                label: Text(tournamentFormatLabels[f]!),
                selected: draft.format == f,
                onSelected: (_) =>
                    notifier.updateDraft((t) => t.copyWith(format: f)),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        _LabeledStepper(
          label: 'Overs',
          value: draft.overs,
          min: 1,
          max: 50,
          semanticLabel: 'Overs',
          onChanged: (v) => notifier.updateDraft((t) => t.copyWith(overs: v)),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Ball',
          style: AppTypography.label.copyWith(color: colors.textTertiary),
        ),
        Wrap(
          spacing: AppSpacing.sm,
          children: [
            for (final b in TournamentBallType.values)
              ChoiceChip(
                key: ValueKey('ballTypeChip_${b.name}'),
                label: Text(tournamentBallTypeLabels[b]!),
                selected: draft.ballType == b,
                onSelected: (_) =>
                    notifier.updateDraft((t) => t.copyWith(ballType: b)),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        _LabeledStepper(
          label: 'Players per side',
          value: draft.playersPerSide,
          min: 6,
          max: 11,
          semanticLabel: 'Players per side',
          onChanged: (v) =>
              notifier.updateDraft((t) => t.copyWith(playersPerSide: v)),
        ),
        const SizedBox(height: AppSpacing.md),
        _LabeledStepper(
          label: 'Squad cap (min)',
          value: draft.squadCapMin,
          min: draft.playersPerSide,
          max: draft.squadCapMax,
          semanticLabel: 'Squad cap minimum',
          onChanged: (v) =>
              notifier.updateDraft((t) => t.copyWith(squadCapMin: v)),
        ),
        const SizedBox(height: AppSpacing.md),
        _LabeledStepper(
          label: 'Squad cap (max)',
          value: draft.squadCapMax,
          min: draft.squadCapMin,
          max: 30,
          semanticLabel: 'Squad cap maximum',
          onChanged: (v) =>
              notifier.updateDraft((t) => t.copyWith(squadCapMax: v)),
        ),
      ],
    );
  }
}

class _LabeledStepper extends StatelessWidget {
  final String label;
  final int value;
  final int min;
  final int max;
  final String semanticLabel;
  final ValueChanged<int> onChanged;

  const _LabeledStepper({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.semanticLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label, style: AppTypography.body)),
        AppStepper(
          value: value,
          min: min,
          max: max,
          semanticLabel: semanticLabel,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _RulesStep extends StatelessWidget {
  final Tournament draft;
  final TournamentsNotifier notifier;
  final AppColors colors;

  const _RulesStep({
    required this.draft,
    required this.notifier,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return _StepScaffold(
      title: 'Rules',
      children: [
        Text(
          'Points scheme',
          style: AppTypography.label.copyWith(color: colors.textTertiary),
        ),
        _LabeledStepper(
          label: 'Win',
          value: draft.pointsScheme.winPoints,
          min: 0,
          max: 10,
          semanticLabel: 'Win points',
          onChanged: (v) => notifier.updateDraft(
            (t) =>
                t.copyWith(pointsScheme: t.pointsScheme.copyWith(winPoints: v)),
          ),
        ),
        _LabeledStepper(
          label: 'Tie',
          value: draft.pointsScheme.tiePoints,
          min: 0,
          max: 10,
          semanticLabel: 'Tie points',
          onChanged: (v) => notifier.updateDraft(
            (t) =>
                t.copyWith(pointsScheme: t.pointsScheme.copyWith(tiePoints: v)),
          ),
        ),
        _LabeledStepper(
          label: 'No result',
          value: draft.pointsScheme.noResultPoints,
          min: 0,
          max: 10,
          semanticLabel: 'No-result points',
          onChanged: (v) => notifier.updateDraft(
            (t) => t.copyWith(
              pointsScheme: t.pointsScheme.copyWith(noResultPoints: v),
            ),
          ),
        ),
        SwitchListTile(
          key: const ValueKey('bonusPointSwitch'),
          contentPadding: EdgeInsets.zero,
          title: const Text('Bonus point enabled'),
          value: draft.pointsScheme.bonusPointEnabled,
          onChanged: (v) => notifier.updateDraft(
            (t) => t.copyWith(
              pointsScheme: t.pointsScheme.copyWith(bonusPointEnabled: v),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: Text(
                'Tie-breaker order (drag to reorder) *',
                style: AppTypography.label.copyWith(color: colors.textTertiary),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        SizedBox(
          height: 220,
          child: ReorderableListView(
            key: const ValueKey('tieBreakerReorderList'),
            shrinkWrap: true,
            onReorderItem: (oldIndex, newIndex) {
              final order = [...draft.tieBreakerOrder];
              final item = order.removeAt(oldIndex);
              order.insert(newIndex, item);
              notifier.updateDraft((t) => t.copyWith(tieBreakerOrder: order));
            },
            children: [
              for (var i = 0; i < draft.tieBreakerOrder.length; i++)
                ListTile(
                  key: ValueKey(
                    'tieBreakerRow_${draft.tieBreakerOrder[i].name}',
                  ),
                  leading: Text('${i + 1}'),
                  title: Text(tieBreakerLabels[draft.tieBreakerOrder[i]]!),
                  trailing: const Icon(Icons.drag_handle),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SwitchListTile(
          key: const ValueKey('overRatePenaltiesSwitch'),
          contentPadding: EdgeInsets.zero,
          title: const Text('Over-rate penalties'),
          value: draft.overRatePenaltiesEnabled,
          onChanged: (v) => notifier.updateDraft(
            (t) => t.copyWith(overRatePenaltiesEnabled: v),
          ),
        ),
        SwitchListTile(
          key: const ValueKey('transferWindowSwitch'),
          contentPadding: EdgeInsets.zero,
          title: const Text('Transfer window'),
          value: draft.transferWindowEnabled,
          onChanged: (v) =>
              notifier.updateDraft((t) => t.copyWith(transferWindowEnabled: v)),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Rain-abandoned final rule * (must be set before registration opens)',
          style: AppTypography.label.copyWith(color: colors.textTertiary),
        ),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.sm,
          children: [
            for (final r in RainFinalRule.values)
              ChoiceChip(
                key: ValueKey('rainFinalRuleChip_${r.name}'),
                label: Text(rainFinalRuleLabels[r]!),
                selected: draft.rainFinalRule == r,
                onSelected: (_) =>
                    notifier.updateDraft((t) => t.copyWith(rainFinalRule: r)),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Team withdrawal rule *',
          style: AppTypography.label.copyWith(color: colors.textTertiary),
        ),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.sm,
          children: [
            for (final w in WithdrawalRule.values)
              ChoiceChip(
                key: ValueKey('withdrawalRuleChip_${w.name}'),
                label: Text(withdrawalRuleLabels[w]!),
                selected: draft.withdrawalRule == w,
                onSelected: (_) =>
                    notifier.updateDraft((t) => t.copyWith(withdrawalRule: w)),
              ),
          ],
        ),
      ],
    );
  }
}

class _MoneyStep extends StatelessWidget {
  final Tournament draft;
  final TournamentsNotifier notifier;
  final AppColors colors;

  const _MoneyStep({
    required this.draft,
    required this.notifier,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return _StepScaffold(
      title: 'Money',
      children: [
        TextField(
          key: const ValueKey('entryFeeField'),
          decoration: const InputDecoration(labelText: 'Entry fee (₹)'),
          keyboardType: TextInputType.number,
          controller: TextEditingController(text: '${draft.entryFee}')
            ..selection = TextSelection.collapsed(
              offset: '${draft.entryFee}'.length,
            ),
          onChanged: (v) => notifier.updateDraft(
            (t) => t.copyWith(entryFee: int.tryParse(v) ?? t.entryFee),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          key: const ValueKey('prizeStructureField'),
          decoration: const InputDecoration(labelText: 'Prize structure'),
          maxLines: 3,
          controller: TextEditingController(text: draft.prizeStructureNote)
            ..selection = TextSelection.collapsed(
              offset: draft.prizeStructureNote.length,
            ),
          onChanged: (v) =>
              notifier.updateDraft((t) => t.copyWith(prizeStructureNote: v)),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Umpire/scorer provisioning',
          style: AppTypography.label.copyWith(color: colors.textTertiary),
        ),
        Wrap(
          spacing: AppSpacing.sm,
          children: [
            for (final o in OfficialsProvisioning.values)
              ChoiceChip(
                key: ValueKey('officialsProvisioningChip_${o.name}'),
                label: Text(officialsProvisioningLabels[o]!),
                selected: draft.officialsProvisioning == o,
                onSelected: (_) => notifier.updateDraft(
                  (t) => t.copyWith(officialsProvisioning: o),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _RegistrationStep extends StatelessWidget {
  final Tournament draft;
  final TournamentsNotifier notifier;
  final AppColors colors;

  const _RegistrationStep({
    required this.draft,
    required this.notifier,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return _StepScaffold(
      title: 'Registration',
      children: [
        Text(
          'Mode',
          style: AppTypography.label.copyWith(color: colors.textTertiary),
        ),
        Wrap(
          spacing: AppSpacing.sm,
          children: [
            for (final m in RegistrationMode.values)
              ChoiceChip(
                key: ValueKey('registrationModeChip_${m.name}'),
                label: Text(registrationModeLabels[m]!),
                selected: draft.registrationMode == m,
                onSelected: (_) => notifier.updateDraft(
                  (t) => t.copyWith(registrationMode: m),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        _LabeledStepper(
          label: 'Team cap',
          value: draft.teamCap,
          min: 2,
          max: 64,
          semanticLabel: 'Team cap',
          onChanged: (v) => notifier.updateDraft((t) => t.copyWith(teamCap: v)),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          key: const ValueKey('docsRequiredField'),
          decoration: const InputDecoration(labelText: 'Docs required'),
          controller: TextEditingController(text: draft.docsRequiredNote)
            ..selection = TextSelection.collapsed(
              offset: draft.docsRequiredNote.length,
            ),
          onChanged: (v) =>
              notifier.updateDraft((t) => t.copyWith(docsRequiredNote: v)),
        ),
        const SizedBox(height: AppSpacing.md),
        _DateField(
          key: const ValueKey('registrationDeadlineField'),
          label: 'Registration deadline',
          value: draft.registrationDeadline,
          onPicked: (d) =>
              notifier.updateDraft((t) => t.copyWith(registrationDeadline: d)),
        ),
      ],
    );
  }
}

class _PublishStep extends ConsumerWidget {
  final Tournament draft;
  final TournamentsNotifier notifier;
  final AppColors colors;

  const _PublishStep({
    required this.draft,
    required this.notifier,
    required this.colors,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _StepScaffold(
      title: 'Review & publish',
      children: [
        _SummaryRow(
          label: 'Name',
          value: draft.name.isEmpty ? '--' : draft.name,
        ),
        _SummaryRow(
          label: 'City',
          value: draft.city.isEmpty ? '--' : draft.city,
        ),
        _SummaryRow(
          label: 'Dates',
          value: draft.startDate == null || draft.endDate == null
              ? '--'
              : '${draft.startDate!.day}/${draft.startDate!.month} -> ${draft.endDate!.day}/${draft.endDate!.month}',
        ),
        _SummaryRow(
          label: 'Format',
          value: tournamentFormatLabels[draft.format]!,
        ),
        _SummaryRow(
          label: 'Overs / ball',
          value:
              '${draft.overs} overs, ${tournamentBallTypeLabels[draft.ballType]}',
        ),
        _SummaryRow(
          label: 'Tie-breakers',
          value: draft.tieBreakerOrder
              .map((t) => tieBreakerLabels[t])
              .join(' -> '),
        ),
        _SummaryRow(
          label: 'Rain-final rule',
          value: draft.rainFinalRule == null
              ? 'Not set *'
              : rainFinalRuleLabels[draft.rainFinalRule]!,
        ),
        _SummaryRow(
          label: 'Withdrawal rule',
          value: draft.withdrawalRule == null
              ? 'Not set *'
              : withdrawalRuleLabels[draft.withdrawalRule]!,
        ),
        _SummaryRow(label: 'Entry fee', value: '₹${draft.entryFee}'),
        _SummaryRow(
          label: 'Registration',
          value: registrationModeLabels[draft.registrationMode]!,
        ),
        const SizedBox(height: AppSpacing.lg),
        if (!draft.canPublish)
          Text(
            '* Name, dates, all tie-breakers, rain-final rule, and withdrawal rule are required before publishing.',
            style: AppTypography.caption.copyWith(color: colors.error),
          ),
        const SizedBox(height: AppSpacing.md),
        AppButton(
          key: const ValueKey('publishTournamentButton'),
          variant: AppButtonVariant.primary,
          label: 'Publish',
          fullWidth: true,
          onPressed: draft.canPublish
              ? () {
                  notifier.publish();
                  Navigator.of(context).pop();
                }
              : null,
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        final colors = Theme.of(context).extension<AppColors>()!;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Row(
            children: [
              SizedBox(
                width: 140,
                child: Text(
                  label,
                  style: AppTypography.caption.copyWith(
                    color: colors.textTertiary,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  value,
                  style: AppTypography.body.copyWith(color: colors.textPrimary),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
