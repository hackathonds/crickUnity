import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'rewards_provider.dart';

/// DS §5.8: "suppressed during Live Scoring & money confirmations,
/// delivered after." A thin lifecycle wrapper that flips
/// [RewardsState.suppressCeremonies] on while its subtree is mounted --
/// used at the Live Scoring Console specifically (the money/live
/// surface DS names). Comprehensive wiring across every money
/// confirmation screen is a broader integration than E6-01's scope,
/// flagged rather than silently skipped.
class CeremonySuppressionScope extends ConsumerStatefulWidget {
  final Widget child;

  const CeremonySuppressionScope({super.key, required this.child});

  @override
  ConsumerState<CeremonySuppressionScope> createState() =>
      _CeremonySuppressionScopeState();
}

class _CeremonySuppressionScopeState
    extends ConsumerState<CeremonySuppressionScope> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted)
        ref.read(rewardsProvider.notifier).setSuppressCeremonies(true);
    });
  }

  @override
  void dispose() {
    ref.read(rewardsProvider.notifier).setSuppressCeremonies(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
