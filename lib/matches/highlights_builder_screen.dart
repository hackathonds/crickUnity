import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_button.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'gallery_models.dart';
import 'gallery_provider.dart';
import 'scoring_provider.dart';

/// DS §7 screen 33: "Highlights builder: clip rail, drag-reorder,
/// [Publish reel] primary; auto-cut chips labeled by moment." PRD
/// §7.15: "auto-compile into a Highlights reel (wickets/boundaries
/// ordered) that the captain can publish." Publish is a structural
/// guard -- the button is never built for a non-captain viewer, not
/// merely disabled (matching this codebase's established convention
/// for every other privileged action).
class HighlightsBuilderScreen extends ConsumerWidget {
  final bool isCaptain;

  const HighlightsBuilderScreen({super.key, required this.isCaptain});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final gallery = ref.watch(galleryProvider);
    final innings = ref.watch(inningsProvider);
    final notifier = ref.read(galleryProvider.notifier);

    final itemsById = {for (final item in gallery.items) item.id: item};
    final reelItems = [
      for (final id in gallery.reelClipIds)
        if (itemsById[id] != null) itemsById[id]!,
    ];
    final suggestions = autoCutSuggestions(gallery, innings);

    return Scaffold(
      appBar: AppBar(title: const Text('Highlights builder')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          if (gallery.reelPublished)
            Container(
              key: const ValueKey('reelPublishedBanner'),
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              margin: const EdgeInsets.only(bottom: AppSpacing.lg),
              decoration: BoxDecoration(
                color: colors.verified.withValues(alpha: 0.12),
                border: Border.all(color: colors.verified),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                'Reel published',
                style: AppTypography.body.copyWith(color: colors.verified),
              ),
            ),
          Text(
            'Auto-cut suggestions',
            style: AppTypography.label.copyWith(color: colors.textTertiary),
          ),
          const SizedBox(height: AppSpacing.xs),
          suggestions.isEmpty
              ? Text(
                  key: const ValueKey('noSuggestionsText'),
                  'No wicket/boundary footage pinned yet.',
                  style: AppTypography.caption.copyWith(
                    color: colors.textTertiary,
                  ),
                )
              : Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    for (final item in suggestions)
                      ActionChip(
                        key: ValueKey('autoCutChip_${item.id}'),
                        label: Text(autoCutChipLabel(item, innings)),
                        onPressed: () => notifier.addToReel(item.id),
                      ),
                  ],
                ),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            'Clip rail',
            style: AppTypography.label.copyWith(color: colors.textTertiary),
          ),
          const SizedBox(height: AppSpacing.xs),
          reelItems.isEmpty
              ? Text(
                  key: const ValueKey('emptyReelText'),
                  'Drag clips here from the auto-cut suggestions above.',
                  style: AppTypography.caption.copyWith(
                    color: colors.textTertiary,
                  ),
                )
              : ReorderableListView.builder(
                  key: const ValueKey('clipRail'),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: reelItems.length,
                  onReorderItem: notifier.reorderReel,
                  itemBuilder: (context, index) {
                    final item = reelItems[index];
                    return Container(
                      key: ValueKey('clipRow_${item.id}'),
                      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: colors.surfaceAlt,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            item.type == MediaType.video
                                ? Icons.videocam
                                : Icons.image_outlined,
                            size: 20,
                            color: colors.textTertiary,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              'Ball ${item.pinnedBallIndex! + 1} '
                              '-- ${item.uploaderName}',
                              style: AppTypography.body.copyWith(
                                color: colors.textPrimary,
                              ),
                            ),
                          ),
                          IconButton(
                            key: ValueKey('removeClip_${item.id}'),
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () => notifier.removeFromReel(item.id),
                          ),
                        ],
                      ),
                    );
                  },
                ),
          const SizedBox(height: AppSpacing.xxl),
          if (isCaptain && !gallery.reelPublished)
            AppButton(
              key: const ValueKey('publishReelButton'),
              variant: AppButtonVariant.primary,
              label: 'Publish reel',
              fullWidth: true,
              onPressed: reelItems.isEmpty ? null : notifier.publishReel,
            ),
        ],
      ),
    );
  }
}
