import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_button.dart';
import '../design_system/components/app_dropdown_field.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'guardian_gate_provider.dart';

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

int _daysInMonth(int year, int month) => DateTime(year, month + 1, 0).day;

/// DS §11.3 Guardian gate, step 1: "DOB step detects minor." Three
/// Dropdown-as-sheet fields (DS §3.7) rather than the month-grid Calendar
/// component (E0-07) -- a calendar built for browsing nearby months is a
/// poor fit for jumping to a birth year decades back; the dropdown's own
/// "search row if >8 options" (already spec'd) makes the ~100-entry year
/// list searchable for free.
class DobStepScreen extends ConsumerStatefulWidget {
  final void Function(bool isMinor) onContinue;

  const DobStepScreen({super.key, required this.onContinue});

  @override
  ConsumerState<DobStepScreen> createState() => _DobStepScreenState();
}

class _DobStepScreenState extends ConsumerState<DobStepScreen> {
  int? _day;
  int? _month;
  int? _year;

  late final int _currentYear = DateTime.now().year;
  late final List<int> _years = [
    for (var y = _currentYear; y >= _currentYear - 100; y--) y,
  ];

  List<int> get _days {
    final maxDay = (_year != null && _month != null)
        ? _daysInMonth(_year!, _month!)
        : 31;
    return [for (var d = 1; d <= maxDay; d++) d];
  }

  void _handleMonthOrYearChanged() {
    final maxDay = (_year != null && _month != null)
        ? _daysInMonth(_year!, _month!)
        : 31;
    if (_day != null && _day! > maxDay) {
      setState(() => _day = maxDay);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final isComplete = _day != null && _month != null && _year != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Create your account')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "What's your date of birth?",
              style: AppTypography.h2.copyWith(color: colors.textPrimary),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'This helps us keep younger players safe.',
              style: AppTypography.body.copyWith(color: colors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: AppDropdownField<int>(
                    key: const ValueKey('dobDayField'),
                    label: 'Day',
                    value: _day,
                    options: _days,
                    labelBuilder: (d) => '$d',
                    onChanged: (d) => setState(() => _day = d),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  flex: 2,
                  child: AppDropdownField<int>(
                    key: const ValueKey('dobMonthField'),
                    label: 'Month',
                    value: _month,
                    options: const [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
                    labelBuilder: (m) => _monthNames[m - 1],
                    onChanged: (m) => setState(() {
                      _month = m;
                      _handleMonthOrYearChanged();
                    }),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppDropdownField<int>(
                    key: const ValueKey('dobYearField'),
                    label: 'Year',
                    value: _year,
                    options: _years,
                    labelBuilder: (y) => '$y',
                    onChanged: (y) => setState(() {
                      _year = y;
                      _handleMonthOrYearChanged();
                    }),
                  ),
                ),
              ],
            ),
            const Spacer(),
            AppButton(
              key: const ValueKey('dobStepContinue'),
              variant: AppButtonVariant.primary,
              label: 'Continue',
              fullWidth: true,
              onPressed: isComplete
                  ? () {
                      final dob = DateTime(_year!, _month!, _day!);
                      final isMinor = ref
                          .read(guardianGateProvider.notifier)
                          .submitDateOfBirth(dob);
                      widget.onContinue(isMinor);
                    }
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
