import 'package:flutter/material.dart';

import '../components/app_segmented_control.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';

/// QA tool for E0-07 (sub-task 4/10): the sliding-thumb track (2-4
/// options) and the scrollable-chip-row fallback (5+ options).
class SegmentedControlScreen extends StatefulWidget {
  const SegmentedControlScreen({super.key});

  @override
  State<SegmentedControlScreen> createState() => _SegmentedControlScreenState();
}

class _SegmentedControlScreenState extends State<SegmentedControlScreen> {
  String _matchesFilter = 'Upcoming';
  String _format = 'T20';

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    Widget label(String text) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        text,
        style: AppTypography.label.copyWith(color: colors.textTertiary),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Segmented control (QA)')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            label('3 options — sliding track'),
            AppSegmentedControl<String>(
              options: const ['Upcoming', 'Live', 'Recent'],
              value: _matchesFilter,
              labelBuilder: (v) => v,
              onChanged: (v) => setState(() => _matchesFilter = v),
            ),
            const SizedBox(height: AppSpacing.xxl),
            label('6 options — falls back to a scrollable chip row'),
            AppSegmentedControl<String>(
              options: const [
                'T20',
                'ODI',
                'Test',
                'T10',
                'The Hundred',
                'Custom',
              ],
              value: _format,
              labelBuilder: (v) => v,
              onChanged: (v) => setState(() => _format = v),
            ),
          ],
        ),
      ),
    );
  }
}
