import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'is_online_provider.dart';

enum QueuedActionStatus { pending, success, error }

/// One offline-queueable action — PRD §4's dashboard edge case: "action
/// buttons that need connectivity grey out with 'You're offline — will
/// retry' queued-action toasts where safe (e.g., availability response
/// queues; payments never queue)".
class QueuedAction {
  final String id;
  final String label;
  final bool isMoneyAction;
  final Future<void> Function() perform;
  final QueuedActionStatus status;

  const QueuedAction({
    required this.id,
    required this.label,
    required this.isMoneyAction,
    required this.perform,
    required this.status,
  });

  QueuedAction copyWith({QueuedActionStatus? status}) {
    return QueuedAction(
      id: id,
      label: label,
      isMoneyAction: isMoneyAction,
      perform: perform,
      status: status ?? this.status,
    );
  }
}

/// Intentionally not persisted (lib/persistence/) -- [QueuedAction.perform]
/// is a live closure captured at submit time, not data; there is no
/// serializable representation of "what to retry" here (unlike every
/// other provider in this migration, whose state is plain data). A
/// restart drops the app's whole call stack anyway, so any pending
/// queued action's closure would already be unreachable garbage by the
/// time a persisted record could be replayed.
class QueuedActionsNotifier extends Notifier<List<QueuedAction>> {
  int _nextId = 0;

  @override
  List<QueuedAction> build() {
    ref.listen<bool>(isOnlineProvider, (previous, isOnline) {
      if (isOnline && previous == false) {
        _resolveAllPending();
      }
    });
    return const [];
  }

  /// Submits an action. Online: resolves immediately. Offline: non-money
  /// actions queue as pending; money actions are rejected immediately as
  /// an error and are never queued (PRD §4: "payments never queue").
  Future<void> submit({
    required String label,
    required bool isMoneyAction,
    required Future<void> Function() perform,
  }) async {
    final id = '${_nextId++}';
    final isOnline = ref.read(isOnlineProvider);

    if (!isOnline && isMoneyAction) {
      state = [
        ...state,
        QueuedAction(
          id: id,
          label: label,
          isMoneyAction: true,
          perform: perform,
          status: QueuedActionStatus.error,
        ),
      ];
      return;
    }

    final action = QueuedAction(
      id: id,
      label: label,
      isMoneyAction: isMoneyAction,
      perform: perform,
      status: QueuedActionStatus.pending,
    );
    state = [...state, action];

    if (isOnline) {
      await _resolve(action);
    }
    // offline, non-money: stays pending until reconnect.
  }

  Future<void> _resolveAllPending() async {
    final pending = state.where((a) => a.status == QueuedActionStatus.pending);
    for (final action in pending.toList()) {
      await _resolve(action);
    }
  }

  Future<void> _resolve(QueuedAction action) async {
    try {
      await action.perform();
      _updateStatus(action.id, QueuedActionStatus.success);
    } catch (_) {
      _updateStatus(action.id, QueuedActionStatus.error);
    }
  }

  void _updateStatus(String id, QueuedActionStatus status) {
    state = [
      for (final a in state)
        if (a.id == id) a.copyWith(status: status) else a,
    ];
  }

  void retry(String id) {
    final matches = state.where((a) => a.id == id);
    if (matches.isEmpty) return;
    _resolve(matches.first);
  }

  void remove(String id) {
    state = state.where((a) => a.id != id).toList();
  }
}

final queuedActionsProvider =
    NotifierProvider<QueuedActionsNotifier, List<QueuedAction>>(
      QueuedActionsNotifier.new,
    );
