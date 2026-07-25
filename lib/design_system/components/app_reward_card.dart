import 'package:flutter/material.dart';

import '../icons/app_icon.dart';
import '../icons/app_icon_id.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_motion.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';

/// DS §3.2.7's three reward tile types.
enum AppRewardType { scratch, spin, chest }

AppIconId _iconFor(AppRewardType type) => switch (type) {
  AppRewardType.scratch => AppIconId.scratch,
  AppRewardType.spin => AppIconId.spin,
  AppRewardType.chest => AppIconId.chest,
};

/// DS §3.2.7 Reward Card (scratch/spin/chest, 140×140 grid tiles). Not an
/// `AppCard` — its r-lg radius and metallic-gradient fill don't fit that
/// shell (hardcoded r-md, `colors.surface` fill), the same reasoning
/// already used for Expense Row / Player Card.
class AppRewardCard extends StatefulWidget {
  final AppRewardType type;
  final bool unclaimed;
  final int count;
  final VoidCallback? onTap;

  const AppRewardCard({
    super.key,
    required this.type,
    this.unclaimed = false,
    this.count = 1,
    this.onTap,
  });

  @override
  State<AppRewardCard> createState() => _AppRewardCardState();
}

class _AppRewardCardState extends State<AppRewardCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glintController;
  bool _motionInitialized = false;

  @override
  void initState() {
    super.initState();
    _glintController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_motionInitialized) return;
    _motionInitialized = true;
    // DS §3.2.7: "Arc glint sweep every 6s (off in reduced motion)" --
    // fully off, not collapsed to a fade, per the spec's literal wording.
    if (!AppMotion.isReduced(context)) {
      _glintController.repeat();
    }
  }

  @override
  void dispose() {
    _glintController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final lightCoin = Color.lerp(colors.coin, Colors.white, 0.35)!;

    return GestureDetector(
      onTap: widget.onTap,
      child: SizedBox(
        key: const ValueKey('appRewardCardBox'),
        width: 140,
        height: 140,
        child: ClipRRect(
          borderRadius: AppRadius.lgRadius,
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [colors.coin, lightCoin, colors.coin],
                    ),
                  ),
                ),
              ),
              AnimatedBuilder(
                key: const ValueKey('appRewardCardGlint'),
                animation: _glintController,
                builder: (context, child) {
                  final dx = -1.5 + _glintController.value * 3.0;
                  return Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment(dx - 0.2, -1),
                          end: Alignment(dx + 0.2, 1),
                          colors: [
                            Colors.transparent,
                            Colors.white.withValues(alpha: 0.25),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              Center(
                child: AppIcon(
                  id: _iconFor(widget.type),
                  semanticLabel: widget.type.name,
                  color: colors.onPrimary,
                  size: 40,
                ),
              ),
              if (widget.unclaimed)
                Positioned(
                  top: AppSpacing.sm,
                  right: AppSpacing.sm,
                  child: Container(
                    key: const ValueKey('appRewardCardUnclaimedBadge'),
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: colors.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              if (widget.count > 1)
                Positioned(
                  bottom: AppSpacing.sm,
                  right: AppSpacing.sm,
                  child: Container(
                    key: const ValueKey('appRewardCardCountPill'),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.35),
                      borderRadius: AppRadius.fullRadius,
                    ),
                    child: Text(
                      '×${widget.count}',
                      style: AppTypography.label.copyWith(color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
