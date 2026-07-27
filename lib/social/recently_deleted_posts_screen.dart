import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_button.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'feed_provider.dart';

/// PRD §12.2: "Delete: soft (author) with 30-day self-restore." Same
/// pattern as expenses' recently_deleted_screen.dart (E5-09) --
/// older-than-30-days entries drop off this list; no permanent-purge
/// action is built (flagged, no storage-reclamation concern in this
/// in-memory mock).
class RecentlyDeletedPostsScreen extends ConsumerWidget {
  const RecentlyDeletedPostsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final posts = ref.watch(feedProvider).posts;
    final notifier = ref.read(feedProvider.notifier);
    final now = DateTime.now();

    final deleted = [
      for (final p in posts)
        if (p.deletedAt != null &&
            now.difference(p.deletedAt!) < recentlyDeletedPostRetention)
          p,
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Recently deleted')),
      body: deleted.isEmpty
          ? Center(
              child: Text(
                key: const ValueKey('recentlyDeletedPostsEmptyState'),
                'Nothing deleted in the last 30 days.',
                style: AppTypography.body.copyWith(color: colors.textSecondary),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                for (final p in deleted)
                  Container(
                    key: ValueKey('recentlyDeletedPostRow_${p.id}'),
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: colors.surfaceAlt,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.contentText,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.body.copyWith(
                                  color: colors.textPrimary,
                                ),
                              ),
                              Text(
                                '${recentlyDeletedPostRetention.inDays - now.difference(p.deletedAt!).inDays}d left',
                                style: AppTypography.caption.copyWith(
                                  color: colors.textTertiary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        AppButton(
                          key: ValueKey('restorePostButton_${p.id}'),
                          variant: AppButtonVariant.secondary,
                          label: 'Restore',
                          onPressed: () => notifier.restorePost(p.id),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}
