import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_button.dart';
import '../design_system/components/app_state_scaffolds.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import '../matches/gallery_models.dart';
import '../matches/gallery_provider.dart';
import '../matches/scoring_provider.dart';
import 'composer_screen.dart';
import 'reel_models.dart';
import 'reels_provider.dart';

/// PRD §12.3: "Reels: <=90s vertical, cricket audio library, remix-
/// allowed toggle, auto-suggested from match highlight clips ('Turn
/// your 3 sixes into a reel?')." The auto-suggest banner genuinely
/// reuses lib/matches/gallery_models.dart's autoCutSuggestions() (built
/// for E4-14's per-match Highlights builder) rather than a second
/// mocked clip-suggestion system -- same match footage, a different
/// (social, non-captain-gated) publish path.
class ReelsScreen extends ConsumerWidget {
  const ReelsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final reels = ref.watch(reelsProvider).reels;
    final gallery = ref.watch(galleryProvider);
    final innings = ref.watch(inningsProvider);
    final suggestions = autoCutSuggestions(gallery, innings);
    final sixCount = suggestions
        .where(
          (item) =>
              item.pinnedBallIndex != null &&
              innings.deliveries[item.pinnedBallIndex!].battingRuns == 6,
        )
        .length;

    return Scaffold(
      appBar: AppBar(title: const Text('Reels')),
      floatingActionButton: FloatingActionButton(
        key: const ValueKey('createReelFab'),
        onPressed: () => _showCreateReelSheet(context, ref, null),
        child: const Icon(Icons.add),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          if (sixCount > 0)
            Container(
              key: const ValueKey('autoSuggestReelBanner'),
              margin: const EdgeInsets.only(bottom: AppSpacing.lg),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: colors.coin.withValues(alpha: 0.12),
                border: Border.all(color: colors.coin),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Turn your $sixCount six${sixCount == 1 ? '' : 'es'} into a reel?',
                      style: AppTypography.body.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                  AppButton(
                    key: const ValueKey('createSuggestedReelButton'),
                    variant: AppButtonVariant.primary,
                    label: 'Create',
                    onPressed: () => _showCreateReelSheet(
                      context,
                      ref,
                      '$sixCount six${sixCount == 1 ? '' : 'es'}',
                    ),
                  ),
                ],
              ),
            ),
          if (reels.isEmpty)
            AppEmptyState(
              message: 'No reels yet -- publish one from a highlight clip.',
              primaryLabel: 'Create a reel',
              onPrimary: () => _showCreateReelSheet(context, ref, null),
            )
          else
            for (final reel in reels)
              Container(
                key: ValueKey('reelCard_${reel.id}'),
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
                      reel.authorName,
                      style: AppTypography.subtitle.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${reel.durationSeconds}s · ${reel.audioTrack}'
                      '${reel.sourceClipLabel != null ? " · ${reel.sourceClipLabel}" : ""}',
                      style: AppTypography.caption.copyWith(
                        color: colors.textTertiary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      reel.remixAllowed ? 'Remix allowed' : 'Remix off',
                      style: AppTypography.caption.copyWith(
                        color: reel.remixAllowed
                            ? colors.success
                            : colors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }

  void _showCreateReelSheet(
    BuildContext context,
    WidgetRef ref,
    String? sourceClipLabel,
  ) {
    var duration = 15;
    var audio = mockCricketAudioTracks.first;
    var remixAllowed = true;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
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
              Text('New reel', style: AppTypography.h2),
              const SizedBox(height: AppSpacing.md),
              Text('Duration: $duration s (max $maxReelDurationSeconds)'),
              Slider(
                value: duration.toDouble(),
                min: 5,
                max: maxReelDurationSeconds.toDouble(),
                divisions: 17,
                onChanged: (v) => setSheetState(() => duration = v.round()),
              ),
              Wrap(
                spacing: AppSpacing.sm,
                children: [
                  for (final track in mockCricketAudioTracks)
                    ChoiceChip(
                      label: Text(track),
                      selected: audio == track,
                      onSelected: (_) => setSheetState(() => audio = track),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              SwitchListTile(
                key: const ValueKey('remixAllowedToggle'),
                contentPadding: EdgeInsets.zero,
                title: const Text('Allow remixes'),
                value: remixAllowed,
                onChanged: (v) => setSheetState(() => remixAllowed = v),
              ),
              const SizedBox(height: AppSpacing.sm),
              AppButton(
                key: const ValueKey('publishSocialReelButton'),
                variant: AppButtonVariant.primary,
                label: 'Publish reel',
                fullWidth: true,
                onPressed: () {
                  ref
                      .read(reelsProvider.notifier)
                      .publishReel(
                        authorName: composerViewerName,
                        durationSeconds: duration,
                        audioTrack: audio,
                        remixAllowed: remixAllowed,
                        sourceClipLabel: sourceClipLabel,
                      );
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
