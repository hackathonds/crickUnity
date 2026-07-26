import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_bottom_sheet.dart';
import '../design_system/components/app_button.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'gallery_models.dart';
import 'gallery_provider.dart';
import 'highlights_builder_screen.dart';
import 'scoring_models.dart';
import 'scoring_provider.dart';

/// PRD §7.15 / DS §7 screen 33 ("per patterns"): "Match gallery: any
/// squad member uploads; captain can feature/hide items; fans can view
/// public gallery." PRD screen-list #38: states "upload / pin-to-ball /
/// publish reel ... squad upload; captain curate ... processing state."
///
/// Backlog cites "PRD §7.15, G.4" -- no Appendix G exists anywhere in
/// the frozen PRD (only Appendix A/B do); this is a stray citation in
/// the backlog, not a genuine second source, so only §7.15's actual
/// text is followed here.
class GalleryScreen extends StatelessWidget {
  final String viewerName;
  final bool isCaptain;

  const GalleryScreen({
    super.key,
    required this.viewerName,
    required this.isCaptain,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gallery'),
        actions: [
          IconButton(
            key: const ValueKey('openHighlightsBuilderButton'),
            icon: const Icon(Icons.movie_creation_outlined),
            tooltip: 'Highlights builder',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => HighlightsBuilderScreen(isCaptain: isCaptain),
              ),
            ),
          ),
        ],
      ),
      body: GalleryBody(viewerName: viewerName, isCaptain: isCaptain),
    );
  }
}

/// The Gallery's content, standalone from its own AppBar so it can also
/// be embedded as a tab in Live Match View (E4-11) without a duplicate
/// app bar -- same pattern as [ScorecardBody] (E4-11).
class GalleryBody extends ConsumerWidget {
  final String viewerName;
  final bool isCaptain;

  const GalleryBody({
    super.key,
    required this.viewerName,
    required this.isCaptain,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final gallery = ref.watch(galleryProvider);
    final notifier = ref.read(galleryProvider.notifier);
    // Fans/non-captains never see hidden items -- captain curate is
    // visible only to the captain, who needs to see what they hid.
    final visible = isCaptain ? gallery.items : gallery.visibleItems;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Expanded(
                child: AppButton(
                  key: const ValueKey('uploadPhotoButton'),
                  variant: AppButtonVariant.secondary,
                  label: 'Upload photo',
                  onPressed: () => notifier.uploadItem(
                    uploaderName: viewerName,
                    type: MediaType.photo,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppButton(
                  key: const ValueKey('uploadVideoButton'),
                  variant: AppButtonVariant.secondary,
                  label: 'Upload video',
                  onPressed: () => notifier.uploadItem(
                    uploaderName: viewerName,
                    type: MediaType.video,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: visible.isEmpty
              ? Center(
                  child: Text(
                    key: const ValueKey('galleryEmptyState'),
                    'No media uploaded yet.',
                    textAlign: TextAlign.center,
                    style: AppTypography.body.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                )
              : GridView.builder(
                  key: const ValueKey('galleryGrid'),
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: AppSpacing.sm,
                    crossAxisSpacing: AppSpacing.sm,
                    childAspectRatio: 4 / 5,
                  ),
                  itemCount: visible.length,
                  itemBuilder: (context, index) =>
                      _MediaTile(item: visible[index], isCaptain: isCaptain),
                ),
        ),
      ],
    );
  }
}

class _MediaTile extends ConsumerWidget {
  final MediaItem item;
  final bool isCaptain;

  const _MediaTile({required this.item, required this.isCaptain});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final notifier = ref.read(galleryProvider.notifier);

    return GestureDetector(
      key: ValueKey('mediaTile_${item.id}'),
      onTap: item.isProcessing ? null : () => _showPinSheet(context),
      child: Container(
        decoration: BoxDecoration(
          color: colors.surfaceAlt,
          borderRadius: BorderRadius.circular(14),
          border: item.isFeatured ? Border.all(color: colors.coin) : null,
        ),
        child: Stack(
          children: [
            Center(
              child: Icon(
                item.type == MediaType.video
                    ? Icons.videocam
                    : Icons.image_outlined,
                size: 40,
                color: colors.textTertiary,
              ),
            ),
            if (item.isProcessing)
              Positioned.fill(
                child: Container(
                  key: ValueKey('processingOverlay_${item.id}'),
                  color: colors.surface.withValues(alpha: 0.7),
                  alignment: Alignment.center,
                  child: Text(
                    'Processing…',
                    style: AppTypography.caption.copyWith(
                      color: colors.textTertiary,
                    ),
                  ),
                ),
              ),
            Positioned(
              left: AppSpacing.xs,
              bottom: AppSpacing.xs,
              child: Text(
                item.uploaderName,
                style: AppTypography.caption.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ),
            if (item.isFeatured)
              Positioned(
                right: AppSpacing.xs,
                top: AppSpacing.xs,
                child: Icon(Icons.star, size: 18, color: colors.coin),
              ),
            if (isCaptain && item.isHidden)
              Positioned(
                right: AppSpacing.xs,
                top: AppSpacing.xs,
                child: Icon(
                  Icons.visibility_off,
                  size: 18,
                  color: colors.textTertiary,
                ),
              ),
            if (isCaptain)
              Positioned(
                left: AppSpacing.xs,
                top: AppSpacing.xs,
                child: PopupMenuButton<String>(
                  key: ValueKey('curateMenu_${item.id}'),
                  icon: Icon(
                    Icons.more_vert,
                    size: 18,
                    color: colors.textPrimary,
                  ),
                  onSelected: (action) {
                    if (action == 'feature') notifier.toggleFeatured(item.id);
                    if (action == 'hide') notifier.toggleHidden(item.id);
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'feature',
                      child: Text(item.isFeatured ? 'Unfeature' : 'Feature'),
                    ),
                    PopupMenuItem(
                      value: 'hide',
                      child: Text(item.isHidden ? 'Unhide' : 'Hide'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showPinSheet(BuildContext context) {
    showAppBottomSheet<void>(
      context: context,
      title: 'Pin to ball',
      contentBuilder: (context) => _PinToBallSheetContent(item: item),
    );
  }
}

class _PinToBallSheetContent extends ConsumerWidget {
  final MediaItem item;

  const _PinToBallSheetContent({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final innings = ref.watch(inningsProvider);
    final notifier = ref.read(galleryProvider.notifier);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (item.pinnedBallIndex != null)
            AppButton(
              key: const ValueKey('unpinButton'),
              variant: AppButtonVariant.destructive,
              label: 'Unpin',
              fullWidth: true,
              onPressed: () {
                notifier.unpinFromBall(item.id);
                Navigator.of(context).pop();
              },
            ),
          for (var i = 0; i < innings.deliveries.length; i++)
            if (!innings.deliveries[i].isManualSwap)
              GestureDetector(
                key: ValueKey('pinToBall_$i'),
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  notifier.pinToBall(item.id, i);
                  Navigator.of(context).pop();
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Text(
                    'Ball ${i + 1}: ${deliveryLabel(innings.deliveries[i])}',
                    style: AppTypography.body.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                ),
              ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}
