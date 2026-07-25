import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../design_system/icons/app_icon.dart';
import '../design_system/icons/app_icon_id.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import '../navigation/push_depth_tracker.dart';
import '../navigation/tab_interaction_providers.dart';

/// One of the 4 bottom-nav tab roots. Owns the collapsing large-title app
/// bar (DS §5 item 14: 96→56, linked to scroll offset) and the shared
/// per-branch [ScrollController] the shell drives for re-tap-to-top.
///
/// Deliberately has no [Scaffold] of its own — it sits inside
/// [AppShell]'s single outer Scaffold, so `Scaffold.of(context)` here
/// resolves to that outer Scaffold (needed for the Home avatar's
/// open-drawer action, PRD §3.3: "avatar tap on Home").
class TabRootScreen extends ConsumerWidget {
  final String title;
  final int branchIndex;
  final String path;
  final bool showDrawerAvatar;
  final Widget? extra;

  const TabRootScreen({
    super.key,
    required this.title,
    required this.branchIndex,
    required this.path,
    this.showDrawerAvatar = false,
    this.extra,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final controller = ref.watch(tabScrollControllerProvider(branchIndex));
    final depth = ref.watch(
      pushDepthProvider.select((m) => m[branchIndex] ?? 0),
    );
    final canPush = depth < maxPushDepth;

    ref.listen(tabRefreshSignalProvider(branchIndex), (previous, next) {
      if (previous != null && next != previous) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Refreshed'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    });

    return CustomScrollView(
      controller: controller,
      slivers: [
        SliverAppBar(
          pinned: true,
          expandedHeight: 96,
          collapsedHeight: 56,
          backgroundColor: colors.surface,
          leading: showDrawerAvatar
              ? Builder(
                  builder: (innerContext) => IconButton(
                    icon: AppIcon(
                      id: AppIconId.avatar,
                      semanticLabel: 'Open menu',
                      color: colors.textPrimary,
                    ),
                    onPressed: () => Scaffold.of(innerContext).openDrawer(),
                  ),
                )
              : null,
          flexibleSpace: FlexibleSpaceBar(
            title: Text(title, style: AppTypography.h1),
            titlePadding: const EdgeInsetsDirectional.only(
              start: AppSpacing.lg,
              bottom: AppSpacing.sm,
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
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
              if (extra != null) ...[
                extra!,
                const SizedBox(height: AppSpacing.xxl),
              ],
              const SizedBox(height: AppSpacing.xxl),
              for (var i = 0; i < 20; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Text(
                    '$title placeholder row $i',
                    style: AppTypography.body.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ),
            ]),
          ),
        ),
      ],
    );
  }
}
