import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';

const List<String> _monthNames = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

const List<String> _weekdayInitials = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// DS §3.10: "Month grid, day cells 44, event dots ≤3 + '+n'; heat variant
/// (activity) uses 4-step sequential ramp with density legend; range-select
/// (booking) paints connective pill. Today = 1.5px primary ring. Long-press
/// day = peek agenda."
///
/// Stateless and controlled — the caller owns which month is shown and
/// which date(s) are selected, matching this design system's established
/// pattern (Segmented Control, Avatar, etc).
class AppCalendarMonthGrid extends StatelessWidget {
  final DateTime month;
  final DateTime? today;
  final DateTime? selectedDate;
  final DateTime? rangeStart;
  final DateTime? rangeEnd;
  final Map<DateTime, int> eventCounts;
  final Map<DateTime, int>? heatLevels;
  final ValueChanged<DateTime>? onDaySelected;
  final ValueChanged<DateTime>? onDayLongPress;
  final VoidCallback? onPreviousMonth;
  final VoidCallback? onNextMonth;

  const AppCalendarMonthGrid({
    super.key,
    required this.month,
    this.today,
    this.selectedDate,
    this.rangeStart,
    this.rangeEnd,
    this.eventCounts = const {},
    this.heatLevels,
    this.onDaySelected,
    this.onDayLongPress,
    this.onPreviousMonth,
    this.onNextMonth,
  });

  bool _inRange(DateTime date) {
    if (rangeStart == null || rangeEnd == null) return false;
    final d = _dateOnly(date);
    return !d.isBefore(_dateOnly(rangeStart!)) &&
        !d.isAfter(_dateOnly(rangeEnd!));
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final resolvedToday = _dateOnly(today ?? DateTime.now());
    final firstOfMonth = DateTime(month.year, month.month, 1);
    // DateTime.weekday: Monday=1..Sunday=7; the grid starts on Sunday.
    final leadingCount = firstOfMonth.weekday % 7;
    final gridStart = firstOfMonth.subtract(Duration(days: leadingCount));
    final gridDates = List<DateTime>.generate(
      42,
      (i) => gridStart.add(Duration(days: i)),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            _NavArrow(
              glyph: '‹',
              onPressed: onPreviousMonth,
              semanticLabel: 'Previous month',
            ),
            Expanded(
              child: Center(
                child: Text(
                  '${_monthNames[month.month - 1]} ${month.year}',
                  style: AppTypography.title.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
              ),
            ),
            _NavArrow(
              glyph: '›',
              onPressed: onNextMonth,
              semanticLabel: 'Next month',
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            for (final initial in _weekdayInitials)
              Expanded(
                child: Center(
                  child: Text(
                    initial,
                    style: AppTypography.caption.copyWith(
                      color: colors.textTertiary,
                    ),
                  ),
                ),
              ),
          ],
        ),
        for (var week = 0; week < 6; week++)
          Row(
            children: [
              for (final date in gridDates.sublist(week * 7, week * 7 + 7))
                Expanded(
                  child: _DayCell(
                    date: date,
                    inMonth: date.month == month.month,
                    today: resolvedToday,
                    selected: selectedDate != null
                        ? _isSameDay(selectedDate!, date)
                        : false,
                    inRange: _inRange(date),
                    isRangeStart:
                        rangeStart != null && _isSameDay(rangeStart!, date),
                    isRangeEnd: rangeEnd != null && _isSameDay(rangeEnd!, date),
                    eventCount: eventCounts[_dateOnly(date)],
                    heatLevel: heatLevels?[_dateOnly(date)],
                    onTap: onDaySelected,
                    onLongPress: onDayLongPress,
                  ),
                ),
            ],
          ),
        if (heatLevels != null) ...[
          const SizedBox(height: AppSpacing.sm),
          _HeatLegend(colors: colors),
        ],
      ],
    );
  }
}

class _NavArrow extends StatelessWidget {
  final String glyph;
  final VoidCallback? onPressed;
  final String semanticLabel;

  const _NavArrow({
    required this.glyph,
    required this.onPressed,
    required this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final enabled = onPressed != null;

    return Semantics(
      label: semanticLabel,
      button: true,
      child: GestureDetector(
        onTap: onPressed,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: Text(
              glyph,
              style: AppTypography.title.copyWith(
                color: enabled ? colors.textPrimary : colors.disabledFg,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  final DateTime date;
  final bool inMonth;
  final DateTime today;
  final bool selected;
  final bool inRange;
  final bool isRangeStart;
  final bool isRangeEnd;
  final int? eventCount;
  final int? heatLevel;
  final ValueChanged<DateTime>? onTap;
  final ValueChanged<DateTime>? onLongPress;

  const _DayCell({
    required this.date,
    required this.inMonth,
    required this.today,
    required this.selected,
    required this.inRange,
    required this.isRangeStart,
    required this.isRangeEnd,
    required this.eventCount,
    required this.heatLevel,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final isToday = _isSameDay(date, today);

    if (!inMonth) {
      return SizedBox(
        height: 44,
        child: Center(
          child: Text(
            '${date.day}',
            style: AppTypography.body.copyWith(color: colors.textTertiary),
          ),
        ),
      );
    }

    Color? heatColor;
    if (heatLevel != null) {
      final ramp = colors.chartSequential;
      final index = (heatLevel!.clamp(0, 3) / 3 * (ramp.length - 1)).round();
      heatColor = ramp[index];
    }

    return GestureDetector(
      key: ValueKey('appCalendarDay-${date.year}-${date.month}-${date.day}'),
      onTap: onTap != null ? () => onTap!(date) : null,
      onLongPress: onLongPress != null ? () => onLongPress!(date) : null,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: 44,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (inRange)
              Positioned.fill(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.horizontal(
                      left: isRangeStart
                          ? const Radius.circular(16)
                          : Radius.zero,
                      right: isRangeEnd
                          ? const Radius.circular(16)
                          : Radius.zero,
                    ),
                  ),
                ),
              ),
            if (heatColor != null)
              Positioned.fill(
                child: Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: heatColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected ? colors.primary : null,
                    border: isToday && !selected
                        ? Border.all(color: colors.primary, width: 1.5)
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      '${date.day}',
                      style: AppTypography.body.copyWith(
                        color: selected ? colors.onPrimary : colors.textPrimary,
                      ),
                    ),
                  ),
                ),
                if (eventCount != null && eventCount! > 0)
                  _EventIndicator(count: eventCount!, colors: colors),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EventIndicator extends StatelessWidget {
  final int count;
  final AppColors colors;

  const _EventIndicator({required this.count, required this.colors});

  @override
  Widget build(BuildContext context) {
    final dots = count > 3 ? 3 : count;
    final overflow = count > 3 ? count - 3 : 0;

    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < dots; i++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1),
              child: Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          if (overflow > 0)
            Text(
              '+$overflow',
              style: AppTypography.caption.copyWith(
                fontSize: 9,
                color: colors.textTertiary,
              ),
            ),
        ],
      ),
    );
  }
}

class _HeatLegend extends StatelessWidget {
  final AppColors colors;

  const _HeatLegend({required this.colors});

  @override
  Widget build(BuildContext context) {
    final ramp = colors.chartSequential;
    final swatchCount = ramp.length < 4 ? ramp.length : 4;

    return Row(
      children: [
        Text(
          'Less',
          style: AppTypography.caption.copyWith(color: colors.textTertiary),
        ),
        const SizedBox(width: AppSpacing.xs),
        for (var i = 0; i < swatchCount; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1),
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color:
                    ramp[(i / (swatchCount - 1) * (ramp.length - 1)).round()],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          'More',
          style: AppTypography.caption.copyWith(color: colors.textTertiary),
        ),
      ],
    );
  }
}
