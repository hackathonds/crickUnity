import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../icons/app_icon.dart';
import '../icons/app_icon_id.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_motion.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';

/// DS §3.22. Offline is treated as a variant of Error (icon swap + freshness
/// stamp), not a fourth scaffold, per the spec's own wording.

/// Formats a last-updated freshness stamp — DS example: "Showing data from
/// 2h ago".
String formatFreshnessStamp(DateTime lastUpdated, {DateTime? now}) {
  final reference = now ?? DateTime.now();
  final diff = reference.difference(lastUpdated);
  if (diff.inMinutes < 1) return 'Showing data from just now';
  if (diff.inHours < 1) return 'Showing data from ${diff.inMinutes}m ago';
  if (diff.inDays < 1) return 'Showing data from ${diff.inHours}h ago';
  return 'Showing data from ${diff.inDays}d ago';
}

/// A simple placeholder Arc illustration (DS's signature quarter-circle
/// motif) — a first-pass abstraction standing in for real per-context
/// empty-state/onboarding art, same category as E0-03's hand-drawn icons.
/// Public (not just this file's Empty scaffold) since E1-01's Welcome pager
/// reuses the same device rather than drawing a second one.
class AppArcIllustration extends StatelessWidget {
  final Color color;
  const AppArcIllustration({super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 120,
      child: CustomPaint(painter: _ArcPainter(color)),
    );
  }
}

class _ArcPainter extends CustomPainter {
  final Color color;
  const _ArcPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    final rect = Rect.fromLTWH(8, 8, size.width - 16, size.height - 16);
    canvas.drawArc(rect, -math.pi / 2, math.pi * 1.5, false, paint);
  }

  @override
  bool shouldRepaint(covariant _ArcPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// DS §3.22 Empty: Arc-line illustration, one-sentence invitation, one
/// Primary CTA (+ optional Tertiary), top-aligned at ~25% viewport.
class AppEmptyState extends StatelessWidget {
  final String message;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final String? tertiaryLabel;
  final VoidCallback? onTertiary;

  const AppEmptyState({
    super.key,
    required this.message,
    required this.primaryLabel,
    required this.onPrimary,
    this.tertiaryLabel,
    this.onTertiary,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return LayoutBuilder(
      builder: (context, constraints) {
        final topSpace = constraints.hasBoundedHeight
            ? constraints.maxHeight * 0.25
            : 0.0;
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              children: [
                SizedBox(height: topSpace),
                AppArcIllustration(color: colors.textTertiary),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: AppTypography.body.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onPrimary,
                    child: Text(primaryLabel),
                  ),
                ),
                if (tertiaryLabel != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  TextButton(
                    onPressed: onTertiary,
                    child: Text(tertiaryLabel!),
                  ),
                ],
                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// DS §3.22 Loading: skeletons mirror the real layout exactly, 1.2s L→R
/// shimmer, width-locked shapes. `.list` = 6 rows; `.card` = card shape.
enum AppSkeletonShape { list, card }

class AppLoadingState extends StatefulWidget {
  final AppSkeletonShape shape;
  final int rowCount;

  const AppLoadingState({
    super.key,
    this.shape = AppSkeletonShape.list,
    this.rowCount = 6,
  });

  @override
  State<AppLoadingState> createState() => _AppLoadingStateState();
}

class _AppLoadingStateState extends State<AppLoadingState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _motionInitialized = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_motionInitialized) return;
    _motionInitialized = true;
    if (AppMotion.isReduced(context)) {
      _controller.value = 0.5;
    } else {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final skeleton = widget.shape == AppSkeletonShape.list
        ? _ListSkeleton(rowCount: widget.rowCount, colors: colors)
        : _CardSkeleton(colors: colors);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final dx = -1.5 + _controller.value * 3.0;
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [colors.surfaceAlt, colors.border, colors.surfaceAlt],
              stops: const [0.0, 0.5, 1.0],
              begin: Alignment(dx - 0.3, 0),
              end: Alignment(dx + 0.3, 0),
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: skeleton,
    );
  }
}

class _ListSkeleton extends StatelessWidget {
  final int rowCount;
  final AppColors colors;
  const _ListSkeleton({required this.rowCount, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('appLoadingListSkeleton'),
      children: [
        for (var i = 0; i < rowCount; i++)
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.sm,
              horizontal: AppSpacing.lg,
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colors.surfaceAlt,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(height: 14, color: colors.surfaceAlt),
                      const SizedBox(height: AppSpacing.xs),
                      Container(
                        height: 12,
                        width: 120,
                        color: colors.surfaceAlt,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _CardSkeleton extends StatelessWidget {
  final AppColors colors;
  const _CardSkeleton({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('appLoadingCardSkeleton'),
      margin: const EdgeInsets.all(AppSpacing.lg),
      height: 140,
      decoration: BoxDecoration(
        color: colors.surfaceAlt,
        borderRadius: AppRadius.mdRadius,
      ),
    );
  }
}

/// DS §3.22 Error: cause in plain words + Retry + tertiary "Report a
/// problem"; `isOffline` swaps to the cloud-off icon and adds a freshness
/// stamp. `compact` renders a slim inline banner instead of a full
/// illustrated scaffold, so a caller can show it *above* preserved form
/// input rather than replacing the screen ("input preserved").
class AppErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final VoidCallback? onReportProblem;
  final bool isOffline;
  final DateTime? lastUpdated;
  final bool compact;

  const AppErrorState({
    super.key,
    required this.message,
    required this.onRetry,
    this.onReportProblem,
    this.isOffline = false,
    this.lastUpdated,
    this.compact = false,
  });

  Widget _icon(AppColors colors, double size) {
    if (isOffline) {
      return AppIcon(
        id: AppIconId.syncedOfflineCloud,
        semanticLabel: 'Offline',
        color: colors.textSecondary,
        size: size,
      );
    }
    return Icon(Icons.error_outline, color: colors.error, size: size);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final freshness = isOffline && lastUpdated != null
        ? formatFreshnessStamp(lastUpdated!)
        : null;

    if (compact) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: colors.surfaceAlt,
          borderRadius: AppRadius.smRadius,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _icon(colors, AppIconSize.dense),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message,
                    style: AppTypography.caption.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                  if (freshness != null)
                    Text(
                      freshness,
                      style: AppTypography.caption.copyWith(
                        color: colors.textTertiary,
                      ),
                    ),
                ],
              ),
            ),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _icon(colors, 48),
            const SizedBox(height: AppSpacing.lg),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.body.copyWith(color: colors.textPrimary),
            ),
            if (freshness != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                freshness,
                style: AppTypography.caption.copyWith(
                  color: colors.textTertiary,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onRetry,
                child: const Text('Retry'),
              ),
            ),
            if (onReportProblem != null) ...[
              const SizedBox(height: AppSpacing.sm),
              TextButton(
                onPressed: onReportProblem,
                child: const Text('Report a problem'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
