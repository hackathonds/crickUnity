import 'package:flutter_riverpod/flutter_riverpod.dart';

class SandboxTutorialState {
  final bool hasBeenOffered;

  const SandboxTutorialState({this.hasBeenOffered = false});
}

/// Only remembers whether the "Practice with a sample match?" offer has
/// been shown this app session -- so it's asked once, not every time
/// the console opens. The practice ball-log itself is local widget
/// state (SandboxScoringScreen), not persisted here, since it's
/// throwaway practice data.
///
/// Intentionally not persisted (lib/persistence/) -- explicitly scoped
/// to "this app session" by design (same convention as
/// guest_provider.dart's hasAutoPrompted): the offer should resurface
/// on the next fresh app launch, not stay silently suppressed forever
/// once shown.
class SandboxTutorialNotifier extends Notifier<SandboxTutorialState> {
  @override
  SandboxTutorialState build() => const SandboxTutorialState();

  void markOffered() {
    state = const SandboxTutorialState(hasBeenOffered: true);
  }
}

final sandboxTutorialProvider =
    NotifierProvider<SandboxTutorialNotifier, SandboxTutorialState>(
      SandboxTutorialNotifier.new,
    );
