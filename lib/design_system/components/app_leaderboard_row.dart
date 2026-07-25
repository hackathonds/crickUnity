import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_elevation.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';
import 'app_arc_ring.dart';
import 'app_avatar.dart';

/// DS §3.18's movement chevron — reuses the established ▲/▼ plain-glyph,
/// success/textTertiary convention (Chips' `AppDeltaChip`, Player Card's
/// trend arrow) rather than inventing a new one.
enum AppLeaderboardMovement { up, down }

/// A leaderboard entry's data — kept separate from the row widget so
/// [AppLeaderboardList] can build both the normal row and its sticky
/// clone from the same source.
class AppLeaderboardRowData {
  final int rank;
  final String name;
  final String teamCaption;
  final String metric;
  final ImageProvider? avatarImage;
  final AppLeaderboardMovement? movement;
  final int? movementValue;

  const AppLeaderboardRowData({
    required this.rank,
    required this.name,
    required this.teamCaption,
    required this.metric,
    this.avatarImage,
    this.movement,
    this.movementValue,
  });
}

/// DS §3.18 Leaderboard Row (56h). A plain row, not an `AppCard` — its
/// anatomy never mentions a surface/border/elevation, and "My row:
/// surfaceAlt fill + 2px primary left rail" is explicitly state-
/// conditional, not an always-present shell.
class AppLeaderboardRow extends StatelessWidget {
  final AppLeaderboardRowData data;
  final bool isMe;
  final VoidCallback? onTap;

  const AppLeaderboardRow({
    super.key,
    required this.data,
    this.isMe = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final isTop3 = data.rank <= 3;
    final rankColor = isTop3 ? colors.coin : colors.textPrimary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        key: const ValueKey('appLeaderboardRowBox'),
        height: 56,
        decoration: BoxDecoration(
          color: isMe ? colors.surfaceAlt : null,
          border: isMe
              ? Border(left: BorderSide(color: colors.primary, width: 2))
              : null,
        ),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Row(
          children: [
            SizedBox(
              width: 28,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (isTop3)
                    AppArcRing(
                      key: const ValueKey('appLeaderboardRowLaurel'),
                      progress: 1.0,
                      size: 28,
                      strokeWidth: 1.5,
                      trackColor: colors.coin,
                      fillColor: colors.coin,
                    ),
                  Text(
                    '${data.rank}',
                    style: AppTypography.stat.copyWith(
                      fontSize: 15,
                      color: rankColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            AppAvatar(
              size: AppAvatarSize.sm,
              name: data.name,
              image: data.avatarImage,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.name,
                    style: AppTypography.body.copyWith(
                      color: colors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    data.teamCaption,
                    style: AppTypography.caption.copyWith(
                      color: colors.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  data.metric,
                  style: AppTypography.stat.copyWith(
                    fontSize: 17,
                    color: colors.textPrimary,
                  ),
                ),
                if (data.movement != null && data.movementValue != null)
                  Text(
                    '${data.movement == AppLeaderboardMovement.up ? '▲' : '▼'}${data.movementValue}',
                    style: AppTypography.caption.copyWith(
                      fontSize: 12,
                      color: data.movement == AppLeaderboardMovement.up
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

/// The scrollable list + DS §3.18's "sticky-clones to bottom when
/// off-screen" behavior for the viewer's own row.
class AppLeaderboardList extends StatefulWidget {
  final List<AppLeaderboardRowData> rows;
  final int? myIndex;
  final ValueChanged<AppLeaderboardRowData>? onRowTap;

  const AppLeaderboardList({
    super.key,
    required this.rows,
    this.myIndex,
    this.onRowTap,
  });

  @override
  State<AppLeaderboardList> createState() => AppLeaderboardListState();
}

class AppLeaderboardListState extends State<AppLeaderboardList> {
  final _myRowKey = GlobalKey();
  final _listKey = GlobalKey();
  bool _showClone = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _updateCloneVisibility(),
    );
  }

  void _updateCloneVisibility() {
    if (widget.myIndex == null || !mounted) return;
    final listBox = _listKey.currentContext?.findRenderObject() as RenderBox?;
    if (listBox == null) return;

    // A lazy ListView.builder unmounts items once they're far enough
    // off-screen -- if "my row" isn't currently built at all, that alone
    // means it's off-screen (not "unknown, skip").
    final myBox = _myRowKey.currentContext?.findRenderObject() as RenderBox?;
    bool shouldShowClone;
    if (myBox == null) {
      shouldShowClone = true;
    } else {
      final myTop = myBox.localToGlobal(Offset.zero).dy;
      final myBottom = myTop + myBox.size.height;
      final listTop = listBox.localToGlobal(Offset.zero).dy;
      final listBottom = listTop + listBox.size.height;
      final isVisible = myBottom > listTop && myTop < listBottom;
      shouldShowClone = !isVisible;
    }

    if (shouldShowClone == _showClone) return;
    setState(() => _showClone = shouldShowClone);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Stack(
      key: _listKey,
      children: [
        NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            // Layout for the new scroll offset hasn't happened yet at
            // notification time -- checking RenderBox positions
            // synchronously here would read stale (pre-scroll)
            // geometry. Defer to after this frame's layout/paint.
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => _updateCloneVisibility(),
            );
            return false;
          },
          child: ListView.builder(
            itemCount: widget.rows.length,
            itemBuilder: (context, index) {
              final data = widget.rows[index];
              final isMe = index == widget.myIndex;
              return AppLeaderboardRow(
                key: isMe ? _myRowKey : null,
                data: data,
                isMe: isMe,
                onTap: widget.onRowTap == null
                    ? null
                    : () => widget.onRowTap!(data),
              );
            },
          ),
        ),
        if (_showClone && widget.myIndex != null)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: DecoratedBox(
              key: const ValueKey('appLeaderboardStickyClone'),
              decoration: BoxDecoration(
                color: colors.surface,
                boxShadow: AppElevation.e2.toBoxShadows(),
              ),
              child: AppLeaderboardRow(
                data: widget.rows[widget.myIndex!],
                isMe: true,
                onTap: widget.onRowTap == null
                    ? null
                    : () => widget.onRowTap!(widget.rows[widget.myIndex!]),
              ),
            ),
          ),
      ],
    );
  }
}
