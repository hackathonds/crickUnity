import 'package:flutter/material.dart';

import '../design_system/components/app_avatar.dart';
import '../design_system/components/app_badge_tile.dart';
import '../design_system/components/app_button.dart';
import '../design_system/components/app_tag_chip.dart';
import '../design_system/icons/app_icon.dart';
import '../design_system/icons/app_icon_id.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_motion.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'profile_blocked_view.dart';
import 'profile_locked_card.dart';
import 'profile_models.dart';
import 'profile_overview_tab.dart';

const List<String> _profileTabLabels = [
  'Overview',
  'Stats',
  'Media',
  'Timeline',
];

/// DS §7 screen 4-5 (My Profile / Public Profile), viewer-relative: cover
/// Arc-mask, avatar 96 overlapping -48, name/verified/role chips, action
/// row per relation, pinned badge strip, sticky stat header strip, tabs.
///
/// Stats tab charts are E2-03 (depends on E13-01, also unbuilt) and Media/
/// Timeline have no data model yet -- all three render a placeholder
/// noting their real story, same "stand-in for a later screen" pattern
/// used throughout E1.
///
/// Interpretation: DS's own anatomy line lists a Message action for
/// "other" viewers generally, but the screen's edge-case note says "no
/// message button for non-teammates" -- read literally (not scoped only
/// to minors, since PRD §5.20 already states minors' "no public
/// messaging" separately), so Message only appears when [relation] is
/// [ViewerRelation.teammate].
class ProfileScreen extends StatefulWidget {
  final PlayerProfile profile;
  final ViewerRelation relation;
  final bool isFollowing;
  final VoidCallback? onEdit;
  final VoidCallback? onShare;
  final VoidCallback? onShowQrCode;
  final VoidCallback? onFollow;
  final VoidCallback? onMessage;
  final VoidCallback? onRequestFollow;
  final VoidCallback? onOpenMenu;
  final ValueChanged<List<String>>? onStyleTagsChanged;
  final VoidCallback? onOpenAchievements;

  const ProfileScreen({
    super.key,
    required this.profile,
    required this.relation,
    this.isFollowing = false,
    this.onEdit,
    this.onShare,
    this.onShowQrCode,
    this.onFollow,
    this.onMessage,
    this.onRequestFollow,
    this.onOpenMenu,
    this.onStyleTagsChanged,
    this.onOpenAchievements,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _tabIndex = 0;

  /// PRD §5.20: minors are forced Private+ regardless of their stated
  /// visibility preset. A [ViewerRelation.follower] is an already-approved
  /// follower, so they still see the full profile; a [ViewerRelation.public]
  /// stranger does not.
  bool get _isPrivateLimited {
    if (widget.relation == ViewerRelation.self ||
        widget.relation == ViewerRelation.teammate) {
      return false;
    }
    final effectivelyPrivate =
        widget.profile.isMinor ||
        widget.profile.visibility == ProfileVisibility.private;
    return effectivelyPrivate && widget.relation != ViewerRelation.follower;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.relation == ViewerRelation.blocked) {
      return const ProfileBlockedView();
    }
    if (_isPrivateLimited) {
      return ProfileLockedCard(
        profile: widget.profile,
        onRequestFollow: widget.onRequestFollow ?? () {},
      );
    }
    return _buildFullProfile(context);
  }

  Widget _buildFullProfile(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final profile = widget.profile;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ProfileCoverAndAvatar(profile: profile),
                const SizedBox(height: AppSpacing.xxl + 8),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            profile.name,
                            style: const TextStyle(
                              fontFamily: AppTypography.displayFamily,
                              fontWeight: FontWeight.w600,
                              fontSize: 24,
                              height: 30 / 24,
                            ).copyWith(color: colors.textPrimary),
                          ),
                          if (profile.isVerifiedAccount) ...[
                            const SizedBox(width: AppSpacing.xs),
                            AppIcon(
                              id: AppIconId.verifiedCheck,
                              semanticLabel: 'Verified',
                              color: colors.verified,
                              size: 18,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xs,
                        children: [
                          for (final role in profile.roleChips)
                            AppTagChip(label: role),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _ProfileActionRow(
                        relation: widget.relation,
                        isFollowing: widget.isFollowing,
                        onEdit: widget.onEdit,
                        onShare: widget.onShare,
                        onShowQrCode: widget.onShowQrCode,
                        onFollow: widget.onFollow,
                        onMessage: widget.onMessage,
                        onOpenMenu: widget.onOpenMenu,
                      ),
                      if (profile.pinnedBadges.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.lg),
                        Row(
                          key: const ValueKey('profilePinnedBadgeStrip'),
                          children: [
                            for (final badge in profile.pinnedBadges) ...[
                              AppBadgeTile(
                                name: badge.name,
                                color: badge.color,
                                earned: true,
                                size: 56,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                            ],
                            const Spacer(),
                            GestureDetector(
                              key: const ValueKey('profileSeeAllBadges'),
                              onTap: widget.onOpenAchievements,
                              child: Text(
                                'See all',
                                style: AppTypography.button.copyWith(
                                  color: colors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: AppSpacing.lg),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _StatHeaderDelegate(
              stats: profile.headerStats,
              colors: colors,
            ),
          ),
          SliverToBoxAdapter(
            child: _ProfileTabBar(
              selectedIndex: _tabIndex,
              onChanged: (index) => setState(() => _tabIndex = index),
            ),
          ),
          SliverToBoxAdapter(child: _buildTabContent(profile)),
        ],
      ),
    );
  }

  Widget _buildTabContent(PlayerProfile profile) {
    return switch (_tabIndex) {
      0 => ProfileOverviewTab(
        profile: profile,
        relation: widget.relation,
        onStyleTagsChanged: widget.onStyleTagsChanged,
      ),
      1 => const _ProfileTabPlaceholder(
        text: 'Format-split stat cards and charts are E2-03.',
      ),
      2 => const _ProfileTabPlaceholder(
        text: 'Media auto-albums are a later story.',
      ),
      _ => const _ProfileTabPlaceholder(
        text: 'The life-in-cricket timeline is a later story.',
      ),
    };
  }
}

class _ProfileCoverAndAvatar extends StatelessWidget {
  final PlayerProfile profile;

  const _ProfileCoverAndAvatar({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipPath(
          clipper: _ArcMaskCoverClipper(),
          child: AspectRatio(
            aspectRatio: 3,
            child: Container(color: profile.coverColor),
          ),
        ),
        Positioned(
          left: AppSpacing.lg,
          bottom: -48,
          child: AppAvatar(
            size: AppAvatarSize.xxl,
            name: profile.name,
            image: profile.avatarImage,
            levelProgress: profile.levelProgress,
            verified: profile.isVerifiedAccount,
          ),
        ),
      ],
    );
  }
}

/// "cover 3:1 with Arc-mask bottom" -- DS gives no exact geometry, so this
/// is a shallow arc dip across the bottom-center, the same restrained
/// interpretation used for other unspecified Arc-motif shapes this
/// session (e.g. the hex-soft badge tile clipper).
class _ArcMaskCoverClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    const dip = 20.0;
    return Path()
      ..lineTo(0, size.height - dip)
      ..quadraticBezierTo(
        size.width / 2,
        size.height + dip,
        size.width,
        size.height - dip,
      )
      ..lineTo(size.width, 0)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _ProfileActionRow extends StatelessWidget {
  final ViewerRelation relation;
  final bool isFollowing;
  final VoidCallback? onEdit;
  final VoidCallback? onShare;
  final VoidCallback? onShowQrCode;
  final VoidCallback? onFollow;
  final VoidCallback? onMessage;
  final VoidCallback? onOpenMenu;

  const _ProfileActionRow({
    required this.relation,
    required this.isFollowing,
    this.onEdit,
    this.onShare,
    this.onShowQrCode,
    this.onFollow,
    this.onMessage,
    this.onOpenMenu,
  });

  @override
  Widget build(BuildContext context) {
    if (relation == ViewerRelation.self) {
      return Row(
        children: [
          Expanded(
            child: AppButton(
              key: const ValueKey('profileEditButton'),
              variant: AppButtonVariant.primary,
              label: 'Edit',
              onPressed: onEdit,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: AppButton(
              key: const ValueKey('profileShareButton'),
              variant: AppButtonVariant.secondary,
              label: 'Share',
              onPressed: onShare,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          AppIconButton(
            key: const ValueKey('profileQrButton'),
            icon: AppIconId.qrCode,
            semanticLabel: 'Show QR code',
            onPressed: onShowQrCode,
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: AppButton(
            key: const ValueKey('profileFollowButton'),
            variant: isFollowing
                ? AppButtonVariant.secondary
                : AppButtonVariant.primary,
            label: isFollowing ? 'Following' : 'Follow',
            onPressed: onFollow,
          ),
        ),
        if (relation == ViewerRelation.teammate) ...[
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: AppButton(
              key: const ValueKey('profileMessageButton'),
              variant: AppButtonVariant.secondary,
              label: 'Message',
              onPressed: onMessage,
            ),
          ),
        ],
        const SizedBox(width: AppSpacing.sm),
        // No AppIconId exists for a "more/overflow" glyph -- AppCard hits
        // the same gap and falls back to Icons.more_vert; matched here for
        // consistency rather than inventing a second workaround.
        IconButton(
          key: const ValueKey('profileMenuButton'),
          icon: const Icon(Icons.more_vert),
          tooltip: 'More',
          onPressed: onOpenMenu,
        ),
      ],
    );
  }
}

class _StatHeaderDelegate extends SliverPersistentHeaderDelegate {
  final ProfileHeaderStats stats;
  final AppColors colors;

  static const double _height = 64;

  _StatHeaderDelegate({required this.stats, required this.colors});

  @override
  double get minExtent => _height;

  @override
  double get maxExtent => _height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final content = Container(
      key: const ValueKey('profileStatHeaderStrip'),
      height: _height,
      color: colors.surface,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _StatColumn(label: 'M', value: '${stats.matches}', colors: colors),
          _StatColumn(label: 'Runs', value: '${stats.runs}', colors: colors),
          _StatColumn(label: 'Wkts', value: '${stats.wickets}', colors: colors),
          _StatColumn(
            label: 'Rating',
            value: '${stats.rating}',
            colors: colors,
          ),
        ],
      ),
    );

    // Pillar 2: verified data is solid/engraved; unverified is lighter and
    // dashed. Scoped to this screen's header strip only -- promote to a
    // shared component if E2-03's Stats tab needs the same treatment.
    if (stats.verified) return content;
    return Opacity(
      key: const ValueKey('profileStatHeaderUnverified'),
      opacity: 0.7,
      child: CustomPaint(
        painter: _DashedRectPainter(colors.border),
        child: content,
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _StatHeaderDelegate oldDelegate) =>
      oldDelegate.stats != stats || oldDelegate.colors != colors;
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;
  final AppColors colors;

  const _StatColumn({
    required this.label,
    required this.value,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: AppTypography.stat.copyWith(color: colors.textPrimary),
        ),
        Text(
          label,
          style: AppTypography.caption.copyWith(color: colors.textTertiary),
        ),
      ],
    );
  }
}

class _DashedRectPainter extends CustomPainter {
  final Color color;

  const _DashedRectPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    const dashWidth = 4.0;
    const dashSpace = 3.0;
    final path = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance = next + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRectPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _ProfileTabBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const _ProfileTabBar({required this.selectedIndex, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final duration = AppMotion.resolveDuration(context, AppMotionToken.fast);

    return Container(
      key: const ValueKey('profileTabBar'),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.divider)),
      ),
      child: Row(
        children: [
          for (var i = 0; i < _profileTabLabels.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(i),
                behavior: HitTestBehavior.opaque,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.md,
                      ),
                      child: Text(
                        _profileTabLabels[i],
                        textAlign: TextAlign.center,
                        style: AppTypography.button.copyWith(
                          color: i == selectedIndex
                              ? colors.textPrimary
                              : colors.textTertiary,
                        ),
                      ),
                    ),
                    AnimatedContainer(
                      duration: duration,
                      curve: AppMotionCurves.standard,
                      height: 2,
                      color: i == selectedIndex
                          ? colors.primary
                          : Colors.transparent,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ProfileTabPlaceholder extends StatelessWidget {
  final String text;

  const _ProfileTabPlaceholder({required this.text});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Text(
        text,
        style: AppTypography.body.copyWith(color: colors.textSecondary),
      ),
    );
  }
}
