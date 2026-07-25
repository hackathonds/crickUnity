import 'package:flutter/material.dart';

import '../components/app_card.dart';
import '../icons/app_icon.dart';
import '../icons/app_icon_id.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';

/// QA tool for E0-07 (sub-task 2/10): the base card across its states.
/// Switch the OS/app theme to Theme 4 (dark) to see the money-surface card
/// keep its border while the plain cards switch to +lum elevation instead.
class CardScreen extends StatelessWidget {
  const CardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    Widget label(String text) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        text,
        style: AppTypography.label.copyWith(color: colors.textTertiary),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Cards (QA)')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          label('Plain, tappable'),
          AppCard(
            onTap: () {},
            child: const Text('Tap anywhere on this card.'),
          ),
          const SizedBox(height: AppSpacing.xxl),
          label('Featured (20 padding)'),
          AppCard(
            featured: true,
            onTap: () {},
            child: const Text('Featured cards get 20 padding instead of 16.'),
          ),
          const SizedBox(height: AppSpacing.xxl),
          label(
            'Header + 2 menu actions (only the header is tappable; '
            'long-press anywhere opens the same menu)',
          ),
          AppCard(
            headerTitle: 'Sunday Friendly vs Titans',
            headerLeading: AppIcon(
              id: AppIconId.matches,
              semanticLabel: 'Match',
              color: colors.primary,
            ),
            hasMultipleActions: true,
            onTap: () {},
            menuActions: [
              AppCardMenuAction(
                label: 'Share',
                icon: AppIconId.shareArc,
                onTap: () {},
              ),
              AppCardMenuAction(
                label: 'Set reminder',
                icon: AppIconId.pendingClock,
                onTap: () {},
              ),
              AppCardMenuAction(
                label: 'Report score issue',
                icon: AppIconId.locked,
                isDestructive: true,
                onTap: () {},
              ),
            ],
            child: const Text('Body content is not itself tappable here.'),
          ),
          const SizedBox(height: AppSpacing.xxl),
          label('Money surface (always bordered — DS Pillar 4)'),
          AppCard(
            isMoneySurface: true,
            child: const Text('Ground fee split · ₹1,200 total'),
          ),
          const SizedBox(height: AppSpacing.xxl),
          label('Selected'),
          AppCard(
            selected: true,
            onTap: () {},
            child: const Text('Selected cards get a 1.5px primary border.'),
          ),
          const SizedBox(height: AppSpacing.xxl),
          label('Loading'),
          const AppCard(isLoading: true, child: SizedBox.shrink()),
        ],
      ),
    );
  }
}
