import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_button.dart';
import '../design_system/components/app_tag_chip.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'academy_models.dart';
import 'academy_provider.dart';

/// PRD §2.10 (Academy Owner): batches, guardian-consent enrollment,
/// fee ledgers, trials, talent showcase opt-in. See
/// academy_models.dart's top-of-file note for the exact quote and the
/// flagged messaging-restriction gap.
class AcademyConsoleScreen extends ConsumerStatefulWidget {
  const AcademyConsoleScreen({super.key});

  @override
  ConsumerState<AcademyConsoleScreen> createState() =>
      _AcademyConsoleScreenState();
}

class _AcademyConsoleScreenState extends ConsumerState<AcademyConsoleScreen> {
  String? _selectedBatchId;
  final _studentNameController = TextEditingController();
  bool _isMinor = false;
  final _guardianNameController = TextEditingController();
  bool _guardianConsent = false;
  String? _enrollError;
  final _trialNameController = TextEditingController();
  final _trialAgeGroupController = TextEditingController();
  DateTime? _trialDate;

  @override
  void dispose() {
    _studentNameController.dispose();
    _guardianNameController.dispose();
    _trialNameController.dispose();
    _trialAgeGroupController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final state = ref.watch(academyProvider);
    final notifier = ref.read(academyProvider.notifier);

    if (_selectedBatchId == null && state.batches.isNotEmpty) {
      _selectedBatchId = state.batches.first.id;
    }
    final batch = state.batches
        .where((b) => b.id == _selectedBatchId)
        .firstOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Academy console')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text('Batches', style: AppTypography.h2),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              for (final b in state.batches)
                ChoiceChip(
                  key: ValueKey('batchChip_${b.id}'),
                  label: Text(b.name),
                  selected: _selectedBatchId == b.id,
                  onSelected: (_) => setState(() => _selectedBatchId = b.id),
                ),
            ],
          ),
          if (batch != null) ...[
            const SizedBox(height: AppSpacing.sm),
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
                    '${batch.ageGroup} · ${batch.scheduleNote}',
                    style: AppTypography.body,
                  ),
                  Text(
                    'Fee: ₹${batch.feeAmount}/month',
                    style: AppTypography.body.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                  Text(
                    'Coach: ${batch.coachName ?? "Unassigned"}',
                    style: AppTypography.caption.copyWith(
                      color: colors.textTertiary,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      final error = notifier.assignCoach(
                        batch.id,
                        'Coach Ramesh',
                      );
                      if (error != null) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text(error)));
                      }
                    },
                    child: const Text('Assign Coach Ramesh (debug)'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text('Enroll a student', style: AppTypography.h2),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              key: const ValueKey('studentNameField'),
              controller: _studentNameController,
              decoration: const InputDecoration(labelText: 'Student name'),
            ),
            SwitchListTile(
              key: const ValueKey('isMinorSwitch'),
              contentPadding: EdgeInsets.zero,
              title: const Text('Minor (requires guardian consent)'),
              value: _isMinor,
              onChanged: (v) => setState(() => _isMinor = v),
            ),
            if (_isMinor) ...[
              TextField(
                key: const ValueKey('guardianNameField'),
                controller: _guardianNameController,
                decoration: const InputDecoration(labelText: 'Guardian name'),
              ),
              CheckboxListTile(
                key: const ValueKey('guardianConsentCheckbox'),
                contentPadding: EdgeInsets.zero,
                title: const Text('Guardian consent given'),
                value: _guardianConsent,
                onChanged: (v) => setState(() => _guardianConsent = v ?? false),
              ),
              Text(
                'Messages to this student route through a guardian-visible channel '
                '(no direct academy-to-minor messaging).',
                style: AppTypography.caption.copyWith(
                  color: colors.textTertiary,
                ),
              ),
            ],
            if (_enrollError != null)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Text(
                  _enrollError!,
                  style: AppTypography.caption.copyWith(color: colors.error),
                ),
              ),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              key: const ValueKey('enrollStudentButton'),
              variant: AppButtonVariant.primary,
              label: 'Enroll',
              fullWidth: true,
              onPressed: _studentNameController.text.trim().isEmpty
                  ? null
                  : () {
                      final error = notifier.enrollStudent(
                        name: _studentNameController.text.trim(),
                        isMinor: _isMinor,
                        guardianName: _isMinor
                            ? _guardianNameController.text.trim()
                            : null,
                        guardianConsentGiven: _guardianConsent,
                        batchId: batch.id,
                      );
                      setState(() {
                        _enrollError = error;
                        if (error == null) {
                          _studentNameController.clear();
                          _guardianNameController.clear();
                          _isMinor = false;
                          _guardianConsent = false;
                        }
                      });
                    },
            ),
            const SizedBox(height: AppSpacing.xl),
            Text('Students & fee ledger', style: AppTypography.h2),
            const SizedBox(height: AppSpacing.sm),
            for (final student in state.studentsFor(batch.id))
              _StudentRow(
                key: ValueKey('studentRow_${student.id}'),
                student: student,
                colors: colors,
              ),
          ],
          const SizedBox(height: AppSpacing.xl),
          Text('Trials', style: AppTypography.h2),
          const SizedBox(height: AppSpacing.sm),
          for (final trial in state.trials)
            Container(
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
                      '${trial.name} (${trial.ageGroup}) · ${trial.registrationsCount} registered',
                      style: AppTypography.body,
                    ),
                  ),
                  TextButton(
                    key: ValueKey('registerTrialButton_${trial.id}'),
                    onPressed: () => notifier.registerForTrial(trial.id),
                    child: const Text('Register (debug)'),
                  ),
                ],
              ),
            ),
          TextField(
            controller: _trialNameController,
            decoration: const InputDecoration(labelText: 'Trial name'),
          ),
          TextField(
            controller: _trialAgeGroupController,
            decoration: const InputDecoration(labelText: 'Age group'),
          ),
          TextButton(
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (picked != null) setState(() => _trialDate = picked);
            },
            child: Text(
              _trialDate == null
                  ? 'Pick date'
                  : '${_trialDate!.day}/${_trialDate!.month}/${_trialDate!.year}',
            ),
          ),
          AppButton(
            key: const ValueKey('publishTrialButton'),
            variant: AppButtonVariant.secondary,
            label: 'Publish trial',
            fullWidth: true,
            onPressed:
                _trialNameController.text.trim().isEmpty || _trialDate == null
                ? null
                : () {
                    notifier.publishTrial(
                      _trialNameController.text.trim(),
                      _trialAgeGroupController.text.trim(),
                      _trialDate!,
                    );
                    _trialNameController.clear();
                    _trialAgeGroupController.clear();
                    setState(() => _trialDate = null);
                  },
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Talent showcase (visible to Team Owners/Organizers)',
            style: AppTypography.h2,
          ),
          const SizedBox(height: AppSpacing.sm),
          if (state.talentShowcaseStudents.isEmpty)
            Text(
              'No students opted in yet.',
              style: AppTypography.body.copyWith(color: colors.textSecondary),
            )
          else
            for (final student in state.talentShowcaseStudents)
              Text(
                student.name,
                style: AppTypography.body.copyWith(color: colors.textPrimary),
              ),
        ],
      ),
    );
  }
}

class _StudentRow extends ConsumerWidget {
  final Student student;
  final AppColors colors;

  const _StudentRow({super.key, required this.student, required this.colors});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(academyProvider.notifier);
    final ledger = ref.watch(academyProvider).ledgerFor(student.id);
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
                  student.name +
                      (student.isMinor
                          ? ' (minor -- guardian: ${student.guardianName})'
                          : ''),
                  style: AppTypography.body.copyWith(color: colors.textPrimary),
                ),
              ),
              Switch(
                key: ValueKey('talentShowcaseSwitch_${student.id}'),
                value: student.talentShowcaseOptIn,
                onChanged: (_) =>
                    notifier.toggleTalentShowcaseOptIn(student.id),
              ),
            ],
          ),
          for (final fee in ledger)
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${fee.monthLabel}: ₹${fee.amount} due ${fee.dueDate.day}/${fee.dueDate.month}',
                    style: AppTypography.caption.copyWith(
                      color: colors.textTertiary,
                    ),
                  ),
                ),
                if (fee.paid)
                  AppTagChip(label: 'Paid', variant: AppTagChipVariant.success)
                else
                  TextButton(
                    key: ValueKey('markFeePaidButton_${fee.id}'),
                    onPressed: () => notifier.markFeePaid(fee.id),
                    child: const Text('Mark paid'),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
