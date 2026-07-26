import 'package:flutter_riverpod/flutter_riverpod.dart';

/// E1-04 · DS §11.2 Guest mode: "sheet remembers dismissals (max 1
/// auto-prompt per session; taps always allowed to re-trigger)."
///
/// This distinguishes two trigger paths for the Register sheet:
/// - An explicit tap on a blocked control always shows it (never gated).
/// - An unprompted "auto-prompt" (a public screen surfacing it on its own,
///   e.g. after a few seconds of viewing) is capped at once per session --
///   tracked here via [hasAutoPrompted].
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
  @override
  GuestState build() => const GuestState();

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
  /// guest completes registration they're no longer a guest.
  void becomeRegistered() => state = state.copyWith(isGuest: false);

  void reset() => state = const GuestState();
}

final guestProvider = NotifierProvider<GuestNotifier, GuestState>(
  GuestNotifier.new,
);
