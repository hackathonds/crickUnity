import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_button.dart';
import '../design_system/components/app_form_step_progress.dart';
import '../design_system/components/app_text_field.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'create_match_basics_step_screen.dart';
import 'create_match_provider.dart';

/// DS §7 screen 24, step 3: "Ground&Time(picker w/ availability)." No
/// Ground module exists yet (PRD §7.2's map/listed-ground booking
/// sub-flow) -- ground is free text; date/time uses the platform date
/// and time pickers rather than a real availability-aware picker.
class CreateMatchGroundTimeStepScreen extends ConsumerStatefulWidget {
  final VoidCallback onContinue;

  const CreateMatchGroundTimeStepScreen({super.key, required this.onContinue});

  @override
  ConsumerState<CreateMatchGroundTimeStepScreen> createState() =>
      _CreateMatchGroundTimeStepScreenState();
}

class _CreateMatchGroundTimeStepScreenState
    extends ConsumerState<CreateMatchGroundTimeStepScreen> {
  late final TextEditingController _groundController;

  @override
  void initState() {
    super.initState();
    _groundController = TextEditingController(
      text: ref.read(createMatchProvider).draft.groundName,
    );
  }

  @override
  void dispose() {
    _groundController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime(BuildContext context, DateTime current) async {
    final date = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
    );
    if (time == null || !context.mounted) return;
    ref
        .read(createMatchProvider.notifier)
        .setDateTime(
          DateTime(date.year, date.month, date.day, time.hour, time.minute),
        );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final state = ref.watch(createMatchProvider);
    final notifier = ref.read(createMatchProvider.notifier);
    final draft = state.draft;

    return Scaffold(
      appBar: AppBar(title: const Text('Start a match')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppFormStepProgress(
              stepCount: createMatchStepLabels.length,
              currentStep: 2,
              labels: createMatchStepLabels,
            ),
            const SizedBox(height: AppSpacing.xxl),
            AppTextField(
              key: const ValueKey('groundNameField'),
              label: 'Ground',
              controller: _groundController,
              onChanged: notifier.setGroundName,
            ),
            const SizedBox(height: AppSpacing.md),
            GestureDetector(
              key: const ValueKey('dateTimePickerRow'),
              onTap: () => _pickDateTime(context, draft.dateTime),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  border: Border.all(color: colors.border),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.event, color: colors.textSecondary),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      '${draft.dateTime.day}/${draft.dateTime.month}/'
                      '${draft.dateTime.year} at '
                      '${draft.dateTime.hour.toString().padLeft(2, '0')}:'
                      '${draft.dateTime.minute.toString().padLeft(2, '0')}',
                      style: AppTypography.body.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            AppButton(
              key: const ValueKey('groundTimeContinueButton'),
              variant: AppButtonVariant.primary,
              label: 'Continue',
              fullWidth: true,
              onPressed: draft.groundName.trim().isNotEmpty
                  ? widget.onContinue
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
