import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_bottom_sheet.dart';
import '../design_system/components/app_button.dart';
import '../design_system/components/app_text_field.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'match_models.dart';
import 'matches_provider.dart';

/// PRD §7.1: "Creating notifies opponent captain -> Accept/Propose
/// changes (diff view)/Decline." This is the receiving captain's
/// screen.
class MatchOpponentDecisionScreen extends ConsumerWidget {
  final String matchId;

  const MatchOpponentDecisionScreen({super.key, required this.matchId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final match = ref
        .watch(matchesProvider)
        .matches
        .firstWhere((m) => m.id == matchId);
    final draft = match.draft;
    final isChallenge = draft.matchType == MatchType.challenge;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isChallenge
              ? 'Challenge from ${match.composerTeamName}'
              : 'Match invite from ${match.composerTeamName}',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // AC amendment #3 (PRD §7.1): "'Challenge a friend/team'
            // entry creates a challenge card the receiver accepts into
            // the wizard."
            if (isChallenge)
              Container(
                key: const ValueKey('challengeCardBanner'),
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${match.composerTeamName} has challenged you to a '
                  'match! Accept to set up the ground and time together.',
                  style: AppTypography.body.copyWith(color: colors.primary),
                ),
              ),
            Text(
              draft.format.label,
              style: AppTypography.h2.copyWith(color: colors.textPrimary),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '${draft.groundName} · ${draft.dateTime.day}/'
              '${draft.dateTime.month}/${draft.dateTime.year} '
              '${draft.dateTime.hour.toString().padLeft(2, '0')}:'
              '${draft.dateTime.minute.toString().padLeft(2, '0')}',
              style: AppTypography.body.copyWith(color: colors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.xxl),
            if (match.status == MatchStatus.pendingOpponent) ...[
              AppButton(
                key: const ValueKey('acceptMatchButton'),
                variant: AppButtonVariant.primary,
                label: isChallenge ? 'Accept & set up match' : 'Accept',
                fullWidth: true,
                onPressed: () => isChallenge
                    ? _showAcceptChallengeSheet(context, draft)
                    : ref.read(matchesProvider.notifier).acceptMatch(matchId),
              ),
              const SizedBox(height: AppSpacing.sm),
              AppButton(
                key: const ValueKey('proposeChangesButton'),
                variant: AppButtonVariant.secondary,
                label: 'Propose changes',
                fullWidth: true,
                onPressed: () => _showProposeChangesSheet(context, draft),
              ),
              const SizedBox(height: AppSpacing.sm),
              AppButton(
                key: const ValueKey('declineMatchButton'),
                variant: AppButtonVariant.destructive,
                label: 'Decline',
                fullWidth: true,
                onPressed: () =>
                    ref.read(matchesProvider.notifier).declineMatch(matchId),
              ),
            ] else
              Text(
                key: const ValueKey('opponentDecisionStatus'),
                switch (match.status) {
                  MatchStatus.accepted => 'You accepted this match.',
                  MatchStatus.declined => 'You declined this match.',
                  MatchStatus.changesProposedToComposer =>
                    'Waiting on ${match.composerTeamName} to review your '
                        'proposed changes.',
                  MatchStatus.pendingOpponent => '',
                  MatchStatus.cancelled => 'This match was cancelled.',
                },
                style: AppTypography.body.copyWith(color: colors.textPrimary),
              ),
          ],
        ),
      ),
    );
  }

  void _showProposeChangesSheet(BuildContext context, MatchDraft draft) {
    showAppBottomSheet<void>(
      context: context,
      title: 'Propose changes',
      contentBuilder: (context) => _ProposeChangesContent(
        matchId: matchId,
        currentGroundName: draft.groundName,
        currentDateTime: draft.dateTime,
      ),
    );
  }

  void _showAcceptChallengeSheet(BuildContext context, MatchDraft draft) {
    showAppBottomSheet<void>(
      context: context,
      title: 'Set up the match',
      contentBuilder: (context) => _AcceptChallengeContent(
        matchId: matchId,
        currentGroundName: draft.groundName,
        currentDateTime: draft.dateTime,
      ),
    );
  }
}

/// AC amendment #3: the receiver "accepts into the wizard" -- ground
/// and time are filled in as part of accepting, in one step, rather
/// than the two-step propose/re-accept cycle Friendly disagreements
/// use.
class _AcceptChallengeContent extends ConsumerStatefulWidget {
  final String matchId;
  final String currentGroundName;
  final DateTime currentDateTime;

  const _AcceptChallengeContent({
    required this.matchId,
    required this.currentGroundName,
    required this.currentDateTime,
  });

  @override
  ConsumerState<_AcceptChallengeContent> createState() =>
      _AcceptChallengeContentState();
}

class _AcceptChallengeContentState
    extends ConsumerState<_AcceptChallengeContent> {
  late final TextEditingController _groundController;
  late DateTime _dateTime;

  @override
  void initState() {
    super.initState();
    _groundController = TextEditingController(text: widget.currentGroundName);
    _dateTime = widget.currentDateTime;
  }

  @override
  void dispose() {
    _groundController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dateTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dateTime),
    );
    if (time == null) return;
    setState(() {
      _dateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
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
          AppTextField(
            key: const ValueKey('acceptChallengeGroundField'),
            label: 'Ground',
            controller: _groundController,
          ),
          const SizedBox(height: AppSpacing.md),
          GestureDetector(
            key: const ValueKey('acceptChallengeDateTimeRow'),
            onTap: () => _pickDateTime(context),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                border: Border.all(color: colors.border),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${_dateTime.day}/${_dateTime.month}/${_dateTime.year} at '
                '${_dateTime.hour.toString().padLeft(2, '0')}:'
                '${_dateTime.minute.toString().padLeft(2, '0')}',
                style: AppTypography.body.copyWith(color: colors.textPrimary),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            key: const ValueKey('confirmAcceptChallengeButton'),
            variant: AppButtonVariant.primary,
            label: 'Confirm & accept',
            fullWidth: true,
            onPressed: () {
              ref
                  .read(matchesProvider.notifier)
                  .acceptChallengeWithDetails(
                    widget.matchId,
                    groundName: _groundController.text.trim(),
                    dateTime: _dateTime,
                  );
              Navigator.of(context).pop();
            },
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

class _ProposeChangesContent extends ConsumerStatefulWidget {
  final String matchId;
  final String currentGroundName;
  final DateTime currentDateTime;

  const _ProposeChangesContent({
    required this.matchId,
    required this.currentGroundName,
    required this.currentDateTime,
  });

  @override
  ConsumerState<_ProposeChangesContent> createState() =>
      _ProposeChangesContentState();
}

class _ProposeChangesContentState
    extends ConsumerState<_ProposeChangesContent> {
  late final TextEditingController _groundController;
  late DateTime _dateTime;

  @override
  void initState() {
    super.initState();
    _groundController = TextEditingController(text: widget.currentGroundName);
    _dateTime = widget.currentDateTime;
  }

  @override
  void dispose() {
    _groundController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dateTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dateTime),
    );
    if (time == null) return;
    setState(() {
      _dateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
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
          AppTextField(
            key: const ValueKey('proposedGroundField'),
            label: 'Ground',
            controller: _groundController,
          ),
          const SizedBox(height: AppSpacing.md),
          GestureDetector(
            key: const ValueKey('proposedDateTimeRow'),
            onTap: () => _pickDateTime(context),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                border: Border.all(color: colors.border),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${_dateTime.day}/${_dateTime.month}/${_dateTime.year} at '
                '${_dateTime.hour.toString().padLeft(2, '0')}:'
                '${_dateTime.minute.toString().padLeft(2, '0')}',
                style: AppTypography.body.copyWith(color: colors.textPrimary),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            key: const ValueKey('submitProposedChangesButton'),
            variant: AppButtonVariant.primary,
            label: 'Send proposed changes',
            fullWidth: true,
            onPressed: () {
              ref
                  .read(matchesProvider.notifier)
                  .proposeChanges(
                    widget.matchId,
                    groundName: _groundController.text.trim(),
                    dateTime: _dateTime,
                  );
              Navigator.of(context).pop();
            },
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}
