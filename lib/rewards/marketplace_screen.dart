import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_segmented_control.dart';
import '../design_system/components/app_state_scaffolds.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'listing_detail_screen.dart';
import 'marketplace_models.dart';
import 'marketplace_provider.dart';
import 'rewards_provider.dart';

/// DS §7-53's "Marketplace grid" -- PRD §18: "level-gated items visibly
/// locked | out-of-stock ... states." Both are rendered inline on the
/// tile, not hidden; a locked/out-of-stock listing is still visible and
/// tappable through to its terms (Listing detail explains why it can't
/// be redeemed yet), matching the "visibly locked" wording exactly.
class MarketplaceScreen extends ConsumerStatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  ConsumerState<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends ConsumerState<MarketplaceScreen> {
  ListingCategory? _filter;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final viewerLevel = ref.watch(rewardsProvider).level;
    final marketplace = ref.watch(marketplaceProvider);
    final filtered = mockRewardListings
        .where((l) => _filter == null || l.category == _filter)
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Marketplace')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSegmentedControl<ListingCategory?>(
              key: const ValueKey('marketplaceCategoryFilter'),
              options: [null, ...ListingCategory.values],
              value: _filter,
              onChanged: (value) => setState(() => _filter = value),
              labelBuilder: (category) =>
                  category == null ? 'All' : listingCategoryLabels[category]!,
            ),
            const SizedBox(height: AppSpacing.lg),
            Expanded(
              child: filtered.isEmpty
                  ? AppEmptyState(
                      message:
                          'No ${listingCategoryLabels[_filter]!.toLowerCase()} '
                          'listings right now.',
                      primaryLabel: 'View all',
                      onPrimary: () => setState(() => _filter = null),
                    )
                  : GridView.builder(
                      key: const ValueKey('marketplaceGrid'),
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 180,
                            mainAxisSpacing: AppSpacing.md,
                            crossAxisSpacing: AppSpacing.md,
                            childAspectRatio: 0.85,
                          ),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final listing = filtered[index];
                        final stock = marketplace.stockFor(listing);
                        final locked = viewerLevel < listing.levelRequirement;
                        return _ListingTile(
                          listing: listing,
                          stock: stock,
                          locked: locked,
                          colors: colors,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  ListingDetailScreen(listingId: listing.id),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListingTile extends StatelessWidget {
  final RewardListing listing;
  final int stock;
  final bool locked;
  final AppColors colors;
  final VoidCallback onTap;

  const _ListingTile({
    required this.listing,
    required this.stock,
    required this.locked,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final outOfStock = stock <= 0;
    final dimmed = locked || outOfStock;

    return GestureDetector(
      key: ValueKey('marketplaceTile_${listing.id}'),
      onTap: onTap,
      child: Opacity(
        opacity: dimmed ? 0.55 : 1.0,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: colors.surfaceAlt,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (locked)
                Icon(Icons.lock_outline, size: 16, color: colors.textTertiary)
              else
                Icon(Icons.card_giftcard, size: 16, color: colors.coin),
              const Spacer(),
              Text(
                listing.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.body.copyWith(color: colors.textPrimary),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${listing.coinPrice} coins',
                style: AppTypography.caption.copyWith(
                  color: colors.textTertiary,
                ),
              ),
              if (locked)
                Text(
                  'Unlocks at Lv${listing.levelRequirement}',
                  style: AppTypography.caption.copyWith(color: colors.error),
                )
              else if (outOfStock)
                Text(
                  'Out of stock',
                  style: AppTypography.caption.copyWith(color: colors.error),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
