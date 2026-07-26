import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'transfer_models.dart';

class TransferResult {
  final String? error;
  final String? transferId;

  const TransferResult({this.error, this.transferId});

  bool get succeeded => error == null;
}

class TransferState {
  final List<TransferRecord> transfers;

  const TransferState({this.transfers = const []});

  TransferState copyWith({List<TransferRecord>? transfers}) {
    return TransferState(transfers: transfers ?? this.transfers);
  }
}

/// PRD §6.26. No real player-stats or team-aggregate system exists yet
/// (Epic E4/stats aren't built), so "personal stats travel" / "team
/// aggregates freeze" have nothing concrete to move or freeze -- those
/// are conceptual guarantees surfaced as confirmation copy on the
/// screen, not data this notifier mutates. What this notifier actually
/// enforces is the one rule that *is* fully specified: a rival-team
/// transfer is blocked once the tournament's window is locked.
class TransferNotifier extends Notifier<TransferState> {
  @override
  TransferState build() => const TransferState();

  TransferResult initiateTransfer({
    required String playerName,
    required String fromTeamName,
    required String toTeamName,
    required bool isRivalTransfer,
    required TransferWindowStatus windowStatus,
    DateTime Function() now = DateTime.now,
  }) {
    if (isRivalTransfer &&
        windowStatus == TransferWindowStatus.lockedPostFixtures) {
      return const TransferResult(
        error:
            'Transfers between these teams are locked -- fixtures have '
            'already been published for this tournament.',
      );
    }
    if (toTeamName.trim().isEmpty) {
      return const TransferResult(error: 'Name the destination team.');
    }
    final id = 'transfer-${now().millisecondsSinceEpoch}';
    state = state.copyWith(
      transfers: [
        TransferRecord(
          id: id,
          playerName: playerName,
          fromTeamName: fromTeamName,
          toTeamName: toTeamName.trim(),
          transferredAt: now(),
          isRivalTransfer: isRivalTransfer,
        ),
        ...state.transfers,
      ],
    );
    return TransferResult(transferId: id);
  }
}

final transferProvider = NotifierProvider<TransferNotifier, TransferState>(
  TransferNotifier.new,
);
