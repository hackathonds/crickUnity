import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'peer_rating_models.dart';

/// In-memory ballots for the current match's peer-rating window -- no
/// backend exists for this yet (same mock-provider pattern as every other
/// module in this app, e.g. [InningsNotifier] for scoring). Submission is
/// "submit-all" per DS §11.6: a rater rates every teammate in one action
/// and cannot resubmit.
class PeerRatingsNotifier extends Notifier<List<PeerRating>> {
  @override
  List<PeerRating> build() => const [];

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
