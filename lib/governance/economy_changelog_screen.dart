import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'economy_console_provider.dart';

/// PRD §2.17 restriction: "public changelog for policy changes
/// affecting users' coins/fees." This is the public-facing surface
/// (any user can reach it) -- distinct from E16-11's internal Admin
/// audit log, which stays Super-Admin-gated.
class EconomyChangelogScreen extends ConsumerWidget {
  const EconomyChangelogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final changelog = ref.watch(economyConsoleProvider).changelog;

    return Scaffold(
      appBar: AppBar(title: const Text("What's changed")),
      body: changelog.isEmpty
          ? Center(
              child: Text(
                'No coin/fee policy changes yet.',
                style: AppTypography.body.copyWith(color: colors.textSecondary),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                for (final entry in changelog)
                  Container(
                    key: ValueKey('changelogEntry_${entry.id}'),
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      border: Border.all(color: colors.border),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.title,
                          style: AppTypography.body.copyWith(
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          entry.description,
                          style: AppTypography.caption.copyWith(
                            color: colors.textSecondary,
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
