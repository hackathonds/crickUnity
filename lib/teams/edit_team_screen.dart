import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_button.dart';
import '../design_system/components/app_dialog.dart';
import '../design_system/components/app_segmented_control.dart';
import '../design_system/components/app_text_field.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'edit_team_provider.dart';
import 'team_models.dart';

/// PRD §6.2: "Owner/Captain edit identity fields ... Manager edits
/// logistics fields only." Identity = name + colors (the two fields
/// whose change PRD calls out as notifying members and entering the
/// change log); logistics = city/ground/format/join policy. No full
/// role/permission model exists yet (that's E3-04), so this screen takes
/// the already-resolved permission as a plain flag rather than a role
/// enum.
class EditTeamScreen extends ConsumerStatefulWidget {
  final bool canEditIdentity;

  const EditTeamScreen({super.key, this.canEditIdentity = true});

  @override
  ConsumerState<EditTeamScreen> createState() => _EditTeamScreenState();
}

class _EditTeamScreenState extends ConsumerState<EditTeamScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _cityController;
  late final TextEditingController _groundController;

  @override
  void initState() {
    super.initState();
    final state = ref.read(editTeamProvider);
    _nameController = TextEditingController(text: state.name);
    _cityController = TextEditingController(text: state.city);
    _groundController = TextEditingController(text: state.homeGround);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    _groundController.dispose();
    super.dispose();
  }

  Future<void> _handleBackAttempt() async {
    final discard = await showAppConfirmDialog(
      context: context,
      title: 'Discard changes?',
      body: "You have unsaved changes. If you leave now, they'll be lost.",
      cancelLabel: 'Cancel',
      confirmLabel: 'Discard',
    );
    if (discard == true) {
      ref.read(editTeamProvider.notifier).discard();
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final state = ref.watch(editTeamProvider);
    final notifier = ref.read(editTeamProvider.notifier);

    Widget sectionLabel(String text) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm, top: AppSpacing.lg),
      child: Text(
        text,
        style: AppTypography.label.copyWith(color: colors.textTertiary),
      ),
    );

    return PopScope(
      canPop: !state.isDirty,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBackAttempt();
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Edit team')),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.canEditIdentity) ...[
                        sectionLabel('Identity'),
                        AppTextField(
                          key: const ValueKey('editTeamNameField'),
                          label: 'Team name',
                          controller: _nameController,
                          onChanged: notifier.setName,
                        ),
                        if (state.formerNameActive()) ...[
                          const SizedBox(height: AppSpacing.sm),
                          Container(
                            key: const ValueKey('editTeamFormerNameChip'),
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm,
                            ),
                            decoration: BoxDecoration(
                              color: colors.surfaceAlt,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'Formerly known as "${state.baseline.formerName}"',
                              style: AppTypography.caption.copyWith(
                                color: colors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                        sectionLabel('Colors'),
                        Row(
                          key: const ValueKey('editTeamColorSwatches'),
                          children: [
                            for (final swatch in colors.chartCategorical) ...[
                              GestureDetector(
                                key: ValueKey(
                                  'editTeamColorSwatch_${swatch.toString()}',
                                ),
                                onTap: () => notifier.setPrimaryColor(swatch),
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: swatch,
                                    shape: BoxShape.circle,
                                    border: swatch == state.primaryColor
                                        ? Border.all(
                                            color: colors.textPrimary,
                                            width: 2,
                                          )
                                        : null,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                            ],
                          ],
                        ),
                      ],
                      sectionLabel('Location'),
                      AppTextField(
                        key: const ValueKey('editTeamCityField'),
                        label: 'City',
                        controller: _cityController,
                        onChanged: notifier.setCity,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(
                        key: const ValueKey('editTeamGroundField'),
                        label: 'Home ground (optional)',
                        controller: _groundController,
                        onChanged: notifier.setHomeGround,
                      ),
                      sectionLabel('Format focus'),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          for (final format in TeamFormat.values)
                            AppChipActionButton(
                              key: ValueKey(
                                'editTeamFormatOption_${format.name}',
                              ),
                              label: teamFormatLabels[format]!,
                              selected: state.formatFocus.contains(format),
                              onPressed: () => notifier.toggleFormat(format),
                            ),
                        ],
                      ),
                      sectionLabel('Join policy'),
                      AppSegmentedControl<TeamJoinPolicy>(
                        key: const ValueKey('editTeamJoinPolicyControl'),
                        options: TeamJoinPolicy.values,
                        value: state.joinPolicy,
                        onChanged: notifier.setJoinPolicy,
                        labelBuilder: (policy) => teamJoinPolicyLabels[policy]!,
                      ),
                    ],
                  ),
                ),
              ),
              if (state.isDirty)
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: AppButton(
                    key: const ValueKey('editTeamSaveButton'),
                    variant: AppButtonVariant.primary,
                    label: 'Save',
                    fullWidth: true,
                    onPressed: state.canSave
                        ? () {
                            notifier.save();
                            Navigator.of(context).pop();
                          }
                        : null,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
