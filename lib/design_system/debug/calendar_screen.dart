import 'package:flutter/material.dart';

import '../components/app_calendar.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';

/// QA tool for E0-07 (sub-task 10/10): [AppCalendarMonthGrid] — plain
/// single-select, event dots, range-select, and the heat variant.
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _month;
  DateTime? _selected;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  late final Map<DateTime, int> _eventCounts;
  late final Map<DateTime, int> _heatLevels;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month, 1);
    _rangeStart = DateTime(now.year, now.month, 10);
    _rangeEnd = DateTime(now.year, now.month, 14);
    _eventCounts = {
      DateTime(now.year, now.month, 3): 1,
      DateTime(now.year, now.month, 8): 3,
      DateTime(now.year, now.month, 20): 5,
    };
    _heatLevels = {
      for (var day = 1; day <= 28; day++)
        DateTime(now.year, now.month, day): day % 4,
    };
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
      appBar: AppBar(title: const Text('Calendar (QA)')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            label('Single-select, event dots, month navigation'),
            AppCalendarMonthGrid(
              month: _month,
              selectedDate: _selected,
              eventCounts: _eventCounts,
              onDaySelected: (d) => setState(() => _selected = d),
              onDayLongPress: (d) => ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Peek agenda: ${d.day}/${d.month}')),
              ),
              onPreviousMonth: () => setState(
                () => _month = DateTime(_month.year, _month.month - 1, 1),
              ),
              onNextMonth: () => setState(
                () => _month = DateTime(_month.year, _month.month + 1, 1),
              ),
            ),
            label('Range-select — connective pill'),
            AppCalendarMonthGrid(
              month: _month,
              rangeStart: _rangeStart,
              rangeEnd: _rangeEnd,
              onDaySelected: (d) => setState(() {
                if (_rangeStart == null || _rangeEnd != null) {
                  _rangeStart = d;
                  _rangeEnd = null;
                } else {
                  _rangeEnd = d;
                }
              }),
            ),
            label('Heat variant — 4-step ramp + density legend'),
            AppCalendarMonthGrid(month: _month, heatLevels: _heatLevels),
          ],
        ),
      ),
    );
  }
}
