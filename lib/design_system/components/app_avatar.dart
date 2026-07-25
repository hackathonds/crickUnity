import 'package:flutter/material.dart';

import '../icons/app_icon.dart';
import '../icons/app_icon_id.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_typography.dart';
import 'app_arc_ring.dart';

/// DS §3.23: "Sizes 24/32/40/48/64/96". The widget's outer footprint is
/// always exactly this pixel value regardless of which optional adornments
/// (ring/presence/verified) are present — the Player Card anatomy note
/// (`[Avatar 48 + level ring 2px] 12 [Name...]`) lists the ring inside the
/// avatar's own box, not as extra layout width.
enum AppAvatarSize {
  xs(24),
  sm(32),
  md(40),
  lg(48),
  xl(64),
  xxl(96);

  final double px;
  const AppAvatarSize(this.px);
}

/// DS §3.23: "presence dot ... (online success / away warning)".
enum AppPresenceStatus { online, away }

const double _ringStrokeWidth = 2;
const double _ringGap = 2;
const double _ringMinPx = 40;
const double _verifiedMinPx = 48;

String _initialsFor(String name) {
  final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
  final letters = words.take(2).map((w) => w[0].toUpperCase());
  return letters.join();
}

Color _deterministicColorFor(String name, List<Color> ramp) {
  final hash = name.codeUnits.fold<int>(0, (acc, unit) => acc + unit);
  return ramp[hash % ramp.length];
}

/// DS §3.23's avatar primitive: sizes 24/32/40/48/64/96, initials fallback
/// on a deterministic theme-categorical color, a level ring at 40+ (when
/// [levelProgress] is given), a presence dot, and a verified badge at 48+.
class AppAvatar extends StatelessWidget {
  final AppAvatarSize size;
  final String name;
  final ImageProvider? image;
  final double? levelProgress;
  final AppPresenceStatus? presence;
  final bool verified;

  const AppAvatar({
    super.key,
    required this.size,
    required this.name,
    this.image,
    this.levelProgress,
    this.presence,
    this.verified = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final px = size.px;
    final showRing = px >= _ringMinPx && levelProgress != null;
    final showVerified = verified && px >= _verifiedMinPx;

    final contentInset = showRing ? _ringStrokeWidth + _ringGap : 0.0;
    final contentDiameter = px - contentInset * 2;

    return SizedBox(
      key: const ValueKey('appAvatarBox'),
      width: px,
      height: px,
      child: Stack(
        children: [
          Positioned(
            left: contentInset,
            top: contentInset,
            width: contentDiameter,
            height: contentDiameter,
            child: _AvatarContent(
              name: name,
              image: image,
              diameter: contentDiameter,
              colors: colors,
            ),
          ),
          if (showRing)
            Positioned.fill(
              child: AppArcRing(
                key: const ValueKey('appAvatarRing'),
                progress: levelProgress!,
                size: px,
                strokeWidth: _ringStrokeWidth,
                trackColor: colors.border,
                fillColor: colors.accent,
              ),
            ),
          if (presence != null)
            Align(
              alignment: Alignment.bottomRight,
              child: _PresenceDot(
                key: const ValueKey('appAvatarPresence'),
                status: presence!,
                colors: colors,
              ),
            ),
          if (showVerified)
            Align(
              alignment: const Alignment(0.75, -0.75),
              child: _VerifiedBadge(
                key: const ValueKey('appAvatarVerified'),
                colors: colors,
              ),
            ),
        ],
      ),
    );
  }
}

class _AvatarContent extends StatelessWidget {
  final String name;
  final ImageProvider? image;
  final double diameter;
  final AppColors colors;

  const _AvatarContent({
    required this.name,
    required this.image,
    required this.diameter,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    if (image != null) {
      return ClipOval(
        child: Image(
          image: image!,
          width: diameter,
          height: diameter,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              _Initials(name: name, diameter: diameter, colors: colors),
        ),
      );
    }
    return _Initials(name: name, diameter: diameter, colors: colors);
  }
}

class _Initials extends StatelessWidget {
  final String name;
  final double diameter;
  final AppColors colors;

  const _Initials({
    required this.name,
    required this.diameter,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final background = _deterministicColorFor(name, colors.chartCategorical);
    final foreground =
        ThemeData.estimateBrightnessForColor(background) == Brightness.dark
        ? Colors.white
        : Colors.black87;

    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      child: Center(
        child: Text(
          _initialsFor(name),
          style: TextStyle(
            fontFamily: AppTypography.bodyFamily,
            fontWeight: FontWeight.w600,
            fontSize: diameter * 0.4,
            color: foreground,
          ),
        ),
      ),
    );
  }
}

class _PresenceDot extends StatelessWidget {
  final AppPresenceStatus status;
  final AppColors colors;

  const _PresenceDot({super.key, required this.status, required this.colors});

  @override
  Widget build(BuildContext context) {
    final color = status == AppPresenceStatus.online
        ? colors.success
        : colors.warning;

    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(color: colors.surface, shape: BoxShape.circle),
      child: Center(
        child: Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      ),
    );
  }
}

class _VerifiedBadge extends StatelessWidget {
  final AppColors colors;

  const _VerifiedBadge({super.key, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(color: colors.surface, shape: BoxShape.circle),
      child: Center(
        child: AppIcon(
          id: AppIconId.verifiedCheck,
          semanticLabel: 'Verified',
          color: colors.verified,
          size: 16,
        ),
      ),
    );
  }
}
