import 'package:flutter/material.dart';

import '../../teams/members_roles_screen.dart';
import '../../teams/permission_matrix_screen.dart';
import '../../teams/team_member_models.dart';
import '../components/app_button.dart';
import '../components/app_dropdown_field.dart';
import '../tokens/app_spacing.dart';

/// QA tool for E3-04: pick the acting/viewer role, then open either the
/// Members & Roles roster or the Permission Matrix as that role -- same
/// "demo + controls" pattern as ProfileScreenDemo/TeamHomeDemo.
class MembersRolesDemo extends StatefulWidget {
  const MembersRolesDemo({super.key});

  @override
  State<MembersRolesDemo> createState() => _MembersRolesDemoState();
}

class _MembersRolesDemoState extends State<MembersRolesDemo> {
  TeamMemberRole _role = TeamMemberRole.owner;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Roles & permissions (QA)')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppDropdownField<TeamMemberRole>(
              key: const ValueKey('membersRolesDemoRoleField'),
              label: 'Acting as',
              value: _role,
              options: TeamMemberRole.values,
              labelBuilder: (r) => teamMemberRoleLabels[r]!,
              onChanged: (value) => setState(() => _role = value),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              key: const ValueKey('membersRolesDemoOpenRoster'),
              variant: AppButtonVariant.primary,
              label: 'Open members & roles',
              fullWidth: true,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => MembersRolesScreen(
                    actingRole: _role,
                    actorName: teamMemberRoleLabels[_role]!,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              key: const ValueKey('membersRolesDemoOpenMatrix'),
              variant: AppButtonVariant.secondary,
              label: 'Open permission matrix',
              fullWidth: true,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PermissionMatrixScreen(viewerRole: _role),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
