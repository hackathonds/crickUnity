import 'dart:async';

import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_typography.dart';

/// DS §3.11 Scoreboard (hero component, Live view header). "Height 128,
/// `surface`, sticky under app bar" (the sticky-under-app-bar placement is
/// the screen's job — this widget is the header content itself).
///
/// "TV Scoreboard mode: same component scaled ×3, dark high-contrast" --
/// implemented as a genuine ×3 dimension scale (height + every font size)
/// rather than `Transform.scale` (which can blur/clip against a fixed
/// parent box); "dark high-contrast" reuses `AppColors.theme4` (this
/// system's actual dark theme tokens) rather than inventing raw black/
/// white, since a forced-dark override independent of the active theme
/// is exactly the scenario Theme 4 already exists for.
class AppScoreboard extends StatefulWidget {
  final String teamAShortName;
  final String teamBShortName;
  final ImageProvider? teamACrest;
  final ImageProvider? teamBCrest;
  final int runs;
  final int wickets;
  final String overs;
  final String contextStrip;
  final bool tvMode;
  final List<String> tvCyclingStrips;

  const AppScoreboard({
    super.key,
    required this.teamAShortName,
    required this.teamBShortName,
    required this.runs,
    required this.wickets,
    required this.overs,
    required this.contextStrip,
    this.teamACrest,
    this.teamBCrest,
    this.tvMode = false,
    this.tvCyclingStrips = const [],
  });

  @override
  State<AppScoreboard> createState() => AppScoreboardState();
}

class AppScoreboardState extends State<AppScoreboard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _wicketFlashController;
  Timer? _cycleTimer;
  int _cycleIndex = 0;
  late int _displayedRuns;

  @override
  void initState() {
    super.initState();
    _displayedRuns = widget.runs;
    _wicketFlashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );
    _startCycling();
  }

  void _startCycling() {
    _cycleTimer?.cancel();
    if (widget.tvCyclingStrips.length <= 1) return;
    _cycleTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (!mounted) return;
      setState(
        () => _cycleIndex = (_cycleIndex + 1) % widget.tvCyclingStrips.length,
      );
    });
  }

  @override
  void didUpdateWidget(covariant AppScoreboard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.runs != oldWidget.runs) {
      setState(() => _displayedRuns = oldWidget.runs);
    }
    if (widget.wickets > oldWidget.wickets) {
      _wicketFlashController.forward(from: 0);
    }
    if (widget.tvCyclingStrips != oldWidget.tvCyclingStrips) {
      _cycleIndex = 0;
      _startCycling();
    }
  }

  @override
  void dispose() {
    _wicketFlashController.dispose();
    _cycleTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = widget.tvMode ? 3.0 : 1.0;
    final colors = widget.tvMode
        ? AppColors.theme4
        : Theme.of(context).extension<AppColors>()!;

    return Container(
      key: const ValueKey('appScoreboardBox'),
      height: 128 * scale,
      color: colors.surface,
      padding: EdgeInsets.symmetric(
        horizontal: 16 * scale,
        vertical: 8 * scale,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _CrestAndName(
                crest: widget.teamACrest,
                name: widget.teamAShortName,
                scale: scale,
                colors: colors,
              ),
              SizedBox(width: 8 * scale),
              Text(
                'vs',
                style: TextStyle(
                  fontFamily: AppTypography.bodyFamily,
                  fontSize: 13 * scale,
                  color: colors.textTertiary,
                ),
              ),
              SizedBox(width: 8 * scale),
              _CrestAndName(
                crest: widget.teamBCrest,
                name: widget.teamBShortName,
                scale: scale,
                colors: colors,
              ),
            ],
          ),
          SizedBox(height: 4 * scale),
          AnimatedBuilder(
            animation: _wicketFlashController,
            builder: (context, child) {
              final flash = _wicketFlashController.value;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      TweenAnimationBuilder<int>(
                        key: const ValueKey('appScoreboardRunsOdometer'),
                        tween: IntTween(
                          begin: _displayedRuns,
                          end: widget.runs,
                        ),
                        duration: const Duration(milliseconds: 240),
                        builder: (context, runsValue, child) => Text(
                          '$runsValue/${widget.wickets}',
                          style: AppTypography.scoreboard.copyWith(
                            fontSize: 40 * scale,
                            height: 44 / 40,
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                      SizedBox(width: 8 * scale),
                      Text(
                        '(${widget.overs})',
                        style: TextStyle(
                          fontFamily: AppTypography.bodyFamily,
                          fontSize: 17 * scale,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  if (flash > 0 && flash < 1)
                    Container(
                      key: const ValueKey('appScoreboardWicketFlash'),
                      height: 2 * scale,
                      width: 120 * scale * flash,
                      color: colors.live,
                    ),
                ],
              );
            },
          ),
          SizedBox(height: 4 * scale),
          Text(
            widget.tvMode && widget.tvCyclingStrips.isNotEmpty
                ? widget.tvCyclingStrips[_cycleIndex %
                      widget.tvCyclingStrips.length]
                : widget.contextStrip,
            key: const ValueKey('appScoreboardContextStrip'),
            style: AppTypography.caption.copyWith(
              fontSize: 13 * scale,
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _CrestAndName extends StatelessWidget {
  final ImageProvider? crest;
  final String name;
  final double scale;
  final AppColors colors;

  const _CrestAndName({
    required this.crest,
    required this.name,
    required this.scale,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipOval(
          child: crest != null
              ? Image(
                  image: crest!,
                  width: 24 * scale,
                  height: 24 * scale,
                  fit: BoxFit.cover,
                )
              : Container(
                  width: 24 * scale,
                  height: 24 * scale,
                  color: colors.surfaceAlt,
                ),
        ),
        SizedBox(width: 4 * scale),
        Text(
          name,
          style: TextStyle(
            fontFamily: AppTypography.bodyFamily,
            fontSize: 13 * scale,
            color: colors.textPrimary,
          ),
        ),
      ],
    );
  }
}
