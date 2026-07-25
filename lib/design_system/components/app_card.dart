import 'package:flutter/material.dart';

import '../icons/app_icon.dart';
import '../icons/app_icon_id.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_elevation.dart';
import '../tokens/app_motion.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';
import 'app_bottom_sheet.dart';
import 'app_pressable.dart';
import 'app_state_scaffolds.dart';

/// One action in a card's context menu — PRD §3.11 defines *which* actions
/// each entity type gets (Post/Match/Player/Expense/...); this base card
/// only needs to render whatever list the caller supplies, never any
/// specific entity's menu.
class AppCardMenuAction {
  final String label;
  final AppIconId icon;
  final VoidCallback onTap;
  final bool isDestructive;

  const AppCardMenuAction({
    required this.label,
    required this.icon,
    required this.onTap,
    this.isDestructive = false,
  });
}

/// The base card — DS §3.2. Specific anatomies (Player/Match/Live/Expense/
/// ...) are separate E0-08 components built on top of this.
class AppCard extends StatefulWidget {
  final Widget child;
  final String? headerTitle;
  final Widget? headerLeading;
  final VoidCallback? onTap;
  final bool hasMultipleActions;
  final bool isMoneySurface;
  final bool selected;
  final bool isLoading;
  final bool featured;
  final List<AppCardMenuAction> menuActions;

  const AppCard({
    super.key,
    required this.child,
    this.headerTitle,
    this.headerLeading,
    this.onTap,
    this.hasMultipleActions = false,
    this.isMoneySurface = false,
    this.selected = false,
    this.isLoading = false,
    this.featured = false,
    this.menuActions = const [],
  });

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> with SingleTickerProviderStateMixin {
  late final AnimationController _peekController;

  @override
  void initState() {
    super.initState();
    _peekController = AnimationController(
      vsync: this,
      duration: AppMotionDuration.fast,
    );
  }

  @override
  void dispose() {
    _peekController.dispose();
    super.dispose();
  }

  Future<void> _openMenu() {
    return showAppBottomSheet<void>(
      context: context,
      title: 'Options',
      contentBuilder: (context) =>
          _CardMenuContent(actions: widget.menuActions),
    );
  }

  Future<void> _handleLongPress() async {
    if (widget.menuActions.isEmpty) return;
    if (!AppMotion.isReduced(context)) {
      await _peekController.forward();
      await _peekController.reverse();
    }
    if (!mounted) return;
    await _openMenu();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final brightness = Theme.of(context).brightness;
    final borderColor = widget.isMoneySurface
        ? colors.moneyBorder
        : colors.border;

    final style = AppElevation.resolveSurfaceStyle(
      level: AppElevationLevel.e1,
      brightness: brightness,
      borderColor: borderColor,
      isMoneySurface: widget.isMoneySurface,
    );

    var surfaceColor = colors.surface;
    if (style.darkSurfaceLuminanceDelta > 0) {
      surfaceColor = Color.lerp(
        surfaceColor,
        Colors.white,
        style.darkSurfaceLuminanceDelta,
      )!;
    }

    final padding = widget.featured ? AppSpacing.xl : AppSpacing.lg;

    Widget content = widget.isLoading
        ? const AppLoadingState(shape: AppSkeletonShape.card)
        : Padding(
            key: const ValueKey('appCardContentPadding'),
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.headerTitle != null) ...[
                  _CardHeader(
                    title: widget.headerTitle!,
                    leading: widget.headerLeading,
                    hasMenu: widget.menuActions.isNotEmpty,
                    onMenuTap: _openMenu,
                    onHeaderTap: widget.hasMultipleActions
                        ? widget.onTap
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
                widget.child,
              ],
            ),
          );

    content = Container(
      key: const ValueKey('appCardSurface'),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: AppRadius.mdRadius,
        border: style.border != null
            ? Border.fromBorderSide(style.border!)
            : null,
        boxShadow: style.shadows,
      ),
      child: content,
    );

    if (widget.selected) {
      content = Container(
        decoration: BoxDecoration(
          borderRadius: AppRadius.mdRadius,
          border: Border.all(color: colors.primary, width: 1.5),
        ),
        child: content,
      );
    }

    final canWholeCardTap = widget.onTap != null && !widget.hasMultipleActions;

    return AnimatedBuilder(
      animation: _peekController,
      builder: (context, child) {
        final scale = 1.0 + (0.03 * _peekController.value);
        return Transform.scale(scale: scale, child: child);
      },
      child: GestureDetector(
        onLongPress: widget.menuActions.isNotEmpty ? _handleLongPress : null,
        child: canWholeCardTap
            ? AppPressable(
                onPressed: widget.onTap,
                tintColor: colors.primary,
                cornerRadius: AppRadius.md,
                focusRingColor: colors.primary,
                child: content,
              )
            : content,
      ),
    );
  }
}

class _CardHeader extends StatelessWidget {
  final String title;
  final Widget? leading;
  final bool hasMenu;
  final VoidCallback onMenuTap;
  final VoidCallback? onHeaderTap;

  const _CardHeader({
    required this.title,
    required this.hasMenu,
    required this.onMenuTap,
    this.leading,
    this.onHeaderTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    final row = Row(
      children: [
        if (leading != null) ...[
          SizedBox(width: 40, height: 40, child: leading),
          const SizedBox(width: AppSpacing.md),
        ],
        Expanded(
          child: Text(
            title,
            style: AppTypography.title.copyWith(color: colors.textPrimary),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (hasMenu)
          IconButton(
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            icon: const Icon(Icons.more_vert),
            color: colors.textSecondary,
            onPressed: onMenuTap,
          ),
      ],
    );

    if (onHeaderTap == null) return row;

    return AppPressable(
      onPressed: onHeaderTap,
      tintColor: colors.primary,
      cornerRadius: AppRadius.sm,
      focusRingColor: colors.primary,
      child: row,
    );
  }
}

class _CardMenuContent extends StatelessWidget {
  final List<AppCardMenuAction> actions;
  const _CardMenuContent({required this.actions});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Material(
      type: MaterialType.transparency,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final action in actions)
            ListTile(
              leading: AppIcon(
                id: action.icon,
                semanticLabel: action.label,
                color: action.isDestructive ? colors.error : colors.textPrimary,
              ),
              title: Text(
                action.label,
                style: AppTypography.body.copyWith(
                  color: action.isDestructive
                      ? colors.error
                      : colors.textPrimary,
                ),
              ),
              onTap: () {
                Navigator.of(context).pop();
                action.onTap();
              },
            ),
        ],
      ),
    );
  }
}
