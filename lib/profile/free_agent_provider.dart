import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../onboarding/profile_wizard_provider.dart';
import '../persistence/persisted_notifier.dart';
import 'free_agent_models.dart';

class AuctionRegistrationResult {
  final String? error;

  const AuctionRegistrationResult({this.error});

  bool get succeeded => error == null;
}

class FreeAgentState {
  final FreeAgentProfile profile;
  final List<AuctionPoolRegistration> auctionRegistrations;

  const FreeAgentState({
    this.profile = const FreeAgentProfile(),
    this.auctionRegistrations = const [],
  });

  FreeAgentState copyWith({
    FreeAgentProfile? profile,
    List<AuctionPoolRegistration>? auctionRegistrations,
  }) {
    return FreeAgentState(
      profile: profile ?? this.profile,
      auctionRegistrations: auctionRegistrations ?? this.auctionRegistrations,
    );
  }

  Map<String, dynamic> toJson() => {
    'profile': profile.toJson(),
    'auctionRegistrations': [for (final r in auctionRegistrations) r.toJson()],
  };

  factory FreeAgentState.fromJson(Map<String, dynamic> json) {
    return FreeAgentState(
      profile: FreeAgentProfile.fromJson(
        json['profile'] as Map<String, dynamic>,
      ),
      auctionRegistrations: [
        for (final r in json['auctionRegistrations'] as List)
          AuctionPoolRegistration.fromJson(r as Map<String, dynamic>),
      ],
    );
  }
}

/// PRD §2.2/§8.7 (Free-agent mode, player side). Browsing team needs and
/// applying reuse `recruitmentBoardProvider` (E3-11) directly -- a
/// free agent's application lands in the exact same pipeline a team
/// manager sees on their Recruitment Board, rather than a separate
/// mirrored data structure.
class FreeAgentNotifier extends PersistedNotifier<FreeAgentState> {
  @override
  String get persistenceKey => 'free_agent_v1';

  @override
  FreeAgentState seed() => const FreeAgentState();

  @override
  Map<String, dynamic> toJson(FreeAgentState value) => value.toJson();

  @override
  FreeAgentState fromJson(Map<String, dynamic> json) =>
      FreeAgentState.fromJson(json);

  void setFreeAgent(bool value) {
    state = state.copyWith(profile: state.profile.copyWith(isFreeAgent: value));
  }

  void toggleDay(Weekday day) {
    final days = {...state.profile.availableDays};
    if (!days.remove(day)) days.add(day);
    state = state.copyWith(
      profile: state.profile.copyWith(availableDays: days),
    );
  }

  void toggleRole(PrimaryRole role) {
    final roles = {...state.profile.rolesOffered};
    if (!roles.remove(role)) roles.add(role);
    state = state.copyWith(
      profile: state.profile.copyWith(rolesOffered: roles),
    );
  }

  AuctionRegistrationResult registerForAuctionPool({
    required String tournamentName,
    required int basePriceRupees,
    DateTime Function() now = DateTime.now,
  }) {
    if (!state.profile.isFreeAgent) {
      return const AuctionRegistrationResult(
        error: 'Turn on free-agent mode before registering for an auction.',
      );
    }
    if (tournamentName.trim().isEmpty) {
      return const AuctionRegistrationResult(
        error: 'Name the tournament to register for.',
      );
    }
    if (state.auctionRegistrations.any(
      (r) => r.tournamentName == tournamentName.trim(),
    )) {
      return const AuctionRegistrationResult(
        error: "You're already registered for this tournament's pool.",
      );
    }
    state = state.copyWith(
      auctionRegistrations: [
        ...state.auctionRegistrations,
        AuctionPoolRegistration(
          tournamentName: tournamentName.trim(),
          basePriceRupees: basePriceRupees,
          registeredAt: now(),
        ),
      ],
    );
    return const AuctionRegistrationResult();
  }

  void withdrawFromAuctionPool(String tournamentName) {
    state = state.copyWith(
      auctionRegistrations: [
        for (final r in state.auctionRegistrations)
          if (r.tournamentName != tournamentName) r,
      ],
    );
  }
}

final freeAgentProvider = NotifierProvider<FreeAgentNotifier, FreeAgentState>(
  FreeAgentNotifier.new,
);
