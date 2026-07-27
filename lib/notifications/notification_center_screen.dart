import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'notification_models.dart';
import 'notification_provider.dart';

/// PRD §3.7 (Notification Center) + §3.13 (Swipe Actions). See
/// notification_models.dart's top-of-file note for the exact quotes
/// and the E12-04/E12-05 scope split.
class NotificationCenterScreen extends ConsumerStatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  ConsumerState<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _NotificationCenterScreenState
    extends ConsumerState<NotificationCenterScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  NotificationFilter _filter = NotificationFilter.all;
  final Set<String> _expandedEntities = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final notifier = ref.read(notificationProvider.notifier);
    ref.watch(notificationProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'For You'),
            Tab(text: 'Following'),
          ],
        ),
        actions: [
          TextButton(
            key: const ValueKey('clearAllReadButton'),
            onPressed: () =>
                ref.read(notificationProvider.notifier).clearAllRead(),
            child: const Text('Clear all read'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            child: Wrap(
              spacing: AppSpacing.sm,
              children: [
                for (final filter in NotificationFilter.values)
                  ChoiceChip(
                    key: ValueKey('notificationFilterChip_${filter.name}'),
                    label: Text(notificationFilterLabels[filter]!),
                    selected: _filter == filter,
                    onSelected: (_) => setState(() => _filter = filter),
                  ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _NotificationList(
                  tab: NotificationTab.forYou,
                  filter: _filter,
                  colors: colors,
                  notifier: notifier,
                  expandedEntities: _expandedEntities,
                  onToggleEntity: (entity) => setState(() {
                    if (!_expandedEntities.add(entity)) {
                      _expandedEntities.remove(entity);
                    }
                  }),
                ),
                _NotificationList(
                  tab: NotificationTab.following,
                  filter: _filter,
                  colors: colors,
                  notifier: notifier,
                  expandedEntities: _expandedEntities,
                  onToggleEntity: (entity) => setState(() {
                    if (!_expandedEntities.add(entity)) {
                      _expandedEntities.remove(entity);
                    }
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationList extends ConsumerWidget {
  final NotificationTab tab;
  final NotificationFilter filter;
  final AppColors colors;
  final NotificationNotifier notifier;
  final Set<String> expandedEntities;
  final ValueChanged<String> onToggleEntity;

  const _NotificationList({
    required this.tab,
    required this.filter,
    required this.colors,
    required this.notifier,
    required this.expandedEntities,
    required this.onToggleEntity,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationProvider);
    final cards = state.visibleFor(tab, filter, DateTime.now());

    if (cards.isEmpty) {
      return Center(
        child: Text(
          'All caught up 🎉',
          style: AppTypography.body.copyWith(color: colors.textSecondary),
        ),
      );
    }

    // PRD §3.7: "Priority notifications ... pin to top with colored
    // edge." P0 cards render individually, un-grouped, above the rest.
    final pinned = cards
        .where((c) => c.priority == NotificationPriority.p0)
        .toList();
    final rest = cards
        .where((c) => c.priority != NotificationPriority.p0)
        .toList();
    final grouped = <String, List<NotificationCard>>{};
    for (final c in rest) {
      grouped.putIfAbsent(c.entityName, () => []).add(c);
    }

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        for (final card in pinned)
          _NotificationRow(
            key: ValueKey('notificationRow_${card.id}'),
            card: card,
            colors: colors,
            notifier: notifier,
          ),
        for (final entry in grouped.entries) ...[
          if (entry.value.length > 1)
            InkWell(
              key: ValueKey('entityRollup_${entry.key}'),
              onTap: () => onToggleEntity(entry.key),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${entry.key} -- ${entry.value.length} update${entry.value.length == 1 ? '' : 's'}',
                        style: AppTypography.label.copyWith(
                          color: colors.textTertiary,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () =>
                          notifier.markAllReadInSection(tab, filter),
                      child: const Text('Mark read'),
                    ),
                    Icon(
                      expandedEntities.contains(entry.key)
                          ? Icons.expand_less
                          : Icons.expand_more,
                    ),
                  ],
                ),
              ),
            ),
          if (entry.value.length == 1 || expandedEntities.contains(entry.key))
            for (final card in entry.value)
              _NotificationRow(
                key: ValueKey('notificationRow_${card.id}'),
                card: card,
                colors: colors,
                notifier: notifier,
              )
          else
            _NotificationRow(
              key: ValueKey('notificationRow_${entry.value.first.id}'),
              card: entry.value.first,
              colors: colors,
              notifier: notifier,
            ),
        ],
      ],
    );
  }
}

class _NotificationRow extends StatelessWidget {
  final NotificationCard card;
  final AppColors colors;
  final NotificationNotifier notifier;

  const _NotificationRow({
    super.key,
    required this.card,
    required this.colors,
    required this.notifier,
  });

  Color get _priorityColor => switch (card.priority) {
    NotificationPriority.p0 => colors.error,
    NotificationPriority.p1 => colors.warning,
    NotificationPriority.p2 => colors.primary,
    NotificationPriority.p3 => colors.textTertiary,
  };

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey('dismissible_${card.id}'),
      background: Container(
        color: colors.success.withValues(alpha: 0.2),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: const Icon(Icons.check),
      ),
      secondaryBackground: Container(
        color: colors.warning.withValues(alpha: 0.2),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: const Icon(Icons.snooze),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          _doneWithUndo(context);
        } else {
          await _showSnoozeSheet(context);
        }
        return false; // list itself re-filters via provider state, not removal animation
      },
      child: GestureDetector(
        onLongPress: () => _showLongPressSheet(context),
        child: Container(
          key: ValueKey('notificationCard_${card.id}'),
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: card.read ? colors.surface : colors.surfaceAlt,
            borderRadius: BorderRadius.circular(14),
            border: Border(left: BorderSide(color: _priorityColor, width: 4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                card.entityName,
                style: AppTypography.caption.copyWith(
                  color: colors.textTertiary,
                ),
              ),
              Text(
                card.title,
                style: AppTypography.body.copyWith(color: colors.textPrimary),
              ),
              if (card.actions.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.sm,
                  children: [
                    for (final action in card.actions)
                      TextButton(
                        key: ValueKey(
                          'notificationAction_${card.id}_${action.name}',
                        ),
                        onPressed: () =>
                            notifier.performAction(card.id, action),
                        child: Text(notificationActionLabels[action]!),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// PRD §3.13: "destructive swipes show undo snackbar (5s) before
  /// commit."
  void _doneWithUndo(BuildContext context) {
    notifier.swipeDone(card.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 5),
        content: const Text('Marked done'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () => notifier.markRead(card.id),
        ),
      ),
    );
  }

  Future<void> _showSnoozeSheet(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final duration in SnoozeDuration.values)
              ListTile(
                key: ValueKey('snoozeOption_${duration.name}'),
                title: Text(snoozeDurationLabels[duration]!),
                onTap: () {
                  notifier.snooze(card.id, duration);
                  Navigator.of(context).pop();
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showLongPressSheet(BuildContext outerContext) {
    showModalBottomSheet<void>(
      context: outerContext,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Mute this type'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _showMuteDurationSheet(outerContext, isEntity: false);
              },
            ),
            ListTile(
              title: const Text('Mute this entity'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _showMuteDurationSheet(outerContext, isEntity: true);
              },
            ),
            ListTile(
              key: ValueKey('turnOffButton_${card.id}'),
              title: const Text('Turn off'),
              onTap: () {
                notifier.turnOff(card.id);
                Navigator.of(sheetContext).pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showMuteDurationSheet(BuildContext context, {required bool isEntity}) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final duration in MuteDuration.values)
              ListTile(
                key: ValueKey(
                  'muteDurationOption_${isEntity ? 'entity' : 'type'}_${duration.name}',
                ),
                title: Text(muteDurationLabels[duration]!),
                onTap: () {
                  if (isEntity) {
                    notifier.muteEntity(card.entityName, duration);
                  } else {
                    notifier.muteType(card.filter, duration);
                  }
                  Navigator.of(sheetContext).pop();
                },
              ),
          ],
        ),
      ),
    );
  }
}
