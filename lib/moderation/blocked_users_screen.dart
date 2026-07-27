import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_button.dart';
import '../design_system/components/app_text_field.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'moderation_provider.dart';

/// PRD §12.10: "Blocking: blocker & blocked become invisible to each
/// other everywhere except co-membership surfaces (same team roster
/// shows name-only, no interaction) -- blocking someone on your team
/// prompts 'You share a team -- captain won't be notified.'" No real
/// "my teammates" lookup is wired here -- a small mock roster stands in
/// so the shared-team exception banner has something genuine to check
/// against, flagged.
const List<String> mockSharedTeamNames = ['Arjun Rao', 'Priya Nair'];

class BlockedUsersScreen extends ConsumerStatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  ConsumerState<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends ConsumerState<BlockedUsersScreen> {
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final state = ref.watch(moderationProvider);
    final notifier = ref.read(moderationProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Blocked accounts')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  label: 'Block by name',
                  controller: _nameController,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              AppButton(
                key: const ValueKey('blockUserButton'),
                variant: AppButtonVariant.secondary,
                label: 'Block',
                onPressed: () {
                  final name = _nameController.text.trim();
                  if (name.isEmpty) return;
                  notifier.blockUser(name);
                  _nameController.clear();
                  if (mockSharedTeamNames.contains(name)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        key: ValueKey('sharedTeamBlockNotice'),
                        content: Text(
                          "You share a team -- captain won't be notified.",
                        ),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            'Blocked',
            style: AppTypography.label.copyWith(color: colors.textTertiary),
          ),
          const SizedBox(height: AppSpacing.xs),
          if (state.blockedNames.isEmpty)
            Text(
              'No blocked accounts.',
              style: AppTypography.body.copyWith(color: colors.textSecondary),
            )
          else
            for (final name in state.blockedNames)
              Container(
                key: ValueKey('blockedRow_$name'),
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: colors.surfaceAlt,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: AppTypography.body.copyWith(
                              color: colors.textPrimary,
                            ),
                          ),
                        ),
                        AppButton(
                          key: ValueKey('unblockButton_$name'),
                          variant: AppButtonVariant.tertiary,
                          label: 'Unblock',
                          onPressed: () => notifier.unblockUser(name),
                        ),
                      ],
                    ),
                    if (mockSharedTeamNames.contains(name))
                      Text(
                        'Shares a team with you -- roster shows name-only, '
                        'no interaction.',
                        style: AppTypography.caption.copyWith(
                          color: colors.textTertiary,
                        ),
                      ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}
