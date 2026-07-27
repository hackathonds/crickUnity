import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_button.dart';
import '../design_system/components/app_text_field.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import '../social/composer_screen.dart';
import 'challenge_models.dart';
import 'challenges_provider.dart';

/// PRD §14 UX matrix: "Challenges Hub / Challenge Detail -- join &
/// track | join / nudge / claim | progress bars, H2H view."
class ChallengesHubScreen extends ConsumerWidget {
  const ChallengesHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final state = ref.watch(challengesProvider);

    final globalChallenges = state.challenges
        .where((c) => c.type == ChallengeType.monthlyGlobal)
        .toList();
    final clubChallenges = state.challenges
        .where((c) => c.type == ChallengeType.club)
        .toList();
    final h2hChallenges = state.challenges
        .where((c) => c.type == ChallengeType.friendH2H)
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Challenges')),
      floatingActionButton: FloatingActionButton(
        key: const ValueKey('createH2hChallengeFab'),
        onPressed: () => _showCreateH2hSheet(context, ref),
        child: const Icon(Icons.add),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          if (state.overtakenLog.isNotEmpty)
            Container(
              key: const ValueKey('overtakenNotificationBanner'),
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: colors.coin.withValues(alpha: 0.12),
                border: Border.all(color: colors.coin),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                state.overtakenLog.last,
                style: AppTypography.body.copyWith(color: colors.textPrimary),
              ),
            ),
          Text(
            'Monthly Global',
            style: AppTypography.label.copyWith(color: colors.textTertiary),
          ),
          const SizedBox(height: AppSpacing.xs),
          for (final challenge in globalChallenges)
            _ChallengeCard(challenge: challenge, colors: colors, ref: ref),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            'Club Challenges',
            style: AppTypography.label.copyWith(color: colors.textTertiary),
          ),
          const SizedBox(height: AppSpacing.xs),
          for (final challenge in clubChallenges)
            _ChallengeCard(challenge: challenge, colors: colors, ref: ref),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            'Friend H2H',
            style: AppTypography.label.copyWith(color: colors.textTertiary),
          ),
          const SizedBox(height: AppSpacing.xs),
          if (h2hChallenges.isEmpty)
            Text(
              'No active head-to-heads.',
              style: AppTypography.body.copyWith(color: colors.textSecondary),
            )
          else
            for (final challenge in h2hChallenges)
              _H2hCard(challenge: challenge, colors: colors, ref: ref),
        ],
      ),
    );
  }

  void _showCreateH2hSheet(BuildContext context, WidgetRef ref) {
    final opponentController = TextEditingController(text: 'Kabir Singh');
    final targetController = TextEditingController(text: '100');
    final stakeController = TextEditingController(text: '20');

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
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
            Text('New head-to-head', style: AppTypography.h2),
            const SizedBox(height: AppSpacing.md),
            AppTextField(label: 'Opponent', controller: opponentController),
            const SizedBox(height: AppSpacing.sm),
            AppTextField(
              label: 'Target runs',
              controller: targetController,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppTextField(
              label: 'Stake coins (max $maxChallengeStakeCoins, optional)',
              controller: stakeController,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              key: const ValueKey('submitH2hChallengeButton'),
              variant: AppButtonVariant.primary,
              label: 'Start challenge',
              fullWidth: true,
              onPressed: () {
                final reason = ref
                    .read(challengesProvider.notifier)
                    .joinFriendChallenge(
                      title:
                          '$composerViewerName vs ${opponentController.text.trim()}',
                      metricLabel: 'Runs',
                      target: int.tryParse(targetController.text.trim()) ?? 100,
                      opponentName: opponentController.text.trim(),
                      stakeCoins: int.tryParse(stakeController.text.trim()),
                    );
                Navigator.of(context).pop();
                if (reason != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Not enough coins to stake')),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  final Challenge challenge;
  final AppColors colors;
  final WidgetRef ref;

  const _ChallengeCard({
    required this.challenge,
    required this.colors,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(challengesProvider.notifier);
    final me = challenge.participantNamed(composerViewerName);

    return Container(
      key: ValueKey('challengeCard_${challenge.id}'),
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            challenge.title,
            style: AppTypography.body.copyWith(color: colors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.xs),
          if (me == null)
            AppButton(
              key: ValueKey('joinChallengeButton_${challenge.id}'),
              variant: AppButtonVariant.secondary,
              label: 'Join',
              onPressed: () => notifier.joinChallenge(challenge.id),
            )
          else ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (me.progress / challenge.target).clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: colors.border,
                color: colors.coin,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${me.progress}/${challenge.target} ${challenge.metricLabel}'
              '${me.claimed ? " -- Finisher badge claimed!" : ""}',
              style: AppTypography.caption.copyWith(color: colors.textTertiary),
            ),
            if (!me.claimed)
              AppButton(
                key: ValueKey('simulateProgressButton_${challenge.id}'),
                variant: AppButtonVariant.tertiary,
                label: 'Simulate +20 (debug)',
                onPressed: () => notifier.recordProgress(
                  challenge.id,
                  composerViewerName,
                  20,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _H2hCard extends StatelessWidget {
  final Challenge challenge;
  final AppColors colors;
  final WidgetRef ref;

  const _H2hCard({
    required this.challenge,
    required this.colors,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(challengesProvider.notifier);

    return Container(
      key: ValueKey('h2hCard_${challenge.id}'),
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            challenge.title,
            style: AppTypography.body.copyWith(color: colors.textPrimary),
          ),
          if (challenge.stakeCoins != null)
            Text(
              'Stake: ${challenge.stakeCoins} coins each',
              style: AppTypography.caption.copyWith(color: colors.coin),
            ),
          const SizedBox(height: AppSpacing.xs),
          for (final p in challenge.participants) ...[
            Row(
              children: [
                SizedBox(width: 90, child: Text(p.name)),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (p.progress / challenge.target).clamp(0.0, 1.0),
                      minHeight: 8,
                      backgroundColor: colors.border,
                      color: p.name == challenge.currentLeader?.name
                          ? colors.success
                          : colors.textTertiary,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Text('${p.progress}/${challenge.target}'),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
          Wrap(
            spacing: AppSpacing.xs,
            children: [
              AppButton(
                key: ValueKey('h2hSimulateProgressButton_${challenge.id}'),
                variant: AppButtonVariant.tertiary,
                label: 'My +15 (debug)',
                onPressed: () => notifier.recordProgress(
                  challenge.id,
                  composerViewerName,
                  15,
                ),
              ),
              for (final sticker in challengeQuickChatStickers.take(2))
                ActionChip(
                  label: Text(sticker),
                  onPressed: () => ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Sent: $sticker'))),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
