import 'package:flutter/material.dart';

import '../icons/app_icon.dart';
import '../icons/app_icon_id.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';

/// One entry in an [AppTimeline] — the caller supplies its own content
/// widget (a "content card") since exact per-entity shapes vary by
/// screen (match events, audit log entries, ...).
class AppTimelineEntry {
  final DateTime date;
  final bool isKeyEvent;
  final AppIconId? icon;
  final Widget content;

  const AppTimelineEntry({
    required this.date,
    required this.content,
    this.isKeyEvent = false,
    this.icon,
  });
}

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// DS §3.4 Timeline (match/audit): "Left rail 2px divider with node dots
/// 10 (event-typed glyphs 16 inside 28 circles for key events); content
/// cards right, 12 gap; sticky date separators."
///
/// `entries` must already be in the order they should render; consecutive
/// entries on the same day are grouped under one sticky date header (via
/// `SliverPersistentHeader(pinned: true)` — a built-in Flutter mechanism,
/// no external sticky-header package needed).
class AppTimeline extends StatelessWidget {
  final List<AppTimelineEntry> entries;
  final String Function(DateTime date) dateLabelBuilder;

  /// True when this timeline is embedded inside another scroll view
  /// (e.g. a profile tab body) rather than owning the whole screen --
  /// sizes to content and defers scrolling to the ancestor instead of
  /// erroring on unbounded height.
  final bool shrinkWrap;

  const AppTimeline({
    super.key,
    required this.entries,
    required this.dateLabelBuilder,
    this.shrinkWrap = false,
  });

  @override
  Widget build(BuildContext context) {
    final groups = <List<AppTimelineEntry>>[];
    for (final entry in entries) {
      if (groups.isNotEmpty && _isSameDay(groups.last.first.date, entry.date)) {
        groups.last.add(entry);
      } else {
        groups.add([entry]);
      }
    }

    return CustomScrollView(
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
      slivers: [
        for (final group in groups) ...[
          SliverPersistentHeader(
            pinned: true,
            delegate: _DateHeaderDelegate(
              label: dateLabelBuilder(group.first.date),
            ),
          ),
          SliverList.list(
            children: [for (final entry in group) _TimelineRow(entry: entry)],
          ),
        ],
      ],
    );
  }
}

class _DateHeaderDelegate extends SliverPersistentHeaderDelegate {
  final String label;
  const _DateHeaderDelegate({required this.label});

  @override
  double get minExtent => 32;
  @override
  double get maxExtent => 32;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Container(
      key: const ValueKey('appTimelineDateHeader'),
      color: colors.bg,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Text(
        label,
        style: AppTypography.label.copyWith(color: colors.textTertiary),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _DateHeaderDelegate oldDelegate) =>
      oldDelegate.label != label;
}

class _TimelineRow extends StatelessWidget {
  final AppTimelineEntry entry;
  const _TimelineRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 28,
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  Positioned.fill(
                    child: Center(
                      child: Container(width: 2, color: colors.divider),
                    ),
                  ),
                  if (entry.isKeyEvent)
                    Container(
                      key: const ValueKey('appTimelineKeyEventNode'),
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: colors.surface,
                        shape: BoxShape.circle,
                        border: Border.all(color: colors.primary, width: 1.5),
                      ),
                      child: entry.icon == null
                          ? null
                          : Center(
                              child: AppIcon(
                                id: entry.icon!,
                                semanticLabel: 'Key event',
                                color: colors.primary,
                                size: 16,
                              ),
                            ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.only(top: 9),
                      child: Container(
                        key: const ValueKey('appTimelineNode'),
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: colors.textTertiary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: entry.content,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
