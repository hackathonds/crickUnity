import 'package:flutter/material.dart';

import '../icons/app_icon.dart';
import '../icons/app_icon_id.dart';
import '../icons/app_icon_registry.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';

/// Internal QA tool rendering every DS §2.5 icon family, outline + filled
/// side by side (coin shown once — it has no outline/filled split), per
/// E0-03's AC. Not a product screen — see PR notes on the 7-states rule.
class IconGalleryScreen extends StatelessWidget {
  const IconGalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Scaffold(
      appBar: AppBar(title: const Text('Icon gallery (QA)')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          for (final entry in appIconFamilies.entries) ...[
            Text(
              entry.key,
              style: AppTypography.h2.copyWith(color: colors.textPrimary),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.lg,
              runSpacing: AppSpacing.lg,
              children: [
                for (final id in entry.value) _IconTile(id: id, colors: colors),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ],
      ),
    );
  }
}

class _IconTile extends StatelessWidget {
  final AppIconId id;
  final AppColors colors;

  const _IconTile({required this.id, required this.colors});

  @override
  Widget build(BuildContext context) {
    final glyph = appIconGlyphs[id]!;
    final label = id.name;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (glyph.isMulticolor)
          AppIcon(id: id, semanticLabel: label)
        else
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppIcon(
                id: id,
                semanticLabel: '$label outline',
                color: colors.textPrimary,
              ),
              const SizedBox(width: AppSpacing.sm),
              AppIcon(
                id: id,
                semanticLabel: '$label filled',
                active: true,
                color: colors.textPrimary,
              ),
            ],
          ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          label,
          style: AppTypography.caption.copyWith(color: colors.textSecondary),
        ),
      ],
    );
  }
}
