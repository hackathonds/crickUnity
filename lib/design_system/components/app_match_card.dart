import 'package:flutter/material.dart';

import '../icons/app_icon_id.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_motion.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';
import 'app_button.dart';
import 'app_card.dart';
import 'app_swipe_action_row.dart';
import 'app_tag_chip.dart';

/// DS §3.2.2's availability row — the only card with embedded actions.
enum AppAvailabilityStatus { yes, maybe, no }

/// DS §3.2.2's left-edge 3px status rail.
enum AppMatchStatusRail { responseNeeded, lockedIn, done, cancelled }

Color _railColor(AppColors colors, AppMatchStatusRail rail) => switch (rail) {
  AppMatchStatusRail.responseNeeded => colors.warning,
  AppMatchStatusRail.lockedIn => colors.success,
  AppMatchStatusRail.done => colors.textTertiary,
  AppMatchStatusRail.cancelled => colors.error,
};

/// A small rounded-square crest tile — no image-loading concern in scope
/// (same boundary as [AppAvatar]): accepts an optional [ImageProvider],
/// falls back to initials on a neutral tile. Kept local to this file since
/// it's specific to match/tournament entities in this sub-task.
class _Crest extends StatelessWidget {
  final String name;
  final ImageProvider? image;

  static const double _size = 32;

  const _Crest({required this.name, this.image});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.xs),
      child: image != null
          ? Image(image: image!, width: _size, height: _size, fit: BoxFit.cover)
          : Container(
              width: _size,
              height: _size,
              color: colors.surfaceAlt,
              alignment: Alignment.center,
              child: Text(
                initial,
                style: AppTypography.label.copyWith(color: colors.textPrimary),
              ),
            ),
    );
  }
}

/// DS §3.2.2 Match Card (132h). Wraps [AppCard] for the shared surface/
/// elevation/tap/long-press-menu shell; the row layout itself is bespoke.
class AppMatchCard extends StatelessWidget {
  final String teamAName;
  final String teamBName;
  final String format;
  final String dateGroundLine;
  final String? weatherSummary;
  final String squadLockCaption;
  final AppMatchStatusRail statusRail;
  final AppAvailabilityStatus? availability;
  final ValueChanged<AppAvailabilityStatus>? onAvailabilityChanged;
  final VoidCallback? onTap;
  final VoidCallback? onShare;
  final VoidCallback? onPin;
  final ImageProvider? teamACrest;
  final ImageProvider? teamBCrest;

  const AppMatchCard({
    super.key,
    required this.teamAName,
    required this.teamBName,
    required this.format,
    required this.dateGroundLine,
    required this.squadLockCaption,
    required this.statusRail,
    this.weatherSummary,
    this.availability,
    this.onAvailabilityChanged,
    this.onTap,
    this.onShare,
    this.onPin,
    this.teamACrest,
    this.teamBCrest,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    // DS §3.2's generic rule ("tap = whole card unless it contains >=2
    // actions, then only header navigates") doesn't quite fit here: this
    // card has no header row, but the availability chips still need to
    // consume their own taps. [onTap] is wired to an outer GestureDetector
    // instead of AppCard's own header-tap plumbing, so a chip tap (handled
    // by the chip's own, innermost GestureDetector) never also triggers
    // the card-level onTap.
    // Explicit full width: AppCard's content Column uses
    // crossAxisAlignment.start (shrink-wraps to its widest row) rather
    // than stretching, but this card needs to span its list's full width
    // like any other list row -- otherwise AppSwipeActionRow's drag-
    // distance threshold (a fraction of the width LayoutBuilder offers)
    // would be measured against a much wider box than the card actually
    // paints, requiring drags far past the visible card edge to commit.
    final card = GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: double.infinity,
        child: ClipRRect(
          borderRadius: AppRadius.mdRadius,
          child: Stack(
            children: [
              AppCard(
                child: Padding(
                  padding: const EdgeInsets.only(left: AppSpacing.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _Crest(name: teamAName, image: teamACrest),
                                const SizedBox(width: AppSpacing.sm),
                                Text(
                                  'vs',
                                  style: AppTypography.caption.copyWith(
                                    color: colors.textTertiary,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                _Crest(name: teamBName, image: teamBCrest),
                              ],
                            ),
                          ),
                          AppTagChip(label: format),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        dateGroundLine,
                        style: AppTypography.title.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          if (weatherSummary != null) ...[
                            Text(
                              weatherSummary!,
                              style: AppTypography.caption.copyWith(
                                color: colors.textSecondary,
                              ),
                            ),
                            Text(
                              ' · ',
                              style: AppTypography.caption.copyWith(
                                color: colors.textTertiary,
                              ),
                            ),
                          ],
                          Text(
                            squadLockCaption,
                            style: AppTypography.caption.copyWith(
                              color: colors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          for (final status
                              in AppAvailabilityStatus.values) ...[
                            AppChipActionButton(
                              label: switch (status) {
                                AppAvailabilityStatus.yes => 'Yes',
                                AppAvailabilityStatus.maybe => 'Maybe',
                                AppAvailabilityStatus.no => 'No',
                              },
                              selected: availability == status,
                              onPressed: onAvailabilityChanged == null
                                  ? null
                                  : () => onAvailabilityChanged!(status),
                            ),
                            if (status != AppAvailabilityStatus.values.last)
                              const SizedBox(width: AppSpacing.sm),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 3,
                  color: _railColor(colors, statusRail),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (onShare == null && onPin == null) return card;

    return AppSwipeActionRow(
      leftAction: onShare == null
          ? null
          : AppSwipeAction(
              icon: AppIconId.shareArc,
              label: 'Share',
              color: colors.primary,
              onTrigger: onShare!,
            ),
      // No dedicated "pin" glyph exists in DS §2.5's icon families;
      // reusing `bookmark` (closest existing "save this for later"
      // meaning) rather than hand-drawing a new one for this single use.
      rightAction: onPin == null
          ? null
          : AppSwipeAction(
              icon: AppIconId.bookmark,
              label: 'Pin',
              color: colors.accent,
              onTrigger: onPin!,
            ),
      child: card,
    );
  }
}

/// DS §3.2.3 Live Match Card (104h).
class AppLiveMatchCard extends StatefulWidget {
  final String teamAName;
  final String teamBName;
  final String scoreLine;
  final String? chasingLine;
  final String? keyMoment;
  final VoidCallback? onTap;
  final VoidCallback? onMute;

  const AppLiveMatchCard({
    super.key,
    required this.teamAName,
    required this.teamBName,
    required this.scoreLine,
    this.chasingLine,
    this.keyMoment,
    this.onTap,
    this.onMute,
  });

  @override
  State<AppLiveMatchCard> createState() => _AppLiveMatchCardState();
}

class _AppLiveMatchCardState extends State<AppLiveMatchCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AppMotion.isReduced(context)) {
      _pulseController.stop();
    } else if (!_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
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

    return GestureDetector(
      onTap: widget.onTap,
      onLongPress: widget.onMute,
      child: AppCard(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    AnimatedBuilder(
                      key: const ValueKey('appLiveMatchCardDot'),
                      animation: _pulseController,
                      builder: (context, child) {
                        final t = AppMotion.isReduced(context)
                            ? 1.0
                            : 0.4 + (0.6 * _pulseController.value);
                        return Opacity(opacity: t, child: child);
                      },
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: colors.live,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      '${widget.teamAName} vs ${widget.teamBName}',
                      style: AppTypography.caption.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  widget.scoreLine,
                  style: AppTypography.scoreboard.copyWith(
                    fontSize: 28,
                    height: 1,
                    color: colors.textPrimary,
                  ),
                ),
                if (widget.chasingLine != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    widget.chasingLine!,
                    style: AppTypography.caption.copyWith(
                      fontWeight: FontWeight.w500,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
            Positioned(
              right: 0,
              top: 0,
              child: AnimatedSwitcher(
                duration: AppMotion.resolveDuration(
                  context,
                  AppMotionToken.standard,
                ),
                transitionBuilder: (child, animation) {
                  if (AppMotion.isReduced(context)) {
                    return FadeTransition(opacity: animation, child: child);
                  }
                  return SlideTransition(
                    position: Tween(
                      begin: const Offset(1, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  );
                },
                child: widget.keyMoment == null
                    ? const SizedBox.shrink(key: ValueKey('noKeyMoment'))
                    : AppTagChip(
                        key: ValueKey(widget.keyMoment),
                        label: widget.keyMoment!,
                        variant: AppTagChipVariant.error,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// DS §3.2.4 Tournament Card (116h).
class AppTournamentCard extends StatelessWidget {
  final String name;
  final bool sanctioned;
  final String teamsCountDatesEntryFeeLine;
  final String? myTeamPosition;
  final DateTime? registrationCloses;
  final VoidCallback? onTap;
  final VoidCallback? onRegister;
  final ImageProvider? banner;

  const AppTournamentCard({
    super.key,
    required this.name,
    required this.teamsCountDatesEntryFeeLine,
    this.sanctioned = false,
    this.myTeamPosition,
    this.registrationCloses,
    this.onTap,
    this.onRegister,
    this.banner,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final closingSoon =
        registrationCloses != null &&
        registrationCloses!.difference(DateTime.now()).inHours < 48;

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.md),
            ),
            child: AspectRatio(
              aspectRatio: 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  banner != null
                      ? Image(image: banner!, fit: BoxFit.cover)
                      : Container(color: colors.surfaceAlt),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          colors.overlay.withValues(alpha: 0.4),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: AppTypography.title.copyWith(
                          color: colors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (sanctioned) ...[
                      const SizedBox(width: AppSpacing.sm),
                      const AppTagChip(
                        label: 'Sanctioned',
                        variant: AppTagChipVariant.verified,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  teamsCountDatesEntryFeeLine,
                  style: AppTypography.caption.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: closingSoon
                      ? const EdgeInsets.all(AppSpacing.sm)
                      : EdgeInsets.zero,
                  decoration: closingSoon
                      ? BoxDecoration(
                          color: colors.warning.withValues(alpha: 0.12),
                          borderRadius: AppRadius.xsRadius,
                        )
                      : null,
                  child: myTeamPosition != null
                      ? AppTagChip(label: myTeamPosition!)
                      : AppButton(
                          variant: AppButtonVariant.tertiary,
                          label: registrationCloses != null
                              ? 'Register by ${registrationCloses!.day}/${registrationCloses!.month}'
                              : 'Register',
                          onPressed: onRegister,
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
