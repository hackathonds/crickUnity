import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../persistence/persisted_notifier.dart';
import '../rewards/rewards_provider.dart';
import 'fan_models.dart';

class FanState {
  final List<Prediction> predictions;
  final int superfanStreak;

  const FanState({this.predictions = const [], this.superfanStreak = 0});

  int get correctCount =>
      predictions.where((p) => p.mvpStatus == PredictionOutcome.correct).length;

  int get resolvedCount =>
      predictions.where((p) => p.mvpStatus != PredictionOutcome.pending).length;

  double get accuracyPercent =>
      resolvedCount == 0 ? 0 : correctCount * 100 / resolvedCount;

  FanState copyWith({List<Prediction>? predictions, int? superfanStreak}) {
    return FanState(
      predictions: predictions ?? this.predictions,
      superfanStreak: superfanStreak ?? this.superfanStreak,
    );
  }

  Map<String, dynamic> toJson() => {
    'predictions': [for (final p in predictions) p.toJson()],
    'superfanStreak': superfanStreak,
  };

  factory FanState.fromJson(Map<String, dynamic> json) {
    return FanState(
      predictions: [
        for (final p in json['predictions'] as List)
          Prediction.fromJson(p as Map<String, dynamic>),
      ],
      superfanStreak: json['superfanStreak'] as int? ?? 0,
    );
  }
}

/// PRD §2.14 -- E7-09's Fan engagement engine.
class FanNotifier extends PersistedNotifier<FanState> {
  @override
  String get persistenceKey => 'fan_v1';

  @override
  FanState seed() => const FanState();

  @override
  Map<String, dynamic> toJson(FanState value) => value.toJson();

  @override
  FanState fromJson(Map<String, dynamic> json) => FanState.fromJson(json);

  void submitPrediction({
    required String matchLabel,
    required String predictedWinnerTeamName,
    required String predictedMvpName,
    DateTime Function() now = DateTime.now,
  }) {
    state = state.copyWith(
      predictions: [
        ...state.predictions,
        Prediction(
          id: 'prediction-${now().microsecondsSinceEpoch}',
          matchLabel: matchLabel,
          predictedWinnerTeamName: predictedWinnerTeamName,
          predictedMvpName: predictedMvpName,
          submittedAt: now(),
        ),
      ],
    );
  }

  /// Wired from scoring_provider.dart's _maybeFireRipple -- genuinely
  /// reads the real InningsState.finalMvp rather than a mocked result.
  void resolveMvpPredictions(String matchLabel, String actualMvpName) {
    var streak = state.superfanStreak;
    final updated = <Prediction>[];
    for (final p in state.predictions) {
      if (p.matchLabel == matchLabel &&
          p.mvpStatus == PredictionOutcome.pending) {
        final correct =
            p.predictedMvpName.trim().toLowerCase() ==
            actualMvpName.trim().toLowerCase();
        if (correct) {
          streak++;
          ref
              .read(rewardsProvider.notifier)
              .awardBonus(10, label: 'Correct MVP prediction: $matchLabel');
        } else {
          streak = 0;
        }
        updated.add(
          p.copyWith(
            mvpStatus: correct
                ? PredictionOutcome.correct
                : PredictionOutcome.incorrect,
          ),
        );
      } else {
        updated.add(p);
      }
    }
    state = state.copyWith(predictions: updated, superfanStreak: streak);
  }

  /// No cross-innings "match winner" field exists anywhere in this
  /// codebase (scoring_models.dart's InningsState models one innings'
  /// stats, not a full match result) -- flagged, resolved via a debug
  /// control instead of fabricated winner data.
  void resolveWinnerPredictions(
    String matchLabel,
    String actualWinnerTeamName,
  ) {
    state = state.copyWith(
      predictions: [
        for (final p in state.predictions)
          if (p.matchLabel == matchLabel &&
              p.resultStatus == PredictionOutcome.pending)
            p.copyWith(
              resultStatus:
                  p.predictedWinnerTeamName.trim().toLowerCase() ==
                      actualWinnerTeamName.trim().toLowerCase()
                  ? PredictionOutcome.correct
                  : PredictionOutcome.incorrect,
            )
          else
            p,
      ],
    );
  }
}

final fanProvider = NotifierProvider<FanNotifier, FanState>(FanNotifier.new);
