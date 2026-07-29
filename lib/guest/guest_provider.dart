import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../persistence/local_store.dart';

/// E1-04 · DS §11.2 Guest mode: "sheet remembers dismissals (max 1
/// auto-prompt per session; taps always allowed to re-trigger)."
///
/// This distinguishes two trigger paths for the Register sheet:
/// - An explicit tap on a blocked control always shows it (never gated).
/// - An unprompted "auto-prompt" (a public screen surfacing it on its own,
///   e.g. after a few seconds of viewing) is capped at once per session --
///   tracked here via [hasAutoPrompted].
///
/// [isGuest] is the one field here that's actually durable ("has this
/// device ever completed registration") and is persisted by hand below --
/// [hasAutoPrompted] is deliberately per-session per its own doc line
/// above, so this doesn't use [PersistedNotifier] (which would persist the
/// whole state, including the field that's supposed to reset every
/// launch).
class GuestState {
  final bool isGuest;
  final bool hasAutoPrompted;

  const GuestState({this.isGuest = true, this.hasAutoPrompted = false});

  GuestState copyWith({bool? isGuest, bool? hasAutoPrompted}) {
    return GuestState(
      isGuest: isGuest ?? this.isGuest,
      hasAutoPrompted: hasAutoPrompted ?? this.hasAutoPrompted,
    );
  }
}

class GuestNotifier extends Notifier<GuestState> {
  static const _persistenceKey = 'guest_registered_v1';

  @override
  GuestState build() {
    final saved = ref.read(localStoreProvider).readJson(_persistenceKey);
    final everRegistered = saved?['registered'] as bool? ?? false;
    return GuestState(isGuest: !everRegistered);
  }

  /// Call from a public screen wanting to auto-surface the Register sheet
  /// without a tap. Returns whether it's allowed to show (and, if so,
  /// marks the session's one auto-prompt budget spent) -- the caller is
  /// still responsible for actually showing the sheet UI.
  bool consumeAutoPromptBudget() {
    if (state.hasAutoPrompted) return false;
    state = state.copyWith(hasAutoPrompted: true);
    return true;
  }

  /// PRD §2.1 "Upgrade path: Register -> becomes Fan by default" -- once a
  /// guest completes registration they're no longer a guest, and that fact
  /// survives an app restart (only this one field persists -- see the
  /// class doc comment).
  void becomeRegistered() {
    state = state.copyWith(isGuest: false);
    ref.read(localStoreProvider).writeJson(_persistenceKey, {
      'registered': true,
    });
  }

  void reset() {
    state = const GuestState();
    ref.read(localStoreProvider).remove(_persistenceKey);
  }
}

final guestProvider = NotifierProvider<GuestNotifier, GuestState>(
  GuestNotifier.new,
);
