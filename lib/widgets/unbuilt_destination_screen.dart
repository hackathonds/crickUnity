import 'package:flutter/material.dart';

import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';

/// A handful of drawer destinations (PRD §3.3's sitemap names them, e.g.
/// "My Teams", "My Matches") were never actually built as real screens --
/// distinct from [PlaceholderScreen], which stands in generically for
/// destinations an *entire story* hasn't reached yet. This is narrower:
/// it names exactly what's missing and why, the same "explain the gap"
/// convention `WearableGlancesScreen`/`LocalizationSettingsScreen` use,
/// rather than a bare "$title — placeholder content" line.
class UnbuiltDestinationScreen extends StatelessWidget {
  final String title;
  final String explanation;

  const UnbuiltDestinationScreen({
    super.key,
    required this.title,
    required this.explanation,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Container(
          key: const ValueKey('unbuiltDestinationNotice'),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: colors.surfaceAlt,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            explanation,
            style: AppTypography.body.copyWith(color: colors.textSecondary),
          ),
        ),
      ),
    );
  }
}
