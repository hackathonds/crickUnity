import 'package:flutter_riverpod/flutter_riverpod.dart';

/// PRD §3.1: "Long-press Matches → quick jump to a pinned live match."
/// Null when no live match is pinned. Debug-togglable until real live-match
/// data exists (E4).
class PinnedLiveMatchNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? matchName) => state = matchName;
}

final pinnedLiveMatchProvider =
    NotifierProvider<PinnedLiveMatchNotifier, String?>(
      PinnedLiveMatchNotifier.new,
    );
