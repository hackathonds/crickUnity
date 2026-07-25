import 'package:flutter/material.dart';

import '../icons/app_icon.dart';
import '../icons/app_icon_id.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_motion.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';
import 'app_avatar.dart';
import 'app_tag_chip.dart';

/// DS §3.2.1's "trend arrow" — up = success, down = textTertiary,
/// reusing [AppDeltaChip]'s established color convention even though
/// this isn't a chip (no background here, just a bare arrow beside the
/// rating number).
enum AppRatingTrend { up, down }

/// DS §3.2.1 Player Card (list, 72h). A plain row, not an `AppCard` — its
/// anatomy never mentions a surface/border/elevation, and "Selected
/// state: 1.5px primary border" implies the border is state-conditional,
/// not an always-present shell.
class AppPlayerCard extends StatelessWidget {
  final String name;
  final List<String> roles;
  final String teamCityLine;
  final String rating;
  final AppRatingTrend? trend;
  final double? levelProgress;
  final ImageProvider? avatarImage;
  final bool selected;
  final bool isLoading;
  final VoidCallback? onTap;

  const AppPlayerCard({
    super.key,
    required this.name,
    required this.roles,
    required this.teamCityLine,
    required this.rating,
    this.trend,
    this.levelProgress,
    this.avatarImage,
    this.selected = false,
    this.isLoading = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        key: const ValueKey('appPlayerCardBox'),
        height: 72,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          borderRadius: AppRadius.mdRadius,
          border: selected
              ? Border.all(color: colors.primary, width: 1.5)
              : null,
        ),
        child: isLoading
            ? const _PlayerCardSkeleton()
            : Row(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      AppAvatar(
                        size: AppAvatarSize.lg,
                        name: name,
                        image: avatarImage,
                        levelProgress: levelProgress,
                      ),
                      if (selected)
                        const Positioned(
                          right: -2,
                          bottom: -2,
                          child: _SelectionCheckBadge(),
                        ),
                    ],
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                name,
                                style: AppTypography.title.copyWith(
                                  color: colors.textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            for (final role in roles) ...[
                              const SizedBox(width: AppSpacing.xs),
                              AppTagChip(label: role),
                            ],
                          ],
                        ),
                        Text(
                          teamCityLine,
                          style: AppTypography.caption.copyWith(
                            color: colors.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        rating,
                        style: AppTypography.stat.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                      if (trend != null)
                        Text(
                          trend == AppRatingTrend.up ? '▲' : '▼',
                          style: AppTypography.caption.copyWith(
                            fontSize: 12,
                            color: trend == AppRatingTrend.up
                                ? colors.success
                                : colors.textTertiary,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}

class _SelectionCheckBadge extends StatelessWidget {
  const _SelectionCheckBadge();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(color: colors.surface, shape: BoxShape.circle),
      child: Center(
        child: AppIcon(
          id: AppIconId.verifiedCheck,
          semanticLabel: 'Selected',
          color: colors.primary,
          size: 16,
        ),
      ),
    );
  }
}

/// DS §3.2.1's "Skeleton: circle + two bars (60%/40%)." The 1.2s L→R
/// shimmer (DS §3 intro's global loading rule) is duplicated locally
/// (the same small mechanism `AppLoadingState` uses in
/// `app_state_scaffolds.dart`) rather than generalizing that shared
/// component's `AppSkeletonShape` enum for this one new caller.
class _PlayerCardSkeleton extends StatefulWidget {
  const _PlayerCardSkeleton();

  @override
  State<_PlayerCardSkeleton> createState() => _PlayerCardSkeletonState();
}

class _PlayerCardSkeletonState extends State<_PlayerCardSkeleton>
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

    final shape = Row(
      key: const ValueKey('appPlayerCardSkeleton'),
      children: [
        Container(
          width: 48,
          height: 48,
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
              FractionallySizedBox(
                widthFactor: 0.6,
                child: Container(height: 14, color: colors.surfaceAlt),
              ),
              const SizedBox(height: AppSpacing.xs),
              FractionallySizedBox(
                widthFactor: 0.4,
                child: Container(height: 12, color: colors.surfaceAlt),
              ),
            ],
          ),
        ),
      ],
    );

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
      child: shape,
    );
  }
}
