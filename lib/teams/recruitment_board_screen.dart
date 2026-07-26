import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_bottom_sheet.dart';
import '../design_system/components/app_button.dart';
import '../design_system/components/app_dialog.dart';
import '../design_system/components/app_segmented_control.dart';
import '../design_system/components/app_text_field.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import '../onboarding/profile_wizard_provider.dart';
import 'recruitment_models.dart';
import 'recruitment_provider.dart';
import 'team_member_models.dart';

const Map<PrimaryRole, String> _roleLabels = {
  PrimaryRole.batter: 'Batter',
  PrimaryRole.bowler: 'Bowler',
  PrimaryRole.allRounder: 'All-rounder',
  PrimaryRole.wicketKeeper: 'Wicket-keeper',
};

enum _Tab { listings, pipeline }

/// PRD §6.25 / DS §11.6 (Recruitment Board): "post composer (role-needed
/// chips, day/time, area) -> listing cards; applicant pipeline screen:
/// kanban-lite horizontal stages ... applicant cards drag between
/// stages with status-notification confirm." The Pipeline tab and the
/// Post-listing action are structurally absent for viewers outside
/// [recruitmentManagerRoles] -- matching the tab/FAB-gating pattern used
/// throughout Epic E3 (Team Home's Money/Manage tabs, Announcements'
/// composer FAB, Documents' Upload FAB).
class RecruitmentBoardScreen extends ConsumerStatefulWidget {
  final String viewerName;
  final TeamMemberRole viewerRole;
  final DateTime Function() now;

  const RecruitmentBoardScreen({
    super.key,
    required this.viewerName,
    required this.viewerRole,
    this.now = DateTime.now,
  });

  @override
  ConsumerState<RecruitmentBoardScreen> createState() =>
      _RecruitmentBoardScreenState();
}

class _RecruitmentBoardScreenState
    extends ConsumerState<RecruitmentBoardScreen> {
  _Tab _tab = _Tab.listings;

  @override
  Widget build(BuildContext context) {
    final canManage = recruitmentManagerRoles.contains(widget.viewerRole);

    return Scaffold(
      appBar: AppBar(title: const Text('Recruitment board')),
      floatingActionButton: canManage
          ? FloatingActionButton(
              key: const ValueKey('postListingFab'),
              onPressed: () => _showComposerSheet(context),
              child: const Icon(Icons.add),
            )
          : null,
      body: Column(
        children: [
          if (canManage)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: AppSegmentedControl<_Tab>(
                key: const ValueKey('recruitmentTabControl'),
                options: _Tab.values,
                value: _tab,
                onChanged: (tab) => setState(() => _tab = tab),
                labelBuilder: (tab) => switch (tab) {
                  _Tab.listings => 'Listings',
                  _Tab.pipeline => 'Pipeline',
                },
              ),
            ),
          Expanded(
            child: canManage && _tab == _Tab.pipeline
                ? const _PipelineView()
                : _ListingsView(
                    viewerName: widget.viewerName,
                    canManage: canManage,
                    now: widget.now,
                  ),
          ),
        ],
      ),
    );
  }

  void _showComposerSheet(BuildContext context) {
    showAppBottomSheet<void>(
      context: context,
      title: 'Post a listing',
      contentBuilder: (context) =>
          _ComposerContent(actingRole: widget.viewerRole),
    );
  }
}

class _ListingsView extends ConsumerWidget {
  final String viewerName;
  final bool canManage;
  final DateTime Function() now;

  const _ListingsView({
    required this.viewerName,
    required this.canManage,
    required this.now,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final state = ref.watch(recruitmentBoardProvider);
    final notifier = ref.read(recruitmentBoardProvider.notifier);

    if (state.listings.isEmpty) {
      return Center(
        child: Text(
          'No open listings.',
          style: AppTypography.body.copyWith(color: colors.textSecondary),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: state.listings.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final listing = state.listings[index];
        final expired = listing.isExpired(now: now);
        final applicantCount = state.applicants
            .where((a) => a.listingId == listing.id)
            .length;
        final alreadyApplied = state.applicants.any(
          (a) => a.listingId == listing.id && a.applicantName == viewerName,
        );

        return Container(
          key: ValueKey('listingCard_${listing.id}'),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border.all(color: colors.border),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: AppSpacing.xs,
                      children: [
                        Chip(label: Text(_roleLabels[listing.roleNeeded]!)),
                        if (expired)
                          Chip(
                            key: const ValueKey('expiredBadge'),
                            label: const Text('Expired'),
                            backgroundColor: colors.disabledBg,
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${listing.dayTime} · ${listing.area}',
                      style: AppTypography.body.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                    Text(
                      canManage
                          ? '$applicantCount applicant'
                                '${applicantCount == 1 ? '' : 's'}'
                          : 'Posted by ${listing.teamName}',
                      style: AppTypography.caption.copyWith(
                        color: colors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              if (!canManage)
                AppButton(
                  key: ValueKey('applyButton_${listing.id}'),
                  variant: AppButtonVariant.primary,
                  label: alreadyApplied ? 'Applied' : 'Apply',
                  onPressed: (expired || alreadyApplied)
                      ? null
                      : () => notifier.apply(
                          listingId: listing.id,
                          applicantName: viewerName,
                        ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ComposerContent extends ConsumerStatefulWidget {
  final TeamMemberRole actingRole;

  const _ComposerContent({required this.actingRole});

  @override
  ConsumerState<_ComposerContent> createState() => _ComposerContentState();
}

class _ComposerContentState extends ConsumerState<_ComposerContent> {
  PrimaryRole _role = PrimaryRole.bowler;
  final _dayTimeController = TextEditingController();
  final _areaController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _dayTimeController.dispose();
    _areaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Role needed',
            style: AppTypography.label.copyWith(color: colors.textTertiary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            children: [
              for (final role in PrimaryRole.values)
                ChoiceChip(
                  key: ValueKey('roleChip_${role.name}'),
                  label: Text(_roleLabels[role]!),
                  selected: _role == role,
                  onSelected: (_) => setState(() => _role = role),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            key: const ValueKey('listingDayTimeField'),
            label: 'Day/time',
            controller: _dayTimeController,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            key: const ValueKey('listingAreaField'),
            label: 'Area',
            controller: _areaController,
          ),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              _error!,
              key: const ValueKey('listingComposerError'),
              style: AppTypography.caption.copyWith(color: colors.error),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            key: const ValueKey('postListingButton'),
            variant: AppButtonVariant.primary,
            label: 'Post listing',
            fullWidth: true,
            onPressed: () {
              final result = ref
                  .read(recruitmentBoardProvider.notifier)
                  .postListing(
                    teamName: 'Riverside Strikers',
                    roleNeeded: _role,
                    dayTime: _dayTimeController.text,
                    area: _areaController.text,
                    actingRole: widget.actingRole,
                  );
              if (result.succeeded) {
                Navigator.of(context).pop();
              } else {
                setState(() => _error = result.error);
              }
            },
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

class _PipelineView extends ConsumerWidget {
  const _PipelineView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(recruitmentBoardProvider);
    final actingRole = TeamMemberRole.captain;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final stage in applicantStageOrder)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.md),
              child: _PipelineColumn(
                stage: stage,
                applicants: state.applicants
                    .where((a) => a.stage == stage)
                    .toList(),
                actingRole: actingRole,
              ),
            ),
        ],
      ),
    );
  }
}

class _PipelineColumn extends ConsumerWidget {
  final ApplicantStage stage;
  final List<Applicant> applicants;
  final TeamMemberRole actingRole;

  const _PipelineColumn({
    required this.stage,
    required this.applicants,
    required this.actingRole,
  });

  Future<void> _handleDrop(
    BuildContext context,
    WidgetRef ref,
    Applicant applicant,
  ) async {
    if (applicant.stage == stage) return;
    final confirmed = await showAppConfirmDialog(
      context: context,
      title: 'Move ${applicant.applicantName}?',
      body:
          'Move to "${applicantStageLabels[stage]}"? '
          "They'll be notified of the status change.",
      confirmLabel: 'Move',
    );
    if (confirmed == true) {
      ref
          .read(recruitmentBoardProvider.notifier)
          .moveStage(
            applicantId: applicant.id,
            newStage: stage,
            actingRole: actingRole,
          );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return DragTarget<Applicant>(
      onWillAcceptWithDetails: (details) => details.data.stage != stage,
      onAcceptWithDetails: (details) => _handleDrop(context, ref, details.data),
      builder: (context, candidateData, rejectedData) {
        return Container(
          key: ValueKey('pipelineColumn_${stage.name}'),
          width: 160,
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: candidateData.isNotEmpty
                ? colors.primary.withValues(alpha: 0.08)
                : colors.surfaceAlt,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                applicantStageLabels[stage]!,
                style: AppTypography.label.copyWith(color: colors.textTertiary),
              ),
              const SizedBox(height: AppSpacing.sm),
              for (final applicant in applicants)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Draggable<Applicant>(
                    key: ValueKey('applicantCard_${applicant.id}'),
                    data: applicant,
                    onDragStarted: () => HapticFeedback.lightImpact(),
                    feedback: Material(
                      color: Colors.transparent,
                      child: _ApplicantCard(applicant: applicant),
                    ),
                    childWhenDragging: Opacity(
                      opacity: 0.3,
                      child: _ApplicantCard(applicant: applicant),
                    ),
                    child: _ApplicantCard(applicant: applicant),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ApplicantCard extends StatelessWidget {
  final Applicant applicant;

  const _ApplicantCard({required this.applicant});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        applicant.applicantName,
        style: AppTypography.caption.copyWith(color: colors.textPrimary),
      ),
    );
  }
}
