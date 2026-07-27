import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_button.dart';
import '../design_system/components/app_state_scaffolds.dart';
import '../design_system/components/app_tag_chip.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import '../moderation/report_sheet.dart';
import '../recognition/record_models.dart';
import '../recognition/records_provider.dart';
import '../social/composer_screen.dart' show composerViewerName;
import 'booking_flow_screen.dart';
import 'ground_models.dart';
import 'grounds_provider.dart';
import 'review_composer_screen.dart';
import 'review_models.dart';
import 'reviews_provider.dart';

/// Backlog E9-02: "Ground profile (facilities/pitch/boundary/records
/// shelf/par-score stats -- PRD §10.1, §19.8)." §19.8 does not exist --
/// §19 Analytics has no numbered subsections at all (confirmed by
/// grepping every `^# 19` heading), so "par-score stats" has no PRD
/// definition beyond the term itself; a mocked per-ground average
/// first-innings total stands in (see [Ground.parScoreFirstInnings]).
///
/// PRD §20 screen-list item 50 additionally names: gallery, facilities,
/// calendar, records | book/follow/review | fully-booked state. This
/// story builds the profile itself plus the Follow toggle and the
/// fully-booked banner; "Book" opens the real E9-03 booking flow
/// (grounds/booking_flow_screen.dart) and "Write a review" opens the
/// real E9-04 review composer (grounds/review_composer_screen.dart).
/// Rating and facet bars now compute from reviewsProvider's actual
/// reviews (weighted recent-first average per PRD §10.3) once any
/// exist for this ground, falling back to the seeded static value
/// otherwise -- same "wire the real module once it exists" convention
/// as every other cross-story integration this session. Weather strip
/// and "upcoming public matches here" (also under §10.4) are out of
/// this story's backlog line and are not built here -- flagged rather
/// than silently scoped in.
class GroundProfileScreen extends ConsumerWidget {
  final String groundId;

  const GroundProfileScreen({super.key, required this.groundId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final ground = ref.watch(groundsProvider).groundById(groundId);

    if (ground == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Ground profile')),
        body: AppErrorState(
          message: 'This ground could not be found.',
          onRetry: () => Navigator.of(context).maybePop(),
        ),
      );
    }

    final notifier = ref.read(groundsProvider.notifier);
    final isFollowing = ref.watch(
      groundsProvider.select((s) => s.followedGroundIds.contains(ground.id)),
    );
    final records = ref
        .watch(recordsProvider)
        .records
        .where(
          (r) => r.scope == RecordScope.ground && r.scopeLabel == ground.name,
        )
        .toList();
    final reviews = ref.watch(reviewsProvider).forGround(ground.id);
    final liveRating = reviews.isEmpty
        ? ground.rating
        : weightedRecentFirstAverage(reviews);
    final liveFacets = reviews.isEmpty
        ? ground.facetRatings
        : averageFacetStars(reviews);

    return Scaffold(
      appBar: AppBar(
        title: Text(ground.name),
        actions: [
          IconButton(
            key: const ValueKey('followGroundButton'),
            icon: Icon(
              isFollowing
                  ? Icons.notifications_active
                  : Icons.notifications_none,
            ),
            tooltip: isFollowing ? 'Unfollow' : 'Follow',
            onPressed: () => notifier.toggleFollow(ground.id),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _GalleryStrip(photoCount: ground.photoCount, colors: colors),
          const SizedBox(height: AppSpacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(ground.name, style: AppTypography.h2),
                        if (ground.verifiedOwner) ...[
                          const SizedBox(width: AppSpacing.xs),
                          Icon(
                            Icons.verified,
                            size: 18,
                            color: colors.verified,
                          ),
                        ],
                      ],
                    ),
                    Text(
                      ground.address,
                      style: AppTypography.caption.copyWith(
                        color: colors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${liveRating.toStringAsFixed(1)}★',
                style: AppTypography.stat.copyWith(color: colors.textPrimary),
              ),
            ],
          ),
          if (ground.isFullyBookedToday) ...[
            const SizedBox(height: AppSpacing.sm),
            AppTagChip(
              label: 'Fully booked today',
              variant: AppTagChipVariant.warning,
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  key: const ValueKey('bookGroundButton'),
                  variant: AppButtonVariant.primary,
                  label: ground.isFullyBookedToday ? 'Fully booked' : 'Book',
                  fullWidth: true,
                  onPressed: ground.isFullyBookedToday
                      ? null
                      : () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                BookingFlowScreen(groundId: ground.id),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppButton(
                  key: const ValueKey('writeReviewButton'),
                  variant: AppButtonVariant.secondary,
                  label: 'Write a review',
                  fullWidth: true,
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ReviewComposerScreen(groundId: ground.id),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            'Facilities',
            style: AppTypography.label.copyWith(color: colors.textTertiary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final entry in ground.facilities.entries)
                Chip(
                  label: Text(
                    facilityLabels[entry.key]! +
                        switch (entry.value) {
                          FacilityAvailability.yes => '',
                          FacilityAvailability.paid => ' (paid)',
                          FacilityAvailability.no => ' (none)',
                        },
                    style: AppTypography.caption,
                  ),
                  backgroundColor: entry.value == FacilityAvailability.no
                      ? colors.surfaceAlt
                      : null,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Pitch & ground',
            style: AppTypography.label.copyWith(color: colors.textTertiary),
          ),
          const SizedBox(height: AppSpacing.xs),
          _InfoRow(
            label: 'Pitch types',
            value: ground.pitchTypes.map((t) => pitchTypeLabels[t]).join(', '),
            colors: colors,
          ),
          _InfoRow(
            label: 'Pitch count',
            value: '${ground.pitchCount}',
            colors: colors,
          ),
          _InfoRow(
            label: 'Boundary',
            value:
                '${ground.boundaryMeters}m · ${boundaryBadgeLabels[ground.boundaryBadge]}',
            colors: colors,
          ),
          _InfoRow(
            label: 'Surface condition',
            value: ground.surfaceConditionTag,
            colors: colors,
          ),
          _InfoRow(
            label: 'Par score (1st innings)',
            value: '${ground.parScoreFirstInnings}',
            colors: colors,
            tabularNumerals: true,
          ),
          _InfoRow(
            label: 'Price',
            value: '₹${ground.pricePerHour}/hour',
            colors: colors,
          ),
          _InfoRow(label: 'Rules', value: ground.rulesNote, colors: colors),
          _InfoRow(
            label: 'Cancellation policy',
            value: ground.cancellationPolicyNote,
            colors: colors,
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Rating breakdown',
            style: AppTypography.label.copyWith(color: colors.textTertiary),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final facet in ReviewFacet.values)
            _FacetBar(
              label: reviewFacetLabels[facet]!,
              value: liveFacets[facet] ?? 0,
              colors: colors,
            ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Ground records',
            style: AppTypography.label.copyWith(color: colors.textTertiary),
          ),
          const SizedBox(height: AppSpacing.xs),
          if (records.isEmpty)
            Text(
              'No ground records tracked here yet.',
              style: AppTypography.body.copyWith(color: colors.textSecondary),
            )
          else
            for (final record in records)
              Container(
                key: ValueKey('groundRecordRow_${record.category.name}'),
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: colors.surfaceAlt,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        recordCategoryLabels[record.category]!,
                        style: AppTypography.body.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      record.isVacant
                          ? 'Vacant -- be first!'
                          : '${record.holderName} · ${record.value}',
                      style: AppTypography.body.copyWith(
                        color: record.isVacant
                            ? colors.textTertiary
                            : colors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Reviews',
            style: AppTypography.label.copyWith(color: colors.textTertiary),
          ),
          const SizedBox(height: AppSpacing.xs),
          if (reviews.isEmpty)
            Text(
              "Reviews come from teams who've played here.",
              style: AppTypography.body.copyWith(color: colors.textSecondary),
            )
          else
            for (final review in reviews)
              _ReviewCard(
                key: ValueKey('reviewCard_${review.id}'),
                review: review,
                colors: colors,
              ),
        ],
      ),
    );
  }
}

/// No real photo/asset upload pipeline exists in this repo -- a tinted
/// placeholder tile strip stands in, same flagged-mock-asset convention
/// as messaging's sticker tray and challenges' quick-chat stickers.
class _GalleryStrip extends StatelessWidget {
  final int photoCount;
  final AppColors colors;

  const _GalleryStrip({required this.photoCount, required this.colors});

  @override
  Widget build(BuildContext context) {
    final tileCount = photoCount == 0 ? 0 : (photoCount).clamp(1, 6);
    if (tileCount == 0) {
      return Container(
        height: 96,
        decoration: BoxDecoration(
          color: colors.surfaceAlt,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.center,
        child: Text(
          'No photos yet',
          style: AppTypography.caption.copyWith(color: colors.textTertiary),
        ),
      );
    }
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: tileCount,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.xs),
        itemBuilder: (context, index) => Container(
          key: ValueKey('galleryTile_$index'),
          width: 120,
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.15 + 0.1 * (index % 3)),
            borderRadius: BorderRadius.circular(14),
          ),
          alignment: Alignment.center,
          child: Icon(Icons.photo_outlined, color: colors.primary),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final AppColors colors;
  final bool tabularNumerals;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.colors,
    this.tabularNumerals = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: AppTypography.caption.copyWith(color: colors.textTertiary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style:
                  (tabularNumerals
                          ? AppTypography.stat.copyWith(
                              fontSize: 15,
                              height: 22 / 15,
                            )
                          : AppTypography.body)
                      .copyWith(color: colors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends ConsumerWidget {
  final Review review;
  final AppColors colors;

  const _ReviewCard({super.key, required this.review, required this.colors});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  review.reviewerName,
                  style: AppTypography.subtitle.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
              ),
              Text('${review.overallStars}★'),
              IconButton(
                key: ValueKey('reportReviewButton_${review.id}'),
                icon: const Icon(Icons.flag_outlined, size: 18),
                tooltip: 'Report review',
                onPressed: () => showReportSheet(
                  context,
                  targetType: 'review',
                  targetLabel: 'Review by ${review.reviewerName}',
                  reporterName: composerViewerName,
                ),
              ),
            ],
          ),
          if (review.text.isNotEmpty)
            Text(
              review.text,
              style: AppTypography.body.copyWith(color: colors.textSecondary),
            ),
          if (review.photoCount > 0)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(
                '${review.photoCount} photo${review.photoCount == 1 ? '' : 's'}',
                style: AppTypography.caption.copyWith(
                  color: colors.textTertiary,
                ),
              ),
            ),
          if (review.hasOwnerReply) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Owner reply',
                    style: AppTypography.label.copyWith(
                      color: colors.textTertiary,
                    ),
                  ),
                  Text(review.ownerReplyText!, style: AppTypography.body),
                ],
              ),
            ),
          ] else
            // PRD §10.3: "Owner single reply per review." No Owner
            // Console exists yet (E9-05) to author this from -- a debug
            // control stands in so the single-reply rule can be
            // exercised now.
            TextButton(
              key: ValueKey('debugOwnerReplyButton_${review.id}'),
              onPressed: () => ref
                  .read(reviewsProvider.notifier)
                  .replyAsOwner(
                    review.id,
                    'Thanks for the feedback! (debug reply)',
                  ),
              child: const Text('Reply as owner (debug)'),
            ),
        ],
      ),
    );
  }
}

class _FacetBar extends StatelessWidget {
  final String label;
  final double value;
  final AppColors colors;

  const _FacetBar({
    required this.label,
    required this.value,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text(label, style: AppTypography.caption)),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (value / 5).clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: colors.border,
                color: colors.primary,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            value.toStringAsFixed(1),
            style: AppTypography.stat.copyWith(
              fontSize: 13,
              height: 18 / 13,
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
