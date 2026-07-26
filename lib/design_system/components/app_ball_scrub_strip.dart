import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';

/// A single ball's outcome. No color-per-outcome table exists anywhere
/// in the frozen docs (the Manhattan chart spec, §3.3, only says "wicket
/// dots 6 on top" without a general outcome-color mapping) -- the
/// mapping below is a reasonable, flagged-as-open-question default:
/// dot/singles neutral ink, four = primary, six = accent, wicket =
/// error, wide/no-ball = warning.
enum AppBallOutcome { dot, runs, four, six, wicket, extra }

Color _colorFor(AppColors colors, AppBallOutcome outcome) => switch (outcome) {
  AppBallOutcome.dot => colors.border,
  AppBallOutcome.runs => colors.textPrimary,
  AppBallOutcome.four => colors.primary,
  AppBallOutcome.six => colors.accent,
  AppBallOutcome.wicket => colors.error,
  AppBallOutcome.extra => colors.warning,
};

class AppBallScrubStripEntry {
  final int over;
  final int ballInOver;
  final AppBallOutcome outcome;

  const AppBallScrubStripEntry({
    required this.over,
    required this.ballInOver,
    required this.outcome,
  });
}

const double _tickSpacing = 16;

/// DS §3.4's "Scrub-bar variant (ball timeline): horizontal strip 48h,
/// balls as 8px ticks colored by outcome, drag = scrub with over/ball
/// readout bubble."
class AppBallScrubStrip extends StatefulWidget {
  final List<AppBallScrubStripEntry> balls;
  final ValueChanged<AppBallScrubStripEntry>? onScrub;

  const AppBallScrubStrip({super.key, required this.balls, this.onScrub});

  @override
  State<AppBallScrubStrip> createState() => AppBallScrubStripState();
}

class AppBallScrubStripState extends State<AppBallScrubStrip> {
  int? _scrubIndex;

  void _updateScrub(Offset localPosition) {
    if (widget.balls.isEmpty) return;
    final index = (localPosition.dx / _tickSpacing).round().clamp(
      0,
      widget.balls.length - 1,
    );
    if (index == _scrubIndex) return;
    setState(() => _scrubIndex = index);
    widget.onScrub?.call(widget.balls[index]);
  }

  void _endScrub() {
    if (_scrubIndex == null) return;
    setState(() => _scrubIndex = null);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final scrubbing = _scrubIndex != null;
    final scrubbed = scrubbing ? widget.balls[_scrubIndex!] : null;

    return SizedBox(
      key: const ValueKey('appBallScrubStripBox'),
      height: 48,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          GestureDetector(
            // Not independently scrollable -- nesting a scrollable here
            // would compete with this same drag gesture for the scrub
            // interaction on the same axis. Callers needing more balls
            // than fit in the available width place this inside their
            // own scroll container (DS only specifies "drag = scrub",
            // not independent scrolling).
            onHorizontalDragStart: (details) =>
                _updateScrub(details.localPosition),
            onHorizontalDragUpdate: (details) =>
                _updateScrub(details.localPosition),
            onHorizontalDragEnd: (_) => _endScrub(),
            onHorizontalDragCancel: _endScrub,
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              height: 48,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    for (var i = 0; i < widget.balls.length; i++)
                      Container(
                        width: 8,
                        height: 24,
                        margin: const EdgeInsets.symmetric(
                          horizontal: (_tickSpacing - 8) / 2,
                        ),
                        decoration: BoxDecoration(
                          color: _colorFor(colors, widget.balls[i].outcome),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          if (scrubbed != null)
            Positioned(
              top: -32,
              left: (_scrubIndex! * _tickSpacing) - 20 + AppSpacing.sm,
              child: Container(
                key: const ValueKey('appBallScrubStripReadout'),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: colors.textPrimary,
                  borderRadius: AppRadius.xsRadius,
                ),
                child: Text(
                  '${scrubbed.over}.${scrubbed.ballInOver}',
                  style: AppTypography.caption.copyWith(color: colors.bg),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
