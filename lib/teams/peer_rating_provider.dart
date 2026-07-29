import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../persistence/persisted_notifier.dart';
import 'peer_rating_models.dart';

/// Ballots for the current match's peer-rating window, persisted
/// on-device (lib/persistence/) -- no backend exists for this yet, same
/// mock-provider pattern as every other module in this app. Submission is
/// "submit-all" per DS §11.6: a rater rates every teammate in one action
/// and cannot resubmit.
class PeerRatingsNotifier extends PersistedNotifier<List<PeerRating>> {
  @override
  String get persistenceKey => 'peer_ratings_v1';

  @override
  List<PeerRating> seed() => const [];

  @override
  Map<String, dynamic> toJson(List<PeerRating> value) => {
    'items': value.map((r) => r.toJson()).toList(),
  };

  @override
  List<PeerRating> fromJson(Map<String, dynamic> json) => [
    for (final item in (json['items'] as List? ?? const []))
      PeerRating.fromJson(item as Map<String, dynamic>),
  ];

  bool hasSubmitted(String raterName) =>
      state.any((r) => r.raterName == raterName);

  void submitAll({
    required String raterName,
    required Map<String, int> starsByTeammate,
    Map<String, List<String>> tagsByTeammate = const {},
  }) {
    if (hasSubmitted(raterName)) return;
    state = [
      ...state,
      for (final entry in starsByTeammate.entries)
        PeerRating(
          raterName: raterName,
          ratedPlayerName: entry.key,
          stars: entry.value,
          tags: tagsByTeammate[entry.key] ?? const [],
        ),
    ];
  }
}

final peerRatingsProvider =
    NotifierProvider<PeerRatingsNotifier, List<PeerRating>>(
      PeerRatingsNotifier.new,
    );
