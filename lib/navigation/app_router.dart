import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../design_system/debug/debug_menu_screen.dart';
import '../design_system/tokens/app_motion.dart';
import '../widgets/placeholder_screen.dart';
import '../widgets/tab_root_screen.dart';
import 'app_shell.dart';
import 'push_depth_tracker.dart';

/// 240ms parallax push/pop (DS §5.1 item 1), collapsing to a plain fade
/// under reduced motion — reuses E0-01's [AppMotion] tokens rather than
/// hand-rolled durations/curves.
Page<void> parallaxPage({required LocalKey key, required Widget child}) {
  return CustomTransitionPage(
    key: key,
    child: child,
    transitionDuration: AppMotionDuration.standard,
    reverseTransitionDuration: AppMotionDuration.standard,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      if (AppMotion.isReduced(context)) {
        return FadeTransition(opacity: animation, child: child);
      }
      final curved = CurvedAnimation(
        parent: animation,
        curve: AppMotionCurves.standard,
      );
      final secondaryCurved = CurvedAnimation(
        parent: secondaryAnimation,
        curve: AppMotionCurves.standard,
      );
      return SlideTransition(
        position: Tween<Offset>(
          begin: Offset.zero,
          end: const Offset(-0.06, 0),
        ).animate(secondaryCurved),
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

/// Builds a branch's root route plus exactly [maxPushDepth] levels of
/// nested `next` routes — the depth cap is enforced structurally: the
/// router simply has no route beyond that depth (DS §1.2).
GoRoute buildBranchRoute({
  required String rootPath,
  required String rootTitle,
  required int branchIndex,
  bool showDrawerAvatar = false,
  Widget? extra,
}) {
  GoRoute nextRoute(String parentPath, int depth) {
    final path = '$parentPath/next';
    return GoRoute(
      path: 'next',
      pageBuilder: (context, state) => parallaxPage(
        key: state.pageKey,
        child: PlaceholderScreen(
          title: '$rootTitle detail $depth',
          branchIndex: branchIndex,
          path: path,
        ),
      ),
      routes: depth < maxPushDepth ? [nextRoute(path, depth + 1)] : const [],
    );
  }

  return GoRoute(
    path: rootPath,
    builder: (context, state) => TabRootScreen(
      title: rootTitle,
      branchIndex: branchIndex,
      path: rootPath,
      showDrawerAvatar: showDrawerAvatar,
      extra: extra,
    ),
    routes: [nextRoute(rootPath, 1)],
  );
}

/// Builds a fresh [GoRouter]. A factory rather than a shared singleton so
/// each widget test gets independent navigation state — a top-level
/// `final GoRouter` would leak pushed routes/branch state between tests
/// in the same file, since GoRouter itself isn't scoped by [ProviderScope].
GoRouter createAppRouter() => GoRouter(
  initialLocation: '/home',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          AppShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            buildBranchRoute(
              rootPath: '/home',
              rootTitle: 'Home',
              branchIndex: 0,
              showDrawerAvatar: true,
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            buildBranchRoute(
              rootPath: '/matches',
              rootTitle: 'Matches',
              branchIndex: 1,
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            buildBranchRoute(
              rootPath: '/community',
              rootTitle: 'Community',
              branchIndex: 2,
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            buildBranchRoute(
              rootPath: '/profile',
              rootTitle: 'Profile',
              branchIndex: 3,
              extra: Builder(
                builder: (context) => OutlinedButton(
                  onPressed: () =>
                      Navigator.of(context, rootNavigator: true).push(
                        MaterialPageRoute(
                          builder: (_) => const DebugMenuScreen(),
                        ),
                      ),
                  child: const Text('Design system QA / debug menu'),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  ],
);
