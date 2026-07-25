import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';

/// DS §3.19: "multi-step forms show Arc-segmented progress (not dots) with
/// step labels." A row of filled bar segments (one per step) rather than
/// the dot-indicator pattern common elsewhere, each with a label below.
class AppFormStepProgress extends StatelessWidget {
  final int stepCount;
  final int currentStep;
  final List<String> labels;

  const AppFormStepProgress({
    super.key,
    required this.stepCount,
    required this.currentStep,
    required this.labels,
  }) : assert(
         labels.length == stepCount,
         'AppFormStepProgress needs exactly one label per step',
       );

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Row(
      children: [
        for (var i = 0; i < stepCount; i++) ...[
          if (i > 0) const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  key: ValueKey('appFormStepProgressSegment$i'),
                  height: 4,
                  decoration: BoxDecoration(
                    color: i <= currentStep ? colors.primary : colors.divider,
                    borderRadius: AppRadius.fullRadius,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  labels[i],
                  style: AppTypography.label.copyWith(
                    color: i == currentStep
                        ? colors.textPrimary
                        : colors.textTertiary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
