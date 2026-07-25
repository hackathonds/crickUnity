import 'package:flutter_riverpod/flutter_riverpod.dart';

/// DS §1.2: "Depth cap = 3 pushes from any tab root; anything deeper
/// becomes a sheet or a tab-within-screen." Tracked per tab-branch index so
/// each tab's stack is independent. Pure state — testable with a plain
/// `ProviderContainer`, no widget tree required.
const int maxPushDepth = 3;

class PushDepthNotifier extends Notifier<Map<int, int>> {
  @override
  Map<int, int> build() => const {};

  int depthOf(int branchIndex) => state[branchIndex] ?? 0;

  bool canPush(int branchIndex) => depthOf(branchIndex) < maxPushDepth;

  /// Attempts to push one level deeper on [branchIndex]. Returns false
  /// (and leaves state untouched) once [maxPushDepth] is reached — the
  /// structural enforcement of the depth cap.
  bool push(int branchIndex) {
    if (!canPush(branchIndex)) return false;
    state = {...state, branchIndex: depthOf(branchIndex) + 1};
    return true;
  }

  void pop(int branchIndex) {
    final current = depthOf(branchIndex);
    if (current > 0) {
      state = {...state, branchIndex: current - 1};
    }
  }

  void reset(int branchIndex) => state = {...state, branchIndex: 0};
}

final pushDepthProvider = NotifierProvider<PushDepthNotifier, Map<int, int>>(
  PushDepthNotifier.new,
);
