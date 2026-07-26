import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_bottom_sheet.dart';
import '../design_system/components/app_button.dart';
import '../design_system/components/app_text_field.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'announcement_models.dart';
import 'announcements_provider.dart';
import 'team_member_models.dart';

/// PRD §6.8: Captain/VC/Manager(/Owner) post announcements, optionally
/// push-priority (max 1 per 6h) with comments toggleable.
Future<void> showAnnouncementComposerSheet({
  required BuildContext context,
  required TeamMemberRole actingRole,
  required String actorName,
  required int totalMembers,
}) {
  return showAppBottomSheet<void>(
    context: context,
    title: 'New announcement',
    contentBuilder: (context) => _ComposerContent(
      actingRole: actingRole,
      actorName: actorName,
      totalMembers: totalMembers,
    ),
  );
}

class _ComposerContent extends ConsumerStatefulWidget {
  final TeamMemberRole actingRole;
  final String actorName;
  final int totalMembers;

  const _ComposerContent({
    required this.actingRole,
    required this.actorName,
    required this.totalMembers,
  });

  @override
  ConsumerState<_ComposerContent> createState() => _ComposerContentState();
}

class _ComposerContentState extends ConsumerState<_ComposerContent> {
  final _bodyController = TextEditingController();
  bool _pushPriority = false;
  bool _commentsEnabled = true;
  String? _error;

  @override
  void dispose() {
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    Widget toggleRow(
      Key key,
      String label,
      bool value,
      ValueChanged<bool> onChanged,
    ) => Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTypography.body.copyWith(color: colors.textPrimary),
          ),
        ),
        Switch(key: key, value: value, onChanged: onChanged),
      ],
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTextField(
            key: const ValueKey('announcementBodyField'),
            label: 'Announcement',
            controller: _bodyController,
          ),
          const SizedBox(height: AppSpacing.md),
          toggleRow(
            const ValueKey('announcementPushPrioritySwitch'),
            'Push-priority (max 1 every $pushPriorityCooldownHours hours)',
            _pushPriority,
            (value) => setState(() => _pushPriority = value),
          ),
          toggleRow(
            const ValueKey('announcementCommentsSwitch'),
            'Allow comments',
            _commentsEnabled,
            (value) => setState(() => _commentsEnabled = value),
          ),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              _error!,
              key: const ValueKey('announcementComposerError'),
              style: AppTypography.caption.copyWith(color: colors.error),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            key: const ValueKey('announcementPostButton'),
            variant: AppButtonVariant.primary,
            label: 'Post',
            fullWidth: true,
            onPressed: () {
              final error = ref
                  .read(announcementsProvider.notifier)
                  .post(
                    body: _bodyController.text,
                    actorName: widget.actorName,
                    actingRole: widget.actingRole,
                    totalMembers: widget.totalMembers,
                    isPushPriority: _pushPriority,
                    commentsEnabled: _commentsEnabled,
                  );
              if (error == null) {
                Navigator.of(context).pop();
              } else {
                setState(() => _error = error);
              }
            },
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}
