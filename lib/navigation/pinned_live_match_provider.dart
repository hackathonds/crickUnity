import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../persistence/persisted_notifier.dart';

/// PRD §3.1: "Long-press Matches → quick jump to a pinned live match."
/// Null when no live match is pinned. Debug-togglable until real live-match
/// data exists (E4).
class PinnedLiveMatchNotifier extends PersistedNotifier<String?> {
  @override
  String get persistenceKey => 'pinned_live_match_v1';

  @override
  String? seed() => null;

  @override
  Map<String, dynamic> toJson(String? value) => {'value': value};

  @override
  String? fromJson(Map<String, dynamic> json) => json['value'] as String?;

  void set(String? matchName) => state = matchName;
}

final pinnedLiveMatchProvider =
    NotifierProvider<PinnedLiveMatchNotifier, String?>(
      PinnedLiveMatchNotifier.new,
    );
