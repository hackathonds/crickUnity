import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One persistent [ScrollController] per tab branch, shared between
/// [AppShell]'s re-tap handling and each branch's root screen — lets the
/// shell drive "scroll to top" without needing ambient
/// `PrimaryScrollController` resolution across the `IndexedStack` boundary.
final tabScrollControllerProvider = Provider.family<ScrollController, int>((
  ref,
  branchIndex,
) {
  final controller = ScrollController();
  ref.onDispose(controller.dispose);
  return controller;
});

/// Bumped once per branch whenever a re-tap happens while already scrolled
/// to top — PRD §3.1: "second re-tap refreshes." The root screen listens
/// and shows a "Refreshed" signal; there's no real data to reload yet.
final tabRefreshSignalProvider = StateProvider.family<int, int>(
  (ref, branchIndex) => 0,
);
