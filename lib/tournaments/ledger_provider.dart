import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../persistence/persisted_notifier.dart';
import 'ledger_models.dart';
import 'tournaments_provider.dart';

class LedgerState {
  final Map<String, List<LedgerEntry>> entriesByTournament;
  final Map<String, List<PrizePayout>> payoutsByTournament;

  const LedgerState({
    this.entriesByTournament = const {},
    this.payoutsByTournament = const {},
  });

  LedgerState copyWith({
    Map<String, List<LedgerEntry>>? entriesByTournament,
    Map<String, List<PrizePayout>>? payoutsByTournament,
  }) {
    return LedgerState(
      entriesByTournament: entriesByTournament ?? this.entriesByTournament,
      payoutsByTournament: payoutsByTournament ?? this.payoutsByTournament,
    );
  }

  List<LedgerEntry> entriesFor(String tournamentId) =>
      entriesByTournament[tournamentId] ?? const [];

  List<PrizePayout> payoutsFor(String tournamentId) =>
      payoutsByTournament[tournamentId] ?? const [];

  Map<String, dynamic> toJson() => {
    'entriesByTournament': {
      for (final entry in entriesByTournament.entries)
        entry.key: [for (final e in entry.value) e.toJson()],
    },
    'payoutsByTournament': {
      for (final entry in payoutsByTournament.entries)
        entry.key: [for (final p in entry.value) p.toJson()],
    },
  };

  factory LedgerState.fromJson(Map<String, dynamic> json) {
    return LedgerState(
      entriesByTournament: {
        for (final entry
            in (json['entriesByTournament'] as Map<String, dynamic>).entries)
          entry.key: [
            for (final e in entry.value as List)
              LedgerEntry.fromJson(e as Map<String, dynamic>),
          ],
      },
      payoutsByTournament: {
        for (final entry
            in (json['payoutsByTournament'] as Map<String, dynamic>).entries)
          entry.key: [
            for (final p in entry.value as List)
              PrizePayout.fromJson(p as Map<String, dynamic>),
          ],
      },
    );
  }
}

/// Backlog E10-07 -- Organizer console + wallet + payouts engine. See
/// ledger_models.dart's top-of-file note for the exact PRD §8.13-8.14
/// quote.
class LedgerNotifier extends PersistedNotifier<LedgerState> {
  @override
  String get persistenceKey => 'ledger_v1';

  @override
  LedgerState seed() => const LedgerState();

  @override
  Map<String, dynamic> toJson(LedgerState value) => value.toJson();

  @override
  LedgerState fromJson(Map<String, dynamic> json) => LedgerState.fromJson(json);

  /// Manual line items for every category except entry fees, which is
  /// instead derived live from the real tournamentsProvider escrow
  /// (E10-02) by the console screen -- no separate re-entry of a
  /// number that already exists as real state.
  void addEntry(
    String tournamentId,
    LedgerCategory category,
    int amount,
    String note, {
    bool isConfidential = false,
    DateTime Function() now = DateTime.now,
  }) {
    final entries = state.entriesFor(tournamentId);
    state = state.copyWith(
      entriesByTournament: {
        ...state.entriesByTournament,
        tournamentId: [
          ...entries,
          LedgerEntry(
            id: 'ledger-${now().microsecondsSinceEpoch}',
            tournamentId: tournamentId,
            category: category,
            amount: amount,
            note: note,
            isConfidential: isConfidential,
          ),
        ],
      },
    );
  }

  /// PRD: "Prize payout tracker" -- the organizer awards a payout to a
  /// winning team.
  void awardPayout(
    String tournamentId,
    String winnerRegistrationId,
    String winnerTeamName,
    int amount, {
    DateTime Function() now = DateTime.now,
  }) {
    final payouts = state.payoutsFor(tournamentId);
    state = state.copyWith(
      payoutsByTournament: {
        ...state.payoutsByTournament,
        tournamentId: [
          ...payouts,
          PrizePayout(
            id: 'payout-${now().microsecondsSinceEpoch}',
            tournamentId: tournamentId,
            winnerRegistrationId: winnerRegistrationId,
            winnerTeamName: winnerTeamName,
            amount: amount,
            awardedAt: now(),
          ),
        ],
      },
    );
    ref.read(tournamentsProvider.notifier).markOrganizerActive(tournamentId);
  }

  /// PRD: "winner confirms receipt."
  void confirmPayoutReceipt(
    String tournamentId,
    String payoutId, {
    DateTime Function() now = DateTime.now,
  }) {
    final payouts = state.payoutsFor(tournamentId);
    state = state.copyWith(
      payoutsByTournament: {
        ...state.payoutsByTournament,
        tournamentId: [
          for (final p in payouts)
            if (p.id == payoutId) p.copyWith(confirmedAt: now()) else p,
        ],
      },
    );
  }
}

final ledgerProvider = NotifierProvider<LedgerNotifier, LedgerState>(
  LedgerNotifier.new,
);
