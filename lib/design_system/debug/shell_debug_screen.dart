import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../navigation/pinned_live_match_provider.dart';
import '../../navigation/tab_badges_provider.dart';
import '../../roles/active_role_view_provider.dart';
import '../../roles/current_roles_provider.dart';
import '../../roles/user_role.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';

/// QA tool simulating the state E0-04's shell reacts to — role activation,
/// tab badges, and the pinned live match — since none of the real data
/// sources exist yet. Non-negotiable #10 still holds: this is a QA
/// simulation of activity already having granted a role, never a
/// role-picker reachable in the real app.
class ShellDebugScreen extends ConsumerWidget {
  const ShellDebugScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final roles = ref.watch(currentRolesProvider);
    final badges = ref.watch(tabBadgesProvider);
    final pinned = ref.watch(pinnedLiveMatchProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Shell debug controls')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(
            'Simulate role activation',
            style: AppTypography.h2.copyWith(color: colors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Roles are activity-inferred, never chosen by users (non-'
            'negotiable #10) — this simulates activity already granting a '
            'role, for QA only.',
            style: AppTypography.caption.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.lg),
          for (final role in UserRole.values)
            CheckboxListTile(
              title: Text(role.name),
              value: roles.contains(role),
              onChanged: (_) =>
                  ref.read(currentRolesProvider.notifier).toggle(role),
            ),
          const Divider(height: AppSpacing.xxl),
          Text(
            'Business mode (PRD §3.1)',
            style: AppTypography.h2.copyWith(color: colors.textPrimary),
          ),
          Text(
            'Only swaps Community -> Bookings when the account also '
            'holds the Ground Owner role above.',
            style: AppTypography.caption.copyWith(color: colors.textSecondary),
          ),
          SwitchListTile(
            key: const ValueKey('businessModeToggle'),
            title: const Text('Business mode enabled'),
            value: ref.watch(businessModeProvider),
            onChanged: (_) => ref.read(businessModeProvider.notifier).toggle(),
          ),
          const Divider(height: AppSpacing.xxl),
          Text(
            'Tab badges',
            style: AppTypography.h2.copyWith(color: colors.textPrimary),
          ),
          SwitchListTile(
            title: const Text('Home: action needed'),
            value: badges.homeActionNeeded,
            onChanged: (value) =>
                ref.read(tabBadgesProvider.notifier).setHomeActionNeeded(value),
          ),
          ListTile(
            title: const Text('Matches: live count'),
            trailing: SizedBox(
              width: 64,
              child: TextFormField(
                key: ValueKey('liveMatchCount-${badges.liveMatchCount}'),
                initialValue: '${badges.liveMatchCount}',
                keyboardType: TextInputType.number,
                onFieldSubmitted: (value) => ref
                    .read(tabBadgesProvider.notifier)
                    .setLiveMatchCount(int.tryParse(value) ?? 0),
              ),
            ),
          ),
          ListTile(
            title: const Text('Community: new post count'),
            trailing: SizedBox(
              width: 64,
              child: TextFormField(
                key: ValueKey(
                  'newCommunityPostCount-${badges.newCommunityPostCount}',
                ),
                initialValue: '${badges.newCommunityPostCount}',
                keyboardType: TextInputType.number,
                onFieldSubmitted: (value) => ref
                    .read(tabBadgesProvider.notifier)
                    .setNewCommunityPostCount(int.tryParse(value) ?? 0),
              ),
            ),
          ),
          SwitchListTile(
            title: const Text('Profile: needs attention'),
            value: badges.profileNeedsAttention,
            onChanged: (value) => ref
                .read(tabBadgesProvider.notifier)
                .setProfileNeedsAttention(value),
          ),
          const Divider(height: AppSpacing.xxl),
          Text(
            'Pinned live match',
            style: AppTypography.h2.copyWith(color: colors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextFormField(
            key: ValueKey('pinnedLiveMatch-$pinned'),
            initialValue: pinned ?? '',
            decoration: const InputDecoration(
              hintText: 'e.g. Titans vs Strikers (blank = none pinned)',
            ),
            onFieldSubmitted: (value) => ref
                .read(pinnedLiveMatchProvider.notifier)
                .set(value.isEmpty ? null : value),
          ),
        ],
      ),
    );
  }
}
