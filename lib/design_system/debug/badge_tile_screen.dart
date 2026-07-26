import 'package:flutter/material.dart';

import '../components/app_avatar.dart';
import '../components/app_badge_tile.dart';
import '../components/app_bottom_sheet.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';

/// QA tool for E0-08 (sub-task 10/12): [AppBadgeTile] (grid/strip sizes,
/// earned/locked, tier ribbon) and [AppBadgeDetailContent] (via the
/// existing bottom sheet).
class BadgeTileScreen extends StatelessWidget {
  const BadgeTileScreen({super.key});

  void _openDetail(BuildContext context, {required bool earned}) {
    showAppBottomSheet<void>(
      context: context,
      title: 'Century Club',
      contentBuilder: (context) => AppBadgeDetailContent(
        name: 'Century Club',
        color: Colors.deepOrange,
        criteria: earned
            ? 'Score 100+ runs in a single innings.'
            : 'Score 100+ runs in a single innings to unlock.',
        rarityPercent: 4,
        earnDateAndProvenance: earned
            ? 'Earned 12 Jun 2026 · vs Strikers'
            : 'Not yet earned',
        friendAvatars: const [
          AppAvatar(size: AppAvatarSize.sm, name: 'Priya Nair'),
          SizedBox(width: 4),
          AppAvatar(size: AppAvatarSize.sm, name: 'Arjun Rao'),
        ],
        onShare: earned ? () {} : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    Widget label(String text) => Padding(
      padding: const EdgeInsets.only(
        bottom: AppSpacing.sm,
        top: AppSpacing.xxl,
      ),
      child: Text(
        text,
        style: AppTypography.label.copyWith(color: colors.textTertiary),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Badge tile (QA)')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            label('Grid size (88) — earned vs locked'),
            Row(
              children: [
                AppBadgeTile(
                  name: 'Century Club',
                  color: Colors.deepOrange,
                  earned: true,
                  tierLabel: 'Gold',
                  onTap: () => _openDetail(context, earned: true),
                ),
                const SizedBox(width: AppSpacing.lg),
                AppBadgeTile(
                  name: 'Hat-trick Hero',
                  color: Colors.deepPurple,
                  earned: false,
                  tierLabel: 'Silver',
                  onTap: () => _openDetail(context, earned: false),
                ),
              ],
            ),
            label('Strip size (56)'),
            Row(
              children: [
                AppBadgeTile(
                  name: 'Century Club',
                  color: Colors.deepOrange,
                  earned: true,
                  size: 56,
                ),
                const SizedBox(width: AppSpacing.md),
                AppBadgeTile(
                  name: 'Hat-trick Hero',
                  color: Colors.deepPurple,
                  earned: false,
                  size: 56,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
