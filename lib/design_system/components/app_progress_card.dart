import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_motion.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';
import 'app_arc_ring.dart';
import 'app_card.dart';
import 'app_tag_chip.dart';

/// DS §3.2.8: "ring when single metric, bar when target text matters" —
/// the card doesn't decide this itself, the caller picks.
enum AppProgressCardVariant { ring, bar }

/// DS §3.2.8 Progress Card (challenge, 112h). A genuine `AppCard` (unlike
/// Reward Card, whose gradient tile doesn't fit that shell).
class AppProgressCard extends StatefulWidget {
  final String title;
  final String rewardLabel;
  final AppProgressCardVariant variant;
  final double progress;
  final String progressCaption;
  final bool failed;
  final String? failedCopy;

  const AppProgressCard({
    super.key,
    required this.title,
    required this.rewardLabel,
    required this.variant,
    required this.progress,
    required this.progressCaption,
    this.failed = false,
    this.failedCopy,
  });

  @override
  State<AppProgressCard> createState() => _AppProgressCardState();
}

class _AppProgressCardState extends State<AppProgressCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseScale;
  bool _pulseInitialized = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _pulseScale =
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.08), weight: 1),
          TweenSequenceItem(tween: Tween(begin: 1.08, end: 1.0), weight: 1),
        ]).animate(
          CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
        );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_pulseInitialized) return;
    _pulseInitialized = true;
    // DS §3.2.8: "≥80% = ring pulses gently once on screen-enter" -- a
    // one-time flourish, not information, so it's simply skipped under
    // reduced motion rather than collapsed to a fade.
    if (widget.progress >= 0.8 &&
        !widget.failed &&
        !AppMotion.isReduced(context)) {
      _pulseController.forward();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    Widget content = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.variant == AppProgressCardVariant.ring) ...[
          AnimatedBuilder(
            key: const ValueKey('appProgressCardPulse'),
            animation: _pulseScale,
            builder: (context, child) {
              return Transform.scale(scale: _pulseScale.value, child: child);
            },
            child: AppArcRing(
              key: const ValueKey('appProgressCardRing'),
              progress: widget.progress,
              size: 44,
              trackColor: colors.border,
              fillColor: colors.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
        ],
        Expanded(
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
                  const SizedBox(width: AppSpacing.sm),
                  AppTagChip(label: widget.rewardLabel),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              if (widget.variant == AppProgressCardVariant.bar) ...[
                ClipRRect(
                  borderRadius: AppRadius.fullRadius,
                  child: SizedBox(
                    key: const ValueKey('appProgressCardBar'),
                    height: 6,
                    child: LinearProgressIndicator(
                      value: widget.progress.clamp(0.0, 1.0),
                      backgroundColor: colors.border,
                      valueColor: AlwaysStoppedAnimation(colors.primary),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
              ],
              Text(
                widget.failed
                    ? (widget.failedCopy ?? '')
                    : widget.progressCaption,
                style: AppTypography.caption.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    if (widget.failed) {
      content = ColorFiltered(
        key: const ValueKey('appProgressCardDesaturated'),
        colorFilter: const ColorFilter.matrix(<double>[
          0.2126,
          0.7152,
          0.0722,
          0,
          0,
          0.2126,
          0.7152,
          0.0722,
          0,
          0,
          0.2126,
          0.7152,
          0.0722,
          0,
          0,
          0,
          0,
          0,
          1,
          0,
        ]),
        child: content,
      );
    }

    return AppCard(child: content);
  }
}
