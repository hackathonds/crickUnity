import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_button.dart';
import '../design_system/components/app_tag_chip.dart';
import '../design_system/components/app_text_field.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'composer_screen.dart';
import 'group_models.dart';
import 'groups_provider.dart';

class GroupDetailScreen extends ConsumerStatefulWidget {
  final String groupId;

  const GroupDetailScreen({super.key, required this.groupId});

  @override
  ConsumerState<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends ConsumerState<GroupDetailScreen> {
  final _postController = TextEditingController();
  final List<TextEditingController> _joinAnswerControllers = [];

  @override
  void dispose() {
    _postController.dispose();
    for (final c in _joinAnswerControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _showJoinQuestionsSheet(Group group) {
    _joinAnswerControllers
      ..clear()
      ..addAll([for (final _ in group.joinQuestions) TextEditingController()]);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          top: AppSpacing.lg,
          bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Join questions', style: AppTypography.h2),
            const SizedBox(height: AppSpacing.md),
            for (var i = 0; i < group.joinQuestions.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: AppTextField(
                  label: group.joinQuestions[i],
                  controller: _joinAnswerControllers[i],
                ),
              ),
            AppButton(
              key: const ValueKey('submitJoinRequestButton'),
              variant: AppButtonVariant.primary,
              label: 'Request to join',
              fullWidth: true,
              onPressed: () {
                ref.read(groupsProvider.notifier).requestToJoin(
                  widget.groupId,
                  [for (final c in _joinAnswerControllers) c.text.trim()],
                );
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final groups = ref.watch(groupsProvider).groups;
    final group = groups.firstWhere((g) => g.id == widget.groupId);
    final notifier = ref.read(groupsProvider.notifier);

    final hasPendingRequest = group.pendingJoinRequests.any(
      (r) => r.requesterName == composerViewerName,
    );

    return Scaffold(
      appBar: AppBar(title: Text(group.name)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Row(
            children: [
              AppTagChip(
                label: groupPrivacyLabels[group.privacy]!,
                variant: AppTagChipVariant.neutral,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '${group.memberNames.length} members',
                style: AppTypography.caption.copyWith(
                  color: colors.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            group.description,
            style: AppTypography.body.copyWith(color: colors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.md),
          if (!group.viewerIsMember)
            AppButton(
              key: const ValueKey('joinGroupButton'),
              variant: AppButtonVariant.primary,
              label: hasPendingRequest ? 'Request pending' : 'Join group',
              fullWidth: true,
              onPressed: hasPendingRequest
                  ? null
                  : () {
                      if (group.joinQuestions.isEmpty) {
                        notifier.requestToJoin(group.id, const []);
                      } else {
                        _showJoinQuestionsSheet(group);
                      }
                    },
            )
          else
            AppButton(
              key: const ValueKey('leaveGroupButton'),
              variant: AppButtonVariant.tertiary,
              label: 'Leave group',
              fullWidth: true,
              onPressed: () => notifier.leaveGroup(group.id),
            ),
          if (group.rules.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xxl),
            Text(
              'Rules (pinned)',
              style: AppTypography.label.copyWith(color: colors.textTertiary),
            ),
            const SizedBox(height: AppSpacing.xs),
            for (final rule in group.rules)
              Text(
                '• $rule',
                style: AppTypography.body.copyWith(color: colors.textSecondary),
              ),
          ],
          if (group.memberListVisibleToPublic || group.viewerIsMember) ...[
            const SizedBox(height: AppSpacing.xxl),
            Text(
              'Members',
              style: AppTypography.label.copyWith(color: colors.textTertiary),
            ),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.xs,
              children: [
                for (final name in group.memberNames)
                  AppTagChip(
                    label: group.adminNames.contains(name)
                        ? '$name (admin)'
                        : group.modNames.contains(name)
                        ? '$name (mod)'
                        : name,
                    variant: AppTagChipVariant.neutral,
                  ),
              ],
            ),
          ],
          if (group.viewerIsAdminOrMod) ...[
            const SizedBox(height: AppSpacing.xxl),
            Text(
              'Admin panel',
              style: AppTypography.label.copyWith(color: colors.textTertiary),
            ),
            const SizedBox(height: AppSpacing.xs),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Require post approval'),
              value: group.postApprovalRequired,
              onChanged: (v) => notifier.setPostApprovalRequired(group.id, v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Member list visible to public'),
              value: group.memberListVisibleToPublic,
              onChanged: (v) => notifier.setMemberListVisibility(group.id, v),
            ),
            if (group.pendingJoinRequests.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text('Pending join requests', style: AppTypography.body),
              for (final r in group.pendingJoinRequests)
                Row(
                  children: [
                    Expanded(child: Text(r.requesterName)),
                    TextButton(
                      onPressed: () => notifier.approveJoinRequest(
                        group.id,
                        r.requesterName,
                      ),
                      child: const Text('Approve'),
                    ),
                    TextButton(
                      onPressed: () =>
                          notifier.denyJoinRequest(group.id, r.requesterName),
                      child: const Text('Deny'),
                    ),
                  ],
                ),
            ],
            if (group.posts.any((p) => !p.approved)) ...[
              const SizedBox(height: AppSpacing.sm),
              Text('Pending posts', style: AppTypography.body),
              for (final p in group.posts.where((p) => !p.approved))
                Row(
                  children: [
                    Expanded(child: Text('${p.authorName}: ${p.body}')),
                    TextButton(
                      onPressed: () => notifier.approvePost(group.id, p.id),
                      child: const Text('Approve'),
                    ),
                    TextButton(
                      onPressed: () => notifier.rejectPost(group.id, p.id),
                      child: const Text('Reject'),
                    ),
                  ],
                ),
            ],
          ],
          const SizedBox(height: AppSpacing.xxl),
          Text(
            'Posts',
            style: AppTypography.label.copyWith(color: colors.textTertiary),
          ),
          const SizedBox(height: AppSpacing.xs),
          if (group.viewerIsMember)
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: 'Write a post',
                    controller: _postController,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                AppButton(
                  key: const ValueKey('createGroupPostButton'),
                  variant: AppButtonVariant.secondary,
                  label: 'Post',
                  onPressed: () {
                    if (_postController.text.trim().isEmpty) return;
                    notifier.createPost(group.id, _postController.text.trim());
                    _postController.clear();
                  },
                ),
              ],
            ),
          const SizedBox(height: AppSpacing.sm),
          for (final post in group.approvedPosts.reversed)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Text('${post.authorName}: ${post.body}'),
            ),
        ],
      ),
    );
  }
}
