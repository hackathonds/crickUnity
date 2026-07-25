import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_elevation.dart';
import '../tokens/app_motion.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';
import 'app_button.dart';

/// DS §3.8: 36h, r-full track `surfaceAlt`, animated thumb `surface` e1
/// slides 160ms; 2-4 segments max; 5+ options become a scrollable chip row
/// instead (reusing [AppChipActionButton] from sub-task 1 rather than
/// building a second selectable-chip primitive).
class AppSegmentedControl<T> extends StatelessWidget {
  final List<T> options;
  final T value;
  final ValueChanged<T> onChanged;
  final String Function(T option) labelBuilder;

  const AppSegmentedControl({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    required this.labelBuilder,
  }) : assert(
         options.length >= 2,
         'AppSegmentedControl needs at least 2 options',
       );

  @override
  Widget build(BuildContext context) {
    if (options.length > 4) {
      return _ChipRowFallback<T>(
        options: options,
        value: value,
        onChanged: onChanged,
        labelBuilder: labelBuilder,
      );
    }

    final colors = Theme.of(context).extension<AppColors>()!;
    final brightness = Theme.of(context).brightness;
    final style = AppElevation.resolveSurfaceStyle(
      level: AppElevationLevel.e1,
      brightness: brightness,
      borderColor: colors.border,
    );
    var thumbColor = colors.surface;
    if (style.darkSurfaceLuminanceDelta > 0) {
      thumbColor = Color.lerp(
        thumbColor,
        Colors.white,
        style.darkSurfaceLuminanceDelta,
      )!;
    }

    final selectedIndex = options.indexOf(value);
    final duration = AppMotion.resolveDuration(context, AppMotionToken.fast);

    return Container(
      key: const ValueKey('appSegmentedControlTrack'),
      height: 36,
      decoration: BoxDecoration(
        color: colors.surfaceAlt,
        borderRadius: AppRadius.fullRadius,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final segmentWidth = constraints.maxWidth / options.length;
          return Stack(
            children: [
              AnimatedPositioned(
                key: const ValueKey('appSegmentedControlThumb'),
                duration: duration,
                curve: AppMotionCurves.standard,
                left: segmentWidth * selectedIndex,
                top: 2,
                bottom: 2,
                width: segmentWidth,
                child: Container(
                  decoration: BoxDecoration(
                    color: thumbColor,
                    borderRadius: AppRadius.fullRadius,
                    border: style.border != null
                        ? Border.fromBorderSide(style.border!)
                        : null,
                    boxShadow: style.shadows,
                  ),
                ),
              ),
              Row(
                children: [
                  for (final option in options)
                    Expanded(
                      child: GestureDetector(
                        onTap: () => onChanged(option),
                        behavior: HitTestBehavior.opaque,
                        child: Center(
                          child: Text(
                            labelBuilder(option),
                            style: AppTypography.button.copyWith(
                              color: option == value
                                  ? colors.textPrimary
                                  : colors.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ChipRowFallback<T> extends StatelessWidget {
  final List<T> options;
  final T value;
  final ValueChanged<T> onChanged;
  final String Function(T option) labelBuilder;

  const _ChipRowFallback({
    required this.options,
    required this.value,
    required this.onChanged,
    required this.labelBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      key: const ValueKey('appSegmentedControlChipRow'),
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final option in options) ...[
            AppChipActionButton(
              label: labelBuilder(option),
              selected: option == value,
              onPressed: () => onChanged(option),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}
