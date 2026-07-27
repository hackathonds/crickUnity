import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data_controls_models.dart';

class DataControlsState {
  final AccountLifecycleStatus status;
  final DateTime? deletionRequestedAt;
  final DataExportSummary exportSummary;

  const DataControlsState({
    this.status = AccountLifecycleStatus.active,
    this.deletionRequestedAt,
    this.exportSummary = const DataExportSummary(
      postsCount: 42,
      matchesPlayed: 38,
      expensesTracked: 21,
      coinsEarnedLifetime: 860,
      followersCount: 214,
    ),
  });

  DateTime? get deletionCompletesAt =>
      deletionRequestedAt?.add(const Duration(days: deletionGraceDays));

  DataControlsState copyWith({
    AccountLifecycleStatus? status,
    DateTime? deletionRequestedAt,
    bool clearDeletionRequestedAt = false,
  }) {
    return DataControlsState(
      status: status ?? this.status,
      deletionRequestedAt: clearDeletionRequestedAt
          ? null
          : (deletionRequestedAt ?? this.deletionRequestedAt),
      exportSummary: exportSummary,
    );
  }
}

/// No real account-lifecycle backend exists -- flagged, same convention
/// as every other missing-backend gap this session. "verified scorecard
/// lines persist anonymized" and "stats preserved ... as 'Deactivated
/// player'" are disclosure text shown to the user here, not a real
/// cross-module data-retention pipeline (nothing writes an
/// "anonymized"/"Deactivated player" flag into any other module's
/// records).
class DataControlsNotifier extends Notifier<DataControlsState> {
  @override
  DataControlsState build() => const DataControlsState();

  void deactivate() {
    state = state.copyWith(status: AccountLifecycleStatus.deactivated);
  }

  void reactivate() {
    state = state.copyWith(status: AccountLifecycleStatus.active);
  }

  void requestDeletion({DateTime Function() now = DateTime.now}) {
    state = state.copyWith(
      status: AccountLifecycleStatus.pendingDeletion,
      deletionRequestedAt: now(),
    );
  }

  void cancelDeletion() {
    state = state.copyWith(
      status: AccountLifecycleStatus.active,
      clearDeletionRequestedAt: true,
    );
  }
}

final dataControlsProvider =
    NotifierProvider<DataControlsNotifier, DataControlsState>(
      DataControlsNotifier.new,
    );
