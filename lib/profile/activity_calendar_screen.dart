import 'package:flutter/material.dart';

import '../design_system/components/app_bottom_sheet.dart';
import '../design_system/components/app_calendar.dart';
import '../design_system/components/app_state_scaffolds.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'activity_calendar_models.dart';
import 'profile_models.dart';

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// PRD §5.12 + DS §3.10/§7.8: month heat grid (reusing E0-07's
/// [AppCalendarMonthGrid] unchanged) with a day-tap agenda peek gated by
/// viewer tier: "Public shows density only; Friends see event types;
/// Self sees everything."
///
/// This app's relationship model has no literal "Friends" tier -- the
/// closest existing analog to a mutual connection is
/// [ViewerRelation.teammate] (same mapping precedent as the Message
/// action being teammate-only in `profile_screen.dart`), so that's used
/// for the Friends tier here. [ViewerRelation.follower]/[.public] both
/// get the Public tier; the day-tap callback is never even wired for
/// them (structural guard, same pattern as the Weaknesses section) --
/// they still see the heat density and legend, just no tap detail.
///
/// `entries` is passed in synchronously (no activity-feed backend exists
/// yet, same precedent as `achievements_wall_screen.dart`), so of the 7
/// canonical states only Default/Empty/Success are real triggers here.
class ActivityCalendarScreen extends StatefulWidget {
  final List<ActivityEntry> entries;
  final ViewerRelation relation;

  /// Testability seam -- defaults to the real current month. Without
  /// this, tests would depend on whatever month the suite happens to
  /// run in (same class of gotcha as the OTP/Guardian-wait `now` seam).
  final DateTime? initialMonth;

  const ActivityCalendarScreen({
    super.key,
    required this.entries,
    required this.relation,
    this.initialMonth,
  });

  @override
  State<ActivityCalendarScreen> createState() => _ActivityCalendarScreenState();
}

class _ActivityCalendarScreenState extends State<ActivityCalendarScreen> {
  late DateTime _visibleMonth = () {
    final reference = widget.initialMonth ?? DateTime.now();
    return DateTime(reference.year, reference.month);
  }();

  bool get _canPeekDetail =>
      widget.relation == ViewerRelation.self ||
      widget.relation == ViewerRelation.teammate;

  @override
  Widget build(BuildContext context) {
    final heatLevels = computeHeatLevels(widget.entries);

    return Scaffold(
      appBar: AppBar(title: const Text('Activity calendar')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: widget.entries.isEmpty
            ? AppEmptyState(
                message:
                    'No cricket activity yet -- play, practice, score '
                    'or umpire a match to start filling in your calendar.',
                primaryLabel: 'Back to profile',
                onPrimary: () => Navigator.of(context).pop(),
              )
            : AppCalendarMonthGrid(
                key: const ValueKey('activityCalendarGrid'),
                month: _visibleMonth,
                heatLevels: heatLevels,
                onPreviousMonth: () => setState(
                  () => _visibleMonth = DateTime(
                    _visibleMonth.year,
                    _visibleMonth.month - 1,
                  ),
                ),
                onNextMonth: () => setState(
                  () => _visibleMonth = DateTime(
                    _visibleMonth.year,
                    _visibleMonth.month + 1,
                  ),
                ),
                onDaySelected: _canPeekDetail ? _openDayPeek : null,
              ),
      ),
    );
  }

  void _openDayPeek(DateTime date) {
    final dayEntries = widget.entries
        .where((e) => _dateOnly(e.date) == _dateOnly(date))
        .toList();
    if (dayEntries.isEmpty) return;

    showAppBottomSheet<void>(
      context: context,
      title: '${date.day}/${date.month}/${date.year}',
      contentBuilder: (context) => _DayPeekContent(
        entries: dayEntries,
        showDetail: widget.relation == ViewerRelation.self,
      ),
    );
  }
}

class _DayPeekContent extends StatelessWidget {
  final List<ActivityEntry> entries;
  final bool showDetail;

  const _DayPeekContent({required this.entries, required this.showDetail});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        key: const ValueKey('activityDayPeekList'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final entry in entries)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Text(
                showDetail
                    ? '${activityTypeLabels[entry.type]} -- ${entry.detail}'
                    : activityTypeLabels[entry.type]!,
                style: AppTypography.body.copyWith(color: colors.textPrimary),
              ),
            ),
        ],
      ),
    );
  }
}
