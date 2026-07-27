import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../coaching/personal_training_log_screen.dart';
import '../design_system/components/app_sponsored_badge.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'discover_models.dart';
import 'discover_provider.dart';

/// DS §11.12: "Discover: editorial cards (tip/rules/news templates),
/// tip cards carry [Add drill] chip deep-linking Drill Library; strictly
/// separate scroll from Feed (PRD rule), sponsored-education label style
/// per 11.9." A separate screen/route from Feed satisfies "strictly
/// separate scroll" -- no shared scroll controller with the Feed screen.
class DiscoverScreen extends ConsumerWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final cards = ref.watch(discoverCardsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Discover')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          for (final card in cards)
            Container(
              key: ValueKey('discoverCard_${card.title}'),
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: colors.surface,
                border: Border.all(color: colors.border),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Chip(
                        label: Text(discoverCardTypeLabels[card.type]!),
                        visualDensity: VisualDensity.compact,
                      ),
                      const Spacer(),
                      if (card.sponsored)
                        AppSponsoredBadge(
                          sponsorName: card.sponsorName!,
                          zone: SponsoredZoneSize.matchCardFooter,
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    card.title,
                    style: AppTypography.subtitle.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    card.body,
                    style: AppTypography.body.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                  if (card.linkedDrillId != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: ActionChip(
                        key: ValueKey('addDrillChip_${card.linkedDrillId}'),
                        label: const Text('Add drill'),
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => PersonalTrainingLogScreen(
                              initialDrillId: card.linkedDrillId,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}
