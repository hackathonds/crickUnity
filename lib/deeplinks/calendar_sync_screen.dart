import 'package:flutter/material.dart';

import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'deep_link_models.dart';

/// DS §11.18: "Calendar sync: Settings row with subscribe explainer +
/// per-category toggles (matches/practice/bookings)." No
/// device_calendar package exists in this project -- this is the
/// "subscribe to a calendar feed" explainer + preference toggles, not a
/// live read/write calendar integration (a real implementation would
/// generate a per-user ICS feed URL for the OS calendar app to
/// subscribe to).
class CalendarSyncScreen extends StatefulWidget {
  const CalendarSyncScreen({super.key});

  @override
  State<CalendarSyncScreen> createState() => _CalendarSyncScreenState();
}

class _CalendarSyncScreenState extends State<CalendarSyncScreen> {
  final Map<CalendarSyncCategory, bool> _enabled = {
    for (final c in CalendarSyncCategory.values) c: true,
  };

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Scaffold(
      appBar: AppBar(title: const Text('Calendar sync')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: colors.surfaceAlt,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              'Subscribe to your CricUnity calendar feed from your '
              'phone\'s calendar app to see matches, practice and '
              'bookings alongside your other events.',
              style: AppTypography.body.copyWith(color: colors.textSecondary),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          for (final category in CalendarSyncCategory.values)
            SwitchListTile(
              key: ValueKey('calendarSyncToggle_${category.name}'),
              contentPadding: EdgeInsets.zero,
              title: Text(calendarSyncCategoryLabels[category]!),
              value: _enabled[category]!,
              onChanged: (v) => setState(() => _enabled[category] = v),
            ),
        ],
      ),
    );
  }
}
