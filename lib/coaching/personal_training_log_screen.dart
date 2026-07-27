import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_button.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import '../social/composer_screen.dart' show composerViewerName;
import 'coach_models.dart';
import 'coach_provider.dart';
import 'training_log_models.dart';
import 'training_log_provider.dart';

/// Backlog E11-05: "Drill Library access for *all* users (not only
/// academy students): self-log drills with units, optional proof
/// (+bonus), partner-confirm, per-drill PBs & progress graphs, feeds
/// daily missions ... and Net-Grinder/Circle-Runner badges, age
/// workload caps." Reuses the real coachProvider Drill Library
/// (E11-03) rather than a second catalog.
class PersonalTrainingLogScreen extends ConsumerStatefulWidget {
  /// E15-04 (Discover): "tip cards carry [Add drill] chip deep-linking
  /// Drill Library." Pre-selects the drill the tip was about, rather
  /// than always landing on whichever drill happens to be first.
  final String? initialDrillId;

  const PersonalTrainingLogScreen({super.key, this.initialDrillId});

  @override
  ConsumerState<PersonalTrainingLogScreen> createState() =>
      _PersonalTrainingLogScreenState();
}

class _PersonalTrainingLogScreenState
    extends ConsumerState<PersonalTrainingLogScreen> {
  String? _selectedDrillId;
  AgeBand _ageBand = AgeBand.adult;
  int _value = 10;
  bool _hasProof = false;
  String? _logError;

  @override
  void initState() {
    super.initState();
    _selectedDrillId = widget.initialDrillId;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final drills = ref.watch(coachProvider).drills;
    final state = ref.watch(trainingLogProvider);
    final notifier = ref.read(trainingLogProvider.notifier);

    if (_selectedDrillId == null && drills.isNotEmpty) {
      _selectedDrillId = drills.first.id;
    }
    final drill = drills.where((d) => d.id == _selectedDrillId).firstOrNull;
    final myEntries = state.forUser(composerViewerName);
    final sessionsThisWeek = state
        .sessionsThisWeekFor(composerViewerName, DateTime.now())
        .length;

    return Scaffold(
      appBar: AppBar(title: const Text('My training log')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(
            '$sessionsThisWeek/$maxSessionsPerWeek logged this week',
            style: AppTypography.body.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Drill Library', style: AppTypography.h2),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              for (final d in drills)
                ChoiceChip(
                  key: ValueKey('logDrillChip_${d.id}'),
                  label: Text(d.name),
                  selected: _selectedDrillId == d.id,
                  onSelected: (_) => setState(() => _selectedDrillId = d.id),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              for (final band in AgeBand.values)
                ChoiceChip(
                  key: ValueKey('logAgeBandChip_${band.name}'),
                  label: Text(ageBandLabels[band]!),
                  selected: _ageBand == band,
                  onSelected: (_) => setState(() => _ageBand = band),
                ),
            ],
          ),
          if (drill != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Builder(
              builder: (context) {
                final (sets, reps) = scaledPrescription(drill, _ageBand);
                return Text(
                  'Prescription: $sets sets x $reps reps',
                  style: AppTypography.caption.copyWith(
                    color: colors.textTertiary,
                  ),
                );
              },
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(child: Text('Value logged', style: AppTypography.body)),
              IconButton(
                icon: const Icon(Icons.remove),
                onPressed: () =>
                    setState(() => _value = (_value - 1).clamp(1, 999)),
              ),
              Text('$_value', style: AppTypography.stat),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () =>
                    setState(() => _value = (_value + 1).clamp(1, 999)),
              ),
            ],
          ),
          SwitchListTile(
            key: const ValueKey('logProofSwitch'),
            contentPadding: EdgeInsets.zero,
            title: Text('Attach proof (+$proofBonusCoins coins)'),
            value: _hasProof,
            onChanged: (v) => setState(() => _hasProof = v),
          ),
          if (_logError != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Text(
                _logError!,
                style: AppTypography.caption.copyWith(color: colors.error),
              ),
            ),
          AppButton(
            key: const ValueKey('logDrillButton'),
            variant: AppButtonVariant.primary,
            label: 'Log drill',
            fullWidth: true,
            onPressed: drill == null
                ? null
                : () {
                    final error = notifier.logDrill(
                      composerViewerName,
                      drill.id,
                      _value,
                      hasProof: _hasProof,
                    );
                    setState(() {
                      _logError = error;
                      if (error == null) _hasProof = false;
                    });
                  },
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Badges', style: AppTypography.h2),
          const SizedBox(height: AppSpacing.sm),
          for (final badgeId in TrainingBadgeId.values)
            Builder(
              builder: (context) {
                final tierIndex = state.badgeTierIndexFor(badgeId);
                final counter = state.badgeCounterFor(badgeId);
                final tierLabel = tierIndex < 0
                    ? 'Unearned'
                    : trainingBadgeTierLabels[tierIndex];
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: Text(
                    '${trainingBadgeNames[badgeId]}: $tierLabel ($counter logged)',
                    style: AppTypography.body.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                );
              },
            ),
          const SizedBox(height: AppSpacing.xl),
          Text('My logged drills', style: AppTypography.h2),
          const SizedBox(height: AppSpacing.sm),
          for (final entry in myEntries.reversed)
            Builder(
              builder: (context) {
                final entryDrill = drills
                    .where((d) => d.id == entry.drillId)
                    .firstOrNull;
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${entryDrill?.name ?? entry.drillId}: ${entry.value}'
                          '${entry.hasProof ? ' (proof)' : ''}',
                          style: AppTypography.body.copyWith(
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                      if (entry.partnerConfirmed)
                        Text(
                          'Confirmed by ${entry.partnerName}',
                          style: AppTypography.caption.copyWith(
                            color: colors.success,
                          ),
                        )
                      else
                        TextButton(
                          key: ValueKey('confirmPartnerButton_${entry.id}'),
                          onPressed: () =>
                              notifier.confirmAsPartner(entry.id, 'Priya Nair'),
                          child: const Text('Confirm as partner (debug)'),
                        ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
