import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'medical_models.dart';
import 'medical_provider.dart';

/// DS §11.16: "Injury log: add-injury sheet (type, date, notes private)
/// -> auto-Injured availability + streak-shield note; return-to-play
/// checklist screen (self-check rows -> confirm) reactivates
/// availability."
class InjuryLogScreen extends ConsumerWidget {
  const InjuryLogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final state = ref.watch(medicalProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Injury log')),
      floatingActionButton: FloatingActionButton.extended(
        key: const ValueKey('addInjuryButton'),
        onPressed: () => _showAddInjurySheet(context, ref),
        label: const Text('Add injury'),
        icon: const Icon(Icons.add),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          if (state.hasActiveInjury)
            Container(
              key: const ValueKey('autoInjuredBanner'),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: colors.surfaceAlt,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Availability set to Injured',
                    style: AppTypography.body.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                  Text(
                    'Your activity streak is shielded while injured.',
                    style: AppTypography.caption.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  OutlinedButton(
                    key: const ValueKey('openReturnToPlayButton'),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ReturnToPlayScreen(),
                      ),
                    ),
                    child: const Text('Return-to-play checklist'),
                  ),
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.lg),
          for (final injury in state.injuries)
            Container(
              key: ValueKey('injuryRow_${injury.id}'),
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: colors.surface,
                border: Border.all(color: colors.border),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          injury.type,
                          style: AppTypography.body.copyWith(
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        injury.active ? 'Active' : 'Resolved',
                        style: AppTypography.caption.copyWith(
                          color: injury.active
                              ? colors.warning
                              : colors.success,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    injury.notes,
                    style: AppTypography.caption.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _showAddInjurySheet(BuildContext context, WidgetRef ref) {
    final typeController = TextEditingController();
    final notesController = TextEditingController();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        final colors = Theme.of(context).extension<AppColors>()!;
        return Padding(
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
                'Add injury',
                style: AppTypography.title.copyWith(color: colors.textPrimary),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                key: const ValueKey('injuryTypeField'),
                controller: typeController,
                decoration: const InputDecoration(labelText: 'Type'),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                key: const ValueKey('injuryNotesField'),
                controller: notesController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Notes (private)'),
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                key: const ValueKey('submitInjuryButton'),
                onPressed: typeController.text.trim().isEmpty
                    ? null
                    : () {
                        ref
                            .read(medicalProvider.notifier)
                            .addInjury(
                              type: typeController.text.trim(),
                              date: DateTime.now(),
                              notes: notesController.text.trim(),
                            );
                        Navigator.of(context).pop();
                      },
                child: const Text('Log injury'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class ReturnToPlayScreen extends ConsumerWidget {
  const ReturnToPlayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(medicalProvider);
    final notifier = ref.read(medicalProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Return-to-play checklist')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          for (var i = 0; i < returnToPlayChecklistRows.length; i++)
            CheckboxListTile(
              key: ValueKey('returnToPlayRow_$i'),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(returnToPlayChecklistRows[i]),
              value: state.returnToPlayChecked.contains(i),
              onChanged: (_) => notifier.toggleReturnToPlayRow(i),
            ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton(
            key: const ValueKey('confirmReturnToPlayButton'),
            onPressed: notifier.allReturnToPlayChecked
                ? () {
                    notifier.confirmReturnToPlay();
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Availability reactivated')),
                    );
                  }
                : null,
            child: const Text('Confirm -- reactivate availability'),
          ),
        ],
      ),
    );
  }
}
