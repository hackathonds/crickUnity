import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;

import '../tokens/app_colors.dart';
import '../tokens/app_elevation.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';
import 'app_button.dart';
import 'app_segmented_control.dart';

/// DS §3.3 Charts (shared rules): "Container r-md, padding 16, title +
/// period segmented control top; axis text 11 textTertiary; gridlines
/// hairline divider at 40%; tooltips = tap-and-hold scrub with haptic tick
/// per datapoint, value bubble follows finger, sticky legend. Every chart
/// offers a table view toggle."
///
/// This is the shared shell only -- the 23 individual visualizations
/// (Manhattan, Worm, Wagon wheel, Radar, ...) are E13-01, out of scope here.
/// Callers supply their own plot as [chart] and, to drive the scrub
/// tooltip, a fraction-to-value lookup ([onScrub]).
///
/// `HapticFeedback.selectionClick()` (from `flutter/services.dart`, part of
/// the Flutter SDK -- no external package) drives the scrub's haptic tick.
/// A prior sub-task (Swipe action row) left its own commit-point haptic
/// unwired on the mistaken premise that "no haptics package/call exists
/// anywhere else in this codebase yet" -- `HapticFeedback` needs no package,
/// so that reasoning doesn't hold here; this is a genuine platform-channel
/// call, wired directly.
class AppChartLegendItem {
  final Color color;
  final String label;

  const AppChartLegendItem({required this.color, required this.label});
}

/// The label shown in the scrub tooltip bubble for a given datapoint.
class AppChartScrubValue {
  final String label;

  const AppChartScrubValue(this.label);
}

/// Maps a scrub position (0.0 at the plot's left edge, 1.0 at its right
/// edge) to the value under the finger, or null if there's no datapoint
/// there. Owned by the caller since only it knows the plotted data.
typedef AppChartScrubResolver = AppChartScrubValue? Function(double fraction);

class AppChartShell extends StatefulWidget {
  /// DS §3.3 "axis text 11 textTertiary" -- 11px has no named type-ramp
  /// role (the ramp's own stated floor is 13, DS §2.4); this is the same
  /// kind of explicit, smaller-than-ramp exception already composed
  /// directly for Scoreboard's overs text and the money styles' currency
  /// symbol. Exposed here (color left to the caller, since `textTertiary`
  /// varies by theme) for the individual chart visualizations (E13-01) that
  /// draw their own axis labels inside [chart].
  static const TextStyle axisTextStyle = TextStyle(
    fontFamily: AppTypography.bodyFamily,
    fontSize: 11,
  );

  final String title;
  final List<String>? periods;
  final int selectedPeriodIndex;
  final ValueChanged<int>? onPeriodChanged;
  final Widget chart;
  final double chartHeight;
  final int gridlineCount;
  final List<AppChartLegendItem> legend;
  final AppChartScrubResolver? onScrub;
  final WidgetBuilder tableViewBuilder;

  const AppChartShell({
    super.key,
    required this.title,
    required this.chart,
    required this.tableViewBuilder,
    this.periods,
    this.selectedPeriodIndex = 0,
    this.onPeriodChanged,
    this.chartHeight = 200,
    this.gridlineCount = 4,
    this.legend = const [],
    this.onScrub,
  }) : assert(
         periods == null || onPeriodChanged != null,
         'onPeriodChanged is required whenever periods is provided',
       );

  @override
  State<AppChartShell> createState() => AppChartShellState();
}

class AppChartShellState extends State<AppChartShell> {
  bool _tableView = false;
  double? _scrubDx;
  String? _scrubLabel;
  int? _lastHapticBucket;

  void _onScrubUpdate(Offset local, double width) {
    if (widget.onScrub == null || width <= 0) return;
    final dx = local.dx.clamp(0.0, width);
    final fraction = dx / width;
    final value = widget.onScrub!(fraction);

    // Coarse buckets so the haptic ticks once per datapoint crossed,
    // not once per pixel of finger movement.
    final bucket = (fraction * 40).round();
    if (bucket != _lastHapticBucket) {
      _lastHapticBucket = bucket;
      HapticFeedback.selectionClick();
    }

    setState(() {
      _scrubDx = dx;
      _scrubLabel = value?.label;
    });
  }

  void _endScrub() {
    _lastHapticBucket = null;
    setState(() {
      _scrubDx = null;
      _scrubLabel = null;
    });
  }

  double _bubbleLeft(double width) {
    const bubbleWidth = 72.0;
    final raw = (_scrubDx ?? 0) - bubbleWidth / 2;
    return raw.clamp(0.0, math.max(0.0, width - bubbleWidth));
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Container(
      key: const ValueKey('appChartShellBox'),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AppRadius.mdRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.title,
                  style: AppTypography.title.copyWith(
                    color: colors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (widget.periods != null) ...[
                const SizedBox(width: AppSpacing.md),
                SizedBox(
                  width: 168,
                  child: AppSegmentedControl<int>(
                    options: List.generate(widget.periods!.length, (i) => i),
                    value: widget.selectedPeriodIndex,
                    onChanged: widget.onPeriodChanged!,
                    labelBuilder: (i) => widget.periods![i],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (_tableView)
            widget.tableViewBuilder(context)
          else
            SizedBox(
              key: const ValueKey('appChartShellPlotArea'),
              height: widget.chartHeight,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onLongPressStart: widget.onScrub == null
                        ? null
                        : (details) =>
                              _onScrubUpdate(details.localPosition, width),
                    onLongPressMoveUpdate: widget.onScrub == null
                        ? null
                        : (details) =>
                              _onScrubUpdate(details.localPosition, width),
                    onLongPressEnd: widget.onScrub == null
                        ? null
                        : (_) => _endScrub(),
                    onLongPressCancel: widget.onScrub == null
                        ? null
                        : _endScrub,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _GridlinePainter(
                              color: colors.divider.withValues(alpha: 0.4),
                              count: widget.gridlineCount,
                            ),
                          ),
                        ),
                        Positioned.fill(child: widget.chart),
                        if (_scrubDx != null)
                          Positioned(
                            left: _scrubDx!.clamp(
                              0.0,
                              math.max(0.0, width - 1),
                            ),
                            top: 0,
                            bottom: 0,
                            child: Container(
                              key: const ValueKey('appChartShellScrubLine'),
                              width: 1,
                              color: colors.textTertiary,
                            ),
                          ),
                        if (_scrubDx != null && _scrubLabel != null)
                          Positioned(
                            left: _bubbleLeft(width),
                            top: 0,
                            child: _ScrubBubble(
                              label: _scrubLabel!,
                              colors: colors,
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          if (widget.legend.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              key: const ValueKey('appChartShellLegend'),
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.xs,
              children: [
                for (final item in widget.legend)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: item.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        item.label,
                        style: AppTypography.caption.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.xs),
          Align(
            alignment: Alignment.centerLeft,
            child: AppButton(
              key: const ValueKey('appChartShellTableToggle'),
              variant: AppButtonVariant.tertiary,
              label: _tableView ? 'Chart view' : 'Table view',
              onPressed: () => setState(() => _tableView = !_tableView),
            ),
          ),
        ],
      ),
    );
  }
}

class _GridlinePainter extends CustomPainter {
  final Color color;
  final int count;

  const _GridlinePainter({required this.color, required this.count});

  @override
  void paint(Canvas canvas, Size size) {
    if (count <= 0) return;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    for (var i = 0; i < count; i++) {
      final y = size.height * (i + 1) / (count + 1);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridlinePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.count != count;
}

class _ScrubBubble extends StatelessWidget {
  final String label;
  final AppColors colors;

  const _ScrubBubble({required this.label, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('appChartShellScrubBubble'),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: colors.textPrimary,
        borderRadius: AppRadius.xsRadius,
        boxShadow: AppElevation.e2.toBoxShadows(),
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(color: colors.surface),
      ),
    );
  }
}
