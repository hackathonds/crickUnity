import 'package:flutter/material.dart';

import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'team_member_models.dart';

/// DS §7 screen 12: "Permission-Matrix link opens read-only table
/// screen." PRD §6.5-6.7: "Team Settings screen exposes a Permission
/// Matrix table (rows=actions, columns=roles, checkmarks) so every
/// member can see who can do what. Owner can toggle 6 configurable
/// cells."
///
/// The base table is read-only for everyone. The PRD only names 2 of
/// the "6 configurable cells" as illustrative examples ("e.g.") -- the
/// other 4 aren't specified in either frozen document, so only the two
/// named ones are implemented as Owner-toggleable; this gap is called
/// out in the story's PR rather than guessed.
class PermissionMatrixScreen extends StatefulWidget {
  final TeamMemberRole viewerRole;

  const PermissionMatrixScreen({super.key, required this.viewerRole});

  @override
  State<PermissionMatrixScreen> createState() => _PermissionMatrixScreenState();
}

class _PermissionMatrixScreenState extends State<PermissionMatrixScreen> {
  late final Map<String, bool> _configurableValues = {
    for (final cell in configurablePermissionCells)
      cell.label: cell.defaultValue,
  };

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final isOwner = widget.viewerRole == TeamMemberRole.owner;

    Widget checkmark(bool granted) => Icon(
      granted ? Icons.check : Icons.remove,
      size: 18,
      color: granted ? colors.success : colors.textTertiary,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Permission matrix')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Table(
              key: const ValueKey('permissionMatrixTable'),
              defaultColumnWidth: const IntrinsicColumnWidth(),
              children: [
                TableRow(
                  children: [
                    const SizedBox(width: 180),
                    for (final role in TeamMemberRole.values)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.sm,
                        ),
                        child: Text(
                          teamMemberRoleLabels[role]!,
                          style: AppTypography.label.copyWith(
                            color: colors.textTertiary,
                          ),
                        ),
                      ),
                  ],
                ),
                for (final row in permissionMatrixRows)
                  TableRow(
                    children: [
                      // TableRow itself has no discoverable Element for
                      // find.byKey (its `key` is Table-internal
                      // reconciliation only) -- the key belongs on an
                      // actual child widget instead.
                      Padding(
                        key: ValueKey('permissionRow_${row.action}'),
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.sm,
                        ),
                        child: Text(
                          row.action,
                          style: AppTypography.body.copyWith(
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                      for (final role in TeamMemberRole.values)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                          ),
                          child: checkmark(row.grantedTo.contains(role)),
                        ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            'Owner-configurable',
            style: AppTypography.label.copyWith(color: colors.textTertiary),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final cell in configurablePermissionCells)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      cell.label,
                      style: AppTypography.body.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                  if (isOwner)
                    Switch(
                      key: ValueKey('configurableCellSwitch_${cell.label}'),
                      value: _configurableValues[cell.label]!,
                      onChanged: (value) => setState(
                        () => _configurableValues[cell.label] = value,
                      ),
                    )
                  else
                    checkmark(_configurableValues[cell.label]!),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
