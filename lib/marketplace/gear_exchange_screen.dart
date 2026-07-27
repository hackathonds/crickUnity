import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import '../messaging/chat_provider.dart';
import '../messaging/chat_thread_screen.dart';
import '../profile/trust_sportsmanship_models.dart' show trustBandLabels;
import '../social/feed_models.dart' show AttachedObject, AttachedObjectType;
import 'gear_models.dart';
import 'gear_provider.dart';

/// DS §11.12: "Gear exchange: listing grid 2-up (photo 1:1, price tnum,
/// condition chip)."
class GearExchangeScreen extends ConsumerWidget {
  const GearExchangeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final listings = ref.watch(gearProvider).listings;

    return Scaffold(
      appBar: AppBar(title: const Text('Gear exchange')),
      body: GridView.builder(
        padding: const EdgeInsets.all(AppSpacing.lg),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: AppSpacing.md,
          crossAxisSpacing: AppSpacing.md,
          childAspectRatio: 0.8,
        ),
        itemCount: listings.length,
        itemBuilder: (context, index) {
          final listing = listings[index];
          return GestureDetector(
            key: ValueKey('gearListingCard_${listing.id}'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => GearListingDetailScreen(listingId: listing.id),
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                color: colors.surface,
                border: Border.all(color: colors.border),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AspectRatio(
                    aspectRatio: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        color: colors.surfaceAlt,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(14),
                        ),
                      ),
                      child: Icon(
                        Icons.sports_cricket,
                        color: colors.textTertiary,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          listing.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.body.copyWith(
                            color: colors.textPrimary,
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              '₹${listing.priceRupees}',
                              style: AppTypography.stat.copyWith(
                                color: colors.textPrimary,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                            const Spacer(),
                            Chip(
                              label: Text(
                                gearConditionLabels[listing.condition]!,
                              ),
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class GearListingDetailScreen extends ConsumerWidget {
  final String listingId;

  const GearListingDetailScreen({super.key, required this.listingId});

  void _chatWithSeller(
    BuildContext context,
    WidgetRef ref,
    GearListing listing,
  ) {
    final gearNotifier = ref.read(gearProvider.notifier);
    if (ref.read(gearProvider).viewerIsMinor) {
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Guardian approval needed'),
          content: const Text(
            'Minor accounts route marketplace chats through a guardian '
            'for approval before messaging a seller.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    final firstChat = !ref.read(gearProvider).safetyTipsShown;
    if (firstChat) {
      gearNotifier.markSafetyTipsShown();
    }

    final chatId = ref
        .read(chatsProvider.notifier)
        .findOrCreateDirectChat(listing.sellerName);
    ref
        .read(chatsProvider.notifier)
        .sendObjectCard(
          chatId,
          object: AttachedObject(
            type: AttachedObjectType.gearListing,
            title: listing.title,
            subtitle:
                '₹${listing.priceRupees} -- ${gearConditionLabels[listing.condition]}',
          ),
        );

    if (firstChat) {
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Safety tips'),
          content: const Text(
            'Meet in a public place, inspect gear before paying, and '
            'never send money before seeing the item.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ChatThreadScreen(chatId: chatId),
                  ),
                );
              },
              child: const Text('Got it'),
            ),
          ],
        ),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ChatThreadScreen(chatId: chatId)),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final state = ref.watch(gearProvider);
    final notifier = ref.read(gearProvider.notifier);
    final listing = state.listings.firstWhere((l) => l.id == listingId);
    final tier = state.tierFor(listing.sellerName);

    return Scaffold(
      appBar: AppBar(title: Text(listing.title)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          AspectRatio(
            aspectRatio: 1.6,
            child: Container(
              decoration: BoxDecoration(
                color: colors.surfaceAlt,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.sports_cricket,
                size: 48,
                color: colors.textTertiary,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            '₹${listing.priceRupees}',
            style: AppTypography.title.copyWith(color: colors.textPrimary),
          ),
          Wrap(
            spacing: AppSpacing.xs,
            children: [
              Chip(label: Text(gearConditionLabels[listing.condition]!)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            listing.description,
            style: AppTypography.body.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            key: const ValueKey('sellerCard'),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: colors.surfaceAlt,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  listing.sellerName,
                  style: AppTypography.body.copyWith(color: colors.textPrimary),
                ),
                Text(
                  trustBandLabels[listing.sellerTrustBand]!,
                  style: AppTypography.caption.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                if (tier != TrustedSellerTier.none)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: Chip(
                      key: ValueKey('trustedSellerBadge_${listing.sellerName}'),
                      label: Text(trustedSellerTierLabels[tier]!),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          OutlinedButton(
            key: const ValueKey('chatWithSellerButton'),
            onPressed: () => _chatWithSeller(context, ref, listing),
            child: const Text('Chat with seller'),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (listing.status != GearListingStatus.sold)
            FilledButton(
              key: const ValueKey('markSoldButton'),
              onPressed: () {
                final buyerDone = notifier.confirmSoldAsBuyer(listingId);
                if (buyerDone) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Sale confirmed by both sides -- leave a review!',
                      ),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Waiting for the other side to confirm.'),
                    ),
                  );
                }
              },
              child: Text(
                state.buyerConfirmedSold.contains(listingId)
                    ? 'Waiting for seller confirmation'
                    : 'Mark as sold (buyer confirm)',
              ),
            ),
          if (listing.status == GearListingStatus.saleInProgress &&
              !state.sellerConfirmedSold.contains(listingId))
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: TextButton(
                key: const ValueKey('simulateSellerConfirmButton'),
                onPressed: () {
                  final bothDone = notifier.confirmSoldAsSeller(listingId);
                  if (bothDone) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Sale confirmed by both sides -- leave a review!',
                        ),
                      ),
                    );
                  }
                },
                child: const Text('(QA) Simulate seller confirmation'),
              ),
            ),
          if (listing.status == GearListingStatus.sold)
            Text(
              'Sold',
              style: AppTypography.body.copyWith(color: colors.success),
            ),
        ],
      ),
    );
  }
}
