import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../social/composer_screen.dart' show composerViewerName;
import 'bookings_provider.dart';
import 'ground_models.dart';
import 'review_models.dart';

class ReviewsState {
  final List<Review> reviews;

  const ReviewsState({this.reviews = const []});

  ReviewsState copyWith({List<Review>? reviews}) =>
      ReviewsState(reviews: reviews ?? this.reviews);

  List<Review> forGround(String groundId) =>
      reviews.where((r) => r.groundId == groundId).toList();
}

/// Backlog E9-04: "Reviews (verified-booker gate, facets, single owner
/// reply -- PRD §10.3, DS §11.17)."
class ReviewsNotifier extends Notifier<ReviewsState> {
  @override
  ReviewsState build() => ReviewsState(reviews: _seedReviews());

  static List<Review> _seedReviews() => [
    Review(
      id: 'review-1',
      groundId: 'ground-green-valley',
      bookingId: 'booking-seed-prior',
      reviewerName: 'Priya Nair',
      overallStars: 5,
      facetStars: const {
        ReviewFacet.pitch: 5,
        ReviewFacet.facilities: 4,
        ReviewFacet.staff: 5,
        ReviewFacet.value: 4,
      },
      photoCount: 2,
      text: 'Excellent turf, floodlights work great for evening matches.',
      createdAt: DateTime.now().subtract(const Duration(days: 20)),
      ownerReplyText: 'Thank you for playing with us!',
      ownerReplyAt: DateTime.now().subtract(const Duration(days: 19)),
    ),
  ];

  /// PRD §10.3: "Only completed-booking teams can review (verified-stay
  /// model)." A reviewer is eligible for a ground once they have at
  /// least one completed booking there without an existing review tied
  /// to that booking.
  bool isEligible(String groundId) {
    final completed = ref
        .read(bookingsProvider.notifier)
        .completedBookingsFor(groundId);
    return completed.any((b) => !state.reviews.any((r) => r.bookingId == b.id));
  }

  String? nextEligibleBookingId(String groundId) {
    final completed = ref
        .read(bookingsProvider.notifier)
        .completedBookingsFor(groundId);
    final unreviewed = completed.where(
      (b) => !state.reviews.any((r) => r.bookingId == b.id),
    );
    return unreviewed.isEmpty ? null : unreviewed.first.id;
  }

  /// Returns null on success, or an error message if the verified-
  /// booker gate rejects the submission.
  String? submitReview({
    required String groundId,
    required int overallStars,
    required Map<ReviewFacet, int> facetStars,
    required int photoCount,
    required String text,
    DateTime Function() now = DateTime.now,
  }) {
    final bookingId = nextEligibleBookingId(groundId);
    if (bookingId == null) {
      return "Reviews come from teams who've played here.";
    }
    state = state.copyWith(
      reviews: [
        ...state.reviews,
        Review(
          id: 'review-${now().microsecondsSinceEpoch}',
          groundId: groundId,
          bookingId: bookingId,
          reviewerName: composerViewerName,
          overallStars: overallStars,
          facetStars: facetStars,
          photoCount: photoCount,
          text: text,
          createdAt: now(),
        ),
      ],
    );
    return null;
  }

  /// PRD §10.3: "Owner single reply per review."
  void replyAsOwner(
    String reviewId,
    String text, {
    DateTime Function() now = DateTime.now,
  }) {
    final review = state.reviews.where((r) => r.id == reviewId).firstOrNull;
    if (review == null || review.hasOwnerReply) return;
    state = state.copyWith(
      reviews: [
        for (final r in state.reviews)
          if (r.id == reviewId)
            r.copyWith(ownerReplyText: text, ownerReplyAt: now())
          else
            r,
      ],
    );
  }
}

final reviewsProvider = NotifierProvider<ReviewsNotifier, ReviewsState>(
  ReviewsNotifier.new,
);
