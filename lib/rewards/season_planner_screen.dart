import 'package:flutter/material.dart';

import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'missions_models.dart';

/// DS §7-55 (Season Planner): "year scroller of monthly themes (locked
/// future months show theme + criteria)." "Locked" reads as "not yet
/// active," not "hidden" -- every month's theme/criteria is visible so
/// players can plan ahead; only the current/past months show as
/// active/complete.
class SeasonPlannerScreen extends StatelessWidget {
  const SeasonPlannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final currentMonth = DateTime.now().month;

    return Scaffold(
      appBar: AppBar(title: const Text('Season Planner')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          for (final m in seasonCalendar)
            Container(
              key: ValueKey('seasonMonthCard_${m.month}'),
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: m.month == currentMonth
                    ? colors.primary.withValues(alpha: 0.1)
                    : colors.surfaceAlt,
                border: m.month == currentMonth
                    ? Border.all(color: colors.primary)
                    : null,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  if (m.month > currentMonth)
                    Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.sm),
                      child: Icon(
                        Icons.lock_outline,
                        size: 16,
                        color: colors.textTertiary,
                      ),
                    ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          m.theme,
                          style: AppTypography.subtitle.copyWith(
                            color: colors.textPrimary,
                          ),
                        ),
                        Text(
                          m.criteria,
                          style: AppTypography.caption.copyWith(
                            color: colors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (m.month < currentMonth)
                    Icon(Icons.check_circle, size: 20, color: colors.success)
                  else if (m.month == currentMonth)
                    Text(
                      'Active',
                      style: AppTypography.caption.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.w600,
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
