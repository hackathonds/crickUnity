import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'match_models.dart';

class CreateMatchState {
  final MatchDraft draft;

  const CreateMatchState({required this.draft});

  CreateMatchState copyWith({MatchDraft? draft}) {
    return CreateMatchState(draft: draft ?? this.draft);
  }
}

/// PRD §7.1's 4-step wizard draft. AC: "Given I created a match last
/// week, When I start the wizard, Then format/ground/time pre-fill
/// from it" -- [build] seeds the draft from [mockLastMatchDraft].
///
/// Intentionally not persisted (lib/persistence/) -- this is in-progress
/// wizard scratch state, same category as registration_flow_provider.dart
/// and create_team_provider.dart: resuming mid-create-match-wizard after
/// an app restart isn't the intended UX. The durable result is the
/// [MatchRecord] `submitMatch` adds to matches_provider.dart, which does
/// persist.
class CreateMatchNotifier extends Notifier<CreateMatchState> {
  @override
  CreateMatchState build() => CreateMatchState(draft: mockLastMatchDraft());

  void setMatchType(MatchType value) =>
      state = state.copyWith(draft: state.draft.copyWith(matchType: value));

  void setFormat(MatchFormat value) =>
      state = state.copyWith(draft: state.draft.copyWith(format: value));

  void setBallType(BallType value) =>
      state = state.copyWith(draft: state.draft.copyWith(ballType: value));

  void setSubRules(ExtraSubRules value) =>
      state = state.copyWith(draft: state.draft.copyWith(subRules: value));

  void setOpponentTeamName(String value) => state = state.copyWith(
    draft: state.draft.copyWith(opponentTeamName: value),
  );

  void setIsGuestTeam(bool value) =>
      state = state.copyWith(draft: state.draft.copyWith(isGuestTeam: value));

  void setGroundName(String value) =>
      state = state.copyWith(draft: state.draft.copyWith(groundName: value));

  void setDateTime(DateTime value) =>
      state = state.copyWith(draft: state.draft.copyWith(dateTime: value));

  void setVisibility(MatchVisibility value) =>
      state = state.copyWith(draft: state.draft.copyWith(visibility: value));

  void setScorerAssignment(ScorerAssignment value) => state = state.copyWith(
    draft: state.draft.copyWith(
      scorerAssignment: value,
      clearScorerMemberName: value != ScorerAssignment.member,
    ),
  );

  void setScorerMemberName(String value) => state = state.copyWith(
    draft: state.draft.copyWith(scorerMemberName: value),
  );

  void toggleUmpire(String name) {
    final current = state.draft.umpireNames;
    state = state.copyWith(
      draft: state.draft.copyWith(
        umpireNames: current.contains(name)
            ? [
                for (final n in current)
                  if (n != name) n,
              ]
            : [...current, name],
      ),
    );
  }

  void setExpensePresetEnabled(bool value) => state = state.copyWith(
    draft: state.draft.copyWith(expensePresetEnabled: value),
  );

  void setAvailabilityDeadlineHours(int value) => state = state.copyWith(
    draft: state.draft.copyWith(availabilityDeadlineHours: value),
  );

  void resetToSmartDefaults() {
    state = CreateMatchState(draft: mockLastMatchDraft());
  }
}

final createMatchProvider =
    NotifierProvider<CreateMatchNotifier, CreateMatchState>(
      CreateMatchNotifier.new,
    );
