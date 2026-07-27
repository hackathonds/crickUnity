import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'club_models.dart';

class ClubState {
  final Club club;
  final List<ClubMember> members;
  final Map<MembershipTierType, MembershipTierDefinition> tiers;
  final List<InterTeamFriendly> friendlies;
  final List<WallOfFameEntry> wallOfFame;
  final List<InterWalletTransferRequest> transferRequests;

  const ClubState({
    required this.club,
    this.members = const [],
    this.tiers = const {},
    this.friendlies = const [],
    this.wallOfFame = const [],
    this.transferRequests = const [],
  });

  ClubState copyWith({
    Club? club,
    List<ClubMember>? members,
    Map<MembershipTierType, MembershipTierDefinition>? tiers,
    List<InterTeamFriendly>? friendlies,
    List<WallOfFameEntry>? wallOfFame,
    List<InterWalletTransferRequest>? transferRequests,
  }) {
    return ClubState(
      club: club ?? this.club,
      members: members ?? this.members,
      tiers: tiers ?? this.tiers,
      friendlies: friendlies ?? this.friendlies,
      wallOfFame: wallOfFame ?? this.wallOfFame,
      transferRequests: transferRequests ?? this.transferRequests,
    );
  }

  int get activeMembersCount => members.length;
  int get duesOutstandingCount =>
      members.where((m) => m.duesStatus != DuesStatus.green).length;
}

/// Backlog E11-01 -- Club home + console engine. See club_models.dart's
/// top-of-file note for the exact PRD §9 quote and the backlog's
/// narrower 4-part scope.
class ClubNotifier extends Notifier<ClubState> {
  @override
  ClubState build() => ClubState(
    club: const Club(
      id: 'club-city-cricket-club',
      name: 'City Cricket Club',
      ownerName: 'Deepak Sharma',
      linkedTeamNames: ['Strikers CC', 'Riverside Warriors'],
      upcomingEventsCount: 1,
      pendingJoinRequests: 2,
      treasuryBalance: 5000,
    ),
    members: [
      ClubMember(
        id: 'member-1',
        name: 'Arjun Rao',
        tier: MembershipTierType.playing,
        duesStatus: DuesStatus.green,
        role: ClubRole.owner,
        joinDate: DateTime.now().subtract(const Duration(days: 900)),
      ),
      ClubMember(
        id: 'member-2',
        name: 'Priya Nair',
        tier: MembershipTierType.playing,
        duesStatus: DuesStatus.amber,
        role: ClubRole.treasurer,
        joinDate: DateTime.now().subtract(const Duration(days: 400)),
      ),
      ClubMember(
        id: 'member-3',
        name: 'Kabir Singh',
        tier: MembershipTierType.social,
        duesStatus: DuesStatus.red,
        joinDate: DateTime.now().subtract(const Duration(days: 120)),
      ),
    ],
    tiers: const {
      MembershipTierType.playing: MembershipTierDefinition(
        type: MembershipTierType.playing,
        price: 1200,
        cadence: SubscriptionCadence.yearly,
        benefits: ['Match priority', 'Kit discount', 'Ground booking priority'],
        gracePeriodDays: 14,
      ),
      MembershipTierType.social: MembershipTierDefinition(
        type: MembershipTierType.social,
        price: 500,
        cadence: SubscriptionCadence.yearly,
        benefits: ['Event access', 'Newsletter'],
        gracePeriodDays: 7,
      ),
    },
    wallOfFame: [
      WallOfFameEntry(
        id: 'wof-1',
        memberName: 'Arjun Rao',
        citation: 'Founding member -- 15 years of service.',
        addedAt: DateTime.now().subtract(const Duration(days: 30)),
      ),
    ],
  );

  void setDuesStatus(String memberId, DuesStatus status) {
    state = state.copyWith(
      members: [
        for (final m in state.members)
          if (m.id == memberId) m.copyWith(duesStatus: status) else m,
      ],
    );
  }

  void addMember(
    String name,
    MembershipTierType tier, {
    DateTime Function() now = DateTime.now,
  }) {
    state = state.copyWith(
      members: [
        ...state.members,
        ClubMember(
          id: 'member-${now().microsecondsSinceEpoch}',
          name: name,
          tier: tier,
          duesStatus: DuesStatus.green,
          joinDate: now(),
        ),
      ],
    );
  }

  /// PRD: "tier definitions (price, cadence, benefits list); ...
  /// grace period (owner-set)."
  void defineTier(MembershipTierDefinition definition) {
    state = state.copyWith(
      tiers: {...state.tiers, definition.type: definition},
    );
  }

  /// PRD Teams: "inter-team friendly scheduler."
  void scheduleFriendly(
    String teamAName,
    String teamBName,
    DateTime date, {
    String venueNote = '',
    DateTime Function() now = DateTime.now,
  }) {
    state = state.copyWith(
      friendlies: [
        ...state.friendlies,
        InterTeamFriendly(
          id: 'friendly-${now().microsecondsSinceEpoch}',
          teamAName: teamAName,
          teamBName: teamBName,
          date: date,
          venueNote: venueNote,
        ),
      ],
    );
  }

  /// PRD Recognition: "Wall of Fame (curated)."
  void addToWallOfFame(
    String memberName,
    String citation, {
    DateTime Function() now = DateTime.now,
  }) {
    state = state.copyWith(
      wallOfFame: [
        ...state.wallOfFame,
        WallOfFameEntry(
          id: 'wof-${now().microsecondsSinceEpoch}',
          memberName: memberName,
          citation: citation,
          addedAt: now(),
        ),
      ],
    );
  }

  /// Backlog addendum (PRD §2.13): "inter-wallet transfers between
  /// club and team treasuries require both treasurers' confirmation."
  void requestTransfer(
    TransferDirection direction,
    String teamName,
    int amount, {
    DateTime Function() now = DateTime.now,
  }) {
    state = state.copyWith(
      transferRequests: [
        ...state.transferRequests,
        InterWalletTransferRequest(
          id: 'transfer-${now().microsecondsSinceEpoch}',
          direction: direction,
          teamName: teamName,
          amount: amount,
        ),
      ],
    );
  }

  void confirmAsClubTreasurer(String requestId) =>
      _confirm(requestId, asClub: true);

  void confirmAsTeamTreasurer(String requestId) =>
      _confirm(requestId, asClub: false);

  void _confirm(String requestId, {required bool asClub}) {
    final request = state.transferRequests
        .where((r) => r.id == requestId)
        .firstOrNull;
    if (request == null || request.completed) return;
    final updated = asClub
        ? request.copyWith(clubTreasurerConfirmed: true)
        : request.copyWith(teamTreasurerConfirmed: true);

    if (updated.bothConfirmed) {
      final delta = updated.direction == TransferDirection.clubToTeam
          ? -updated.amount
          : updated.amount;
      state = state.copyWith(
        club: state.club.copyWith(
          treasuryBalance: state.club.treasuryBalance + delta,
        ),
      );
    }

    state = state.copyWith(
      transferRequests: [
        for (final r in state.transferRequests)
          if (r.id == requestId)
            updated.copyWith(completed: updated.bothConfirmed)
          else
            r,
      ],
    );
  }
}

final clubProvider = NotifierProvider<ClubNotifier, ClubState>(
  ClubNotifier.new,
);
