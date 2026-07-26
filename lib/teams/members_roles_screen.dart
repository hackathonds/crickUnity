import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_bottom_sheet.dart';
import '../design_system/components/app_button.dart';
import '../design_system/components/app_tag_chip.dart';
import '../design_system/components/app_text_field.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'members_roles_provider.dart';
import 'team_member_models.dart';

/// DS §7 screen 12 (Members & Roles, captain+): "Roster rows with role
/// chips; ⋮ per row (change role/remove w/ reason dialog)."
class MembersRolesScreen extends ConsumerWidget {
  final TeamMemberRole actingRole;
  final String actorName;

  const MembersRolesScreen({
    super.key,
    required this.actingRole,
    required this.actorName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(membersRolesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Members & roles')),
      body: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: state.roster.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) => _MemberRow(
          member: state.roster[index],
          actingRole: actingRole,
          actorName: actorName,
        ),
      ),
    );
  }
}

class _MemberRow extends ConsumerWidget {
  final TeamMember member;
  final TeamMemberRole actingRole;
  final String actorName;

  const _MemberRow({
    required this.member,
    required this.actingRole,
    required this.actorName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Container(
      key: ValueKey('memberRow_${member.name}'),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              member.name,
              style: AppTypography.body.copyWith(color: colors.textPrimary),
            ),
          ),
          AppTagChip(label: teamMemberRoleLabels[member.role]!),
          const SizedBox(width: AppSpacing.sm),
          IconButton(
            key: ValueKey('memberRowMenu_${member.name}'),
            icon: const Icon(Icons.more_vert),
            tooltip: 'More',
            onPressed: () => _openRowMenu(context, ref),
          ),
        ],
      ),
    );
  }

  void _openRowMenu(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _MenuRow(
              key: ValueKey('changeRoleAction_${member.name}'),
              label: 'Change role',
              onTap: () {
                Navigator.of(sheetContext).pop();
                _openChangeRoleSheet(context, ref);
              },
            ),
            _MenuRow(
              key: ValueKey('removeAction_${member.name}'),
              label: 'Remove from team',
              onTap: () {
                Navigator.of(sheetContext).pop();
                _openRemoveSheet(context, ref);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _openChangeRoleSheet(BuildContext context, WidgetRef ref) {
    showAppBottomSheet<void>(
      context: context,
      title: 'Change role',
      contentBuilder: (context) => _ChangeRoleContent(
        member: member,
        actingRole: actingRole,
        actorName: actorName,
      ),
    );
  }

  void _openRemoveSheet(BuildContext context, WidgetRef ref) {
    showAppBottomSheet<void>(
      context: context,
      title: 'Remove ${member.name}?',
      contentBuilder: (context) => _RemoveMemberContent(
        member: member,
        actingRole: actingRole,
        actorName: actorName,
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _MenuRow({super.key, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Text(
          label,
          style: AppTypography.body.copyWith(color: colors.textPrimary),
        ),
      ),
    );
  }
}

class _ChangeRoleContent extends ConsumerStatefulWidget {
  final TeamMember member;
  final TeamMemberRole actingRole;
  final String actorName;

  const _ChangeRoleContent({
    required this.member,
    required this.actingRole,
    required this.actorName,
  });

  @override
  ConsumerState<_ChangeRoleContent> createState() => _ChangeRoleContentState();
}

class _ChangeRoleContentState extends ConsumerState<_ChangeRoleContent> {
  String? _error;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AC: a Vice-Captain cannot appoint another Vice-Captain --
          // structurally excluded from the option list, not just an
          // error on tap, same "hidden not disabled" pattern used
          // elsewhere for role-gated affordances (E3-02's team tabs).
          for (final role in TeamMemberRole.values)
            if (role != widget.member.role &&
                !(widget.actingRole == TeamMemberRole.viceCaptain &&
                    role == TeamMemberRole.viceCaptain))
              GestureDetector(
                key: ValueKey('roleOption_${role.name}'),
                onTap: () {
                  final error = ref
                      .read(membersRolesProvider.notifier)
                      .changeRole(
                        memberName: widget.member.name,
                        newRole: role,
                        actingRole: widget.actingRole,
                        actorName: widget.actorName,
                      );
                  if (error == null) {
                    Navigator.of(context).pop();
                  } else {
                    setState(() => _error = error);
                  }
                },
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  child: Text(
                    teamMemberRoleLabels[role]!,
                    style: AppTypography.body.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                ),
              ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Text(
                _error!,
                key: const ValueKey('changeRoleError'),
                style: AppTypography.caption.copyWith(color: colors.error),
              ),
            ),
        ],
      ),
    );
  }
}

class _RemoveMemberContent extends ConsumerStatefulWidget {
  final TeamMember member;
  final TeamMemberRole actingRole;
  final String actorName;

  const _RemoveMemberContent({
    required this.member,
    required this.actingRole,
    required this.actorName,
  });

  @override
  ConsumerState<_RemoveMemberContent> createState() =>
      _RemoveMemberContentState();
}

class _RemoveMemberContentState extends ConsumerState<_RemoveMemberContent> {
  final _reasonController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTextField(
            key: const ValueKey('removeReasonField'),
            label: 'Reason (required)',
            controller: _reasonController,
          ),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              _error!,
              key: const ValueKey('removeMemberError'),
              style: AppTypography.caption.copyWith(color: colors.error),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            key: const ValueKey('confirmRemoveButton'),
            variant: AppButtonVariant.destructive,
            label: 'Remove',
            fullWidth: true,
            onPressed: () {
              final error = ref
                  .read(membersRolesProvider.notifier)
                  .removeMember(
                    memberName: widget.member.name,
                    actingRole: widget.actingRole,
                    actorName: widget.actorName,
                    reason: _reasonController.text,
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
