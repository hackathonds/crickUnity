import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../rewards/rewards_provider.dart';
import '../social/composer_screen.dart';
import 'challenge_models.dart';

class ChallengesState {
  final List<Challenge> challenges;
  final List<String> overtakenLog;

  const ChallengesState({
    this.challenges = const [],
    this.overtakenLog = const [],
  });

  ChallengesState copyWith({
    List<Challenge>? challenges,
    List<String>? overtakenLog,
  }) {
    return ChallengesState(
      challenges: challenges ?? this.challenges,
      overtakenLog: overtakenLog ?? this.overtakenLog,
    );
  }
}

enum JoinChallengeFailureReason { insufficientStake }

/// PRD §13.3/§14 -- E8-03's challenges engine.
class ChallengesNotifier extends Notifier<ChallengesState> {
  @override
  ChallengesState build() => ChallengesState(challenges: _seedChallenges());

  static List<Challenge> _seedChallenges() {
    final endsAt = DateTime.now().add(const Duration(days: 10));
    return [
      Challenge(
        id: 'challenge-global-runs',
        type: ChallengeType.monthlyGlobal,
        title: 'October: 200 runs',
        metricLabel: 'Runs',
        target: 200,
        endsAt: endsAt,
        participants: const [
          ChallengeParticipant(name: 'Arjun Rao', progress: 140),
        ],
      ),
      Challenge(
        id: 'challenge-club-fielding',
        type: ChallengeType.club,
        title: 'Lions January Fielding Drive',
        metricLabel: 'Catches + run-outs',
        target: 20,
        endsAt: endsAt,
        participants: const [
          ChallengeParticipant(name: 'Priya Nair', progress: 12),
          ChallengeParticipant(name: 'Kabir Singh', progress: 9),
        ],
      ),
    ];
  }

  /// PRD: "stake optional ... capped 50 coins to keep friendly." Both
  /// sides genuinely stake via rewardsProvider.spendCoins.
  JoinChallengeFailureReason? joinFriendChallenge({
    required String title,
    required String metricLabel,
    required int target,
    required String opponentName,
    int? stakeCoins,
    DateTime Function() now = DateTime.now,
  }) {
    final cappedStake = stakeCoins?.clamp(0, maxChallengeStakeCoins);
    if (cappedStake != null && cappedStake > 0) {
      final spent = ref
          .read(rewardsProvider.notifier)
          .spendCoins(cappedStake, label: 'Challenge stake: $title');
      if (!spent) return JoinChallengeFailureReason.insufficientStake;
    }

    state = state.copyWith(
      challenges: [
        ...state.challenges,
        Challenge(
          id: 'challenge-h2h-${now().microsecondsSinceEpoch}',
          type: ChallengeType.friendH2H,
          title: title,
          metricLabel: metricLabel,
          target: target,
          stakeCoins: cappedStake,
          endsAt: now().add(const Duration(days: 14)),
          participants: [
            ChallengeParticipant(name: composerViewerName),
            ChallengeParticipant(name: opponentName),
          ],
        ),
      ],
    );
    return null;
  }

  void joinChallenge(String challengeId) {
    _update(challengeId, (c) {
      if (c.participantNamed(composerViewerName) != null) return c;
      return c.copyWith(
        participants: [
          ...c.participants,
          const ChallengeParticipant(name: composerViewerName),
        ],
      );
    });
  }

  /// PRD: "live head-to-head bar ... overtaken notifications" (backlog).
  void recordProgress(String challengeId, String participantName, int amount) {
    final index = state.challenges.indexWhere((c) => c.id == challengeId);
    if (index < 0) return;
    final challenge = state.challenges[index];
    final previousLeader = challenge.currentLeader?.name;

    final updatedParticipants = [
      for (final p in challenge.participants)
        if (p.name == participantName)
          p.copyWith(progress: p.progress + amount)
        else
          p,
    ];
    var updated = challenge.copyWith(participants: updatedParticipants);

    final newLeader = updated.currentLeader?.name;
    if (challenge.type == ChallengeType.friendH2H &&
        newLeader != null &&
        newLeader != previousLeader &&
        previousLeader != null) {
      state = state.copyWith(
        overtakenLog: [
          ...state.overtakenLog,
          '$newLeader overtook $previousLeader in "${challenge.title}"!',
        ],
      );
    }
    updated = updated.copyWith(lastLeaderName: newLeader);

    // Award/settle on reaching target.
    final finisher = updated.participantNamed(participantName);
    if (finisher != null &&
        finisher.progress >= updated.target &&
        !finisher.claimed) {
      if (updated.type == ChallengeType.friendH2H) {
        final pot = (updated.stakeCoins ?? 0) * updated.participants.length;
        if (pot > 0) {
          ref
              .read(rewardsProvider.notifier)
              .awardBonus(pot, label: 'Won H2H: ${updated.title}');
        }
      } else {
        ref
            .read(rewardsProvider.notifier)
            .awardBonus(20, label: 'Finished challenge: ${updated.title}');
      }
      updated = updated.copyWith(
        participants: [
          for (final p in updated.participants)
            if (p.name == participantName) p.copyWith(claimed: true) else p,
        ],
      );
    }

    final updatedList = [...state.challenges];
    updatedList[index] = updated;
    state = state.copyWith(challenges: updatedList);
  }

  void _update(String challengeId, Challenge Function(Challenge) transform) {
    state = state.copyWith(
      challenges: [
        for (final c in state.challenges)
          if (c.id == challengeId) transform(c) else c,
      ],
    );
  }
}

final challengesProvider =
    NotifierProvider<ChallengesNotifier, ChallengesState>(
      ChallengesNotifier.new,
    );
