import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'officials_console_models.dart';

class OfficialsConsoleState {
  final List<Assignment> upcomingAssignments;
  final List<EarningsLedgerRow> ledger;
  final List<RatingFacet> ratingFacets;
  final List<ReviewRow> reviews;
  final int disputeFreeMatches;

  const OfficialsConsoleState({
    this.upcomingAssignments = const [],
    this.ledger = const [],
    this.ratingFacets = const [],
    this.reviews = const [],
    this.disputeFreeMatches = 0,
  });

  double get averageRating => reviews.isEmpty
      ? 0
      : reviews.fold(0.0, (a, r) => a + r.rating) / reviews.length;

  OfficialsConsoleState copyWith({
    List<Assignment>? upcomingAssignments,
    List<EarningsLedgerRow>? ledger,
    List<RatingFacet>? ratingFacets,
    List<ReviewRow>? reviews,
    int? disputeFreeMatches,
  }) {
    return OfficialsConsoleState(
      upcomingAssignments: upcomingAssignments ?? this.upcomingAssignments,
      ledger: ledger ?? this.ledger,
      ratingFacets: ratingFacets ?? this.ratingFacets,
      reviews: reviews ?? this.reviews,
      disputeFreeMatches: disputeFreeMatches ?? this.disputeFreeMatches,
    );
  }
}

/// No real officiating-history persistence exists anywhere in the app
/// (E4's matches never record who scored/umpired) -- flagged mock
/// console state, same convention as every other missing-backend gap
/// this session.
class OfficialsConsoleNotifier extends Notifier<OfficialsConsoleState> {
  @override
  OfficialsConsoleState build() {
    final now = DateTime.now();
    return OfficialsConsoleState(
      disputeFreeMatches: 34,
      upcomingAssignments: [
        Assignment(
          id: 'a-1',
          matchLabel: 'Strikers CC vs Riverside Warriors',
          date: now.add(const Duration(days: 1)),
          groundName: 'Green Valley Ground',
          feeRupees: 500,
        ),
        Assignment(
          id: 'a-2',
          matchLabel: 'City Titans vs Titans',
          date: now.add(const Duration(days: 4)),
          groundName: 'Central Oval',
          feeRupees: 600,
        ),
        Assignment(
          id: 'a-3',
          matchLabel: 'Monsoon Cup group match',
          date: now.add(const Duration(days: 9)),
          groundName: 'Riverside Turf',
          feeRupees: 900,
        ),
      ],
      ledger: [
        EarningsLedgerRow(
          matchLabel: 'vs Titans',
          date: now.subtract(const Duration(days: 3)),
          feeRupees: 500,
          status: PaymentStatus.paid,
        ),
        EarningsLedgerRow(
          matchLabel: 'vs Riverside Warriors',
          date: now.subtract(const Duration(days: 9)),
          feeRupees: 600,
          status: PaymentStatus.pending,
        ),
        EarningsLedgerRow(
          matchLabel: 'vs City Titans',
          date: now.subtract(const Duration(days: 15)),
          feeRupees: 500,
          status: PaymentStatus.paid,
        ),
        EarningsLedgerRow(
          matchLabel: 'vs Strikers CC',
          date: now.subtract(const Duration(days: 20)),
          feeRupees: 700,
          status: PaymentStatus.pending,
        ),
      ],
      ratingFacets: const [
        RatingFacet(label: 'Punctuality', score: 4.6),
        RatingFacet(label: 'Accuracy', score: 4.8),
        RatingFacet(label: 'Communication', score: 4.3),
      ],
      reviews: const [
        ReviewRow(
          reviewerName: 'Arjun Rao',
          rating: 5,
          comment: 'Sharp calls all match, kept things moving.',
        ),
        ReviewRow(
          reviewerName: 'Priya Nair',
          rating: 4,
          comment: 'Good scoring, one delayed correction.',
        ),
        ReviewRow(
          reviewerName: 'Kabir Singh',
          rating: 3,
          comment: 'Disagreed with a run-out call.',
          disputeAppealed: false,
        ),
      ],
    );
  }

  /// DS §11.4: "[Request payment reminder] on pending >7d."
  void requestPaymentReminder(String matchLabel) {
    state = state.copyWith(
      ledger: [
        for (final row in state.ledger)
          if (row.matchLabel == matchLabel)
            row.copyWith(reminderSent: true)
          else
            row,
      ],
    );
  }

  /// DS §11.4: "dispute-appeal row state."
  void appealReview(String reviewerName) {
    state = state.copyWith(
      reviews: [
        for (final r in state.reviews)
          if (r.reviewerName == reviewerName)
            r.copyWith(disputeAppealed: true)
          else
            r,
      ],
    );
  }
}

final officialsConsoleProvider =
    NotifierProvider<OfficialsConsoleNotifier, OfficialsConsoleState>(
      OfficialsConsoleNotifier.new,
    );
