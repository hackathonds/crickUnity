/// PRD §2.6 (Scorer) Credentialing: "'Verified Scorer' badge after 10
/// dispute-free scored matches with avg rating >= 4.0. Badge tiers:
/// Bronze (10), Silver (50), Gold (150), Platinum (500)." §2.7 (Umpire):
/// "Credentialing tiers: mirror Scorer tiers."
/// DS §11.4: "Officials Console: next-assignment hero card -> calendar
/// strip -> tabs Assignments/Earnings/Ratings. Earnings: banking voice,
/// monthly bars + ledger rows (fee . match . status paid/pending),
/// [Request payment reminder] on pending >7d. Ratings: average hero +
/// facet bars + recent review rows; dispute-appeal row state. Credential
/// tier card: Arc progress to next tier ('34/50 matches to Silver') +
/// certification requirement chip linking 11.11."
library;

enum CredentialTier { bronze, silver, gold, platinum }

const Map<CredentialTier, String> credentialTierLabels = {
  CredentialTier.bronze: 'Bronze',
  CredentialTier.silver: 'Silver',
  CredentialTier.gold: 'Gold',
  CredentialTier.platinum: 'Platinum',
};

const Map<CredentialTier, int> credentialTierThresholds = {
  CredentialTier.bronze: 10,
  CredentialTier.silver: 50,
  CredentialTier.gold: 150,
  CredentialTier.platinum: 500,
};

/// PRD: "'Verified Scorer' badge after 10 dispute-free scored matches
/// with avg rating >= 4.0" -- a compound condition (backlog AC amendment
/// #11 flagged this: the original tier check only counted matches, not
/// rating). Applied consistently across every tier, not just the entry
/// Bronze one, since the PRD gives no reason the rating bar would relax
/// at higher tiers.
const double minAverageRatingForCredentialTier = 4.0;

CredentialTier? currentTier(int disputeFreeMatches, double averageRating) {
  if (averageRating < minAverageRatingForCredentialTier) return null;
  CredentialTier? tier;
  for (final t in CredentialTier.values) {
    if (disputeFreeMatches >= credentialTierThresholds[t]!) tier = t;
  }
  return tier;
}

CredentialTier? nextTier(int disputeFreeMatches) {
  for (final t in CredentialTier.values) {
    if (disputeFreeMatches < credentialTierThresholds[t]!) return t;
  }
  return null;
}

enum PaymentStatus { paid, pending }

class Assignment {
  final String id;
  final String matchLabel;
  final DateTime date;
  final String groundName;
  final int feeRupees;

  const Assignment({
    required this.id,
    required this.matchLabel,
    required this.date,
    required this.groundName,
    required this.feeRupees,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'matchLabel': matchLabel,
    'date': date.toIso8601String(),
    'groundName': groundName,
    'feeRupees': feeRupees,
  };

  factory Assignment.fromJson(Map<String, dynamic> json) {
    return Assignment(
      id: json['id'] as String,
      matchLabel: json['matchLabel'] as String,
      date: DateTime.parse(json['date'] as String),
      groundName: json['groundName'] as String,
      feeRupees: json['feeRupees'] as int,
    );
  }
}

class EarningsLedgerRow {
  final String matchLabel;
  final DateTime date;
  final int feeRupees;
  final PaymentStatus status;
  final bool reminderSent;

  const EarningsLedgerRow({
    required this.matchLabel,
    required this.date,
    required this.feeRupees,
    required this.status,
    this.reminderSent = false,
  });

  int get daysPending => status == PaymentStatus.pending
      ? DateTime.now().difference(date).inDays
      : 0;

  EarningsLedgerRow copyWith({bool? reminderSent}) => EarningsLedgerRow(
    matchLabel: matchLabel,
    date: date,
    feeRupees: feeRupees,
    status: status,
    reminderSent: reminderSent ?? this.reminderSent,
  );

  Map<String, dynamic> toJson() => {
    'matchLabel': matchLabel,
    'date': date.toIso8601String(),
    'feeRupees': feeRupees,
    'status': status.name,
    'reminderSent': reminderSent,
  };

  factory EarningsLedgerRow.fromJson(Map<String, dynamic> json) {
    return EarningsLedgerRow(
      matchLabel: json['matchLabel'] as String,
      date: DateTime.parse(json['date'] as String),
      feeRupees: json['feeRupees'] as int,
      status: PaymentStatus.values.byName(json['status'] as String),
      reminderSent: json['reminderSent'] as bool? ?? false,
    );
  }
}

class RatingFacet {
  final String label;
  final double score;

  const RatingFacet({required this.label, required this.score});

  Map<String, dynamic> toJson() => {'label': label, 'score': score};

  factory RatingFacet.fromJson(Map<String, dynamic> json) {
    return RatingFacet(
      label: json['label'] as String,
      score: (json['score'] as num).toDouble(),
    );
  }
}

class ReviewRow {
  final String reviewerName;
  final double rating;
  final String comment;
  final bool disputeAppealed;

  const ReviewRow({
    required this.reviewerName,
    required this.rating,
    required this.comment,
    this.disputeAppealed = false,
  });

  ReviewRow copyWith({bool? disputeAppealed}) => ReviewRow(
    reviewerName: reviewerName,
    rating: rating,
    comment: comment,
    disputeAppealed: disputeAppealed ?? this.disputeAppealed,
  );

  Map<String, dynamic> toJson() => {
    'reviewerName': reviewerName,
    'rating': rating,
    'comment': comment,
    'disputeAppealed': disputeAppealed,
  };

  factory ReviewRow.fromJson(Map<String, dynamic> json) {
    return ReviewRow(
      reviewerName: json['reviewerName'] as String,
      rating: (json['rating'] as num).toDouble(),
      comment: json['comment'] as String,
      disputeAppealed: json['disputeAppealed'] as bool? ?? false,
    );
  }
}
