import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'team_models.dart';

/// PRD §6.1: "team limit 5 owned per user (raise via support)."
const int maxOwnedTeams = 5;

/// PRD §6.1: "Name (unique within city; suggestions if taken) -> Logo
/// (upload/generated monogram) -> City & home ground (optional link) ->
/// Format focus -> Join policy -> Colors."
///
/// PRD also names a "profanity filter" on the team name -- same gap as
/// the profile bio field (E2-02): no word-list/moderation service exists
/// anywhere in this codebase, so it isn't fabricated here either. Only
/// the length/uniqueness/team-limit rules that have a concrete, checkable
/// definition are enforced.
class CreateTeamState {
  final String name;
  final String city;
  final String homeGround;
  final Set<TeamFormat> formatFocus;
  final TeamJoinPolicy joinPolicy;
  final Color primaryColor;
  final Color secondaryColor;

  /// Mock stand-in for "how many teams does this user already own" --
  /// no backend teams service exists yet.
  final int ownedTeamCount;

  const CreateTeamState({
    this.name = '',
    this.city = '',
    this.homeGround = '',
    this.formatFocus = const {},
    this.joinPolicy = TeamJoinPolicy.open,
    this.primaryColor = const Color(0xFF123B2A),
    this.secondaryColor = const Color(0xFFE0A82E),
    this.ownedTeamCount = 0,
  });

  bool get nameLongEnough => name.trim().length >= 3;

  bool get nameTaken => mockExistingTeamNamesInCity(
    city,
  ).any((existing) => existing.toLowerCase() == name.trim().toLowerCase());

  List<String> get nameSuggestions {
    if (!nameTaken) return const [];
    return ['$name $city', '$name CC', '$name XI'];
  }

  bool get canCreateAnotherTeam => ownedTeamCount < maxOwnedTeams;

  bool get canContinueFromName => nameLongEnough && !nameTaken;

  bool get canCreate =>
      canContinueFromName &&
      city.trim().isNotEmpty &&
      formatFocus.isNotEmpty &&
      canCreateAnotherTeam;

  CreateTeamState copyWith({
    String? name,
    String? city,
    String? homeGround,
    Set<TeamFormat>? formatFocus,
    TeamJoinPolicy? joinPolicy,
    Color? primaryColor,
    Color? secondaryColor,
    int? ownedTeamCount,
  }) {
    return CreateTeamState(
      name: name ?? this.name,
      city: city ?? this.city,
      homeGround: homeGround ?? this.homeGround,
      formatFocus: formatFocus ?? this.formatFocus,
      joinPolicy: joinPolicy ?? this.joinPolicy,
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      ownedTeamCount: ownedTeamCount ?? this.ownedTeamCount,
    );
  }
}

class CreateTeamNotifier extends Notifier<CreateTeamState> {
  @override
  CreateTeamState build() => const CreateTeamState();

  void setName(String value) => state = state.copyWith(name: value);
  void setCity(String value) => state = state.copyWith(city: value);
  void setHomeGround(String value) => state = state.copyWith(homeGround: value);

  void toggleFormat(TeamFormat format) {
    final formats = {...state.formatFocus};
    if (!formats.remove(format)) formats.add(format);
    state = state.copyWith(formatFocus: formats);
  }

  void setJoinPolicy(TeamJoinPolicy policy) =>
      state = state.copyWith(joinPolicy: policy);
  void setPrimaryColor(Color color) =>
      state = state.copyWith(primaryColor: color);
  void setSecondaryColor(Color color) =>
      state = state.copyWith(secondaryColor: color);

  /// Returns null (without creating anything) if [CreateTeamState.canCreate]
  /// is false -- callers should already be gating the final step's button
  /// on that, this is the defensive backstop.
  Team? createTeam() {
    if (!state.canCreate) return null;
    return Team(
      name: state.name.trim(),
      city: state.city.trim(),
      homeGround: state.homeGround.trim().isEmpty
          ? null
          : state.homeGround.trim(),
      formatFocus: state.formatFocus.toList(),
      joinPolicy: state.joinPolicy,
      primaryColor: state.primaryColor,
      secondaryColor: state.secondaryColor,
    );
  }

  void reset() => state = const CreateTeamState();
}

final createTeamProvider =
    NotifierProvider<CreateTeamNotifier, CreateTeamState>(
      CreateTeamNotifier.new,
    );
