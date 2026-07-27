/// PRD §8.7 (Auction): "Optional player-auction mode: player pool
/// (registered free agents with base price), team purses, live auction
/// room (organizer as auctioneer; bid buttons with increments; timer
/// per lot; unsold pool re-rounds), results roster auto-forms teams.
/// Spectator mode for fans. All bids logged; purse math enforced
/// (can't bid beyond purse minus minimum-squad reserve)."
///
/// DS §7-40 (Auction Room, a real numbered screen entry, not a
/// phantom citation): "lot card center (player card XL + base price),
/// purse rail top (all teams tnum), bid buttons increments bottom 64
/// targets, timer ring Arc 12s; spectator layout hides bid controls;
/// reconnect banner preserves lot state."
///
/// Backlog splits this XL story into 5 sub-parts: lot / bidding /
/// purse / spectator / reconnect -- each is called out at its owning
/// file/section below.
library;

import '../onboarding/profile_wizard_provider.dart' show PrimaryRole;

/// PrimaryRole is already the app's player-role vocabulary
/// (onboarding/profile_wizard_provider.dart) -- reused rather than a
/// second role enum for the auction pool.
class FreeAgent {
  final String id;
  final String name;
  final PrimaryRole role;
  final int basePrice;

  const FreeAgent({
    required this.id,
    required this.name,
    required this.role,
    required this.basePrice,
  });
}

/// PRD names no exact increment amounts -- flagged judgment call, same
/// as every other unspecified numeric range this session.
const List<int> bidIncrements = [50, 100, 200];

/// DS §7-40: "timer ring Arc 12s."
const Duration lotTimerDuration = Duration(seconds: 12);

/// PRD names no exact reserve-per-slot value -- flagged judgment call:
/// each remaining minimum-squad slot (other than the lot currently up
/// for bid) reserves this many coins of purse.
const int minimumBidReservePerSlot = 100;

enum LotStatus { pending, live, sold, unsold }

/// Sub-part "lot": the item currently up for auction.
class Lot {
  final String id;
  final FreeAgent player;
  final LotStatus status;
  final int currentBid;
  final String? currentBidderRegistrationId;
  final String? currentBidderTeamName;
  final int round;

  const Lot({
    required this.id,
    required this.player,
    this.status = LotStatus.pending,
    this.currentBid = 0,
    this.currentBidderRegistrationId,
    this.currentBidderTeamName,
    this.round = 1,
  });

  Lot copyWith({
    LotStatus? status,
    int? currentBid,
    String? currentBidderRegistrationId,
    String? currentBidderTeamName,
    int? round,
  }) {
    return Lot(
      id: id,
      player: player,
      status: status ?? this.status,
      currentBid: currentBid ?? this.currentBid,
      currentBidderRegistrationId:
          currentBidderRegistrationId ?? this.currentBidderRegistrationId,
      currentBidderTeamName:
          currentBidderTeamName ?? this.currentBidderTeamName,
      round: round ?? this.round,
    );
  }
}

/// Sub-part "purse": per-team budget and the minimum-squad-reserve
/// math PRD §8.7 requires be enforced on every bid.
class AuctionTeamPurse {
  final String registrationId;
  final String teamName;
  final int totalPurse;
  final int spent;
  final int squadSize;
  final int minSquadSize;

  const AuctionTeamPurse({
    required this.registrationId,
    required this.teamName,
    required this.totalPurse,
    this.spent = 0,
    this.squadSize = 0,
    required this.minSquadSize,
  });

  int get remaining => totalPurse - spent;

  /// Reserve for every minimum-squad slot still needed *after* the lot
  /// currently up for bid (which itself fills one slot).
  int get reserveForRemainingSlots {
    final slotsAfterThisLot = (minSquadSize - squadSize - 1).clamp(
      0,
      minSquadSize,
    );
    return slotsAfterThisLot * minimumBidReservePerSlot;
  }

  int get maxBiddable =>
      (remaining - reserveForRemainingSlots).clamp(0, remaining);

  AuctionTeamPurse copyWith({int? spent, int? squadSize}) {
    return AuctionTeamPurse(
      registrationId: registrationId,
      teamName: teamName,
      totalPurse: totalPurse,
      spent: spent ?? this.spent,
      squadSize: squadSize ?? this.squadSize,
      minSquadSize: minSquadSize,
    );
  }
}

/// PRD §8.7: "All bids logged."
class BidLogEntry {
  final String lotId;
  final String teamRegistrationId;
  final String teamName;
  final int amount;
  final DateTime timestamp;

  const BidLogEntry({
    required this.lotId,
    required this.teamRegistrationId,
    required this.teamName,
    required this.amount,
    required this.timestamp,
  });
}
