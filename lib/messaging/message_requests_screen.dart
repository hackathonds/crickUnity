import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_avatar.dart';
import '../design_system/components/app_button.dart';
import '../design_system/components/app_state_scaffolds.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'chat_provider.dart';

/// PRD §12.9: "Message requests inbox for non-connections; minors
/// receive requests only from teammates/coaches (guardian-visible)."
/// The minor-restriction rule needs a real minor/guardian account
/// system to genuinely gate (no such account-type distinction exists
/// anywhere in this codebase yet) -- flagged rather than half-built
/// with a fake "isMinor" flag that nothing else would honor.
class MessageRequestsScreen extends ConsumerWidget {
  const MessageRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final state = ref.watch(chatsProvider);
    final notifier = ref.read(chatsProvider.notifier);
    final requests = state.chats.where((c) => c.isConnectionRequest).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Message requests')),
      body: requests.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: AppEmptyState(
                message: 'No pending message requests.',
                primaryLabel: 'Back',
                onPrimary: () => Navigator.of(context).pop(),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                for (final chat in requests)
                  Container(
                    key: ValueKey('requestRow_${chat.id}'),
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: colors.surfaceAlt,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        AppAvatar(size: AppAvatarSize.md, name: chat.name),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                chat.name,
                                style: AppTypography.subtitle.copyWith(
                                  color: colors.textPrimary,
                                ),
                              ),
                              Text(
                                chat.lastMessage?.text ?? '',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.caption.copyWith(
                                  color: colors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Row(
                                children: [
                                  AppButton(
                                    key: ValueKey(
                                      'acceptRequestButton_${chat.id}',
                                    ),
                                    variant: AppButtonVariant.primary,
                                    label: 'Accept',
                                    onPressed: () =>
                                        notifier.acceptRequest(chat.id),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  AppButton(
                                    key: ValueKey(
                                      'declineRequestButton_${chat.id}',
                                    ),
                                    variant: AppButtonVariant.tertiary,
                                    label: 'Decline',
                                    onPressed: () =>
                                        notifier.declineRequest(chat.id),
                                  ),
                                ],
                              ),
                            ],
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
