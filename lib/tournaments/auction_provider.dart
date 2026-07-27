import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auction_models.dart';

class AuctionState {
  final Map<String, List<Lot>> lotsByTournament;
  final Map<String, int> currentLotIndexByTournament;
  final Map<String, List<AuctionTeamPurse>> pursesByTournament;
  final Map<String, List<BidLogEntry>> bidLogByTournament;

  const AuctionState({
    this.lotsByTournament = const {},
    this.currentLotIndexByTournament = const {},
    this.pursesByTournament = const {},
    this.bidLogByTournament = const {},
  });

  AuctionState copyWith({
    Map<String, List<Lot>>? lotsByTournament,
    Map<String, int>? currentLotIndexByTournament,
    Map<String, List<AuctionTeamPurse>>? pursesByTournament,
    Map<String, List<BidLogEntry>>? bidLogByTournament,
  }) {
    return AuctionState(
      lotsByTournament: lotsByTournament ?? this.lotsByTournament,
      currentLotIndexByTournament:
          currentLotIndexByTournament ?? this.currentLotIndexByTournament,
      pursesByTournament: pursesByTournament ?? this.pursesByTournament,
      bidLogByTournament: bidLogByTournament ?? this.bidLogByTournament,
    );
  }

  List<Lot> lotsFor(String tournamentId) =>
      lotsByTournament[tournamentId] ?? const [];

  int currentLotIndexFor(String tournamentId) =>
      currentLotIndexByTournament[tournamentId] ?? 0;

  /// Sub-part "reconnect": DS §7-40's "reconnect banner preserves lot
  /// state" is satisfied structurally -- this state lives in the
  /// provider, not the screen's own State object, so re-entering the
  /// auction room after navigating away rebuilds the identical live
  /// lot/timer/purse state rather than resetting the auction.
  Lot? currentLot(String tournamentId) {
    final lots = lotsFor(tournamentId);
    final index = currentLotIndexFor(tournamentId);
    return index < lots.length ? lots[index] : null;
  }

  List<AuctionTeamPurse> pursesFor(String tournamentId) =>
      pursesByTournament[tournamentId] ?? const [];

  List<BidLogEntry> bidLogFor(String tournamentId) =>
      bidLogByTournament[tournamentId] ?? const [];
}

/// Backlog E10-06 (XL, split lot/bidding/purse/spectator/reconnect) --
/// Auction room engine. See auction_models.dart's top-of-file note for
/// the exact PRD §8.7 / DS §7-40 quotes each sub-part implements.
class AuctionNotifier extends Notifier<AuctionState> {
  @override
  AuctionState build() => const AuctionState();

  /// Sub-part "lot": seeds the lot queue (one per free agent) and the
  /// purse table, then opens the first lot.
  void setupAuction(
    String tournamentId,
    List<FreeAgent> pool,
    List<AuctionTeamPurse> purses,
  ) {
    final lots = [
      for (final player in pool)
        Lot(id: 'lot-${tournamentId}_${player.id}', player: player),
    ];
    state = state.copyWith(
      lotsByTournament: {...state.lotsByTournament, tournamentId: lots},
      currentLotIndexByTournament: {
        ...state.currentLotIndexByTournament,
        tournamentId: 0,
      },
      pursesByTournament: {...state.pursesByTournament, tournamentId: purses},
      bidLogByTournament: {...state.bidLogByTournament, tournamentId: []},
    );
    _openCurrentLot(tournamentId);
  }

  void _openCurrentLot(String tournamentId) {
    final lots = state.lotsFor(tournamentId);
    final index = state.currentLotIndexFor(tournamentId);
    if (index >= lots.length) return;
    _updateLot(
      tournamentId,
      lots[index].id,
      (l) => l.copyWith(status: LotStatus.live),
    );
  }

  /// Sub-part "bidding" + purse enforcement: PRD §8.7 -- "purse math
  /// enforced (can't bid beyond purse minus minimum-squad reserve)."
  /// Returns null on success, or a rejection message.
  String? placeBid(
    String tournamentId,
    String teamRegistrationId,
    int increment, {
    DateTime Function() now = DateTime.now,
  }) {
    final lot = state.currentLot(tournamentId);
    if (lot == null || lot.status != LotStatus.live) return 'No live lot.';
    final purse = state
        .pursesFor(tournamentId)
        .where((p) => p.registrationId == teamRegistrationId)
        .firstOrNull;
    if (purse == null) return 'Team not found.';

    final baseline = lot.currentBid == 0
        ? lot.player.basePrice
        : lot.currentBid;
    final newBid = baseline + increment;
    if (newBid > purse.maxBiddable) {
      return "${purse.teamName}'s bid would exceed their purse minus the minimum-squad reserve.";
    }

    _updateLot(
      tournamentId,
      lot.id,
      (l) => l.copyWith(
        currentBid: newBid,
        currentBidderRegistrationId: teamRegistrationId,
        currentBidderTeamName: purse.teamName,
      ),
    );
    final log = state.bidLogFor(tournamentId);
    state = state.copyWith(
      bidLogByTournament: {
        ...state.bidLogByTournament,
        tournamentId: [
          ...log,
          BidLogEntry(
            lotId: lot.id,
            teamRegistrationId: teamRegistrationId,
            teamName: purse.teamName,
            amount: newBid,
            timestamp: now(),
          ),
        ],
      },
    );
    return null;
  }

  /// Called when the DS §7-40 12-second lot timer elapses. Sold if
  /// anyone bid; unsold otherwise (PRD §8.7: "unsold pool re-rounds").
  void resolveLot(String tournamentId) {
    final lot = state.currentLot(tournamentId);
    if (lot == null || lot.status != LotStatus.live) return;

    if (lot.currentBidderRegistrationId != null) {
      _updateLot(
        tournamentId,
        lot.id,
        (l) => l.copyWith(status: LotStatus.sold),
      );
      final purses = state.pursesFor(tournamentId);
      state = state.copyWith(
        pursesByTournament: {
          ...state.pursesByTournament,
          tournamentId: [
            for (final p in purses)
              if (p.registrationId == lot.currentBidderRegistrationId)
                p.copyWith(
                  spent: p.spent + lot.currentBid,
                  squadSize: p.squadSize + 1,
                )
              else
                p,
          ],
        },
      );
    } else {
      _updateLot(
        tournamentId,
        lot.id,
        (l) => l.copyWith(status: LotStatus.unsold),
      );
    }

    final nextIndex = state.currentLotIndexFor(tournamentId) + 1;
    state = state.copyWith(
      currentLotIndexByTournament: {
        ...state.currentLotIndexByTournament,
        tournamentId: nextIndex,
      },
    );
    _openCurrentLot(tournamentId);
  }

  /// PRD §8.7: "unsold pool re-rounds." Re-queues every unsold lot as
  /// a fresh pending lot at the end of the queue, incrementing round.
  void reRoundUnsold(String tournamentId) {
    final lots = state.lotsFor(tournamentId);
    final unsold = lots.where((l) => l.status == LotStatus.unsold).toList();
    if (unsold.isEmpty) return;
    final requeued = [
      for (final l in unsold)
        Lot(
          id: '${l.id}_round${l.round + 1}',
          player: l.player,
          round: l.round + 1,
        ),
    ];
    state = state.copyWith(
      lotsByTournament: {
        ...state.lotsByTournament,
        tournamentId: [...lots, ...requeued],
      },
    );
    _openCurrentLot(tournamentId);
  }

  void _updateLot(
    String tournamentId,
    String lotId,
    Lot Function(Lot) transform,
  ) {
    state = state.copyWith(
      lotsByTournament: {
        ...state.lotsByTournament,
        tournamentId: [
          for (final l in state.lotsFor(tournamentId))
            if (l.id == lotId) transform(l) else l,
        ],
      },
    );
  }
}

final auctionProvider = NotifierProvider<AuctionNotifier, AuctionState>(
  AuctionNotifier.new,
);
