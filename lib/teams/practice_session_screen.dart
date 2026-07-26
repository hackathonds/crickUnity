import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_button.dart';
import '../design_system/components/app_tag_chip.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'availability_matrix_models.dart';
import 'practice_session_models.dart';
import 'practice_session_provider.dart';

/// DS §7 screen 15 (Practice Session detail): "Hero: template name +
/// focus tags; drill list rows (name·prescription·XP chip); RSVP chips;
/// on-site window shows [Check-in QR] primary; roll-call mode (coach):
/// roster toggles."
class PracticeSessionScreen extends ConsumerWidget {
  final String viewerName;
  final bool isCoach;
  final DateTime Function() now;

  const PracticeSessionScreen({
    super.key,
    required this.viewerName,
    this.isCoach = false,
    this.now = DateTime.now,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final state = ref.watch(practiceSessionProvider);
    final notifier = ref.read(practiceSessionProvider.notifier);
    final session = state.session;

    return Scaffold(
      appBar: AppBar(title: const Text('Practice session')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(
            session.venueName,
            style: AppTypography.h2.copyWith(color: colors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              for (final tag in session.focusTags) AppTagChip(label: tag),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            'Drills',
            style: AppTypography.label.copyWith(color: colors.textTertiary),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final drill in session.drills)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${drill.name} · ${drill.prescription}',
                      style: AppTypography.body.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                  AppTagChip(label: '+${drill.xp} XP'),
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            'Your RSVP',
            style: AppTypography.label.copyWith(color: colors.textTertiary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final response in AvailabilityResponse.values)
                AppChipActionButton(
                  key: ValueKey('rsvpOption_${response.name}'),
                  label: availabilityResponseLabels[response]!,
                  selected: session.rsvps[viewerName] == response,
                  onPressed: () => notifier.rsvp(viewerName, response),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),
          _CheckInSection(
            viewerName: viewerName,
            now: now,
            checkedIn: session.checkedIn.contains(viewerName),
          ),
          if (isCoach) ...[
            const SizedBox(height: AppSpacing.xxl),
            Text(
              'Roll-call',
              style: AppTypography.label.copyWith(color: colors.textTertiary),
            ),
            const SizedBox(height: AppSpacing.sm),
            for (final member in session.roster)
              _RollCallRow(memberName: member, now: now),
            const SizedBox(height: AppSpacing.lg),
            if (!session.ended)
              AppButton(
                key: const ValueKey('endSessionButton'),
                variant: AppButtonVariant.secondary,
                label: 'End session',
                fullWidth: true,
                onPressed: notifier.endSession,
              ),
          ],
          if (session.ended) ...[
            const SizedBox(height: AppSpacing.xxl),
            _RecapCard(session: session, isCoach: isCoach),
          ],
        ],
      ),
    );
  }
}

class _CheckInSection extends ConsumerWidget {
  final String viewerName;
  final DateTime Function() now;
  final bool checkedIn;

  const _CheckInSection({
    required this.viewerName,
    required this.now,
    required this.checkedIn,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final notifier = ref.read(practiceSessionProvider.notifier);
    final canCheckIn = notifier.canCheckIn(now: now);

    if (checkedIn) {
      return Text(
        key: const ValueKey('checkedInLabel'),
        "You're checked in.",
        style: AppTypography.body.copyWith(color: colors.success),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppButton(
          key: const ValueKey('checkInButton'),
          variant: AppButtonVariant.primary,
          label: 'Check in',
          fullWidth: true,
          onPressed: canCheckIn
              ? () => notifier.checkIn(viewerName, now: now)
              : null,
        ),
        if (!canCheckIn) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Check-in opens $checkInWindowHours hour before the session '
            'and stays open until $checkInWindowHours hour after.',
            key: const ValueKey('checkInWindowNote'),
            style: AppTypography.caption.copyWith(color: colors.textTertiary),
          ),
        ],
      ],
    );
  }
}

class _RollCallRow extends ConsumerWidget {
  final String memberName;
  final DateTime Function() now;

  const _RollCallRow({required this.memberName, required this.now});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final state = ref.watch(practiceSessionProvider);
    final notifier = ref.read(practiceSessionProvider.notifier);
    final checkedIn = state.session.checkedIn.contains(memberName);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Text(
              memberName,
              style: AppTypography.body.copyWith(color: colors.textPrimary),
            ),
          ),
          Switch(
            key: ValueKey('rollCallToggle_$memberName'),
            value: checkedIn,
            onChanged: checkedIn
                ? null
                : (_) => notifier.checkIn(memberName, now: now),
          ),
        ],
      ),
    );
  }
}

class _RecapCard extends ConsumerWidget {
  final PracticeSession session;
  final bool isCoach;

  const _RecapCard({required this.session, required this.isCoach});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final notifier = ref.read(practiceSessionProvider.notifier);

    return Container(
      key: const ValueKey('sessionRecapCard'),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Session recap',
            style: AppTypography.subtitle.copyWith(color: colors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${session.checkedIn.length} attended · ${session.drills.length} '
            'drills run',
            style: AppTypography.body.copyWith(color: colors.textSecondary),
          ),
          if (session.noShows.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              'No-shows',
              style: AppTypography.label.copyWith(color: colors.textTertiary),
            ),
            for (final noShow in session.noShows)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        noShow.excused
                            ? '${noShow.memberName} (excused)'
                            : noShow.memberName,
                        style: AppTypography.body.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                    if (isCoach && !noShow.excused)
                      AppButton(
                        key: ValueKey('excuseNoShow_${noShow.memberName}'),
                        variant: AppButtonVariant.tertiary,
                        label: 'Excuse',
                        onPressed: () => notifier.excuseNoShow(
                          noShow.memberName,
                          reason: 'Excused by coach',
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}
