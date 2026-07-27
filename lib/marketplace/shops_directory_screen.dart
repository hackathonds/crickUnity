import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'gear_provider.dart';

/// DS §11.12: "Shops directory: verified shop profiles reusing
/// Ground-profile pattern (catalog strip instead of calendar)." A
/// simplified card list rather than a full Ground-Profile-scale screen
/// (header/tabs/reviews) -- proportionate to this being one line of the
/// DS spec, not its own story.
class ShopsDirectoryScreen extends ConsumerWidget {
  const ShopsDirectoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final shops = ref.watch(shopsDirectoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Shops directory')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          for (final shop in shops)
            Container(
              key: ValueKey('shopProfileCard_${shop.name}'),
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
                      Text(
                        shop.name,
                        style: AppTypography.subtitle.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                      if (shop.verified) ...[
                        const SizedBox(width: AppSpacing.xs),
                        Icon(Icons.verified, size: 16, color: colors.verified),
                      ],
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Catalog',
                    style: AppTypography.label.copyWith(
                      color: colors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  SizedBox(
                    height: 36,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        for (final item in shop.catalogItems)
                          Padding(
                            padding: const EdgeInsets.only(
                              right: AppSpacing.xs,
                            ),
                            child: Chip(label: Text(item)),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
