import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import '../navigation/push_depth_tracker.dart';

/// Stands in for every real destination this story doesn't build (Home
/// Dashboard, Matches list, Feed, Profile, the 10 role consoles — all
/// separate backlog stories). When [branchIndex] and [path] are supplied,
/// it also demonstrates the push-depth cap (DS §1.2) with an "Open next"
/// button; drawer/console destinations omit them and render as a plain
/// static screen (PRD §1.1: drawer consoles are "self-contained stacks",
/// out of this story's depth-cap scope).
class PlaceholderScreen extends ConsumerStatefulWidget {
  final String title;
  final int? branchIndex;
  final String? path;

  const PlaceholderScreen({
    super.key,
    required this.title,
    this.branchIndex,
    this.path,
  });

  @override
  ConsumerState<PlaceholderScreen> createState() => _PlaceholderScreenState();
}

class _PlaceholderScreenState extends ConsumerState<PlaceholderScreen> {
  PushDepthNotifier? _pushDepthNotifier;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Captured here rather than read inside dispose(): by the time
    // dispose() runs, Riverpod's ConsumerStatefulElement may already
    // consider `ref` unusable (e.g. during a mass tree teardown), and
    // `ref.read` throws — capture the notifier while `ref` is still valid.
    _pushDepthNotifier = ref.read(pushDepthProvider.notifier);
  }

  @override
  void dispose() {
    final branchIndex = widget.branchIndex;
    if (branchIndex != null) {
      _pushDepthNotifier?.pop(branchIndex);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final branchIndex = widget.branchIndex;
    final path = widget.path;

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.title} — placeholder content',
              style: AppTypography.body.copyWith(color: colors.textSecondary),
            ),
            if (branchIndex != null && path != null) ...[
              const SizedBox(height: AppSpacing.xxl),
              Consumer(
                builder: (context, ref, _) {
                  final depth = ref.watch(
                    pushDepthProvider.select((m) => m[branchIndex] ?? 0),
                  );
                  final canPush = depth < maxPushDepth;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Push depth: $depth / $maxPushDepth',
                        style: AppTypography.caption.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      if (canPush)
                        ElevatedButton(
                          onPressed: () {
                            final pushed = ref
                                .read(pushDepthProvider.notifier)
                                .push(branchIndex);
                            if (pushed) context.push('$path/next');
                          },
                          child: const Text('Open next'),
                        )
                      else
                        Text(
                          'Depth cap reached — deeper flows become a sheet '
                          '(DS §1.2), not another push.',
                          style: AppTypography.caption.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
