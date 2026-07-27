/// PRD §2.14 (Fan role): "predictions & fan polls on live matches; fan
/// leaderboards (prediction accuracy, superfan streaks); redeem
/// fan-tier coins (earned via predictions, watching, streaks) for fan
/// merchandise/coupons."
enum PredictionOutcome { pending, correct, incorrect }

class Prediction {
  final String id;
  final String matchLabel;
  final String predictedWinnerTeamName;
  final String predictedMvpName;
  final PredictionOutcome resultStatus;
  final PredictionOutcome mvpStatus;
  final DateTime submittedAt;

  const Prediction({
    required this.id,
    required this.matchLabel,
    required this.predictedWinnerTeamName,
    required this.predictedMvpName,
    this.resultStatus = PredictionOutcome.pending,
    this.mvpStatus = PredictionOutcome.pending,
    required this.submittedAt,
  });

  Prediction copyWith({
    PredictionOutcome? resultStatus,
    PredictionOutcome? mvpStatus,
  }) {
    return Prediction(
      id: id,
      matchLabel: matchLabel,
      predictedWinnerTeamName: predictedWinnerTeamName,
      predictedMvpName: predictedMvpName,
      resultStatus: resultStatus ?? this.resultStatus,
      mvpStatus: mvpStatus ?? this.mvpStatus,
      submittedAt: submittedAt,
    );
  }
}
