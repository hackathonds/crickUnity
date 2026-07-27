import 'ground_models.dart';

/// PRD §10.3 (Reviews & Ratings): "Only completed-booking teams can
/// review (verified-stay model): stars + facets (pitch, facilities,
/// staff, value) + photos. Owner single reply per review. Report
/// abusive review -> Admin queue. Rating = weighted recent-first
/// average; facet bars on profile." DS §11.17: "Review composer
/// (verified bookers only, post-booking prompt): overall stars XL 44
/// targets -> facet star rows -> photos -> text; publish -> owner-
/// notified. Non-eligible visitors see a trust-cue note."
class Review {
  final String id;
  final String groundId;
  final String bookingId;
  final String reviewerName;
  final int overallStars;
  final Map<ReviewFacet, int> facetStars;

  /// No real photo-upload pipeline exists -- a count only, same
  /// flagged-mock-asset convention as the gallery strip (E9-02).
  final int photoCount;
  final String text;
  final DateTime createdAt;
  final String? ownerReplyText;
  final DateTime? ownerReplyAt;

  const Review({
    required this.id,
    required this.groundId,
    required this.bookingId,
    required this.reviewerName,
    required this.overallStars,
    this.facetStars = const {},
    this.photoCount = 0,
    this.text = '',
    required this.createdAt,
    this.ownerReplyText,
    this.ownerReplyAt,
  });

  bool get hasOwnerReply => ownerReplyText != null;

  Review copyWith({String? ownerReplyText, DateTime? ownerReplyAt}) {
    return Review(
      id: id,
      groundId: groundId,
      bookingId: bookingId,
      reviewerName: reviewerName,
      overallStars: overallStars,
      facetStars: facetStars,
      photoCount: photoCount,
      text: text,
      createdAt: createdAt,
      ownerReplyText: ownerReplyText ?? this.ownerReplyText,
      ownerReplyAt: ownerReplyAt ?? this.ownerReplyAt,
    );
  }
}

/// PRD names no exact decay curve for "weighted recent-first average"
/// -- a flagged judgment call: linear decay to a floor weight over a
/// 180-day window, recent reviews counting up to 3x an old one.
const int ratingRecencyWindowDays = 180;
const double ratingRecencyMaxWeight = 3.0;
const double ratingRecencyFloorWeight = 1.0;

double weightedRecentFirstAverage(List<Review> reviews, {DateTime? now}) {
  if (reviews.isEmpty) return 0;
  final reference = now ?? DateTime.now();
  double weightedSum = 0;
  double weightTotal = 0;
  for (final review in reviews) {
    final ageDays = reference
        .difference(review.createdAt)
        .inDays
        .clamp(0, ratingRecencyWindowDays);
    final fraction = 1 - (ageDays / ratingRecencyWindowDays);
    final weight =
        ratingRecencyFloorWeight +
        (ratingRecencyMaxWeight - ratingRecencyFloorWeight) * fraction;
    weightedSum += review.overallStars * weight;
    weightTotal += weight;
  }
  return weightTotal == 0 ? 0 : weightedSum / weightTotal;
}

Map<ReviewFacet, double> averageFacetStars(List<Review> reviews) {
  final result = <ReviewFacet, double>{};
  for (final facet in ReviewFacet.values) {
    final values = [
      for (final r in reviews)
        if (r.facetStars.containsKey(facet)) r.facetStars[facet]!,
    ];
    result[facet] = values.isEmpty
        ? 0
        : values.reduce((a, b) => a + b) / values.length;
  }
  return result;
}
